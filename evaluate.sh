#!/bin/bash

set -e

SCRIPT_PATH=$(dirname $(realpath $0))

cd MimIR
git submodule update --init --recursive

# install MimIR
mkdir -p build && cd build
cmake .. -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=${SCRIPT_PATH}/install
make -j`nproc` install

# install impala
mkdir -p ${SCRIPT_PATH}/impala/build && cd ${SCRIPT_PATH}/impala/build
cmake .. -DCMAKE_BUILD_TYPE=Release -DMim_DIR=${SCRIPT_PATH}/install/lib/cmake/mim -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=${SCRIPT_PATH}/install
make -j`nproc` install

# build regex
mkdir -p ${SCRIPT_PATH}/mimir_regex_benchmark/build && cd ${SCRIPT_PATH}/mimir_regex_benchmark/build
git submodule update --init ../compile-time-regular-expressions
cmake .. -DCMAKE_BUILD_TYPE=Release -DMim_DIR=${SCRIPT_PATH}/install/lib/cmake/mim -DCMAKE_CXX_COMPILER=/usr/bin/clang++ -DCMAKE_C_COMPILER=/usr/bin/clang -DCMAKE_INSTALL_PREFIX=${SCRIPT_PATH}/install
make -j`nproc`

cd ..

echo "Prepare email address annotations"
grep -oE "[a-zA-Z0-9_.\-]+@[a-zA-Z0-9_.\-]+" fradulent_emails.txt > addresses.txt
python3 annotate_matched.py

echo "Run Email Address RegEx Benchmark"
./build/benchmark_mail annotated.txt 2> full_results.csv
echo "Full results are saved in full_results.csv"

echo "Compile-time RegEx Benchmark"
cd build
cmake . -DREGEX_COMPILE_TIME_BENCHMARK=ON
# warm-up the cache
make clean; make -n benchmark_mail 2> /dev/null | grep -E "(clang++|bin/mim)" | sed "s/^/time /" | bash --verbose &> /dev/null
make clean; make -n benchmark_mail 2> /dev/null | grep -E "(clang++|bin/mim)" | sed "s/^/time /" | bash --verbose |& grep -oP "(\-o [\/\w\.]+|\-c [\/\w\.]+|[\/\w\.]+ --output-ll [\/\w\.]+|user.*$)"
