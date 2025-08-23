#!/usr/bin/env python3
"""
Skrypt do usuwania nieużywanych metod z pliku premium_investor_analytics_screen.dart
"""

import re

# Nieużywane metody do usunięcia (nazwa i linia początkowa)
UNUSED_METHODS = [
    '_buildSortChip',
    '_exportSelectedInvestors', 
    '_sendEmailToSelectedInvestors',
    '_buildInvestorsContent',
    '_buildMajorityControlSliver',
    '_buildMajorityHoldersContent',
    '_exportEmails',
    '_performMajorityControlAnalysis',
    '_performVotingDistributionAnalysis',
    '_showRefreshCacheDialog',
    '_buildPerformanceGrid',
    '_buildPerformanceChart',
    '_buildTrendMetrics',
    '_buildTrendChart',
    '_enterSelectionMode',
    '_mapUnifiedToProductType'
]

def find_method_bounds(lines, method_name, start_line):
    """Znajdź granice metody - początek i koniec"""
    # Znajdź dokładną linię z definicją metody
    method_start = None
    for i in range(start_line - 1, len(lines)):
        if method_name in lines[i] and ('(' in lines[i] or '=>' in lines[i]):
            method_start = i
            break
    
    if method_start is None:
        return None, None
    
    # Znajdź koniec metody poprzez liczenie nawiasów
    brace_count = 0
    in_method = False
    method_end = None
    
    for i in range(method_start, len(lines)):
        line = lines[i].strip()
        
        # Rozpoczynamy liczenie nawiasów gdy znajdziemy pierwszy {
        if '{' in line:
            in_method = True
            brace_count += line.count('{')
            brace_count -= line.count('}')
        elif in_method:
            brace_count += line.count('{')
            brace_count -= line.count('}')
        
        # Jeśli wrócimy do zera nawiasów, to jest koniec metody
        if in_method and brace_count == 0:
            method_end = i
            break
        
        # Obsługa metod jednoliniowych z =>
        if '=>' in lines[method_start] and ';' in line:
            method_end = i
            break
    
    return method_start, method_end

def remove_unused_methods():
    """Usuń nieużywane metody z pliku"""
    file_path = 'lib/screens/premium_investor_analytics_screen.dart'
    
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Zbierz zakresy do usunięcia (odwrotnie, żeby usuwać od końca)
    ranges_to_remove = []
    
    for method_name in UNUSED_METHODS:
        print(f"Szukam metody: {method_name}")
        
        # Znajdź linię z definicją metody
        for i, line in enumerate(lines):
            if method_name in line and ('(' in line or '=>' in line):
                # Sprawdź czy to rzeczywiście definicja metody
                if re.search(rf'\b{re.escape(method_name)}\s*\(', line) or re.search(rf'\b{re.escape(method_name)}\s*\(.*\)\s*=>', line):
                    start, end = find_method_bounds(lines, method_name, i + 1)
                    if start is not None and end is not None:
                        ranges_to_remove.append((start, end + 1, method_name))
                        print(f"  Znaleziono na liniach {start + 1}-{end + 1}")
                        break
                    else:
                        print(f"  Nie można znaleźć granic metody")
                break
        else:
            print(f"  Nie znaleziono metody {method_name}")
    
    # Usuń od końca pliku, żeby nie popsuć numeracji linii
    ranges_to_remove.sort(reverse=True)
    
    for start, end, method_name in ranges_to_remove:
        print(f"Usuwam {method_name}: linie {start + 1}-{end}")
        del lines[start:end]
    
    # Zapisz poprawiony plik
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    
    print(f"Usunięto {len(ranges_to_remove)} nieużywanych metod")

if __name__ == '__main__':
    remove_unused_methods()