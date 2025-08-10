#!/usr/bin/env python3
"""
Skrypt testowy do sprawdzenia struktury plików JSON przed normalizacją.
Pokazuje przykładowe pola i ich wartości.
"""

import json
import os

def preview_json_structure(file_path: str, max_records: int = 3) -> None:
    """
    Wyświetla strukturę pliku JSON.
    
    Args:
        file_path: Ścieżka do pliku JSON
        max_records: Maksymalna liczba rekordów do wyświetlenia
    """
    print(f"\n📋 Podgląd struktury: {os.path.basename(file_path)}")
    print("=" * 60)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if isinstance(data, list):
            print(f"📊 Typ: Lista z {len(data)} rekordami")
            
            for i, record in enumerate(data[:max_records]):
                if isinstance(record, dict):
                    print(f"\n📄 Rekord {i + 1}:")
                    for key, value in list(record.items())[:10]:  # Pokaż max 10 pól
                        value_str = str(value)[:50] + "..." if len(str(value)) > 50 else str(value)
                        print(f"   {key}: {value_str}")
                    
                    if len(record) > 10:
                        print(f"   ... i {len(record) - 10} więcej pól")
        
        elif isinstance(data, dict):
            print("📊 Typ: Pojedynczy obiekt")
            for key, value in list(data.items())[:15]:
                value_str = str(value)[:50] + "..." if len(str(value)) > 50 else str(value)
                print(f"   {key}: {value_str}")
        
        else:
            print("📊 Typ: Nierozpoznany format danych")
            
    except json.JSONDecodeError as e:
        print(f"❌ Błąd parsowania JSON: {e}")
    except FileNotFoundError:
        print(f"❌ Plik nie istnieje: {file_path}")
    except Exception as e:
        print(f"❌ Błąd: {e}")

def analyze_field_names(file_path: str) -> None:
    """
    Analizuje nazwy pól w pliku JSON.
    """
    print(f"\n🔍 Analiza nazw pól: {os.path.basename(file_path)}")
    print("-" * 40)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        all_fields = set()
        
        if isinstance(data, list):
            for record in data:
                if isinstance(record, dict):
                    all_fields.update(record.keys())
        elif isinstance(data, dict):
            all_fields.update(data.keys())
        
        print(f"📋 Znaleziono {len(all_fields)} unikalnych pól:")
        
        # Podziel pola na kategorie
        polish_fields = []
        english_fields = []
        mixed_fields = []
        
        for field in sorted(all_fields):
            if any(char in "ąćęłńóśźżĄĆĘŁŃÓŚŹŻ" for char in field):
                polish_fields.append(field)
            elif "_" in field or field.isupper():
                mixed_fields.append(field)
            else:
                english_fields.append(field)
        
        if polish_fields:
            print(f"\n🇵🇱 Pola z polskimi znakami ({len(polish_fields)}):")
            for field in polish_fields[:10]:
                print(f"   - {field}")
            if len(polish_fields) > 10:
                print(f"   ... i {len(polish_fields) - 10} więcej")
        
        if mixed_fields:
            print(f"\n🔤 Pola ze znakami _ lub WIELKIE ({len(mixed_fields)}):")
            for field in mixed_fields[:10]:
                print(f"   - {field}")
            if len(mixed_fields) > 10:
                print(f"   ... i {len(mixed_fields) - 10} więcej")
        
        if english_fields:
            print(f"\n🏴󠁧󠁢󠁥󠁮󠁧󠁿 Pola w stylu angielskim ({len(english_fields)}):")
            for field in english_fields[:10]:
                print(f"   - {field}")
            if len(english_fields) > 10:
                print(f"   ... i {len(english_fields) - 10} więcej")
                
    except Exception as e:
        print(f"❌ Błąd analizy: {e}")

def main():
    """
    Główna funkcja testowa.
    """
    print("🔍 Analiza struktury plików JSON - Metropolitan Investment")
    print("=" * 70)
    
    json_dir = "split_investment_data"
    
    if not os.path.exists(json_dir):
        print(f"❌ Katalog {json_dir} nie istnieje!")
        return
    
    # Pliki do analizy
    json_files = ["clients.json", "apartments.json", "loans.json", "shares.json"]
    
    for filename in json_files:
        file_path = os.path.join(json_dir, filename)
        
        if os.path.exists(file_path):
            preview_json_structure(file_path)
            analyze_field_names(file_path)
        else:
            print(f"⚠️  Plik nie istnieje: {file_path}")
    
    print("\n" + "=" * 70)
    print("✅ Analiza zakończona!")
    print("\n💡 Następne kroki:")
    print("   1. Sprawdź pola wymagające normalizacji")
    print("   2. Uruchom: python3 normalize_json_fields.py")
    print("   3. Lub użyj: ./run_normalization.sh")

if __name__ == "__main__":
    main()
