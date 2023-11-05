#!/bin/bash
# -*- coding: utf-8 -*-

set -e

pwd=`dirname "$(readlink -f "$0")"`
base=$pwd/../..
src=fr
tgt=en
data=$base/data/$tgt-$src/

# change into base directory to ensure paths are valid
cd "$base"

# create preprocessed directory
mkdir -p "$data/preprocessed/"

# normalize and tokenize raw data
cat "$data/raw/train.$src.bpe" | perl moses_scripts/normalize-punctuation.perl -l $src | perl moses_scripts/tokenizer.perl -l $src -a -q > "$data/preprocessed/train.$src.bpe.p"
cat "$data/raw/train.$tgt.bpe" | perl moses_scripts/normalize-punctuation.perl -l $tgt | perl moses_scripts/tokenizer.perl -l $tgt -a -q > "$data/preprocessed/train.$tgt.bpe.p"

# train truecase models
perl moses_scripts/train-truecaser.perl --model "$data/preprocessed/tm.$src.bpe" --corpus "$data/preprocessed/train.$src.bpe.p"
perl moses_scripts/train-truecaser.perl --model "$data/preprocessed/tm.$tgt.bpe" --corpus "$data/preprocessed/train.$tgt.bpe.p"

# apply truecase models to splits
cat "$data/preprocessed/train.$src.bpe.p" | perl moses_scripts/truecase.perl --model "$data/preprocessed/tm.$src" > "$data/preprocessed/train.$src.bpe"
cat "$data/preprocessed/train.$tgt.bpe.p" | perl moses_scripts/truecase.perl --model "$data/preprocessed/tm.$tgt" > "$data/preprocessed/train.$tgt.bpe"

# prepare remaining splits with learned models
for split in valid test tiny_train
do
    cat "$data/raw/$split.$src.bpe" | perl moses_scripts/normalize-punctuation.perl -l $src | perl moses_scripts/tokenizer.perl -l $src -a -q | perl moses_scripts/truecase.perl --model "$data/preprocessed/tm.$src.bpe" > "$data/preprocessed/$split.$src.bpe"
    cat "$data/raw/$split.$tgt.bpe" | perl moses_scripts/normalize-punctuation.perl -l $tgt | perl moses_scripts/tokenizer.perl -l $tgt -a -q | perl moses_scripts/truecase.perl --model "$data/preprocessed/tm.$tgt.bpe" > "$data/preprocessed/$split.$tgt.bpe"
done

# remove tmp files
rm "$data/preprocessed/train.$src.bpe.p"
rm "$data/preprocessed/train.$tgt.bpe.p"

# preprocess all files for model training
python preprocess.py --target-lang $tgt --source-lang $src --dest-dir "$data/prepared/" --train-prefix "$data/preprocessed/train" --valid-prefix "$data/preprocessed/valid" --test-prefix "$data/preprocessed/test" --tiny-train-prefix "$data/preprocessed/tiny_train" --threshold-src 1 --threshold-tgt 1 --num-words-src 4000 --num-words-tgt 4000

echo "done!"