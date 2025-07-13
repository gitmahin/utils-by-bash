# !/bin/bash
shopt -s extglob

# measuring compilation starting time
start_time_ns=$(date +%s%N)

# user inputs globally
option="$1"
file="$2"

# cp -> compile in parallel
is_parallel_mode=0

# d -> merge .out and .cpp file into directory
is_d_mode=0

is_auto_find_file_mode=0

autoFindCppFiles(){
    local result=""
    result=$(ls *.cpp *.c++ 2> /dev/null) 
    [[ -z "$result" ]] && { echo "No file found!"; exit 1; }
    echo "$result"
}

askToContinue() {
    local choose
    read -p "Do you want to continue? [y/n]" choose
    [[ "$choose" == [yY] ]] && return 0 || return 1
}

getOption() {
    # find the option starting with hyphen
    if [[ "$option" == -* ]]; then
        # Remove the hyphen for easier parsing
        parsed_options="${option:1}"

        # ISSUE: Correctly check that given option is available
        # =~ check if the string "pl" is found anywhere within parsed_options
        if [[ "$parsed_options" =~ "pl" ]]; then  
            is_parallel_mode=1
        fi

        if [[ "$parsed_options" =~ "d" ]]; then
            is_d_mode=1
        fi

        if [[ "$parsed_options" =~ "a" && "$parsed_options" =~ "pl" ]]; then
            is_auto_find_file_mode=1
        fi

    else
        # if file($2) is not provided store option($1) value in file(var)
        [[ -z "$file" ]] && file="$option"
        return 0
    fi
}

# call the function
getOption
[[ $? == 1 ]] && { echo "Invalid options"; exit 1; }

# cpp file validation
isCPPFile() {
    # user validation
    local file=$1
    [[ "$file" == *.cpp || "$file" == *.c++ ]] && return 0 || return 1
}

# out file validation
isOutFile() {
    # user validation
    local file=$1
    [[ "$file" == *.out ]] && return 0 || return 1
}

# extract file_name and file_ext from core file 
getFileDivision() {
    local file=$1
    local file_name
    local file_ext
    # if name doesn't indicate to cpp file pass the file as it is
    if ! $(isCPPFile "$file"); then
        if $(isOutFile "$file"); then
            file_name="${file%.*}"
            echo "$file_name;"
        else
            echo "$file;"
        fi
    else
        # get value before the last .*
        file_name="${file%.*}"

        # get value after the last *.
        file_ext="${file##*.}"

        echo "$file_name;$file_ext"
    fi
    return 0
}

# cpp code compiler
compileCpp(){
    local file=$1
    local file_name=$2
    local folder_name
    # compile c++
    # user validation -> isCPPFile
    if  $(isCPPFile "$file"); then
        # backend validation -> if file existes
        # echo "inside $file"
        if [[ -e "$file" ]]; then
            g++ "$file" -o "$file_name" 2> /dev/tty || exit 1
        # in directory mode
        elif [[ "$is_d_mode" == 1 && ! -e "$file" ]]; then
            folder_name="cpp-$file_name"
            if [[ -e "$folder_name/$file" ]]; then
                g++ "$folder_name/$file" -o "$file_name" 2> /dev/tty || exit 1
            else 
                echo "File not found in the directory"; exit 1;
            fi
        else
       
            echo "File not found in this location"; exit 1;

        fi
    else 
        local file_ext="${file##*.}"
        if [[ "$file" == *"."* && "$file_ext" == "out" ]]; then
            return 0
        elif [[ "$file" != *"."* && "$file_ext" != "out"  ]]; then
            return 0
        else 
            echo "File is not cpp compatitable!"
            exit 1
        fi
    fi
}

# processor
cppCompilerManager(){
    local compile_start_ns=$(date +%s%N)

    IFS=";" read -r file_name file_ext <<< "$(getFileDivision "$file")"
    # echo "$file_name$file_ext"

    # check if user given file ext is cpp or c++
    if  $(isCPPFile "$file"); then
        local folder_name="cpp-$file_name"

        swapFile(){
            [[ "$file" == *.cpp ]] && file="$file_name.c++" || file="$file_name.cpp"
        }
        
        # if file exist then pass the file as it is
        # else if not file exist in current directory, try finding via swaping file extension
        # else not file exist in current directory then go one level up, if not exist
        # && directory mode enabled try finding via swaping the file extension
        if [[ -e "$file" || -e "./$folder_name/$file" ]]; then
            file="$file"
        else
            if [[ ! -e "$file" ]]; then
                swapFile
            elif [[ "$is_d_mode" == 1 && ! -e "./$folder_name/$file" ]]; then
                swapFile
            fi
        fi
    fi
            # echo "$file"

    # compile c++
    # user validation -> isCPPFile
    compileCpp "$file" "$file_name"

    # [[ $? == 1 ]] && echo "not cpp file" || echo "cpp file"

    # in directory mode
    if [[ "$is_d_mode" == 1 ]]; then
        local folder_name="cpp-$file_name"
        local current_path="$(pwd)"
        local parent_folder="$(basename "$current_path")"

        # "If the `new folder name` (f-myprogram) is NOT the same as 
        # the `current dir's name` (my-programe).
        # if new folder name is same to current dir then dont create & move the folder"
        if [[ "$folder_name" != "$parent_folder" ]]; then
            [[ ! -d "$folder_name" && -e "$file" && -e "$file_name" ]] && mkdir "$folder_name" > /dev/null 2>&1
            # dont move only stderr to null (e.g. 2> /dev/null)
            # because the mv -v commands also printed to standard output, the entire output captured by $(cppCompilerManager ...)
            mv -v "$file" "./$folder_name" > /dev/null 2>&1
            mv -v "$file_name" "./$folder_name" > /dev/null 2>&1

        fi
    fi


    # !!! CAUTION: updating $file_name here 
    # swap the output file ext and try to execute
    # if file is not exist it will virtually update the file name to guess the exec file
    # if [[ "$is_d_mode" == 0 && ! -e "$file_name" || ! -e "./$folder_name/$file_name" ]]; then
    #     [[ "./$folder_name/$file_name" == *.out || "$file_name" == *.out ]] && file_name="${file_name%.*}" || file_name="$file_name"
    # fi

    if [[ "$is_d_mode" == 0 && ! -e "$file_name" ]]; then
        [[ "$file_name" == *.out ]] && file_name="${file_name%.*}" || file_name="$file_name.out"
    elif [[ "$is_d_mode" == 1 && ! -e "./$folder_name/$file_name" ]]; then
        [[ "./$folder_name/$file_name" == *.out ]] && file_name="${file_name%.*}" || file_name="$file_name.out"
    fi

    # End timing for compilation here
    local compile_end_ns=$(date +%s%N)
    local compile_duration_ms=$(( (compile_end_ns - compile_start_ns) / 1000000 ))

    # lastly return the folder_name and file_name
    [[ "$is_parallel_mode" == 0 ]] && echo "$folder_name;$file_name" || echo "$compile_duration_ms"
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


case "$is_parallel_mode" in 
    1)
     
            # shift -> for not to include options as a file 
            shift
            declare -A temp_outputs
            files=""

            if [[ "$is_auto_find_file_mode" == 1 ]]; then
                
                outputAutoResult="$(autoFindCppFiles)"
                files=(${outputAutoResult// / })
                echo "${files[@]}"

            fi

            askToContinue
            [[ $? == 1 ]] && { echo "Operation canceled"; exit 1; }

            for file_type in "${files[@]:-$@}"; do
                # making temp file to track out from compilerManger
                temp_output_file=$(mktemp)
                # Start time for this individual compilation in nanoseconds
                loop_start_ns=$(date +%s%N)

                (
                    file="$file_type"
                    # redirect the both stdout & stderr to temp file
                    cppCompilerManager > "$temp_output_file" 2>&1
                ) &
                
                loop_end_ns=$(date +%s%N)
                # calculate duration in nanoseconds
                duration_ns=$(( loop_end_ns - loop_start_ns ))
                # convert nanoseconds to milliseconds (integer division)
                duration_ms=$(( duration_ns / 1000000 ))
                echo "[Started in: $duration_ms ms] => $file_type"

                # adding to the array
                [[ $? != 1 ]] && temp_outputs["$file_type"]="$temp_output_file"
            done

            # wait form compilation
            wait
            
            # Process the results from temporary files
            for file_type in "${files[@]:-$@}"; do
                temp_output_file="${temp_outputs["$file_type"]}"
                
                if [[ -s "$temp_output_file" ]]; then
                    compile_time_ms="$(tail -n 1 "$temp_output_file")"
                    if [[ "$compile_time_ms" =~ ^[0-9]+$ ]]; then
                    echo "[$file_type] => Compiled success in $compile_time_ms ms!"
                    else
                    echo "[$file_type] => $compile_time_ms"
                    fi
                else
                    echo "[$file_type] => $compile_time_ms"
                fi
                
                # remove the temporary file
                rm -f "$temp_output_file"
            done
            exit 0

        ;;

    0)
        result="$(cppCompilerManager)"

        [[ "$result" =~ ";" ]] && IFS=";" read -r folder_name file_name <<< "$(cppCompilerManager)" || echo "$result"
        # IFS=";" read -r folder_name file_name <<< "$(cppCompilerManager)"
        
        if [[ -d "$folder_name" && -e "$folder_name/$file_name" ]]; then
            "./$folder_name/$file_name"
        elif [[ -e "$file_name" ]]; then
            "./$file_name"
        elif [[ -z "$folder_name" && -z "$file_name" ]]; then
            exit 1
        else 
            echo "File not exist or may have been moved!"
            exit 1
        fi
        ;;
    *)
        echo "Invalid options"
        exit 1
        ;;
esac




