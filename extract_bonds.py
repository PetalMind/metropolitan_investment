#!/usr/bin/env python3
import json
from datetime import datetime

def safe_to_double(value):
    """Safely convert value to double/float"""
    if value is None or value == 'NULL':
        return 0.0
    if isinstance(value, (int, float)):
        return float(value)
    if isinstance(value, str):
        if value.strip() == '' or value.upper() == 'NULL':
            return 0.0
        # Handle comma-separated numbers like "305,700.00"
        cleaned = value.replace(',', '')
        try:
            return float(cleaned)
        except ValueError:
            return 0.0
    return 0.0

def parse_date(date_str):
    """Parse date string to ISO format"""
    if not date_str or date_str == 'NULL':
        return None
    
    try:
        # Handle different date formats
        if '-' in date_str:
            # ISO format like "2019-01-30 00:00:00"
            return date_str.split(' ')[0] + 'T00:00:00.000Z'
        elif '/' in date_str:
            # Format like "2/8/19"
            parts = date_str.split('/')
            if len(parts) == 3:
                month, day, year = parts
                year = int(year)
                if year < 100:
                    year += 2000 if year < 30 else 1900
                return f"{year:04d}-{int(month):02d}-{int(day):02d}T00:00:00.000Z"
        return date_str
    except Exception as e:
        print(f"Error parsing date: {date_str} - {e}")
        return None

def main():
    print("🔍 Extracting bonds from JSON data...")
    
    # Read the JSON file
    try:
        with open('tableConvert.com_n0b2g7.json', 'r', encoding='utf-8') as file:
            data = json.load(file)
    except FileNotFoundError:
        print("❌ Error: tableConvert.com_n0b2g7.json not found")
        return
    except json.JSONDecodeError as e:
        print(f"❌ Error parsing JSON: {e}")
        return

    # Filter for bonds only
    bonds = [item for item in data if item.get('Typ_produktu') == 'Obligacje']
    
    print(f"📊 Found {len(bonds)} bond products out of {len(data)} total products")
    
    if not bonds:
        print("⚠️ No bonds found in the data")
        return

    # Transform data to match Bond model with English field names
    transformed_bonds = []
    current_time = datetime.now().isoformat() + 'Z'
    
    for i, bond in enumerate(bonds):
        transformed_bond = {
            # Generate unique ID
            "id": f"bond_{i+1:04d}",
            
            # Core investment fields (English names)
            "productType": bond.get('Typ_produktu', 'Obligacje'),
            "investmentAmount": safe_to_double(bond.get('Kwota_inwestycji')),
            "realizedCapital": safe_to_double(bond.get('Kapital zrealizowany')),
            "remainingCapital": safe_to_double(bond.get('Kapital Pozostaly')),
            "realizedInterest": 0.0,  # Not in source data
            "remainingInterest": 0.0,  # Not in source data
            "realizedTax": 0.0,  # Not in source data
            "remainingTax": 0.0,  # Not in source data
            "transferToOtherProduct": safe_to_double(bond.get('Przekaz na inny produkt')),
            "capitalForRestructuring": safe_to_double(bond.get('Kapitał do restrukturyzacji')),
            "capitalSecuredByRealEstate": safe_to_double(bond.get('Kapitał zabezpieczony nieruchomością')),
            
            # Metadata fields
            "sourceFile": "tableConvert.com_n0b2g7.json",
            "createdAt": current_time,
            "uploadedAt": current_time,
            
            # Client and transaction info (English names)
            "clientId": bond.get('ID_Klient'),
            "clientName": bond.get('Klient'),
            "companyId": bond.get('ID_Spolka'),
            "salesId": bond.get('ID_Sprzedaz'),
            "sharesCount": None,  # NULL for bonds
            "paymentAmount": safe_to_double(bond.get('Kwota_wplat')),
            "branch": bond.get('Oddzial'),
            "advisor": bond.get('Opiekun z MISA'),
            "productName": bond.get('Produkt_nazwa'),
            "productStatusEntry": bond.get('Produkt_status_wejscie'),
            "productStatus": bond.get('Status_produktu'),
            
            # Date fields
            "signedDate": parse_date(bond.get('Data_podpisania')),
            "investmentEntryDate": parse_date(bond.get('Data_wejscia_do_inwestycji')),
            "issueDate": parse_date(bond.get('data_emisji')),
            "maturityDate": parse_date(bond.get('data_wykupu')),  # data_wykupu for bonds
            "redemptionDate": parse_date(bond.get('data_wykupu')),
            "interestRate": bond.get('oprocentowanie'),
            
            # Additional info for any unmapped fields
            "additionalInfo": {
                "wierzyciel_spolka": bond.get('wierzyciel_spolka')
            }
        }
        
        transformed_bonds.append(transformed_bond)

    # Save transformed data
    output_file = 'bonds_extracted.json'
    try:
        with open(output_file, 'w', encoding='utf-8') as file:
            json.dump(transformed_bonds, file, indent=2, ensure_ascii=False)
        
        print(f"✅ Successfully extracted {len(transformed_bonds)} bonds to {output_file}")
        
        # Show sample data
        if transformed_bonds:
            print("\n📋 Sample bond data:")
            sample = transformed_bonds[0]
            print(f"  ID: {sample['id']}")
            print(f"  Client: {sample['clientName']}")
            print(f"  Product: {sample['productName']}")
            print(f"  Investment: {sample['investmentAmount']}")
            print(f"  Remaining: {sample['remainingCapital']}")
            print(f"  Signed Date: {sample['signedDate']}")
            
    except Exception as e:
        print(f"❌ Error saving file: {e}")

if __name__ == "__main__":
    main()
