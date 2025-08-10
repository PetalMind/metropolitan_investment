#!/usr/bin/env python3
"""
Skrypt do ujednolicenia nazywnictwa pól w plikach JSON zgodnie z konwencjami projektu Metropolitan Investment.

Mapuje polskie nazwy pól na ujednolicone nazwy używane w kodzie Dart/Flutter.
Zgodnie z dokumentacją projektu: polska nazwa w Firestore -> angielska nazwa w kodzie.
"""

import json
import os
from typing import Dict, Any, List

# Mapowanie nazw pól zgodnie z konwencjami projektu
FIELD_MAPPINGS = {
    # Wspólne pola dla wszystkich typów inwestycji
    "Kapital Pozostaly": "remainingCapital",
    "Kwota_inwestycji": "investmentAmount", 
    "Kwota inwestycji": "investmentAmount",
    "Kwota_wplat": "paidAmount",
    "Kapital zrealizowany": "realizedCapital",
    "Przekaz na inny produkt": "transferToOtherProduct",
    "Data_podpisania": "signingDate",
    "Data_wejscia_do_inwestycji": "investmentEntryDate",
    "Typ_produktu": "productType",
    "typ_produktu": "productType",
    "Produkt_nazwa": "productName",
    "Status_produktu": "productStatus",
    "Produkt_status_wejscie": "productStatusEntry",
    "ID_Klient": "clientId",
    "Klient": "clientName",
    "Opiekun z MISA": "misaGuardian",
    "Oddzial": "branch",
    "ID_Spolka": "companyId",
    "wierzyciel_spolka": "creditorCompany",
    "data_emisji": "issueDate",
    "data_wykupu": "redemptionDate",
    
    # Pola specyficzne dla apartamentów
    "numer_apartamentu": "apartmentNumber",
    "budynek": "building",
    "adres": "address",
    "powierzchnia": "area",
    "liczba_pokoi": "roomCount",
    "pietro": "floor",
    "status": "status",
    "cena_za_m2": "pricePerM2",
    "data_oddania": "deliveryDate",
    "deweloper": "developer",
    "nazwa_projektu": "projectName",
    "balkon": "balcony",
    "miejsce_parkingowe": "parkingSpace",
    "komorka_lokatorska": "storageRoom",
    
    # Pola specyficzne dla pożyczek
    "pozyczka_numer": "loanNumber",
    "pozyczka_typ": "loanType",
    "pozyczka_status": "loanStatus",
    "pozyczka_oprocentowanie": "loanInterestRate",
    "pozyczka_termin_splaty": "loanRepaymentTerm",
    "pozyczka_zabezpieczenie": "loanCollateral",
    
    # Pola specyficzne dla udziałów
    "Ilosc_Udzialow": "shareCount",
    "ilosc_udzialow": "shareCount",
    "wartosc_nominalna": "nominalValue",
    "wartosc_rynkowa": "marketValue",
    
    # Pola specyficzne dla klientów
    "imie_nazwisko": "fullName",
    "nazwa_firmy": "companyName",
    "telefon": "phone",
    "email": "email",
    
    # Pola meta
    "created_at": "createdAt",
    "uploaded_at": "uploadedAt",
    "source_file": "sourceFile",
    "kapital_do_restrukturyzacji": "capitalForRestructuring",
    "kapital_zabezpieczony_nieruchomoscia": "realEstateSecuredCapital",
    
    # Pola ID
    "ID_Sprzedaz": "saleId",
    "id": "id"
}

def normalize_field_names(data: Dict[str, Any]) -> Dict[str, Any]:
    """
    Normalizuje nazwy pól w obiekcie zgodnie z mapowaniem.
    
    Args:
        data: Słownik z danymi do normalizacji
        
    Returns:
        Słownik z znormalizowanymi nazwami pól
    """
    normalized = {}
    
    for key, value in data.items():
        # Użyj zmapowanej nazwy lub pozostaw oryginalną
        normalized_key = FIELD_MAPPINGS.get(key, key)
        normalized[normalized_key] = value
        
        # Loguj mapowanie jeśli zostało zastosowane
        if normalized_key != key:
            print(f"  Mapowanie: '{key}' -> '{normalized_key}'")
    
    return normalized

def process_json_file(file_path: str) -> None:
    """
    Przetwarza pojedynczy plik JSON, normalizując nazwy pól.
    
    Args:
        file_path: Ścieżka do pliku JSON
    """
    print(f"\nPrzetwarzanie pliku: {file_path}")
    
    try:
        # Wczytaj plik JSON
        with open(file_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        # Sprawdź czy to lista obiektów
        if isinstance(data, list):
            normalized_data = []
            for i, item in enumerate(data):
                if isinstance(item, dict):
                    print(f"  Normalizacja obiektu {i + 1}/{len(data)}")
                    normalized_item = normalize_field_names(item)
                    normalized_data.append(normalized_item)
                else:
                    normalized_data.append(item)
            
            # Zapisz znormalizowany plik
            backup_path = file_path + '.backup'
            os.rename(file_path, backup_path)
            print(f"  Utworzono backup: {backup_path}")
            
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(normalized_data, f, ensure_ascii=False, indent=2)
            
            print(f"  ✅ Znormalizowano {len(normalized_data)} obiektów")
            
        elif isinstance(data, dict):
            print("  Normalizacja pojedynczego obiektu")
            normalized_data = normalize_field_names(data)
            
            # Zapisz znormalizowany plik
            backup_path = file_path + '.backup'
            os.rename(file_path, backup_path)
            print(f"  Utworzono backup: {backup_path}")
            
            with open(file_path, 'w', encoding='utf-8') as f:
                json.dump(normalized_data, f, ensure_ascii=False, indent=2)
            
            print("  ✅ Znormalizowano pojedynczy obiekt")
            
        else:
            print("  ⚠️  Plik nie zawiera obiektu ani listy obiektów")
            
    except json.JSONDecodeError as e:
        print(f"  ❌ Błąd parsowania JSON: {e}")
    except Exception as e:
        print(f"  ❌ Błąd przetwarzania: {e}")

def main():
    """
    Główna funkcja skryptu - przetwarza wszystkie pliki JSON w katalogu.
    """
    print("🔄 Skrypt normalizacji nazw pól JSON - Metropolitan Investment")
    print("=" * 60)
    
    # Katalog z plikami JSON
    json_dir = "split_investment_data"
    
    if not os.path.exists(json_dir):
        print(f"❌ Katalog {json_dir} nie istnieje!")
        return
    
    # Lista plików do przetworzenia
    json_files = [
        "clients.json",
        "apartments.json", 
        "loans.json",
        "shares.json"
    ]
    
    processed_count = 0
    
    for filename in json_files:
        file_path = os.path.join(json_dir, filename)
        
        if os.path.exists(file_path):
            process_json_file(file_path)
            processed_count += 1
        else:
            print(f"⚠️  Plik nie istnieje: {file_path}")
    
    print("\n" + "=" * 60)
    print(f"✅ Zakończono! Przetworzono {processed_count} plików.")
    print(f"💾 Utworzono kopie zapasowe z rozszerzeniem .backup")
    print("\n📋 Statystyki mapowań:")
    print(f"   - Zdefiniowano {len(FIELD_MAPPINGS)} mapowań pól")
    print("   - Pola wspólne: Kapital Pozostaly -> remainingCapital")
    print("   - Pola wspólne: Kwota_inwestycji -> investmentAmount")
    print("   - Pola klientów: imie_nazwisko -> fullName")
    print("   - Pola specjalistyczne dla każdego typu produktu")

if __name__ == "__main__":
    main()
