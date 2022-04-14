#!/bin/sh

#filetype:px_width1/px_width2
to_generate='png:16/32/48/110/300/400/800/1000
jpg:16/32/48/110/300/400/800/1000
ico:16/32/48/110
pdf:0'

for gen in $to_generate; do
    sizes=$(echo "$gen" | awk -F ':' '{print $2}')
    ft=$(echo "$gen" | awk -F ':' '{print $1}')

    if [ -z "$1" ] || [ "$ft" = "$1" ]; then
        echo "filetype: $gen"
        mkdir -p "$ft"
        case $ft in
            'jpg')
                bg='white';;
            *)
                bg='none';;
        esac

        for size in $(echo $sizes | tr '/' ' '); do
            printf "size: $size"

            resize=''
            if [ "$size" -ne 0 ]; then
                resize="-resize $size"
            else
                size=''
            fi

            for file in svg/*; do
                filename=$(basename "$file" | sed "s/.svg//")
                if [ "$size" != '' ]; then
                    filename="$filename""_$size""px"
                fi
                filename="$filename.$ft"
                convert -background "$bg" "$file" $resize "$ft/$filename"
            done
            echo " - DONE"
        done
    fi
done
