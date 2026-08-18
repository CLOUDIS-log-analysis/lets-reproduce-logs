#!/usr/bin/env python3
"""Convert MongoDB structured JSON logs to the pre-4.4 text layout."""

from __future__ import annotations

import argparse
import json
import os
import re
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, TextIO


PLACEHOLDER = re.compile(r"\{([^{}]+)\}")


class ConversionError(Exception):
    """An input line cannot be represented as a MongoDB JSON log record."""


def compact_json(value: Any) -> str:
    """Render a JSON value without adding whitespace or ASCII escapes."""
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"))


def escape_line(value: str) -> str:
    """Keep one converted record on one physical output line."""
    return value.replace("\r", "\\r").replace("\n", "\\n")


def render_value(value: Any) -> str:
    """Render a value for a legacy message or key=value suffix."""
    if isinstance(value, str):
        return escape_line(value)
    if value is True:
        return "true"
    if value is False:
        return "false"
    if value is None:
        return "null"
    if isinstance(value, (dict, list)):
        return compact_json(value)
    return str(value)


def format_timestamp(value: Any) -> str:
    """Convert ISO-8601/EJSON dates to MongoDB's legacy millisecond layout."""
    if isinstance(value, dict) and "$numberLong" in value:
        value = value["$numberLong"]

    if isinstance(value, (int, float)) or (
        isinstance(value, str) and value.lstrip("-").isdigit()
    ):
        try:
            timestamp = datetime.fromtimestamp(float(value) / 1000, tz=timezone.utc)
        except (OverflowError, OSError, ValueError) as error:
            raise ConversionError(f"invalid t.$date value {value!r}") from error
    elif isinstance(value, str):
        try:
            timestamp = datetime.fromisoformat(value.replace("Z", "+00:00"))
        except ValueError as error:
            raise ConversionError(f"invalid t.$date value {value!r}") from error
        if timestamp.tzinfo is None:
            raise ConversionError(f"t.$date has no UTC offset: {value!r}")
    else:
        raise ConversionError(f"invalid t.$date value {value!r}")

    timestamp = timestamp.astimezone(timezone.utc)
    return (
        timestamp.strftime("%Y-%m-%dT%H:%M:%S.")
        + f"{timestamp.microsecond // 1000:03d}"
        + timestamp.strftime("%z")
    )


def render_message(message: Any, attributes: dict[str, Any]) -> tuple[str, set[str]]:
    """Fill direct {attribute} placeholders and report consumed attributes."""
    if not isinstance(message, str):
        raise ConversionError("msg is missing or is not a string")

    used: set[str] = set()

    def replace(match: re.Match[str]) -> str:
        name = match.group(1)
        if name not in attributes:
            return match.group(0)
        used.add(name)
        return render_value(attributes[name])

    return escape_line(PLACEHOLDER.sub(replace, message)), used


def render_record(record: dict[str, Any], preserve_structured_fields: bool) -> str:
    """Render one structured record using the classic MongoDB text layout."""
    timestamp = record.get("t")
    if not isinstance(timestamp, dict) or "$date" not in timestamp:
        raise ConversionError("t.$date is missing")

    severity = record.get("s")
    component = record.get("c")
    context = record.get("ctx", "-")
    if not isinstance(severity, str) or not severity:
        raise ConversionError("s is missing or is not a string")
    if not isinstance(component, str) or not component:
        raise ConversionError("c is missing or is not a string")
    if not isinstance(context, str):
        raise ConversionError("ctx is not a string")

    attributes = record.get("attr", {})
    if attributes is None:
        attributes = {}
    if not isinstance(attributes, dict):
        raise ConversionError("attr is not an object")

    message, consumed = render_message(record.get("msg"), attributes)
    suffixes = [
        f"{key}={render_value(value)}"
        for key, value in attributes.items()
        if key not in consumed
    ]

    if preserve_structured_fields:
        # These fields have no old log-header equivalent, so retaining them is
        # opt-in rather than part of the default legacy layout.
        for key in ("tags", "truncated", "size"):
            if key in record:
                suffixes.append(f"{key}={compact_json(record[key])}")

    body = " ".join([message, *suffixes])
    return (
        f"{format_timestamp(timestamp['$date'])} "
        f"{severity:<2} {component:<8} [{escape_line(context)}] {body}"
    )


def decode_record(
    raw_line: str, source: Path, line_number: int, ignore_trailing_data: bool
) -> dict[str, Any] | None:
    """Decode one JSONL line, optionally ignoring trailing non-JSON bytes."""
    if not raw_line.strip():
        return None

    decoder = json.JSONDecoder()
    content = raw_line.lstrip()
    try:
        value, end = decoder.raw_decode(content)
    except json.JSONDecodeError as error:
        raise ConversionError(
            f"{source}:{line_number}: invalid JSON: {error.msg}"
        ) from error

    if not isinstance(value, dict):
        raise ConversionError(f"{source}:{line_number}: JSON record is not an object")

    trailing = content[end:].strip()
    if trailing:
        detail = repr(trailing if len(trailing) <= 80 else trailing[:77] + "...")
        if not ignore_trailing_data:
            raise ConversionError(
                f"{source}:{line_number}: non-JSON trailing data {detail}"
            )
        print(
            f"warning: {source}:{line_number}: ignoring non-JSON trailing data {detail}",
            file=sys.stderr,
        )
    return value


def convert(
    source: Path,
    destination: TextIO,
    ignore_trailing_data: bool,
    preserve_structured_fields: bool,
) -> None:
    """Stream-convert source records into destination."""
    with source.open("r", encoding="utf-8") as input_file:
        for line_number, raw_line in enumerate(input_file, start=1):
            record = decode_record(
                raw_line.rstrip("\n"), source, line_number, ignore_trailing_data
            )
            if record is None:
                continue
            try:
                destination.write(render_record(record, preserve_structured_fields) + "\n")
            except ConversionError as error:
                raise ConversionError(f"{source}:{line_number}: {error}") from error


def parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Convert MongoDB JSON log records to the pre-4.4 text layout."
    )
    parser.add_argument("input", type=Path, help="structured JSON log file")
    parser.add_argument(
        "output",
        type=Path,
        nargs="?",
        help="legacy-format output file (default: standard output)",
    )
    parser.add_argument(
        "--ignore-trailing-data",
        action="store_true",
        help="warn and ignore non-JSON data after an otherwise valid JSON object",
    )
    parser.add_argument(
        "--preserve-structured-fields",
        action="store_true",
        help="append JSON-only tags, truncated, and size fields as key=value suffixes",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(sys.argv[1:] if argv is None else argv)
    source = args.input

    if not source.is_file():
        print(f"error: input file does not exist: {source}", file=sys.stderr)
        return 2

    if args.output is None:
        try:
            convert(
                source,
                sys.stdout,
                args.ignore_trailing_data,
                args.preserve_structured_fields,
            )
        except (ConversionError, OSError) as error:
            print(f"error: {error}", file=sys.stderr)
            return 1
        return 0

    destination = args.output
    try:
        if source.resolve() == destination.resolve():
            print("error: output file must differ from input file", file=sys.stderr)
            return 2

        if not destination.parent.is_dir():
            print(
                f"error: output directory does not exist: {destination.parent}",
                file=sys.stderr,
            )
            return 2
        temporary_fd, temporary_name = tempfile.mkstemp(
            prefix=f".{destination.name}.", suffix=".tmp", dir=destination.parent, text=True
        )
        try:
            with os.fdopen(temporary_fd, "w", encoding="utf-8", newline="\n") as output_file:
                convert(
                    source,
                    output_file,
                    args.ignore_trailing_data,
                    args.preserve_structured_fields,
                )
            os.replace(temporary_name, destination)
        except BaseException:
            try:
                os.unlink(temporary_name)
            except FileNotFoundError:
                pass
            raise
    except (ConversionError, OSError) as error:
        print(f"error: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
