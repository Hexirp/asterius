#!/bin/bash

set -euo pipefail

echo 'deb [check-valid-until=no] http://snapshot.debian.org/archive/debian/20200828T083857Z sid main contrib non-free' > /etc/apt/sources.list
apt update
apt full-upgrade -y
apt install -y \
  automake \
  build-essential \
  curl \
  gawk \
  git \
  libdw-dev \
  libffi-dev \
  libgmp-dev \
  libncurses-dev \
  libtool-bin \
  pkg-config \
  python3-sphinx \
  xz-utils \
  zlib1g-dev
mkdir -p ~/.local/bin
curl -L https://github.com/commercialhaskell/stack/releases/download/v2.3.3/stack-2.3.3-linux-x86_64-bin -o ~/.local/bin/stack
chmod u+x ~/.local/bin/stack
~/.local/bin/stack --resolver ghc-8.8.4 install \
  alex-3.2.5 \
  happy-1.19.12 \
  hscolour-1.24.4

pushd /tmp
git clone --recurse-submodules --branch $BRANCH https://github.com/TerrorJack/ghc.git
popd

export PATH=~/.local/bin:$(~/.local/bin/stack path --compiler-bin):$PATH
mv .github/workflows/build-linux-dwarf.mk /tmp/ghc/mk/build.mk
pushd /tmp/ghc
./boot
./configure --enable-dwarf-unwind
make
make binary-dist
mkdir ghc-bindist
mv *.tar.* ghc-bindist/
(ls -l ghc-bindist && sha256sum -b ghc-bindist/*) > ghc-bindist/sha256.txt
popd

mv /tmp/ghc/ghc-bindist .
