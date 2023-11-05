#!/usr/bin/env bash
# -*- coding: utf-8 -*-

# Example call:
#   bash scripts/run_preprocessing.sh

set -e

raw_data=$1
# set languages
src_lang=$2
tgt_lang=$3

# set paths
scripts=`dirname "$(readlink -f "$0")"`
base=$scripts/..
moses_scripts=$base/moses_scripts
preprocessed=$raw_data/../preprocessed
prepared=$raw_data/../prepared

mkdir -p $preprocessed
mkdir -p $prepared

for lang in $src_lang $tgt_lang
    do
        echo "training truecase model for $lang"

        # normalise and tokenize punctuation in training
        # split for truecase model training
        cat $raw_data/train.$lang.bpe | perl $moses_scripts/normalize-punctuation.perl -l $lang | perl $moses_scripts/tokenizer.perl -l $lang -a -q > $preprocessed/train.$lang.bpe
        
        # train truecase model for language
        perl $moses_scripts/train-truecaser.perl --model $preprocessed/tm.$lang --corpus $preprocessed/train.$lang
        
        # normalise, tokenise and apply truecase model to each data split
        for split in train tiny_train test valid
            do
                echo "preprocessing $split split for language $lang..."            
                cat $raw_data/$split.$lang.bpe | perl $moses_scripts/normalize-punctuation.perl -l $lang | perl $moses_scripts/tokenizer.perl -l $lang -a -q | perl $moses_scripts/truecase.perl --model $preprocessed/tm.$lang.bpe >| $preprocessed/$split.$lang.bpe
                
            done
    done

echo "preparing data for model training..."

python $base/preprocess.py \
    --source-lang $src_lang \
    --target-lang $tgt_lang \
    --dest-dir $prepared \
    --train-prefix $preprocessed/train \
    --valid-prefix $preprocessed/valid \
    --test-prefix $preprocessed/test \
    --tiny-train-prefix $preprocessed/tiny_train \
    --threshold-src 1 \
    --threshold-tgt 1 \
    --num-words-src 4000 \
    --num-words-tgt 4000

echo "done."
