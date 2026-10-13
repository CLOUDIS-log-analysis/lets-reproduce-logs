#!/usr/bin/env bash

./configure \
  --prefix="$HOME/ksh/runtime" \
  --with-http_sub_module \
  --with-debug \
  --with-cc-opt='-O0 -g3 -fno-omit-frame-pointer' \
  --without-http_rewrite_module \
  --without-pcre \
  --without-http_gzip_module
