#!/bin/bash

BASE_FILE=$(echo $1| cut -f1 -d'.')
PAGE_NUM=$2

INPUT_FILE=${BASE_FILE}_${PAGE_NUM}.md
OUTPUT_FILE=${BASE_FILE}_${PAGE_NUM}.pdf

ruby gen.rb ${BASE_FILE}.md $PAGE_NUM > $INPUT_FILE

touch $OUTPUT_FILE
chmod a+w $OUTPUT_FILE
docker run --rm --init \
    -v $PWD:/home/marp/app/  \
    -e LANG="ja_JP.UTF-8" marpteam/marp-cli \
    $INPUT_FILE --pdf --allow-local-files