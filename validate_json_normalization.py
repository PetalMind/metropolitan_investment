#!/usr/bin/env python3
"""
Skrypt walidacyjny do sprawdzenia poprawności normalizacji pól JSON.

Sprawdza:
- Czy wszystkie oczekiwane pola zostały zmapowane
- Czy nie ma nieoczekiwanych pól
- Czy struktury danych są spójne
- Czy wartości kapitału pozostałego są poprawne
"""

import json
import os
from typing import Dict, Any, List, Set
from collections import Counter

# Oczekiwane pola po normalizacji dla każdego typu
EXPECTED_FIELDS = {
    "clients": {
        "required": ["id", "fullName", "createdAt"],
        "optional": ["companyName", "phone", "email"]
    },
    "apartments": {
        "required": ["id", "productType", "remainingCapital", "investmentAmount"],
        "optional": ["apartmentNumber", "building", "address", "area", "roomCount", 
                    "floor", "status", "pricePerM2", "deliveryDate", "developer", 
                    "projectName", "balcony", "parkingSpace", "storageRoom", "clientId",
                    "clientName", "createdAt", "uploadedAt", "sourceFile"]
    },
    "loans": {
        "required": ["id", "productType", "remainingCapital", "investmentAmount"],
        "optional": ["loanNumber", "loanType", "loanStatus", "loanInterestRate",
                    "loanRepaymentTerm", "loanCollateral", "clientId", "clientName",
                    "createdAt", "uploadedAt", "sourceFile"]
    },
    "shares": {
        "required": ["id", "productType", "remainingCapital", "investmentAmount"],
        "optional": ["shareCount", "nominalValue", "marketValue", "clientId",
                    "clientName", "createdAt", "uploadedAt", "sourceFile"]
    }
}

def analyze_json_structure(data: List[Dict[str, Any]], file_type: str) -> Dict[str, Any]:
    """
    Analizuje strukturę danych JSON i zwraca statystyki.
    
    Args:
        data: Lista obiektów JSON
        file_type: Typ pliku (clients, apartments, loans, shares)
        
    Returns:
        Słownik ze statystykami
    """
    stats = {
        "total_records": len(data),
        "all_fields": set(),
        "field_counts": Counter(),
        "missing_required": [],
        "unexpected_fields": [],
        "capital_stats": {"zero": 0, "positive": 0, "total": 0}
    }
    
    expected = EXPECTED_FIELDS.get(file_type, {"required": [], "optional": []})
    required_fields = set(expected["required"])
    optional_fields = set(expected["optional"])
    expected_all = required_fields | optional_fields
    
    for record in data:
        if not isinstance(record, dict):
            continue
            
        record_fields = set(record.keys())
        stats["all_fields"].update(record_fields)
        
        # Sprawdź wymagane pola
        missing = required_fields - record_fields
        if missing:
            stats["missing_required"].extend(list(missing))
        
        # Sprawdź nieoczekiwane pola
        unexpected = record_fields - expected_all
        if unexpected:
            stats["unexpected_fields"].extend(list(unexpected))
        
        # Policz wystąpienia pól
        for field in record_fields:
            stats["field_counts"][field] += 1
        
        # Analizuj kapitał pozostały
        if "remainingCapital" in record:
            stats["capital_stats"]["total"] += 1
            try:
                capital_value = float(str(record["remainingCapital"]).replace(",", ""))
                if capital_value == 0:
                    stats["capital_stats"]["zero"] += 1
                else:
                    stats["capital_stats"]["positive"] += 1
            except (ValueError, TypeError):
                pass
    
    # Usuń duplikaty z list
    stats["missing_required"] = list(set(stats["missing_required"]))
    stats["unexpected_fields"] = list(set(stats["unexpected_fields"]))
    
    return stats

def validate_json_file(file_path: str, file_type: str) -> None:
    """
    Waliduje pojedynczy plik JSON.
    
    Args:
        file_path: Ścieżka do pliku JSON
        file_type: Typ pliku do walidacji
    """
    print(f"\n📋 Walidacja pliku: {file_path}")
    print("-" * 50)
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        if not isinstance(data, list):
            print("❌ Plik nie zawiera listy obiektów")
            return
        
        stats = analyze_json_structure(data, file_type)
        
        # Wyświetl statystyki
        print(f"📊 Liczba rekordów: {stats['total_records']}")
        print(f"📊 Liczba unikalnych pól: {len(stats['all_fields'])}")
        
        # Wymagane pola
        if stats["missing_required"]:
            print(f"❌ Brakujące wymagane pola: {stats['missing_required']}")
        else:
            print("✅ Wszystkie wymagane pola są obecne")
        
        # Nieoczekiwane pola
        if stats["unexpected_fields"]:
            print(f"⚠️  Nieoczekiwane pola: {stats['unexpected_fields'][:10]}...")
        else:
            print("✅ Wszystkie pola są oczekiwane")
        
        # Najczęściej występujące pola
        print("\n🔍 Najczęściej występujące pola:")
        for field, count in stats["field_counts"].most_common(10):
            percentage = (count / stats["total_records"]) * 100
            print(f"   {field}: {count} ({percentage:.1f}%)")
        
        # Statystyki kapitału
        if stats["capital_stats"]["total"] > 0:
            zero_pct = (stats["capital_stats"]["zero"] / stats["capital_stats"]["total"]) * 100
            positive_pct = (stats["capital_stats"]["positive"] / stats["capital_stats"]["total"]) * 100
            print(f"\n💰 Kapitał pozostały:")
            print(f"   Zero: {stats['capital_stats']['zero']} ({zero_pct:.1f}%)")
            print(f"   Dodatni: {stats['capital_stats']['positive']} ({positive_pct:.1f}%)")
        
        print("✅ Walidacja zakończona")
        
    except json.JSONDecodeError as e:
        print(f"❌ Błąd parsowania JSON: {e}")
    except Exception as e:
        print(f"❌ Błąd walidacji: {e}")

def compare_before_after(original_file: str, normalized_file: str) -> None:
    """
    Porównuje pliki przed i po normalizacji.
    
    Args:
        original_file: Ścieżka do pliku oryginalnego (.backup)
        normalized_file: Ścieżka do pliku znormalizowanego
    """
    print(f"\n🔄 Porównanie: oryginalny vs znormalizowany")
    print("-" * 50)
    
    try:
        # Wczytaj oba pliki
        with open(original_file, 'r', encoding='utf-8') as f:
            original_data = json.load(f)
        
        with open(normalized_file, 'r', encoding='utf-8') as f:
            normalized_data = json.load(f)
        
        if not isinstance(original_data, list) or not isinstance(normalized_data, list):
            print("❌ Pliki nie zawierają list obiektów")
            return
        
        # Porównaj liczby rekordów
        if len(original_data) != len(normalized_data):
            print(f"⚠️  Różna liczba rekordów: {len(original_data)} -> {len(normalized_data)}")
        else:
            print(f"✅ Zachowano liczbę rekordów: {len(original_data)}")
        
        # Porównaj pola
        if original_data and normalized_data:
            orig_fields = set(original_data[0].keys()) if original_data[0] else set()
            norm_fields = set(normalized_data[0].keys()) if normalized_data[0] else set()
            
            added_fields = norm_fields - orig_fields
            removed_fields = orig_fields - norm_fields
            
            print(f"📊 Pola oryginalne: {len(orig_fields)}")
            print(f"📊 Pola znormalizowane: {len(norm_fields)}")
            
            if added_fields:
                print(f"➕ Dodane pola: {list(added_fields)[:5]}...")
            if removed_fields:
                print(f"➖ Usunięte pola: {list(removed_fields)[:5]}...")
        
    except Exception as e:
        print(f"❌ Błąd porównania: {e}")

def main():
    """
    Główna funkcja walidacji.
    """
    print("🔍 Skrypt walidacji normalizacji JSON - Metropolitan Investment")
    print("=" * 70)
    
    json_dir = "split_investment_data"
    
    if not os.path.exists(json_dir):
        print(f"❌ Katalog {json_dir} nie istnieje!")
        return
    
    # Pliki do walidacji
    files_to_validate = [
        ("clients.json", "clients"),
        ("apartments.json", "apartments"),
        ("loans.json", "loans"),
        ("shares.json", "shares")
    ]
    
    for filename, file_type in files_to_validate:
        file_path = os.path.join(json_dir, filename)
        backup_path = file_path + ".backup"
        
        if os.path.exists(file_path):
            validate_json_file(file_path, file_type)
            
            # Porównaj z backupem jeśli istnieje
            if os.path.exists(backup_path):
                compare_before_after(backup_path, file_path)
        else:
            print(f"⚠️  Plik nie istnieje: {file_path}")
    
    print("\n" + "=" * 70)
    print("✅ Walidacja zakończona!")
    print("\n💡 Wskazówki:")
    print("   - Sprawdź nieoczekiwane pola - mogą wymagać dodania do mapowania")
    print("   - Kapitał pozostały = 0.00 może oznaczać zakończone inwestycje")
    print("   - Wysokie wartości procentowe dla pól wskazują na kompletność danych")

if __name__ == "__main__":
    main()
