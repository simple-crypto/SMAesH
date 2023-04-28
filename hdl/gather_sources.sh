#! /bin/bash

# Copy all HDL source files in OUT_DIR.

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

if [ -z "$OUT_DIR" ]
then
    echo "OUT_DIR must be set"
    exit
fi


mkdir -p $OUT_DIR

# Iterate over each directory
for var in "$@"
do
    dir="$SCRIPT_DIR/$var"
    files=$(find $dir -name '*.v' -o -name '*.vh')
    for file in $files
    do
        cp $file $OUT_DIR
        echo "$file copied to $OUT_DIR"
    done
done
