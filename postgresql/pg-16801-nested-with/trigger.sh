#!/usr/bin/env bash
docker exec -i pg-16801 psql -U postgres < payload.sql
