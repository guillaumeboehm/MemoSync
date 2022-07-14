#!/bin/sh

#filetype:px_width1/px_width2
to_generate='png:16/32/48/110/300/400/800/1000
jpg:16/32/48/110/300/400/800/1000
ico:16/32/48/110
android.png:48/72/96/144/192/1024
ios.png:16/20/29/32/40/48/50/55/57/58/60/64/72/76/80/87/88/100/114/120/128/144/152/167/172/180/196/216/256/512/1024
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
            'android.png')
                bg='white';;
            'ios.png')
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

# android gen
echo "ANDROID GENERATION -"
rm -rf android/ && mv android.png android/
( cd android/ || exit
rm -f Full_logo_* && rm -f Round_*
mkdir -p mipmap-mdpi/ && cp -f *48* mipmap-mdpi/ic_launcher.png && cp -f *48* mipmap-mdpi/ic_quick_notify.png && rm -f *48*
mkdir -p mipmap-hdpi/ && cp -f *72* mipmap-hdpi/ic_launcher.png && cp -f *72* mipmap-hdpi/ic_quick_notify.png && rm -f *72*
mkdir -p mipmap-xhdpi/ && cp -f *96* mipmap-xhdpi/ic_launcher.png && cp -f *96* mipmap-xhdpi/ic_quick_notify.png && rm -f *96*
mkdir -p mipmap-xxhdpi/ && cp -f *144* mipmap-xxhdpi/ic_launcher.png && cp -f *144* mipmap-xxhdpi/ic_quick_notify.png && rm -f *144*
mkdir -p mipmap-xxxhdpi/ && cp -f *192* mipmap-xxxhdpi/ic_launcher.png && cp -f *192* mipmap-xxxhdpi/ic_quick_notify.png && rm -f *192*
mv -f *1024* ../appstore.png )

# ios gen
echo "IOS GENERATION -"
rm -rf ios && mv ios.png ios/
(cd ios/ || exit
rm Full_logo_* && rm Round_*
for file in *.png; do
    mv -f "$file" "$(echo "$file" | sed 's/Square_NoTab_logo_//g' | sed 's/px.ios//g')"
done
cp -f 512.png ../playstore.png
mkdir -p AppIcon.appiconset
cp -f ../IOS_Logos_Contents.json AppIcon.appiconset/Contents.json
mv -f *.png AppIcon.appiconset)
