#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Skrypt do uzupełniania danych kontaktowych (email i telefon) w pliku clients_normalized.json
na podstawie danych z pliku clients_extracted_updated.json.

Porównuje klientów po ID i uzupełnia brakujące dane kontaktowe.
"""

import json
import os
from datetime import datetime
from typing import Dict, List, Any

def load_json_file(file_path: str) -> List[Dict[str, Any]]:
    """Ładuje dane z pliku JSON."""
    try:
        with open(file_path, 'r', encoding='utf-8') as file:
            data = json.load(file)
            print(f"Załadowano {len(data)} rekordów z {file_path}")
            return data
    except FileNotFoundError:
        print(f"Błąd: Nie znaleziono pliku {file_path}")
        return []
    except json.JSONDecodeError as e:
        print(f"Błąd dekodowania JSON w pliku {file_path}: {e}")
        return []

def save_json_file(file_path: str, data: List[Dict[str, Any]]) -> bool:
    """Zapisuje dane do pliku JSON."""
    try:
        # Tworzenie kopii zapasowej
        backup_path = f"{file_path}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
        if os.path.exists(file_path):
            with open(file_path, 'r', encoding='utf-8') as original:
                with open(backup_path, 'w', encoding='utf-8') as backup:
                    backup.write(original.read())
            print(f"Utworzono kopię zapasową: {backup_path}")
        
        # Zapisywanie nowych danych
        with open(file_path, 'w', encoding='utf-8') as file:
            json.dump(data, file, indent=2, ensure_ascii=False)
        print(f"Zapisano {len(data)} rekordów do {file_path}")
        return True
    except Exception as e:
        print(f"Błąd podczas zapisywania pliku {file_path}: {e}")
        return False

def create_id_lookup(clients: List[Dict[str, Any]]) -> Dict[str, Dict[str, Any]]:
    """Tworzy słownik dla szybkiego wyszukiwania klientów po ID."""
    lookup = {}
    for client in clients:
        client_id = client.get('id', '')
        if client_id:
            lookup[client_id] = client
    return lookup

def update_contact_data(normalized_clients: List[Dict[str, Any]], 
                       updated_clients_lookup: Dict[str, Dict[str, Any]]) -> tuple:
    """
    Uzupełnia dane kontaktowe w clients_normalized na podstawie clients_extracted_updated.
    
    Returns:
        tuple: (updated_clients, stats)
    """
    stats = {
        'total_processed': 0,
        'email_updated': 0,
        'phone_updated': 0,
        'both_updated': 0,
        'no_match_found': 0,
        'already_complete': 0
    }
    
    updated_clients = []
    
    for client in normalized_clients:
        stats['total_processed'] += 1
        client_id = client.get('id', '')
        
        # Sprawdzenie czy istnieje odpowiadający klient w updated_clients
        if client_id not in updated_clients_lookup:
            stats['no_match_found'] += 1
            updated_clients.append(client)
            continue
        
        source_client = updated_clients_lookup[client_id]
        
        # Sprawdzenie aktualnych danych kontaktowych
        current_email = client.get('email', '').strip()
        current_phone = client.get('phone', '').strip()
        
        source_email = source_client.get('email', '').strip()
        source_phone = source_client.get('phone', '').strip()
        
        # Flags dla aktualizacji
        email_needs_update = not current_email and source_email
        phone_needs_update = not current_phone and source_phone
        
        if not email_needs_update and not phone_needs_update:
            stats['already_complete'] += 1
            updated_clients.append(client)
            continue
        
        # Tworzenie zaktualizowanego klienta
        updated_client = client.copy()
        
        if email_needs_update:
            updated_client['email'] = source_email
            stats['email_updated'] += 1
        
        if phone_needs_update:
            updated_client['phone'] = source_phone
            stats['phone_updated'] += 1
        
        if email_needs_update and phone_needs_update:
            stats['both_updated'] += 1
        
        # Aktualizacja timestamp
        updated_client['updatedAt'] = datetime.now().isoformat() + 'Z'
        
        updated_clients.append(updated_client)
    
    return updated_clients, stats

def print_statistics(stats: Dict[str, int]):
    """Wyświetla statystyki aktualizacji."""
    print("\n" + "="*50)
    print("STATYSTYKI AKTUALIZACJI")
    print("="*50)
    print(f"Łącznie przetworzonych rekordów: {stats['total_processed']}")
    print(f"Zaktualizowanych emaili: {stats['email_updated']}")
    print(f"Zaktualizowanych telefonów: {stats['phone_updated']}")
    print(f"Zaktualizowanych obu pól: {stats['both_updated']}")
    print(f"Już kompletnych rekordów: {stats['already_complete']}")
    print(f"Nie znaleziono dopasowania: {stats['no_match_found']}")
    print("="*50)

def main():
    """Główna funkcja skryptu."""
    print("Rozpoczynanie aktualizacji danych kontaktowych klientów...")
    
    # Ścieżki do plików
    base_dir = "/home/deb/Documents/metropolitan_investment"
    normalized_file = os.path.join(base_dir, "split_investment_data_normalized", "clients_normalized.json")
    updated_file = os.path.join(base_dir, "clients_extracted_updated.json")
    
    print(f"Plik docelowy: {normalized_file}")
    print(f"Plik źródłowy: {updated_file}")
    
    # Ładowanie danych
    normalized_clients = load_json_file(normalized_file)
    updated_clients = load_json_file(updated_file)
    
    if not normalized_clients:
        print("Błąd: Nie udało się załadować pliku clients_normalized.json")
        return
    
    if not updated_clients:
        print("Błąd: Nie udało się załadować pliku clients_extracted_updated.json")
        return
    
    # Tworzenie lookup dictionary dla szybkiego wyszukiwania
    print("Tworzenie indeksu dla szybkiego wyszukiwania...")
    updated_clients_lookup = create_id_lookup(updated_clients)
    print(f"Utworzono indeks dla {len(updated_clients_lookup)} klientów")
    
    # Aktualizacja danych
    print("Rozpoczynanie aktualizacji danych kontaktowych...")
    updated_data, stats = update_contact_data(normalized_clients, updated_clients_lookup)
    
    # Wyświetlenie statystyk
    print_statistics(stats)
    
    # Zapisanie zaktualizowanych danych
    if stats['email_updated'] > 0 or stats['phone_updated'] > 0:
        print(f"\nZapisywanie zaktualizowanych danych do {normalized_file}...")
        if save_json_file(normalized_file, updated_data):
            print("✅ Aktualizacja zakończona pomyślnie!")
        else:
            print("❌ Błąd podczas zapisywania pliku!")
    else:
        print("\n📋 Brak danych do aktualizacji. Wszystkie rekordy są już kompletne.")
    
    print("\nSkrypt zakończony.")

if __name__ == "__main__":
    main()
