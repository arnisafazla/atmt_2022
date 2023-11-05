set -e

pwd=`dirname "$(readlink -f "$0")"`
base=$pwd/../..
src=fr
tgt=en
data=data/$tgt-$src/

# change into base directory to ensure paths are valid
cd $base

# create preprocessed directory
mkdir -p $data/preprocessed/

# normalize and tokenize raw data
cat $data/raw/train.$src | perl moses_scripts/normalize-punctuation.perl -l $src | perl moses_scripts/tokenizer.perl -l $src -a -q > $data/preprocessed/train.$src.p
cat $data/raw/train.$tgt | perl moses_scripts/normalize-punctuation.perl -l $tgt | perl moses_scripts/tokenizer.perl -l $tgt -a -q > $data/preprocessed/train.$tgt.p

# train truecase models
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.$src --corpus $data/preprocessed/train.$src.p
perl moses_scripts/train-truecaser.perl --model $data/preprocessed/tm.$tgt --corpus $data/preprocessed/train.$tgt.p

# prepare remaining splits with learned models
for split in valid test tiny_train
do
    cat $data/raw/$split.$src | perl moses_scripts/normalize-punctuation.perl -l $src | perl moses_scripts/tokenizer.perl -l $src -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.$src > $data/preprocessed/$split.$src
    cat $data/raw/$split.$tgt | perl moses_scripts/normalize-punctuation.perl -l $tgt | perl moses_scripts/tokenizer.perl -l $tgt -a -q | perl moses_scripts/truecase.perl --model $data/preprocessed/tm.$tgt > $data/preprocessed/$split.$tgt
done

# Use Subword-nmt to apply BPE Segments
subword-nmt learn-joint-bpe-and-vocab --input $data/preprocessed/train.$src $data/preprocessed/train.$tgt $data/preprocessed/test.$src $data/preprocessed/test.$tgt $data/preprocessed/tiny_train.$src $data/preprocessed/tiny_train.$tgt $data/preprocessed/valid.$src $data/preprocessed/valid.$tgt -s 20000 -o $data/bpe/bpe.codes --write-vocabulary $data/bpe/train_dict.$src $data/bpe/train_dict.$tgt $data/bpe/test_dict.$src $data/bpe/test_dict.$tgt $data/bpe/tiny_train_dict.$src $data/bpe/tiny_train_dict.$tgt $data/bpe/valid_dict.$src $data/bpe/valid_dict.$tgt
# Apply the test dataset
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/test_dict.$src  < $data/preprocessed/test.$src > $data/bpe/test.$src
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/test_dict.$tgt  < $data/preprocessed/test.$tgt > $data/bpe/test.$tgt
# Apply the train dataset
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/train_dict.$src  < $data/preprocessed/train.$src > $data/bpe/train.$src
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/train_dict.$tgt  < $data/preprocessed/train.$tgt > $data/bpe/train.$tgt
# Apply the tiny-test dataset
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/tiny_train_dict.$src  < $data/preprocessed/tiny_train.$src > $data/bpe/tiny_train.$src
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/tiny_train_dict.$tgt  < $data/preprocessed/tiny_train.$tgt > $data/bpe/tiny_train.$tgt
# # Apply the valid dataset
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/valid_dict.$src  < $data/preprocessed/valid.$src > $data/bpe/valid.$src
subword-nmt apply-bpe -c $data/bpe/bpe.codes --vocabulary $data/bpe/valid_dict.$tgt  < $data/preprocessed/valid.$tgt > $data/bpe/valid.$tgt

# preprocess all files for model training
python preprocess.py --target-lang $tgt --source-lang $src --dest-dir $data/prepared/ --train-prefix $data/bpe/train --valid-prefix $data/bpe/valid --test-prefix $data/bpe/test --tiny-train-prefix $data/bpe/tiny_train --threshold-src 1 --threshold-tgt 1 --num-words-src 4000 --num-words-tgt 4000

echo "done!"
