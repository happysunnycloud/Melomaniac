# ������ python diff2.py "list1.txt" "list2.txt" "result.txt"
# ��� ������� ������ ������ ����� ��������� utf-8

import re
import sys


def read_file_list(filename):
    with open(filename, 'r', encoding='utf-8-sig') as f:
        return [line.strip() for line in f if line.strip()]


def extract_path(line):
    # Формат лога: File "полный_путь" duration processed
    match = re.search(r'File "(.*?)"', line)
    return match.group(1) if match else line.strip()


def main():
    if len(sys.argv) != 4:
        print('Использование: python diff.py file1.txt file2.txt result.txt')
        return

    file1, file2, output = sys.argv[1:4]

    list1 = read_file_list(file1)
    list2 = read_file_list(file2)

    # Извлекаем пути из лога и нормализуем регистр
    paths2 = {extract_path(line).casefold() for line in list2}

    # Оставляем строки первого файла, которых нет во втором
    difference = [
        path for path in list1
        if path.casefold() not in paths2
    ]

    with open(output, 'w', encoding='utf-8-sig', newline='\n') as f:
        f.write('\n'.join(difference))

    print(f'Готово. Найдено отличий: {len(difference)}')
    print(f'Результат записан в: {output}')


if __name__ == '__main__':
    main()
