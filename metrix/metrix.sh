#!/bin/bash

collect_and_view_metrics() {
    local folder=$1       # First argument is the folder to change into (optional)
    shift                 # Shift to remove the folder argument
    local files=("$@")    # Remaining arguments are the files to collect (optional)

    original_dir=$(pwd)
    if [ -n "$folder" ]; then
        cd "$folder" || { echo "Failed to change directory to $folder"; exit 1; }
    fi

    # If files include "*.*", expand it in the current directory (after cd)
    for i in "${!files[@]}"; do
        if [[ "${files[$i]}" == "*.*" ]]; then
            files=("${files[@]:0:$i}" ./*.* "${files[@]:$((i + 1))}")
        fi
    done

    (metrix++ collect --std.code.lines.code --std.code.complexity.cyclomatic "${files[@]}" && metrix++ view) 2> /dev/null | awk '
    /Overall metrics for/ {
        match($0, /Overall metrics for '\''([^'\'']+)'\'' metric/, arr)
        metric = arr[1]
    }
    /Total\s+:\s+[0-9.]+/ {
        print metric ": " $NF
    }'

    # Change back to the original directory
    cd "$original_dir" || { echo "Failed to change directory back to $original_dir"; exit 1; }
}

directories=(
    "Enzyme" "git clone https://github.com/EnzymeAD/Enzyme.git Enzyme && cd Enzyme && git checkout bc856756bc1639bcb6d1173030adcc4479a00c17 && cd .."
    "AD" "git clone https://github.com/NeuralCoder3/thorin2.git AD -b ad_ptr_merge"
)

# Clone the repositories if they don't exist
for ((i = 0; i < ${#directories[@]}; i += 2)); do
    dir=${directories[i]}
    git_command=${directories[i + 1]}
    if [ ! -d "$dir" ]; then
        echo "Cloning $dir repository..."
        eval "$git_command"
    fi
done

echo "Comparing the complexity of Enzyme and MimIR AD"
echo 

echo "Complexity of Enzyme (core only)"
collect_and_view_metrics "Enzyme/enzyme/Enzyme" "TypeAnalysis" "SCEV/ScalarEvolutionExpander12.cpp" "*.*" | tee enzyme_core_metrics.txt
echo 
echo "Complexity of Enzyme in total"
collect_and_view_metrics "Enzyme/enzyme/Enzyme" | tee enzyme_total_metrics.txt
echo
echo "Complexity of MimIR AD (core only)"
collect_and_view_metrics "AD/dialects/autodiff" | tee mimir_core_metrics.txt
echo
echo "Complexity of MimIR AD"
collect_and_view_metrics "AD/dialects" "autodiff" "affine" "matrix" "direct" "core" | tee mimir_total_metrics.txt
