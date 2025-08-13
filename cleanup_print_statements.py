#!/usr/bin/env python3
"""
Skrypt do usuwania wszystkich print statements z projektu Flutter
Usuwa print(), developer.log() i console.log() z plików Dart i JavaScript
"""

import os
import re
import sys
from pathlib import Path
from typing import List, Tuple, Dict
import argparse

class PrintCleaner:
    def __init__(self, project_root: str):
        self.project_root = Path(project_root)
        self.stats = {
            'files_processed': 0,
            'files_modified': 0,
            'prints_removed': 0,
            'developer_logs_removed': 0,
            'console_logs_removed': 0,
            'errors': 0
        }
        
        # Wzorce regex dla różnych typów debug statements
        self.dart_patterns = [
            # print() statements
            r'^\s*print\s*\(\s*[^)]*\)\s*;\s*$',
            # developer.log() statements  
            r'^\s*developer\.log\s*\([^)]*\)\s*;\s*$',
            # debugPrint() statements
            r'^\s*debugPrint\s*\([^)]*\)\s*;\s*$',
            # Multiline print statements
            r'^\s*print\s*\(\s*$.*?^\s*\)\s*;\s*$',
        ]
        
        self.js_patterns = [
            # console.log() statements
            r'^\s*console\.log\s*\([^)]*\)\s*;\s*$',
            # console.error(), console.warn(), etc.
            r'^\s*console\.(log|error|warn|info|debug)\s*\([^)]*\)\s*;\s*$',
        ]
        
        # Pliki do pominięcia
        self.excluded_dirs = {
            '.git', '.dart_tool', 'build', 'node_modules', '.pub-cache',
            'ios', 'android', 'linux', 'windows', 'macos', 'web'
        }
        
        # Pliki debug/test, które pozostawiamy
        self.debug_files = {
            'debug', 'test_', '_test', '_debug', 'demo', 'example'
        }

    def should_skip_file(self, file_path: Path) -> bool:
        """Sprawdza czy plik powinien zostać pominięty"""
        # Pomiń katalogi systemowe
        for part in file_path.parts:
            if part in self.excluded_dirs:
                return True
        
        # Zachowaj pliki debug/test
        file_name = file_path.stem.lower()
        for debug_keyword in self.debug_files:
            if debug_keyword in file_name:
                return True
                
        return False

    def clean_dart_file(self, file_path: Path) -> Tuple[str, int]:
        """Czyści plik Dart z print statements"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            original_lines = content.split('\n')
            cleaned_lines = []
            removed_count = 0
            i = 0
            
            while i < len(original_lines):
                line = original_lines[i]
                line_removed = False
                
                # Sprawdź pojedyncze linie
                for pattern in self.dart_patterns[:-1]:  # Bez multiline
                    if re.match(pattern, line, re.MULTILINE):
                        removed_count += 1
                        line_removed = True
                        break
                
                # Sprawdź multiline print statements
                if not line_removed and re.match(r'^\s*print\s*\(\s*$', line):
                    # Znajdź zamykający nawias
                    bracket_count = 1
                    j = i + 1
                    while j < len(original_lines) and bracket_count > 0:
                        for char in original_lines[j]:
                            if char == '(':
                                bracket_count += 1
                            elif char == ')':
                                bracket_count -= 1
                        j += 1
                    
                    if bracket_count == 0:
                        removed_count += 1
                        i = j - 1  # Przeskocz wszystkie linie multiline print
                        line_removed = True
                
                if not line_removed:
                    cleaned_lines.append(line)
                
                i += 1
            
            cleaned_content = '\n'.join(cleaned_lines)
            
            # Usuń podwójne puste linie
            cleaned_content = re.sub(r'\n\n\n+', '\n\n', cleaned_content)
            
            return cleaned_content, removed_count
            
        except Exception as e:
            print(f"❌ Błąd podczas czyszczenia {file_path}: {e}")
            self.stats['errors'] += 1
            return "", 0

    def clean_js_file(self, file_path: Path) -> Tuple[str, int]:
        """Czyści plik JavaScript z console.log statements"""
        try:
            with open(file_path, 'r', encoding='utf-8') as f:
                content = f.read()
            
            lines = content.split('\n')
            cleaned_lines = []
            removed_count = 0
            
            for line in lines:
                line_removed = False
                
                for pattern in self.js_patterns:
                    if re.match(pattern, line):
                        removed_count += 1
                        line_removed = True
                        break
                
                if not line_removed:
                    cleaned_lines.append(line)
            
            cleaned_content = '\n'.join(cleaned_lines)
            
            # Usuń podwójne puste linie
            cleaned_content = re.sub(r'\n\n\n+', '\n\n', cleaned_content)
            
            return cleaned_content, removed_count
            
        except Exception as e:
            print(f"❌ Błąd podczas czyszczenia {file_path}: {e}")
            self.stats['errors'] += 1
            return "", 0

    def process_file(self, file_path: Path, dry_run: bool = False) -> None:
        """Przetwarza pojedynczy plik"""
        if self.should_skip_file(file_path):
            return
        
        self.stats['files_processed'] += 1
        
        if file_path.suffix == '.dart':
            cleaned_content, removed_count = self.clean_dart_file(file_path)
            if removed_count > 0:
                self.stats['prints_removed'] += removed_count
                print(f"🧹 {file_path.relative_to(self.project_root)}: usunięto {removed_count} print statements")
        
        elif file_path.suffix == '.js':
            cleaned_content, removed_count = self.clean_js_file(file_path)
            if removed_count > 0:
                self.stats['console_logs_removed'] += removed_count
                print(f"🧹 {file_path.relative_to(self.project_root)}: usunięto {removed_count} console.log statements")
        
        else:
            return
        
        # Zapisz zmiany jeśli nie jest to dry run
        if removed_count > 0:
            if not dry_run:
                try:
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(cleaned_content)
                    self.stats['files_modified'] += 1
                except Exception as e:
                    print(f"❌ Błąd zapisywania {file_path}: {e}")
                    self.stats['errors'] += 1
            else:
                print(f"🔍 [DRY RUN] Zostałyby usunięte {removed_count} statements z {file_path.relative_to(self.project_root)}")

    def clean_project(self, dry_run: bool = False) -> None:
        """Czyści cały projekt"""
        print(f"🚀 Rozpoczynam czyszczenie print statements w {self.project_root}")
        if dry_run:
            print("🔍 [DRY RUN MODE] - żadne pliki nie będą modyfikowane")
        
        # Znajdź wszystkie pliki Dart i JavaScript
        dart_files = list(self.project_root.rglob('*.dart'))
        js_files = list(self.project_root.rglob('*.js'))
        
        all_files = dart_files + js_files
        
        print(f"📁 Znaleziono {len(dart_files)} plików .dart i {len(js_files)} plików .js")
        
        for file_path in all_files:
            self.process_file(file_path, dry_run)
        
        self.print_stats()

    def print_stats(self) -> None:
        """Wyświetla statystyki"""
        print("\n" + "="*60)
        print("📊 STATYSTYKI CZYSZCZENIA")
        print("="*60)
        print(f"📁 Plików przetworzonych: {self.stats['files_processed']}")
        print(f"✏️  Plików zmodyfikowanych: {self.stats['files_modified']}")
        print(f"🧹 Print statements usuniętych: {self.stats['prints_removed']}")
        print(f"🧹 Console.log statements usuniętych: {self.stats['console_logs_removed']}")
        
        total_removed = self.stats['prints_removed'] + self.stats['console_logs_removed'] + self.stats['developer_logs_removed']
        print(f"🎯 ŁĄCZNIE usuniętych statements: {total_removed}")
        
        if self.stats['errors'] > 0:
            print(f"❌ Błędów: {self.stats['errors']}")
        
        print("="*60)

def main():
    parser = argparse.ArgumentParser(description='Usuwa print statements z projektu Flutter')
    parser.add_argument('--project-root', '-p', default='.', 
                       help='Ścieżka do katalogu głównego projektu')
    parser.add_argument('--dry-run', '-d', action='store_true',
                       help='Tryb podglądu - nie modyfikuje plików')
    parser.add_argument('--only-dart', action='store_true',
                       help='Czyść tylko pliki .dart')
    parser.add_argument('--only-js', action='store_true',
                       help='Czyść tylko pliki .js')
    
    args = parser.parse_args()
    
    project_root = Path(args.project_root).resolve()
    
    if not project_root.exists():
        print(f"❌ Katalog {project_root} nie istnieje!")
        sys.exit(1)
    
    # Sprawdź czy to projekt Flutter
    pubspec_yaml = project_root / 'pubspec.yaml'
    if not pubspec_yaml.exists():
        print(f"⚠️  Ostrzeżenie: Nie znaleziono pubspec.yaml w {project_root}")
        response = input("Czy kontynuować? (y/N): ")
        if response.lower() != 'y':
            sys.exit(0)
    
    cleaner = PrintCleaner(str(project_root))
    
    # Modyfikuj wzorce jeśli wybrano konkretny typ plików
    if args.only_dart:
        # Zostaw tylko wzorce Dart
        pass
    elif args.only_js:
        # Zostaw tylko wzorce JS
        cleaner.dart_patterns = []
    
    try:
        cleaner.clean_project(dry_run=args.dry_run)
        print(f"\n✅ Czyszczenie {'(podgląd) ' if args.dry_run else ''}zakończone pomyślnie!")
    except KeyboardInterrupt:
        print(f"\n⚠️  Przerwano przez użytkownika")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Błąd: {e}")
        sys.exit(1)

if __name__ == '__main__':
    main()
