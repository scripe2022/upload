#!/bin/bash
USER="username"
ADDRESS="address"
HASHFILE=".hashfile"
REMOTEDIR="~/project/"

update_hash() {
    file_list=()
    hash_value=()
    while IFS= read -d '' -r filename; do
        file_list+=("$filename")
        md5=`md5sum ${filename} | awk '{ print $1 }'`
        hash_value+=("$md5")
    done < <(find . -type f -print0)

    n=${#file_list[@]}
    :> ./$HASHFILE
    for ((i=0; i<n; i++)); do
        echo ${file_list[$i]} >> ./$HASHFILE
        echo ${hash_value[$i]} >> ./$HASHFILE
    done
}

check_modify() {
    IFS=$'\n' read -d '' -r -a file_content < ./$HASHFILE
    while IFS= read -d '' -r filename; do
        md5=`md5sum ${filename} | awk '{ print $1 }'`
        if [[ (! "${file_content[@]}" =~ $filename) || (! "${file_content[@]}" =~ $md5) ]]; then
            echo "scp $filename $USER@$ADDRESS:$REMOTEDIR$filename"
            `scp $filename $USER@$ADDRESS:$REMOTEDIR$filename`
        fi
    done < <(find . -type f -print0)
    update_hash
}

if [[ ! -f "$HASHFILE" ]]; then
    WORKDIR=$(pwd | awk -F "/" '{print $NF}')
    REMOTEPARENT="${REMOTEDIR%/*}/"
    echo "$HASHFILE not found."
    read -p "scp -r ../$WORKDIR $USER@$ADDRESS:$REMOTEPARENT (Y/N): " user_input
    if [[ $user_input == "y" || $user_input == "Y" ]]; then
        echo "scp -r ../$WORKDIR $USER@$ADDRESS:$REMOTEPARENT" 
        `scp -r ../$WORKDIR $USER@$ADDRESS:$REMOTEPARENT`
        update_hash
    fi
    exit
fi
check_modify
