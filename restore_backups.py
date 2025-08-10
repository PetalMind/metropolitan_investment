#!/usr/bin/env python3
"""
Skrypt do przywracania plików JSON z kopii zapasowych.
Metropolitan Investment - Restore from Backup
"""

import os
import shutil
from datetime import datetime

def restore_from_backup(file_path: str) -> bool:
    """
    Przywraca plik z kopii zapasowej.
    
    Args:
        file_path: Ścieżka do pliku głównego
        
    Returns:
        True jeśli przywrócono pomyślnie, False w przeciwnym razie
    """
    backup_path = file_path + '.backup'
    
    if not os.path.exists(backup_path):
        print(f"❌ Brak kopii zapasowej: {backup_path}")
        return False
    
    try:
        # Utwórz kopię przed przywróceniem (na wszelki wypadek)
        if os.path.exists(file_path):
            timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
            temp_backup = f"{file_path}.before_restore_{timestamp}"
            shutil.copy2(file_path, temp_backup)
            print(f"📦 Utworzono kopię przed przywróceniem: {os.path.basename(temp_backup)}")
        
        # Przywróć z kopii
        shutil.copy2(backup_path, file_path)
        print(f"✅ Przywrócono: {os.path.basename(file_path)}")
        return True
        
    except Exception as e:
        print(f"❌ Błąd przywracania: {e}")
        return False

def list_backups(json_dir: str) -> list:
    """
    Wyświetla dostępne kopie zapasowe.
    
    Args:
        json_dir: Katalog z plikami JSON
        
    Returns:
        Lista plików backup
    """
    backup_files = []
    
    if not os.path.exists(json_dir):
        print(f"❌ Katalog {json_dir} nie istnieje!")
        return backup_files
    
    for filename in os.listdir(json_dir):
        if filename.endswith('.backup'):
            backup_path = os.path.join(json_dir, filename)
            original_path = backup_path[:-7]  # Usuń '.backup'
            
            if os.path.exists(backup_path):
                backup_size = os.path.getsize(backup_path)
                backup_time = datetime.fromtimestamp(os.path.getmtime(backup_path))
                
                backup_info = {
                    'backup_file': filename,
                    'original_file': os.path.basename(original_path),
                    'backup_path': backup_path,
                    'original_path': original_path,
                    'size': backup_size,
                    'modified': backup_time
                }
                backup_files.append(backup_info)
    
    return backup_files

def interactive_restore():
    """
    Interaktywne przywracanie plików.
    """
    print("🔄 Interaktywne przywracanie z kopii zapasowych")
    print("=" * 50)
    
    json_dir = "split_investment_data"
    backups = list_backups(json_dir)
    
    if not backups:
        print("❌ Nie znaleziono kopii zapasowych!")
        return
    
    print(f"📋 Znaleziono {len(backups)} kopii zapasowych:\n")
    
    for i, backup in enumerate(backups, 1):
        size_kb = backup['size'] / 1024
        print(f"{i}. {backup['original_file']}")
        print(f"   📁 Backup: {backup['backup_file']}")
        print(f"   📊 Rozmiar: {size_kb:.1f} KB")
        print(f"   📅 Utworzono: {backup['modified'].strftime('%Y-%m-%d %H:%M:%S')}")
        print()
    
    while True:
        try:
            choice = input("Wybierz numer pliku do przywrócenia (0 = wyjdź): ").strip()
            
            if choice == '0':
                print("👋 Anulowano.")
                return
            
            file_index = int(choice) - 1
            
            if 0 <= file_index < len(backups):
                backup_info = backups[file_index]
                
                print(f"\n🔄 Przywracanie: {backup_info['original_file']}")
                confirm = input("Kontynuować? (y/n): ").strip().lower()
                
                if confirm in ['y', 'yes', 'tak', 't']:
                    if restore_from_backup(backup_info['original_path']):
                        print("✅ Przywracanie zakończone pomyślnie!")
                    else:
                        print("❌ Przywracanie nieudane!")
                else:
                    print("❌ Anulowano przywracanie.")
                
                return
            else:
                print("❌ Nieprawidłowy numer. Spróbuj ponownie.")
                
        except ValueError:
            print("❌ Wprowadź prawidłowy numer.")
        except KeyboardInterrupt:
            print("\n👋 Przerwano przez użytkownika.")
            return

def restore_all_files():
    """
    Przywraca wszystkie pliki z kopii zapasowych.
    """
    print("🔄 Przywracanie wszystkich plików z kopii zapasowych")
    print("=" * 50)
    
    json_dir = "split_investment_data"
    backups = list_backups(json_dir)
    
    if not backups:
        print("❌ Nie znaleziono kopii zapasowych!")
        return
    
    print(f"📋 Znaleziono {len(backups)} kopii zapasowych")
    confirm = input("\nCzy przywrócić WSZYSTKIE pliki? (y/n): ").strip().lower()
    
    if confirm not in ['y', 'yes', 'tak', 't']:
        print("❌ Anulowano.")
        return
    
    success_count = 0
    
    for backup in backups:
        print(f"\n🔄 Przywracanie: {backup['original_file']}")
        if restore_from_backup(backup['original_path']):
            success_count += 1
    
    print(f"\n✅ Przywrócono {success_count}/{len(backups)} plików")

def main():
    """
    Główna funkcja skryptu.
    """
    print("🔙 Skrypt przywracania z kopii zapasowych - Metropolitan Investment")
    print("=" * 70)
    
    while True:
        print("\n📋 Opcje:")
        print("1. Wyświetl dostępne kopie zapasowe")
        print("2. Przywróć pojedynczy plik (interaktywnie)")
        print("3. Przywróć wszystkie pliki")
        print("0. Wyjdź")
        
        try:
            choice = input("\nWybierz opcję: ").strip()
            
            if choice == '0':
                print("👋 Do widzenia!")
                break
            elif choice == '1':
                json_dir = "split_investment_data"
                backups = list_backups(json_dir)
                
                if backups:
                    print(f"\n📋 Dostępne kopie zapasowe ({len(backups)}):")
                    for backup in backups:
                        size_kb = backup['size'] / 1024
                        print(f"   📁 {backup['backup_file']} ({size_kb:.1f} KB)")
                        print(f"      📅 {backup['modified'].strftime('%Y-%m-%d %H:%M:%S')}")
                else:
                    print("\n❌ Brak dostępnych kopii zapasowych")
                    
            elif choice == '2':
                interactive_restore()
            elif choice == '3':
                restore_all_files()
            else:
                print("❌ Nieprawidłowa opcja. Wybierz 0-3.")
                
        except KeyboardInterrupt:
            print("\n👋 Przerwano przez użytkownika.")
            break
        except Exception as e:
            print(f"❌ Błąd: {e}")

if __name__ == "__main__":
    main()
