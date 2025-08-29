import 'package:flutter/material.dart';
import '../models/product.dart';

class ProductForm extends StatefulWidget {
  final Product? product;
  final void Function(Product product) onSave;
  final VoidCallback? onCancel;

  const ProductForm({
    super.key,
    this.product,
    required this.onSave,
    this.onCancel,
  });

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  ProductType? _type;
  late String _companyName;
  late String _companyId;
  double? _interestRate;
  DateTime? _issueDate;
  DateTime? _maturityDate;
  int? _sharesCount;
  double? _sharePrice;
  String _currency = 'PLN';
  double? _exchangeRate;
  bool _isPrivateIssue = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _name = p?.name ?? '';
    _type = p?.type;
    _companyName = p?.companyName ?? '';
    _companyId = p?.companyId ?? '';
    _interestRate = p?.interestRate;
    _issueDate = p?.issueDate;
    _maturityDate = p?.maturityDate;
    _sharesCount = p?.sharesCount;
    _sharePrice = p?.sharePrice;
    _currency = p?.currency ?? 'PLN';
    _exchangeRate = p?.exchangeRate;
    _isPrivateIssue = p?.isPrivateIssue ?? false;
    _isActive = p?.isActive ?? true;
  }

  Future<void> _selectDate(BuildContext context, bool isIssueDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate
          ? (_issueDate ?? DateTime.now())
          : (_maturityDate ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
        } else {
          _maturityDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              initialValue: _name,
              decoration: const InputDecoration(labelText: 'Nazwa produktu'),
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
              onSaved: (v) => _name = v!,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ProductType>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Typ produktu'),
              items: ProductType.values
                  .map(
                    (type) => DropdownMenuItem(
                      value: type,
                      child: Text(type.displayName),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _type = v),
              validator: (v) => v == null ? 'Wybierz typ' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _companyName,
              decoration: const InputDecoration(labelText: 'Nazwa firmy'),
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
              onSaved: (v) => _companyName = v!,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _companyId,
              decoration: const InputDecoration(labelText: 'ID firmy'),
              validator: (v) => v == null || v.isEmpty ? 'Wymagane' : null,
              onSaved: (v) => _companyId = v!,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, true),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data emisji',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _issueDate != null
                            ? '${_issueDate!.day}/${_issueDate!.month}/${_issueDate!.year}'
                            : 'Wybierz datę',
                        style: TextStyle(
                          color: _issueDate != null
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: InkWell(
                    onTap: () => _selectDate(context, false),
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Data wykupu',
                        suffixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _maturityDate != null
                            ? '${_maturityDate!.day}/${_maturityDate!.month}/${_maturityDate!.year}'
                            : 'Wybierz datę',
                        style: TextStyle(
                          color: _maturityDate != null
                              ? Theme.of(context).textTheme.bodyMedium?.color
                              : Theme.of(context).hintColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _interestRate?.toString(),
              decoration: const InputDecoration(
                labelText: 'Oprocentowanie (%)',
              ),
              keyboardType: TextInputType.number,
              onSaved: (v) => _interestRate = double.tryParse(v ?? ''),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _sharesCount?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Liczba udziałów',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _sharesCount = int.tryParse(v ?? ''),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    initialValue: _sharePrice?.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Cena udziału',
                    ),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _sharePrice = double.tryParse(v ?? ''),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _currency,
              decoration: const InputDecoration(labelText: 'Waluta'),
              onSaved: (v) => _currency = v ?? 'PLN',
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _exchangeRate?.toString(),
              decoration: const InputDecoration(labelText: 'Kurs wymiany'),
              keyboardType: TextInputType.number,
              onSaved: (v) => _exchangeRate = double.tryParse(v ?? ''),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _isPrivateIssue,
              onChanged: (v) => setState(() => _isPrivateIssue = v),
              title: const Text('Emisja prywatna'),
            ),
            SwitchListTile(
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              title: const Text('Aktywny'),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (widget.onCancel != null)
                  TextButton(
                    onPressed: widget.onCancel,
                    child: const Text('Anuluj'),
                  ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState?.validate() ?? false) {
                      _formKey.currentState?.save();
                      // LOGUJEMY WSZYSTKO DO KONSOLI
                        '[ProductForm] _isPrivateIssue: $_isPrivateIssue',
                      );
                      try {
                        widget.onSave(
                          Product(
                            id: widget.product?.id ?? '',
                            name: _name,
                            type: _type!,
                            companyId: _companyId,
                            companyName: _companyName,
                            interestRate: _interestRate,
                            issueDate: _issueDate,
                            maturityDate: _maturityDate,
                            sharesCount: _sharesCount,
                            sharePrice: _sharePrice,
                            currency: _currency,
                            exchangeRate: _exchangeRate,
                            isPrivateIssue: _isPrivateIssue,
                            metadata: {},
                            createdAt:
                                widget.product?.createdAt ?? DateTime.now(),
                            updatedAt: DateTime.now(),
                            isActive: _isActive,
                          ),
                        );
                      } catch (e, stack) {
                          '[ProductForm] BŁĄD PRZY ZAPISIE PRODUKTU: $e',
                        );

                        // Specjalne logowanie dla błędu Firestore o indeksie
                        if (e.toString().contains(
                          'cloud_firestore/failed-precondition',
                        )) {
                            '[ProductForm] ⚠️ FIRESTORE INDEX ERROR DETECTED! ⚠️',
                          );
                            '[ProductForm] Musisz utworzyć indeks w Firestore Console.',
                          );
                            '[ProductForm] Pełny błąd: ${e.toString()}',
                          );

                          // Próba wyodrębnienia linku do utworzenia indeksu
                          final regex = RegExp(
                            r'https://console\.firebase\.google\.com/[^\s\)]+',
                          );
                          final match = regex.firstMatch(e.toString());
                          if (match != null) {
                              '[ProductForm] 🔗 LINK DO UTWORZENIA INDEKSU: ${match.group(0)}',
                            );
                          } else {
                              '[ProductForm] Nie znaleziono linku w błędzie. Sprawdź konsolę Firebase ręcznie.',
                            );
                          }
                        }

                        // Inne typy błędów Firestore
                        if (e.toString().contains('firebase')) {
                            '[ProductForm] Firebase error type: ${e.runtimeType}',
                          );
                        }
                      }
                    }
                  },
                  child: Text(widget.product == null ? 'Dodaj' : 'Zapisz'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
