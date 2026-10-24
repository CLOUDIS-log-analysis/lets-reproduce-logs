#!/usr/bin/env bash

set -euo pipefail

BASE="$HOME/ksh"
RUNTIME="$BASE/runtime"

./configure \
	--prefix="$RUNTIME" \
	--with-debug \
	--with-http_ssl_module \
	--with-cc-opt="-O0 -g3 -fno-omit-frame-pointer"
