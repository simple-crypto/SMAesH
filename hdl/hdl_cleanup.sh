#!/bin/sh

# Remove all fv_* and verilator_me attributes

for f in `find $1 -iname '*.v'`; do
    echo "Cleaning $f"
    # Delete attribtutes... best-effort regexes
    for ATTR in fv_ verilator_me; do 
        # in the middle of a list
        sed -i -e "s/,\s*$ATTR.*=\s*[a-zA-Z0-9_]*,/,/g" $f
        # single attribute in a list
        sed -i -e "s/(\*\s*$ATTR.*=\s*\([a-zA-Z0-9_]*\|\".*\"\)\s*\*)//g" $f
        # attribute at the end of a list
        sed -i -e "s/,\s*$ATTR.*=\s*\([a-zA-Z0-9_]*\|\".*\"\)\s*\*)/ \*)/g" $f
        # attribute at the start of a list
        sed -i -e "s/(\*\s*$ATTR.*=\s*\([a-zA-Z0-9_]*\|\".*\"\)\s*,/(* /g" $f
    done
done
