#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Skrypt do wyodrębniania produktów typu "Apartamenty" z pliku JSON
Zgodny z modelem Apartment z apartment.dart
"""

import json
import os
from datetime import datetime

def extract_apartments():
    """
    Wyodrębnia produkty typu 'Apartamenty' z głównego pliku JSON
    i tworzy nowy plik apartments_new.json
    """
    input_file = "tableConvert.com_n0b2g7.json"
    output_file = "apartments_new.json"
    
    print(f"🔍 Wczytywanie danych z pliku: {input_file}")
    
    # Sprawdź czy plik wejściowy istnieje
    if not os.path.exists(input_file):
        print(f"❌ BŁĄD: Plik {input_file} nie istnieje!")
        return
    
    try:
        # Wczytaj dane z pliku JSON
        with open(input_file, 'r', encoding='utf-8') as f:
            data = json.load(f)
        
        print(f"📊 Załadowano {len(data)} rekordów")
        
        # Filtruj i mapuj apartamenty zgodnie z modelem Apartment.dart
        apartments = []
        
        def safe_to_double(value, default=0.0):
            """Bezpiecznie konwertuj na double, obsługuj przecinki"""
            if value is None:
                return default
            if isinstance(value, (int, float)):
                return float(value)
            if isinstance(value, str):
                # Usuń przecinki z liczb jak "305,700.00"
                cleaned = value.replace(',', '').strip()
                if cleaned == '' or cleaned.lower() == 'null':
                    return default
                try:
                    return float(cleaned)
                except ValueError:
                    return default
            return default

        for record in data:
            # Sprawdź różne możliwe nazwy pola typu produktu
            product_type = (
                record.get('Typ_produktu') or 
                record.get('typ_produktu') or 
                record.get('productType') or 
                ''
            )
            
            # Sprawdź czy to apartament
            if product_type.strip().lower() == 'apartamenty':
                
                # Mapuj TYLKO pola zgodne z NOWYM modelem Apartment - TYLKO ANGIELSKIE NAZWY!
                mapped_apartment = {
                    # Core investment fields
                    'productType': 'Apartamenty',
                    'investmentAmount': safe_to_double(record.get('Kwota_inwestycji')),
                    'capitalForRestructuring': safe_to_double(record.get('Kapitał do restrukturyzacji')),
                    'capitalSecuredByRealEstate': safe_to_double(record.get('Kapitał zabezpieczony nieruchomością')),
                    'sourceFile': 'tableConvert.com_n0b2g7.json',
                    'createdAt': datetime.now().isoformat(),
                    'uploadedAt': datetime.now().isoformat(),
                    
                    # Investment fields from JSON data - MAPPED TO ENGLISH NAMES
                    'saleId': str(record.get('ID_Sprzedaz', '')).strip(),
                    'clientId': str(record.get('ID_Klient', '')).strip(), 
                    'clientName': str(record.get('Klient', '')).strip(),
                    'advisor': str(record.get('Opiekun z MISA', '')).strip(),
                    'branch': str(record.get('Oddzial', '')).strip(),
                    'productStatus': str(record.get('Status_produktu', '')).strip(),
                    'marketEntry': str(record.get('Produkt_status_wejscie', '')).strip(),
                    'signedDate': record.get('Data_podpisania'),
                    'investmentEntryDate': record.get('Data_wejscia_do_inwestycji'),
                    'projectName': str(record.get('Produkt_nazwa', '')).strip(),
                    'creditorCompany': str(record.get('wierzyciel_spolka', '')).strip(),
                    'companyId': str(record.get('ID_Spolka', '')).strip(),
                    'issueDate': record.get('data_emisji'),
                    'redemptionDate': record.get('data_wykupu'),
                    'shareCount': str(record.get('Ilosc_Udzialow', '')).strip(),
                    'paymentAmount': safe_to_double(record.get('Kwota_wplat')),
                    'realizedCapital': safe_to_double(record.get('Kapital zrealizowany')),
                    'transferToOtherProduct': safe_to_double(record.get('Przekaz na inny produkt')),
                    'remainingCapital': safe_to_double(record.get('Kapital Pozostaly')),
                    'additionalInfo': {}  # Empty - no additional fields
                }
                
                # NO POLISH FIELD NAMES - ONLY ENGLISH!
                
                apartments.append(mapped_apartment)
                print(f"✅ Zmapowano apartament: {mapped_apartment.get('projectName', 'Brak nazwy')}")
                print(f"   💰 Kwota inwestycji: {mapped_apartment.get('investmentAmount')}")
                print(f"   👤 Klient: {mapped_apartment.get('clientName')}")
                print(f"   🏢 Oddział: {mapped_apartment.get('branch')}")
                print(f"   💎 Kapitał restrukturyzacji: {mapped_apartment.get('capitalForRestructuring')}")
                print(f"   📊 ID Sprzedaży: {mapped_apartment.get('saleId')}")
                print()
        
        print(f"\n📈 Statystyki:")
        print(f"   Całkowita liczba rekordów: {len(data)}")
        print(f"   Znalezione apartamenty: {len(apartments)}")
        
        if len(apartments) == 0:
            print("⚠️  Nie znaleziono żadnych apartamentów!")
            print("🔍 Sprawdzanie dostępnych typów produktów...")
            
            # Pokaż wszystkie typy produktów dla debugowania
            product_types = set()
            for record in data:
                pt = (
                    record.get('Typ_produktu') or 
                    record.get('typ_produktu') or 
                    record.get('productType') or 
                    'Brak'
                )
                product_types.add(pt.strip())
            
            print("📝 Dostępne typy produktów:")
            for pt in sorted(product_types):
                count = sum(1 for r in data if (
                    (r.get('Typ_produktu') or r.get('typ_produktu') or r.get('productType') or '').strip() == pt
                ))
                print(f"   - '{pt}': {count} rekordów")
            
            return
        
        # Zapisz apartamenty do nowego pliku
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(apartments, f, ensure_ascii=False, indent=2)
        
        print(f"\n🎉 SUKCES!")
        print(f"📁 Zapisano {len(apartments)} apartamentów do pliku: {output_file}")
        print(f"📊 Rozmiar pliku: {os.path.getsize(output_file)} bajtów")
        
        # Pokaż przykładowe dane z pierwszego apartamentu
        if apartments:
            print(f"\n📋 Przykład pierwszego apartamentu:")
            first_apt = apartments[0]
            print(f"   Nazwa: {first_apt.get('Produkt_nazwa', 'Brak')}")
            print(f"   Kwota inwestycji: {first_apt.get('Kwota_inwestycji', 'Brak')}")
            print(f"   Kapitał do restrukturyzacji: {first_apt.get('Kapitał do restrukturyzacji', 'Brak')}")
            print(f"   Typ produktu: {first_apt.get('Typ_produktu', 'Brak')}")
    
    except json.JSONDecodeError as e:
        print(f"❌ BŁĄD: Nieprawidłowy format JSON: {e}")
    except Exception as e:
        print(f"❌ BŁĄD: {e}")

def main():
    """Główna funkcja skryptu"""
    print("🏢 EKSTRAKTOR APARTAMENTÓW")
    print("=" * 50)
    print(f"⏰ Czas uruchomienia: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print()
    
    extract_apartments()
    
    print("\n" + "=" * 50)
    print("✅ Skrypt zakończony")

if __name__ == "__main__":
    main()
