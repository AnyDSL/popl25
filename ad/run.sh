#!/bin/bash

mkdir -p mount 

folders=(
    "Enzyme" "git clone https://github.com/EnzymeAD/Enzyme.git Enzyme && cd Enzyme && git checkout bc856756bc1639bcb6d1173030adcc4479a00c17 && cd .."
    "mount/impala" "git clone --recurse-submodules https://github.com/NeuralCoder3/impala.git -b feature/autodiff-for mount/impala"
    "mount/thorin2" "git clone --recurse-submodules https://github.com/NeuralCoder3/thorin2.git -b feature/autodiff-for-null mount/thorin2"
    "mount/impala-adbench" "git clone https://github.com/NeuralCoder3/adbench-thorin.git mount/impala-adbench"
)

for (( i=0; i<${#folders[@]}; i+=2 ))
do
    if [ ! -d "${folders[i]}" ]; then
        eval "${folders[i+1]}"
    else
        echo "${folders[i]} already exists"
    fi
done

function container_run {
    docker run -v "`pwd`/scripts:/scripts" -v "`pwd`/Enzyme:/Enzyme" -v "`pwd`/mount:/app" --user 1000 fodinabor/llvm-dev:14-noble "$@"
}

echo "Building Enzyme and MimIR"

build_dirs=( 
    "Enzyme/enzyme/build"
    "mount/impala/build"
)
all_exist=false
if [ -z "$FORCE_BUILD" ]; then
    all_exist=true
    for dir in "${build_dirs[@]}"; do
        if [ ! -d "$dir" ]; then
            all_exist=false
            break
        fi
    done
fi
if [ "$all_exist" = true ]; then
    echo "All build directories exist, skipping build (set FORCE_BUILD=1 to force rebuild)"
else
    container_run /scripts/build.sh
fi


echo "Building Benchmarks Enzyme"

benchmarks=(
    "ba"
    "lstm"
    "gmm"
    "nn"
)
for bm in "${benchmarks[@]}"; do
    outfile="mount/impala-adbench/build/$bm/enzyme/${bm}_enzyme"
    if [ -f "$outfile" ]; then
        echo "  $bm already exists"
        continue
    fi
    echo "  Building $bm"
    container_run bash -c "cd /app/impala-adbench/$bm && make build-enzyme-native"
done

echo "Building Benchmarks MimIR"

for bm in "${benchmarks[@]}"; do
    outfile="mount/impala-adbench/build/$bm/impala/native/${bm}_impala"
    if [ -f "$outfile" ]; then
        echo "  $bm already exists"
        continue
    fi
    echo "  Building $bm"
    container_run bash -c "cd /app/impala-adbench/$bm && make build-impala"
done


echo 

echo "Running Benchmarks"

benchfiles=(
    "ba" "BA 1:" "ba5_n257_m65132_p225911.txt" 
    "ba" "BA 2:" "ba13_n245_m198739_p1091386.txt"
    "lstm" "LSTM 1:" "lstm_l2_c1024.txt" 
    "lstm" "LSTM 2:" "lstm_l4_c4096.txt"
    "gmm" "GMM 1:" "1k/gmm_d20_K100.txt"
    "gmm" "GMM 2:" "10k/gmm_d32_K100.txt"
    "nn" "NN 1:" "7840 10000 100"
    "nn" "NN 2:" "7840 50000 100"
)

rm -f output.txt

for (( i=0; i<${#benchfiles[@]}; i+=3 ))
do
    if [ $((i % 6)) -eq 0 ]; then
        echo | tee -a output.txt
    fi
    echo "${benchfiles[i+1]}" | tee -a output.txt
    # Bench 1:
    #   Enzyme: X
    #   Thorin: Y
    container_run bash -c "
        cd /app/impala-adbench/${benchfiles[i]} && 
        echo -n '  Enzyme: ' && 
        /scripts/timit.sh /app/impala-adbench/build/${benchfiles[i]}/enzyme/${benchfiles[i]}_enzyme /app/impala-adbench/benchmark/${benchfiles[i]}/${benchfiles[i+2]} && \
        echo -n '  Thorin: ' && 
        /scripts/timit.sh /app/impala-adbench/build/${benchfiles[i]}/impala/native/${benchfiles[i]}_impala /app/impala-adbench/benchmark/${benchfiles[i]}/${benchfiles[i+2]}" | tee -a output.txt
done
