#!/bin/bash

PWD_DIR=`dirname $0`
BASE_FILE=$1
PAGE_NUM=$2
WORKDIR="/tmp/vcislide"

INPUT_FILE=${BASE_FILE}_${PAGE_NUM}.md
OUTPUT_FILE=${BASE_FILE}_${PAGE_NUM}.pdf

mkdir -p $WORKDIR
ruby $PWD_DIR/gen.rb $PWD_DIR/template.md $PAGE_NUM > $WORKDIR/$INPUT_FILE

touch $WORKDIR/$OUTPUT_FILE
chmod a+w $WORKDIR/$OUTPUT_FILE
docker run --rm --init \
    -v $WORKDIR:/home/marp/app/  \
    -e LANG="ja_JP.UTF-8" marpteam/marp-cli \
    $INPUT_FILE --pdf --allow-local-files
mv $WORKDIR/$OUTPUT_FILE ./