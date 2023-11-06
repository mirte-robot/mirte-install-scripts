#!/bin/bash
git clone  https://github.com/json-c/json-c.git -b json-c-0.17
cd json-c
mkdir build
cd build
cmake -DCMAKE_BUILD_TYPE=Release ..
make
make install # requires sudo privileges
cd ../../
rm -rf json-c
ldconfig