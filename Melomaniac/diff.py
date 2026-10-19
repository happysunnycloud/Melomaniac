# вызов python diff.py ER18102026.log
import sys
import os
import re

def main():
    if len(sys.argv) < 2:
        print("Ошибка: Укажите путь к файлу лога.")
        sys.exit(1)

    input_file = sys.argv[1]
    output_file = "diff_result.txt"

    if not os.path.exists(input_file):
        print(f"Ошибка: Файл '{input_file}' не найден.")
        sys.exit(1)

    log_pattern = re.compile(r'(Start|Finish) duration cacl to "(.*?)"')
    starts = set()
    finishes = set()

    # Пробуем открыть файл в правильной кодировке Windows
    try:
        with open(input_file, 'r', encoding='cp1251', errors='ignore') as f:
            lines = f.readlines()
    except Exception:
        with open(input_file, 'r', encoding='utf-8', errors='ignore') as f:
            lines = f.readlines()

    for line in lines:
        match = log_pattern.search(line)
        if match:
            event_type, file_path = match.groups()
            if event_type == 'Start':
                starts.add(file_path)
            elif event_type == 'Finish':
                finishes.add(file_path)

    only_started = sorted(list(starts - finishes))
    only_finished = sorted(list(finishes - starts))

    # Записываем результат (тоже в cp1251 для чтения в Блокноте без кракозябр)
    with open(output_file, 'w', encoding='cp1251', errors='ignore') as out:
        out.write("=== ФАЙЛЫ, КОТОРЫЕ СТАРТОВАЛИ, НО НЕ ФИНИШИРОВАЛИ ===\n")
        if only_started:
            for path in only_started:
                out.write(f'"{path}"\n')
        else:
            out.write("Таких файлов нет.\n")

        out.write("\n=== ФАЙЛЫ, КОТОРЫЕ ФИНИШИРОВАЛИ БЕЗ СТАРТА ===\n")
        if only_finished:
            for path in only_finished:
                out.write(f'"{path}"\n')
        else:
            out.write("Таких файлов нет.\n")

    print(f"Анализ завершен. Результаты сохранены в: {output_file}")

if __name__ == "__main__":
    main()
