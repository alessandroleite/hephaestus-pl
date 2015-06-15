#!/bin/bash

REPOSITORY_HOME=$PWD

apt-get update -qq
apt-get install -qq libgmp3c2 wget lbzip2
# mkdir ghc-7.6.3 && cd ghc-7.6.3
wget https://www.haskell.org/ghc/dist/7.6.3/ghc-7.6.3-x86_64-unknown-linux.tar.bz2 --no-check-certificate
tar xvf ghc-7.6.3-x86_64-unknown-linux.tar.bz2 && cd ghc-7.6.3
./configure --prefix=/opt/ghc && make install
export PATH=/opt/ghc/bin:$PATH

apt-get install -qq libgmp3-dev libglc-dev freeglut3 freeglut3-dev
wget http://lambda.haskell.org/platform/download/2013.2.0.0/haskell-platform-2013.2.0.0.tar.gz --no-check-certificate
tar xvf haskell-platform-2013.2.0.0.tar.gz && cd haskell-platform-2013.2.0.0
./configure --prefix=/opt/haskell-platform --enable-unsupported-ghc-version
make -j4 && make install
export PATH=/opt/haskell-platform/bin:$PATH

apt-get install -qq ncurses-dev

cabal update

cabal install bimap         \
              bitset        \
              parse-dimacs  \
              hxt-relaxng              

cabal install hatt     \
              fgl      \
              graphviz \
              syb      \
              MissingH \
              text-0.11.3.1

cd $REPOSITORY_HOME/hephaestus-pl

make test-products

# https://gist.github.com/wting/8498731