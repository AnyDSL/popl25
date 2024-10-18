#!/bin/bash

echo "Building Torch"

python -m venv venv
source venv/bin/activate
pip install -r requirements.txt


benchfiles=(
    "ba" "BA 1:" "ba5_n257_m65132_p225911.txt" "gmm/torch/main.py BA"
    "ba" "BA 2:" "ba13_n245_m198739_p1091386.txt" "gmm/torch/main.py BA"
    "lstm" "LSTM 1:" "lstm_l2_c1024.txt" "gmm/torch/main.py LSTM"
    "lstm" "LSTM 2:" "lstm_l4_c4096.txt" "gmm/torch/main.py LSTM"
    "gmm" "GMM 1:" "1k/gmm_d20_K100.txt" "gmm/torch/main.py GMM"
    "gmm" "GMM 2:" "10k/gmm_d32_K100.txt" "gmm/torch/main.py GMM"
    "nn" "NN 1:" "7840 10000 100" "nn/torch/torch_nn.py"
    "nn" "NN 2:" "7840 50000 100" "nn/torch/torch_nn.py"
)

SCRIPT_PATH=$(dirname $(realpath $0))
cd mount/impala-adbench
# python nn/torch/torch_nn.py 7840 10000 10
# python3 gmm/torch/main.py GMM
# python3 gmm/torch/main.py BA
# python3 gmm/torch/main.py LSTM

for (( i=0; i<${#benchfiles[@]}; i+=4 ))
do
    if [ $((i % 8)) -eq 0 ]; then
        echo | tee -a $SCRIPT_PATH/output.txt
    fi
    echo "${benchfiles[i+1]}" | tee -a $SCRIPT_PATH/output.txt
    echo -n "  Torch: " | tee -a $SCRIPT_PATH/output.txt
    $SCRIPT_PATH/scripts/timit.sh python3 ${benchfiles[i+3]} ${benchfiles[i+2]} | tee -a $SCRIPT_PATH/output.txt
done

cd $SCRIPT_PATH