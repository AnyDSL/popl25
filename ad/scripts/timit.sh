#!/bin/bash

# all remaining args are the command 
# e.g. timit ./a --config config.json
# only returns the runtime in milliseconds
# but voids the output


# Run the command and time it
start=$(date +%s%N)
"$@" > /dev/null 2>&1
# timeout 600s "$@" > /dev/null 2>&1
end=$(date +%s%N)

# Calculate the runtime in milliseconds
runtime=$((($end - $start)/1000000))

# Return the runtime
echo $runtime