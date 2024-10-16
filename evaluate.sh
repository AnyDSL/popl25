#!/bin/bash

set -e

SCRIPT_PATH=$(dirname $(realpath $0))

export PATH=${SCRIPT_PATH}/install/bin:$PATH
export LD_LIBRARY_PATH=${SCRIPT_PATH}/install/lib:$LD_LIBRARY_PATH

mkdir -p ${SCRIPT_PATH}/output

cd MimIR
git submodule update --init --recursive

# install MimIR
mkdir -p build && cd build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=OFF -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=${SCRIPT_PATH}/install
ninja install

# install impala
mkdir -p ${SCRIPT_PATH}/impala/build && cd ${SCRIPT_PATH}/impala/build
cmake .. -G Ninja -DCMAKE_BUILD_TYPE=Release -DMim_DIR=${SCRIPT_PATH}/install/lib/cmake/mim -DCMAKE_CXX_COMPILER=g++ -DCMAKE_C_COMPILER=gcc -DCMAKE_INSTALL_PREFIX=${SCRIPT_PATH}/install
ninja install

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
./build/benchmark_mail annotated.txt 2> ${SCRIPT_PATH}/output/benchmark_mail_runtime_full.csv | tee ${SCRIPT_PATH}/output/benchmark_mail_runtime.csv
echo "Summary results are saved in output/benchmark_mail_runtime.csv"
echo "Full results are saved in output/benchmark_mail_runtime_full.csv"

echo "Compile-time RegEx Benchmark"
cd build
cmake . -DREGEX_COMPILE_TIME_BENCHMARK=ON
# warm-up the file cache once
make clean; make -n benchmark_mail 2> /dev/null | grep -E "(clang++|bin/mim)" | sed "s/^/time /" | bash --verbose &> /dev/null
make clean; make -n benchmark_mail 2> /dev/null | grep -E "(clang++|bin/mim)" | sed "s/^/time /" | bash --verbose |& grep -oP "(\-o [\/\w\.]+|\-c [\/\w\.]+|[\/\w\.]+ --output-ll [\/\w\.]+|user.*$)" |& tee ${SCRIPT_PATH}/output/benchmark_mail_compiletime.csv

echo "CLOC RegEx implementations"
rm -rf pcre2 &> /dev/null
git clone https://github.com/PCRE2Project/pcre2.git &> /dev/null
cd pcre2
git reset --hard 0ef82f7eb78e9effd662239c6dac70c534a6d60b &> /dev/null # this is the commit we used in the paper
cd ../..

echo -n "CTRE: " | tee ${SCRIPT_PATH}/output/regex_cloc.txt
cloc --csv compile-time-regular-expressions/single-header/ctre.hpp | grep "SUM" | grep -oP "\d+$" | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt

echo -n "std::regex: " | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt
CPP_INCLUDE=`c++ -xc++ /dev/null -E -Wp,-v 2>&1 | sed -n 's,^ ,,p' | grep "/" | head -n 1`
cloc ${CPP_INCLUDE}/bits/regex* --csv | grep "SUM" | grep -oP "\d+$" | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt

echo -n "PCRE2: " | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt
cloc build/pcre2/src --csv | grep "SUM" | grep -oP "\d+$" | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt

echo -n "Hand-written: " | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt
cloc manual_match_mail.cpp --csv | grep "SUM" | grep -oP "\d+$" | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt

MIMIR_CPP=`cloc --include-ext="hpp,cpp,h,c" ../MimIR/*/mim/plug/regex ../MimIR/*/automaton --csv | grep "SUM" | grep -oP "\d+$"`
MIMIR_MIM=`cloc --force-lang=rust ../MimIR/src/mim/plug/regex/regex.mim --csv | grep "SUM" | grep -oP "\d+$"`
echo "MimIR: C++: $MIMIR_CPP, Mim: $MIMIR_MIM, Total: $((MIMIR_CPP + MIMIR_MIM))" | tee -a ${SCRIPT_PATH}/output/regex_cloc.txt

echo "REGEX CLOC results are saved in output/regex_cloc.txt"

echo "Run Impala Benchmarks Game"

cd ${SCRIPT_PATH}/benchmarksgame

# for a few benchmarks game benchmarks, we must restrict CopyProp to Basic Block only -> register trap to reset, in case of aborting benchmark...
trap 'sed -i "s/(%mem.copy_prop_pass (beta_red, eta_exp, .tt));/(%mem.copy_prop_pass (beta_red, eta_exp, .ff));/" ${SCRIPT_PATH}/install/lib/mim/mem.mim; exit' INT
sed -i 's/(%mem.copy_prop_pass (beta_red, eta_exp, .ff));/(%mem.copy_prop_pass (beta_red, eta_exp, .tt));/' ${SCRIPT_PATH}/install/lib/mim/mem.mim

NO_RUST=1 NO_HASKELL=1 ./run.sh |& tee results
python3 ../scripts/benchmarksgame-stddev.py | tee ${SCRIPT_PATH}/output/benchmarksgame.csv

# restore CopyProp to general Lams:
sed -i 's/(%mem.copy_prop_pass (beta_red, eta_exp, .tt));/(%mem.copy_prop_pass (beta_red, eta_exp, .ff));/' ${SCRIPT_PATH}/install/lib/mim/mem.mim
echo "Benchmark Game results are saved in output/benchmarksgame.csv"

echo "Compute AD Complexity"
# run the metrix.sh script
cd ${SCRIPT_PATH}/metrix
./metrix.sh | tee ${SCRIPT_PATH}/output/metrix.txt

echo "Run GMM benchmarks"
cd ${SCRIPT_PATH}/
sudo docker run -ti -v "`pwd`/output/autodiff/gmm:/output" -e FOLDERS="10k_small" fodinabor/mimir-ad-bench:gmm
python3 scripts/plot_gmm.py
echo "GMM results are saved in output/autodiff"

echo "Building the Coq soundness proof files."
cd ${SCRIPT_PATH}/soundness
git submodule update --init --recursive
cd mimir
make -j`nproc`

echo "Done."
echo "You can find the results in the output directory."
