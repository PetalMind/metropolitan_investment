#!/usr/bin/env python3
import json
from datetime import datetime

def safe_to_string(value):
    """Safely convert value to string, handling None and various types"""
    if value is None or value == "NULL":
        return ""
    return str(value).strip()

def parse_date(date_str):
    """Parse date string to ISO format"""
    if not date_str or date_str == "NULL" or date_str.strip() == "":
        return None
    
    try:
        # Handle datetime format from JSON: "2019-11-05 00:00:00"
        if " " in date_str:
            date_part = date_str.split(" ")[0]
            return datetime.strptime(date_part, "%Y-%m-%d").isoformat()
        else:
            return datetime.strptime(date_str, "%Y-%m-%d").isoformat()
    except ValueError:
        print(f"Warning: Could not parse date: {date_str}")
        return None

def extract_clients():
    print("🚀 Starting client extraction...")
    
    # Read the JSON file
    with open('tableConvert.com_n0b2g7.json', 'r', encoding='utf-8') as f:
        data = json.load(f)
    
    print(f"📊 Total records in JSON: {len(data)}")
    
    clients = []
    unique_clients = set()
    
    for record in data:
        client_name = safe_to_string(record.get("Klient", ""))
        
        # Skip empty client names, "NULL", or employee-like entries
        if not client_name or client_name == "NULL" or client_name == "":
            continue
            
        # Skip if it looks like an employee (contains common employee indicators)
        employee_indicators = [
            "Michał Ostrowski", "Ewelina Morzywołek", "Damian Kijowski", 
            "MISA", "Metropolitan", "Biuro", "Oddział", "Opiekun"
        ]
        
        is_employee = any(indicator in client_name for indicator in employee_indicators)
        if is_employee:
            continue
        
        # Create unique client entry
        if client_name not in unique_clients:
            unique_clients.add(client_name)
            
            # Map client data to English fields matching client.dart model
            client_id = safe_to_string(record.get("ID_Klient"))
            client_data = {
                "id": client_id,  # Use ID_Klient as the main ID
                "excelId": client_id,
                "fullName": client_name,
                "name": client_name,
                "email": "",  # Not available in this dataset
                "phone": "",  # Not available in this dataset
                "address": "",  # Not available in this dataset
                "pesel": None,  # Not available in this dataset
                "companyName": None,
                "type": "individual",  # Default to individual
                "notes": "",
                "votingStatus": "undecided",
                "colorCode": "#FFFFFF",
                "unviableInvestments": [],
                "createdAt": datetime.now().isoformat(),
                "updatedAt": datetime.now().isoformat(),
                "isActive": True,
                "additionalInfo": {
                    "sourceFile": "tableConvert.com_n0b2g7.json",
                    "originalClientId": safe_to_string(record.get("ID_Klient")),
                    "extractedAt": datetime.now().isoformat()
                }
            }
            
            clients.append(client_data)
    
    print(f"✅ Extracted {len(clients)} unique clients")
    
    # Save to JSON file
    with open('clients_extracted.json', 'w', encoding='utf-8') as f:
        json.dump(clients, f, ensure_ascii=False, indent=2)
    
    print("💾 Clients saved to clients_extracted.json")
    
    # Print sample of extracted clients
    print("\n📋 Sample of extracted clients:")
    for i, client in enumerate(clients[:10]):
        print(f"{i+1}. {client['fullName']} (ID: {client['excelId']})")
    
    if len(clients) > 10:
        print(f"... and {len(clients) - 10} more clients")
    
    return clients

if __name__ == "__main__":
    extracted_clients = extract_clients()
    print(f"\n🎯 Total unique clients extracted: {len(extracted_clients)}")
