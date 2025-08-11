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
        # Handle comma-separated numbers like "50,663.18"
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
            # ISO format like "2019-06-22 00:00:00"
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
    print("🔍 Extracting loans from JSON data...")
    
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

    # Filter for loans only
    loans = [item for item in data if item.get('Typ_produktu') == 'Pożyczka']
    
    print(f"📊 Found {len(loans)} loan products out of {len(data)} total products")
    
    if not loans:
        print("⚠️ No loans found in the data")
        return

    # Transform data to match Loan model with English field names
    transformed_loans = []
    current_time = datetime.now().isoformat() + 'Z'
    
    for i, loan in enumerate(loans):
        transformed_loan = {
            # Generate unique ID
            "id": f"loan_{i+1:04d}",
            
            # Core fields (English names)
            "productType": loan.get('Typ_produktu', 'Pożyczka'),
            "investmentAmount": safe_to_double(loan.get('Kwota_inwestycji')),
            "remainingCapital": safe_to_double(loan.get('Kapital Pozostaly')),
            "capitalForRestructuring": safe_to_double(loan.get('Kapitał do restrukturyzacji')),
            "capitalSecuredByRealEstate": safe_to_double(loan.get('Kapitał zabezpieczony nieruchomością')),
            
            # Metadata fields
            "sourceFile": "tableConvert.com_n0b2g7.json",
            "createdAt": current_time,
            "uploadedAt": current_time,
            
            # Client info (English names)
            "clientId": loan.get('ID_Klient'),
            "clientName": loan.get('Klient'),
            
            # Additional transaction info
            "companyId": loan.get('ID_Spolka'),
            "salesId": loan.get('ID_Sprzedaz'),
            "paymentAmount": safe_to_double(loan.get('Kwota_wplat')),
            "branch": loan.get('Oddzial'),
            "advisor": loan.get('Opiekun z MISA'),
            "productName": loan.get('Produkt_nazwa'),
            "productStatusEntry": loan.get('Produkt_status_wejscie'),
            "productStatus": loan.get('Status_produktu'),
            
            # Date fields
            "signedDate": parse_date(loan.get('Data_podpisania')),
            "investmentEntryDate": parse_date(loan.get('Data_wejscia_do_inwestycji')),
            "issueDate": parse_date(loan.get('data_emisji')),
            "maturityDate": parse_date(loan.get('data_wykupu')),
            
            # Loan specific fields
            "loanNumber": None,  # Not in current data structure
            "borrower": loan.get('Klient'),  # Use client name as borrower for now
            "creditorCompany": loan.get('wierzyciel_spolka'),
            "interestRate": loan.get('oprocentowanie'),
            "disbursementDate": parse_date(loan.get('Data_wejscia_do_inwestycji')),  # Use investment entry date
            "repaymentDate": parse_date(loan.get('data_wykupu')),
            "accruedInterest": 0.0,  # Not in current data structure
            "collateral": None,  # Not in current data structure
            "status": loan.get('Status_produktu'),
            
            # Additional info for any unmapped fields
            "additionalInfo": {
                "realizedCapital": safe_to_double(loan.get('Kapital zrealizowany')),
                "transferToOtherProduct": safe_to_double(loan.get('Przekaz na inny produkt')),
                "sharesCount": loan.get('Ilosc_Udzialow')  # Keep original even if NULL for loans
            }
        }
        
        transformed_loans.append(transformed_loan)

    # Save transformed data
    output_file = 'loans_extracted.json'
    try:
        with open(output_file, 'w', encoding='utf-8') as file:
            json.dump(transformed_loans, file, indent=2, ensure_ascii=False)
        
        print(f"✅ Successfully extracted {len(transformed_loans)} loans to {output_file}")
        
        # Show sample data
        if transformed_loans:
            print("\n📋 Sample loan data:")
            sample = transformed_loans[0]
            print(f"  ID: {sample['id']}")
            print(f"  Client: {sample['clientName']}")
            print(f"  Product: {sample['productName']}")
            print(f"  Investment: {sample['investmentAmount']}")
            print(f"  Remaining: {sample['remainingCapital']}")
            print(f"  Signed Date: {sample['signedDate']}")
            print(f"  Creditor: {sample['creditorCompany']}")
            
    except Exception as e:
        print(f"❌ Error saving file: {e}")

if __name__ == "__main__":
    main()
