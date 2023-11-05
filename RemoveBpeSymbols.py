import sys


def removeBpeSymbols(input_path, output_path):
    translation_file = open(input_path, "r", encoding="UTF-8")
    output_file = open(output_path, "w", encoding="UTF-8")
    for line in translation_file.readlines():
        output_file.write(line.replace("@@ ", ""))

    pass


if __name__ == '__main__':
    removeBpeSymbols(sys.argv[1], sys.argv[2])
