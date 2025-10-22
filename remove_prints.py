#!/usr/bin/env python3
"""
Skrypt do usuwania wszystkich wywołań print() z plików Dart.
Obsługuje wieloliniowe wywołania print i zachowuje formatowanie.
"""

import re
import sys
from pathlib import Path


def remove_prints_from_file(file_path: Path) -> tuple[int, str]:
    """
    Usuwa wszystkie wywołania print() z pliku Dart.
    Zwraca (liczba_usunięć, nowa_zawartość).
    """
    content = file_path.read_text(encoding='utf-8')
    original_content = content
    
    # Pattern dla print() - obsługuje wieloliniowe wywołania
    # Dopasowuje: print(...), print('...'), print("..."), print('''...'''), etc.
    pattern = r'^\s*print\s*\([^;]*?\);\s*$'
    
    # Usuń wszystkie linie zawierające print (pojedyncze linie)
    lines = content.split('\n')
    new_lines = []
    removed_count = 0
    i = 0
    
    while i < len(lines):
        line = lines[i]
        
        # Sprawdź czy linia zawiera początek print(
        if re.search(r'^\s*print\s*\(', line):
            # Znajdź koniec wywołania print (może być wieloliniowe)
            full_print = line
            paren_count = line.count('(') - line.count(')')
            
            # Jeśli nie zamknięto nawiasów, czytaj kolejne linie
            j = i + 1
            while paren_count > 0 and j < len(lines):
                full_print += '\n' + lines[j]
                paren_count += lines[j].count('(') - lines[j].count(')')
                j += 1
            
            # Sprawdź czy to kompletne wywołanie print
            if paren_count == 0 and full_print.rstrip().endswith(';'):
                # Pomiń wszystkie linie tego wywołania print
                i = j
                removed_count += 1
                continue
        
        new_lines.append(line)
        i += 1
    
    new_content = '\n'.join(new_lines)
    
    # Usuń puste linie podwójne (zostaw maksymalnie 2 puste linie pod rząd)
    new_content = re.sub(r'\n\n\n+', '\n\n', new_content)
    
    return removed_count, new_content


def main():
    if len(sys.argv) < 2:
        print("Usage: python remove_prints.py <file1.dart> [file2.dart ...]")
        sys.exit(1)
    
    total_removed = 0
    
    for file_arg in sys.argv[1:]:
        file_path = Path(file_arg)
        
        if not file_path.exists():
            print(f"❌ Plik nie istnieje: {file_path}")
            continue
        
        if not file_path.suffix == '.dart':
            print(f"⚠️  Pomijam nie-dartowy plik: {file_path}")
            continue
        
        print(f"🔄 Przetwarzam: {file_path}")
        
        try:
            removed, new_content = remove_prints_from_file(file_path)
            
            if removed > 0:
                # Zapisz nową zawartość
                file_path.write_text(new_content, encoding='utf-8')
                print(f"  ✅ Usunięto {removed} wywołań print()")
                total_removed += removed
            else:
                print(f"  ℹ️  Brak print() do usunięcia")
        
        except Exception as e:
            print(f"  ❌ Błąd: {e}")
    
    print(f"\n🎯 PODSUMOWANIE: Usunięto łącznie {total_removed} wywołań print()")


if __name__ == '__main__':
    main()
