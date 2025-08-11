#!/usr/bin/env python3
import json
from datetime import datetime

def safe_to_double(value):
    """Safely convert value to double/float"""
    if value is None or value == 'NULL' or value == '':
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

def safe_to_int(value):
    """Safely convert value to int"""
    if value is None or value == 'NULL' or value == '':
        return 0
    if isinstance(value, int):
        return value
    if isinstance(value, float):
        return int(value)
    if isinstance(value, str):
        if value.strip() == '' or value.upper() == 'NULL':
            return 0
        try:
            return int(float(value))
        except ValueError:
            return 0
    return 0

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
    print("🔍 Extracting shares from JSON data...")
    
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

    # Filter for shares only
    shares = [item for item in data if item.get('Typ_produktu') == 'Udziały']
    
    print(f"📊 Found {len(shares)} share products out of {len(data)} total products")
    
    if not shares:
        print("⚠️ No shares found in the data")
        return

    # Transform data to match Share model with English field names
    transformed_shares = []
    current_time = datetime.now().isoformat() + 'Z'
    
    for i, share in enumerate(shares):
        transformed_share = {
            # Generate unique ID
            "id": f"share_{i+1:04d}",
            
            # Core fields (English names)
            "productType": share.get('Typ_produktu', 'Udziały'),
            "investmentAmount": safe_to_double(share.get('Kwota_inwestycji')),
            "sharesCount": safe_to_int(share.get('Ilosc_Udzialow')),
            "remainingCapital": safe_to_double(share.get('Kapital Pozostaly')),
            "capitalForRestructuring": safe_to_double(share.get('Kapitał do restrukturyzacji')),
            "capitalSecuredByRealEstate": safe_to_double(share.get('Kapitał zabezpieczony nieruchomością')),
            
            # Metadata fields
            "sourceFile": "tableConvert.com_n0b2g7.json",
            "createdAt": current_time,
            "uploadedAt": current_time,
            
            # Client info (English names)
            "clientId": share.get('ID_Klient'),
            "clientName": share.get('Klient'),
            
            # Additional transaction info
            "companyId": share.get('ID_Spolka'),
            "salesId": share.get('ID_Sprzedaz'),
            "paymentAmount": safe_to_double(share.get('Kwota_wplat')),
            "branch": share.get('Oddzial'),
            "advisor": share.get('Opiekun z MISA'),
            "productName": share.get('Produkt_nazwa'),
            "productStatusEntry": share.get('Produkt_status_wejscie'),
            "productStatus": share.get('Status_produktu'),
            
            # Date fields
            "signedDate": parse_date(share.get('Data_podpisania')),
            "investmentEntryDate": parse_date(share.get('Data_wejscia_do_inwestycji')),
            "issueDate": parse_date(share.get('data_emisji')),
            "maturityDate": parse_date(share.get('data_wykupu')),
            
            # Additional info for any unmapped fields
            "additionalInfo": {
                "wierzyciel_spolka": share.get('wierzyciel_spolka'),
                "realizedCapital": safe_to_double(share.get('Kapital zrealizowany')),
                "transferToOtherProduct": safe_to_double(share.get('Przekaz na inny produkt'))
            }
        }
        
        transformed_shares.append(transformed_share)

    # Save transformed data
    output_file = 'shares_extracted.json'
    try:
        with open(output_file, 'w', encoding='utf-8') as file:
            json.dump(transformed_shares, file, indent=2, ensure_ascii=False)
        
        print(f"✅ Successfully extracted {len(transformed_shares)} shares to {output_file}")
        
        # Show sample data
        if transformed_shares:
            print("\n📋 Sample share data:")
            sample = transformed_shares[0]
            print(f"  ID: {sample['id']}")
            print(f"  Client: {sample['clientName']}")
            print(f"  Product: {sample['productName']}")
            print(f"  Investment: {sample['investmentAmount']}")
            print(f"  Shares Count: {sample['sharesCount']}")
            print(f"  Remaining: {sample['remainingCapital']}")
            print(f"  Signed Date: {sample['signedDate']}")
            
    except Exception as e:
        print(f"❌ Error saving file: {e}")

if __name__ == "__main__":
    main()
