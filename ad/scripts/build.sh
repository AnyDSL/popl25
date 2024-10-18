#!/bin/bash

echo "Building Enzyme"

cd /Enzyme/enzyme
mkdir -p build
cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release 
ninja


echo "Building MimIR"

cd /app/impala
CC=gcc CXX=g++ cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release
cd build
ninja

