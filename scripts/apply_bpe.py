import subword_nmt
import os

data_folder = '../data/en-fr/raw/'

train_src = os.path.join(data_folder, 'train.en')
train_trg = os.path.join(data_folder, 'train.fr')
tiny_train_src = os.path.join(data_folder, 'tiny_train.en')
tiny_train_trg = os.path.join(data_folder, 'tiny_train.fr')
valid_src = os.path.join(data_folder, 'valid.en')
valid_trg = os.path.join(data_folder, 'valid.fr')
test_src = os.path.join(data_folder, 'test.en')
test_trg = os.path.join(data_folder, 'test.fr')

src_codes = os.path.join(data_folder, 'src_codes.bpe')
trg_codes = os.path.join(data_folder, 'trg_codes.bpe')

train_src_bpe = os.path.join(data_folder, 'train.en.bpe')
train_trg_bpe = os.path.join(data_folder, 'train.fr.bpe')
tiny_train_src_bpe = os.path.join(data_folder, 'tiny_train.en.bpe')
tiny_train_trg_bpe = os.path.join(data_folder, 'tiny_train.fr.bpe')
valid_src_bpe = os.path.join(data_folder, 'valid.en.bpe')
valid_trg_bpe = os.path.join(data_folder, 'valid.fr.bpe')
test_src_bpe = os.path.join(data_folder, 'test.en.bpe')
test_trg_bpe = os.path.join(data_folder, 'test.fr.bpe')

# Train BPE models using the command line
os.system(f'subword-nmt learn-bpe -s 32000 < {train_src} > {src_codes}')
os.system(f'subword-nmt learn-bpe -s 32000 < {train_trg} > {trg_codes}')

# Apply BPE to your data using the command line
os.system(f'subword-nmt apply-bpe -c {src_codes} < {train_src} > {train_src_bpe}')
os.system(f'subword-nmt apply-bpe -c {trg_codes} < {train_trg} > {train_trg_bpe}')

os.system(f'subword-nmt apply-bpe -c {src_codes} < {tiny_train_src} > {tiny_train_src_bpe}')
os.system(f'subword-nmt apply-bpe -c {trg_codes} < {tiny_train_trg} > {tiny_train_trg_bpe}')

# Repeat the above steps for valid and test data
os.system(f'subword-nmt apply-bpe -c {src_codes} < {valid_src} > {valid_src_bpe}')
os.system(f'subword-nmt apply-bpe -c {trg_codes} < {valid_trg} > {valid_trg_bpe}')

os.system(f'subword-nmt apply-bpe -c {src_codes} < {test_src} > {test_src_bpe}')
os.system(f'subword-nmt apply-bpe -c {trg_codes} < {test_trg} > {test_trg_bpe}')

#
# import re, collections
# import sys
#
#
# def get_stats(vocab):
#     pairs = collections.defaultdict(int)
#     for word, freq in vocab.items():
#         symbols = word.split()
#         for i in range(len(symbols) - 1):
#             pairs[symbols[i], symbols[i + 1]] += freq
#     return pairs
#
#
# def merge_vocab(pair, v_in):
#     v_out = {}
#     bigram = re.escape(' '.join(pair))
#     p = re.compile(r'(?<!\S)' + bigram + r'(?!\S)')
#     for word in v_in:
#         w_out = p.sub(''.join(pair), word)
#         v_out[w_out] = v_in[word]
#     return v_out
#
#
# if __name__ == '__main__':
#     num_merges = 500
#     file1 = open(sys.argv[1], 'rb')
#     vocab = {}
#     ind = {}
#     num = 0
#     ind_inv = {}
#     line_num = 0
#     for line in file1.readlines():
#         print(line)
#         line = line.rstrip().split(' ')
#         for term in line:
#             term = term.decode('utf8')
#             if len(term) == 0:
#                 continue
#             if term not in ind:
#                 ind[term] = []
#             ind[term].append(num)
#             ind_inv[num] = term
#             num += 1
#             s = ''
#             for i in term[:-1]:
#                 s += i
#                 s += ' '
#             s += term[-1]
#             if s not in vocab:
#                 vocab[s] = 0
#             vocab[s] += 1
#         ind_inv[num] = '<\s>'
#         num += 1
#         line_num += 1
#         if line_num % 1000 == 0:
#             print(line_num)
#     print(len(vocab))
#     for i in range(num_merges):
#         print(i)
#         pairs = get_stats(vocab)
#         best = max(pairs, key=pairs.get)
#         vocab = merge_vocab(best, vocab)
#     out = [0] * num
#     print(num, len(vocab), len(ind))
#     fileout = open(sys.argv[2], 'wb')
#     for (k, v) in vocab.items():
#         s = ''.join(k.split(' '))
#         for i in ind[s]:
#             out[i] = k.split(' ')
#     for i in range(num):
#         if ind_inv[i] == '<\s>':
#             fileout.writelines('\n')
#             continue
#         for k in out[i]:
#             fileout.writelines(str(k.encode('utf8')) + ' ')
