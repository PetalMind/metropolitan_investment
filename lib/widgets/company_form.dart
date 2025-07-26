import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/company.dart';
import '../services/company_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_button.dart';

class CompanyForm extends StatefulWidget {
  final Company? company;

  const CompanyForm({super.key, this.company});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends State<CompanyForm> {
  final _formKey = GlobalKey<FormState>();
  final _companyService = CompanyService();

  late final TextEditingController _nameController;
  late final TextEditingController _fullNameController;
  late final TextEditingController _taxIdController;
  late final TextEditingController _addressController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late final TextEditingController _websiteController;
  late final TextEditingController _descriptionController;

  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.company?.name ?? '');
    _fullNameController = TextEditingController(
      text: widget.company?.fullName ?? '',
    );
    _taxIdController = TextEditingController(text: widget.company?.taxId ?? '');
    _addressController = TextEditingController(
      text: widget.company?.address ?? '',
    );
    _phoneController = TextEditingController(text: widget.company?.phone ?? '');
    _emailController = TextEditingController(text: widget.company?.email ?? '');
    _websiteController = TextEditingController(
      text: widget.company?.website ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.company?.description ?? '',
    );
    _isActive = widget.company?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _fullNameController.dispose();
    _taxIdController.dispose();
    _addressController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nazwa firmy jest wymagana';
    }
    if (value.trim().length < 2) {
      return 'Nazwa firmy musi mieć co najmniej 2 znaki';
    }
    return null;
  }

  String? _validateTaxId(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'NIP jest wymagany';
    }

    final cleanNip = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanNip.length != 10) {
      return 'NIP musi składać się z 10 cyfr';
    }

    if (!_companyService.isValidNIP(cleanNip)) {
      return 'Nieprawidłowy format NIP';
    }

    return null;
  }

  String? _validateEmail(String? value) {
    if (value != null && value.isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value)) {
        return 'Nieprawidłowy format email';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{9,15}$');
      if (!phoneRegex.hasMatch(value)) {
        return 'Nieprawidłowy format telefonu';
      }
    }
    return null;
  }

  String? _validateWebsite(String? value) {
    if (value != null && value.isNotEmpty) {
      final urlRegex = RegExp(r'^https?://.*$');
      if (!urlRegex.hasMatch(value)) {
        return 'URL musi zaczynać się od http:// lub https://';
      }
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('CompanyForm: Validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('CompanyForm: Submitting form...');
      debugPrint('  Name: ${_nameController.text.trim()}');
      debugPrint('  Full Name: ${_fullNameController.text.trim()}');
      debugPrint('  Tax ID: ${_taxIdController.text.trim()}');
      debugPrint('  Address: ${_addressController.text.trim()}');
      debugPrint('  Phone: ${_phoneController.text.trim()}');
      debugPrint('  Email: ${_emailController.text.trim()}');
      debugPrint('  Website: ${_websiteController.text.trim()}');
      debugPrint('  Description: ${_descriptionController.text.trim()}');
      debugPrint('  Is Active: $_isActive');

      // Check if NIP already exists for other companies
      if (widget.company == null) {
        final existingCompany = await _companyService.getCompanyByTaxId(
          _taxIdController.text.trim(),
        );
        if (existingCompany != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Firma o tym NIP już istnieje'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }
      }

      final company = Company(
        id: widget.company?.id ?? '',
        name: _nameController.text.trim(),
        fullName: _fullNameController.text.trim().isNotEmpty
            ? _fullNameController.text.trim()
            : _nameController.text.trim(),
        taxId: _taxIdController.text.trim(),
        address: _addressController.text.trim(),
        phone: _phoneController.text.trim(),
        email: _emailController.text.trim(),
        website: _websiteController.text.trim(),
        description: _descriptionController.text.trim(),
        isActive: _isActive,
        createdAt: widget.company?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint(
        'CompanyForm: Created company object: ${company.toFirestore()}',
      );

      if (widget.company == null) {
        debugPrint('CompanyForm: Creating new company...');
        await _companyService.createCompany(company);
        debugPrint('CompanyForm: Company created successfully');
      } else {
        debugPrint('CompanyForm: Updating existing company...');
        await _companyService.updateCompany(widget.company!.id, company);
        debugPrint('CompanyForm: Company updated successfully');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.company == null
                  ? 'Firma została dodana pomyślnie'
                  : 'Firma została zaktualizowana pomyślnie',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('CompanyForm: Error occurred: $e');

      // Parse Firebase Console link if present
      String errorMessage = e.toString();
      final firebaseConsoleRegex = RegExp(
        r'https://console\.firebase\.google\.com[^\s]+',
      );
      final match = firebaseConsoleRegex.firstMatch(errorMessage);

      if (match != null) {
        debugPrint(
          'CompanyForm: Firebase Console Link found: ${match.group(0)}',
        );
        debugPrint(
          'CompanyForm: This is likely an index error. Please create the required index.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania firmy: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        constraints: const BoxConstraints(maxWidth: 800),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.business, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.company == null ? 'Dodaj firmę' : 'Edytuj firmę',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nazwa firmy *',
                                prefixIcon: Icon(Icons.business),
                              ),
                              validator: _validateName,
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 3,
                            child: TextFormField(
                              controller: _fullNameController,
                              decoration: const InputDecoration(
                                labelText: 'Pełna nazwa firmy',
                                prefixIcon: Icon(Icons.business_center),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _taxIdController,
                              decoration: const InputDecoration(
                                labelText: 'NIP *',
                                prefixIcon: Icon(Icons.numbers),
                                hintText: '123-456-78-90',
                              ),
                              validator: _validateTaxId,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\-]'),
                                ),
                                LengthLimitingTextInputFormatter(12),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _addressController,
                              decoration: const InputDecoration(
                                labelText: 'Adres',
                                prefixIcon: Icon(Icons.location_on),
                              ),
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon',
                                prefixIcon: Icon(Icons.phone),
                                hintText: '+48 123 456 789',
                              ),
                              validator: _validatePhone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[0-9\+\-\(\)\s]'),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email',
                                prefixIcon: Icon(Icons.email),
                                hintText: 'kontakt@firma.pl',
                              ),
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _websiteController,
                        decoration: const InputDecoration(
                          labelText: 'Strona internetowa',
                          prefixIcon: Icon(Icons.language),
                          hintText: 'https://www.firma.pl',
                        ),
                        validator: _validateWebsite,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Opis',
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Aktywna'),
                        subtitle: Text(
                          _isActive
                              ? 'Firma jest aktywna'
                              : 'Firma jest nieaktywna',
                        ),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                        activeColor: AppTheme.primaryColor,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: _isLoading
                                ? null
                                : () => Navigator.of(context).pop(),
                            child: const Text('Anuluj'),
                          ),
                          const SizedBox(width: 12),
                          AnimatedButton(
                            onPressed: _isLoading ? null : _submitForm,
                            isLoading: _isLoading,
                            child: Text(
                              widget.company == null
                                  ? 'Dodaj firmę'
                                  : 'Zapisz zmiany',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
