#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Prosty skrypt do uzupełniania emaili i telefonów w clients_normalized.json
z danych z clients_extracted_updated.json.
"""

import json
import os
from datetime import datetime

def main():
    # Ścieżki do plików
    base_dir = "/home/deb/Documents/metropolitan_investment"
    normalized_file = os.path.join(base_dir, "split_investment_data_normalized", "clients_normalized.json")
    updated_file = os.path.join(base_dir, "clients_extracted_updated.json")
    
    print("Ładowanie plików...")
    
    # Ładowanie danych
    with open(normalized_file, 'r', encoding='utf-8') as f:
        normalized_clients = json.load(f)
    
    with open(updated_file, 'r', encoding='utf-8') as f:
        updated_clients = json.load(f)
    
    # Tworzenie słownika dla szybkiego wyszukiwania po ID
    updated_lookup = {client['id']: client for client in updated_clients}
    
    # Liczniki
    email_updated = 0
    phone_updated = 0
    
    # Aktualizacja danych
    for client in normalized_clients:
        client_id = client['id']
        
        # Sprawdzenie czy istnieje odpowiadający klient
        if client_id in updated_lookup:
            source_client = updated_lookup[client_id]
            
            # Aktualizacja emaila jeśli brakuje
            if not client.get('email', '').strip() and source_client.get('email', '').strip():
                client['email'] = source_client['email']
                email_updated += 1
            
            # Aktualizacja telefonu jeśli brakuje
            if not client.get('phone', '').strip() and source_client.get('phone', '').strip():
                client['phone'] = source_client['phone']
                phone_updated += 1
            
            # Aktualizacja timestamp jeśli coś się zmieniło
            if (not client.get('email', '').strip() and source_client.get('email', '').strip()) or \
               (not client.get('phone', '').strip() and source_client.get('phone', '').strip()):
                client['updatedAt'] = datetime.now().isoformat() + 'Z'
    
    # Tworzenie kopii zapasowej
    backup_file = f"{normalized_file}.backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}"
    with open(backup_file, 'w', encoding='utf-8') as f:
        json.dump(normalized_clients, f, indent=2, ensure_ascii=False)
    print(f"Utworzono kopię zapasową: {backup_file}")
    
    # Zapisanie zaktualizowanych danych
    with open(normalized_file, 'w', encoding='utf-8') as f:
        json.dump(normalized_clients, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Aktualizacja zakończona!")
    print(f"📧 Zaktualizowanych emaili: {email_updated}")
    print(f"📱 Zaktualizowanych telefonów: {phone_updated}")
    print(f"📋 Łącznie przetworzonych rekordów: {len(normalized_clients)}")

if __name__ == "__main__":
    main()
