#!/usr/bin/env python3
"""
Szybka wersja skryptu normalizacji, która tworzy osobny folder output.
"""

import json
import os
import shutil
from typing import Dict, Any, List

# Mapowanie nazw pól
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
    
    # Pola klientów
    "imie_nazwisko": "fullName",
    "nazwa_firmy": "companyName",
    "telefon": "phone",
    "email": "email",
    
    # Pola apartamentów
    "numer_apartamentu": "apartmentNumber",
    "budynek": "building",
    "adres": "address",
    "powierzchnia": "area",
    "liczba_pokoi": "roomCount",
    "pietro": "floor",
    "cena_za_m2": "pricePerM2",
    "data_oddania": "deliveryDate",
    "deweloper": "developer",
    "nazwa_projektu": "projectName",
    "balkon": "balcony",
    "miejsce_parkingowe": "parkingSpace",
    "komorka_lokatorska": "storageRoom",
    
    # Pola pożyczek
    "pozyczka_numer": "loanNumber",
    "pozyczkobiorca": "borrower",
    "wierzyciel_spolka": "creditorCompany",
    "oprocentowanie": "interestRate",
    "data_udzielenia": "disbursementDate",
    "data_splaty": "repaymentDate",
    "odsetki_naliczone": "accruedInterest",
    "zabezpieczenie": "collateral",
    
    # Pola udziałów
    "Ilosc_Udzialow": "shareCount",
    
    # Pola inwestycji (rozszerzony model)
    "Oddzial": "branch",
    "ID_Sprzedaz": "saleId",
    "ID_Spolka": "companyId",
    
    # Standardowe pola systemowe
    "created_at": "createdAt",
    "uploaded_at": "updatedAt",
    "source_file": "sourceFile",
}

def normalize_field_names(data: Dict[str, Any]) -> Dict[str, Any]:
    """Normalizuje nazwy pól zgodnie z mapowaniami"""
    normalized = {}
    
    for key, value in data.items():
        normalized_key = FIELD_MAPPINGS.get(key, key)
        normalized[normalized_key] = value
    
    return normalized

def main():
    print("🔄 Szybka normalizacja JSON dla Firebase Upload")
    print("=" * 60)
    
    # Katalogi
    input_dir = "split_investment_data"
    output_dir = "split_investment_data_normalized"
    
    # Sprawdź katalog źródłowy
    if not os.path.exists(input_dir):
        print(f"❌ Katalog {input_dir} nie istnieje!")
        return
    
    # Utwórz katalog wyjściowy
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
        print(f"🧹 Usunięto poprzedni katalog {output_dir}")
    
    os.makedirs(output_dir)
    print(f"📁 Utworzono katalog: {output_dir}")
    
    # Lista plików
    json_files = ["clients.json", "apartments.json", "loans.json", "shares.json"]
    processed_count = 0
    
    for filename in json_files:
        input_path = os.path.join(input_dir, filename)
        
        if not os.path.exists(input_path):
            print(f"⚠️  Plik nie istnieje: {input_path}")
            continue
            
        print(f"\n📄 Przetwarzanie: {filename}")
        
        try:
            # Wczytaj plik
            with open(input_path, 'r', encoding='utf-8') as f:
                data = json.load(f)
            
            if isinstance(data, list):
                normalized_data = []
                for item in data:
                    if isinstance(item, dict):
                        normalized_item = normalize_field_names(item)
                        normalized_data.append(normalized_item)
                    else:
                        normalized_data.append(item)
                
                # Utwórz nazwę wyjściową
                name, ext = os.path.splitext(filename)
                output_filename = f"{name}_normalized{ext}"
                output_path = os.path.join(output_dir, output_filename)
                
                # Zapisz znormalizowany plik
                with open(output_path, 'w', encoding='utf-8') as f:
                    json.dump(normalized_data, f, ensure_ascii=False, indent=2)
                
                print(f"  ✅ Utworzono: {output_filename} ({len(normalized_data)} obiektów)")
                processed_count += 1
                
        except Exception as e:
            print(f"  ❌ Błąd: {e}")
    
    print("\n" + "=" * 60)
    print(f"✅ Zakończono! Przetworzono {processed_count} plików.")
    print(f"📁 Znormalizowane pliki w: {output_dir}/")
    
    # Pokaż co zostało utworzone
    if os.path.exists(output_dir):
        print(f"\n📋 Utworzone pliki:")
        for filename in os.listdir(output_dir):
            file_path = os.path.join(output_dir, filename)
            size = os.path.getsize(file_path)
            print(f"   - {filename} ({size:,} bytes)")

if __name__ == "__main__":
    main()
