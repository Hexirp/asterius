#!/bin/sh

set -eu

export PATH=/opt/wasi-sdk/bin:$PATH

clang \
  -Wl,--compress-relocations \
  -Wl,--export=aligned_alloc \
  -Wl,--export=calloc \
  -Wl,--export=free \
  -Wl,--export=malloc \
  -Wl,--export=realloc \
  -Wl,--strip-all \
  -O3 \
  -o asterius-libc.wasm \
  main.c
