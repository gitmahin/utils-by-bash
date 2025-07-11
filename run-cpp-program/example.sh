# !/bin/bash

file=$1


isCPPFile() {
    [[ "$file" == *.cpp || "$file" == *.c++ ]] && return 0 || return 1
}

if [[ "$(isCPPFile)" != 0 ]];then
    echo "$file;"
fi