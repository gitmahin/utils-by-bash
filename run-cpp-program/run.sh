# !/bin/bash
shopt -s extglob
exec 2> debug.log 

set -x
INPUT_OPTION=$1
INPUT_FILE=$2

avaiableOptions=("-d" "-o")

# check input options
[[ -z "$INPUT_OPTION" && ! " ${avaiableOptions[*]} " =~ [[:space:]]${INPUT_OPTION}[[:space:]] ]] && { echo "Invalid option $INPUT_OPTION"; exit 1; }

getFileDivision() {
    file="$1"
    # get value before the last .*
    file_name="${file%.*}"

    # get value after the last *.
    file_ext="${file##*.}"

    echo "$file_name;$file_ext"
    return 0
}

isCPPFile() {
    file="$1"
    [[ "$file" == *.cpp || "$file" == *.c++ ]] && return 0 || return 1
}

compilerManager(){
    local file="$2" option="$1"

    # if file($2) is not provided store option($1) value in file(var)
    [[ -z "$file" ]] && file="$option"

    IFS=";" read -r file_name file_ext <<< "$(getFileDivision "$file")"


    # check if file not exist
    # swap the file ext and try to find out the file

    
    if $(isCPPFile "$file"); then
        if [[ ! -e "$file" ]]; then
            [[ "$file" == "*.cpp" ]] && file="$file_name.c++" || file="$file_name.cpp"
        fi
        else
            echo ";$file"
    fi

    if [[ "$file_ext" == @(cpp|c++) ]]; then
        # compile c++
        g++ "$file" -o "$file_name" > /dev/null 2>&1
    fi

    if [[ "$option" == "-d" ]]; then
        folder_name="f-$file_name"
        [[ ! -d "$folder_name" ]] && mkdir "$folder_name" > /dev/null 2>&1
        # dont move only stderr to null (e.g. 2> /dev/null)
        # because the mv -v commands also printed to standard output, the entire output captured by $(compilerManager ...)
        mv -v "$file" "./$folder_name" > /dev/null 2>&1
        mv -v "$file_name" "./$folder_name" > /dev/null 2>&1

        [[ ! -e "./$folder_name/$file_name" ]] && file_name="$file_name.out" || file_name="${file_name%.*}"

    fi

    echo "$folder_name;$file_name"
    return 0
}

# check g++ installation
# redirect file discriptor and get only exit status
if ! g++ -v &> /dev/null; then
    echo "g++ not installed! Installing..."
    echo "RUN: sudo apt-get update"
    sudo apt-get update
    echo "RUN: sudo apt-get install build-essential gdb"
    sudo apt-get install build-essential gdb
    echo "$(which g++)"
fi

IFS=";" read -r folder_name file_name <<< "$(compilerManager "$INPUT_OPTION" "$INPUT_FILE")"

echo "Hello brother -> $folder_name; $file_name"
if [[ -d "$folder_name" && ! -z "$file_name" ]]; then
    "./$folder_name/$file_name"
elif [[ -e "$file_name" ]]; then
    "./$file_name"
else 
    echo "Given file location not exist"
fi
set +x
