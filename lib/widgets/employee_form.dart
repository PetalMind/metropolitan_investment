import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/employee.dart';
import '../services/employee_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_button.dart';

class EmployeeForm extends StatefulWidget {
  final Employee? employee;

  const EmployeeForm({super.key, this.employee});

  @override
  State<EmployeeForm> createState() => _EmployeeFormState();
}

class _EmployeeFormState extends State<EmployeeForm> {
  final _formKey = GlobalKey<FormState>();
  final _employeeService = EmployeeService();

  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _branchCodeController;
  late final TextEditingController _branchNameController;
  late final TextEditingController _positionController;

  bool _isLoading = false;
  bool _isActive = true;

  final List<String> _positions = [
    'Dyrektor Generalny',
    'Dyrektor Zarządzający',
    'Dyrektor Finansowy',
    'Dyrektor ds. Inwestycji',
    'Starszy Doradca Inwestycyjny',
    'Doradca Inwestycyjny',
    'Młodszy Doradca Inwestycyjny',
    'Analityk Finansowy',
    'Starszy Analityk',
    'Specjalista ds. Klientów',
    'Kierownik Filii',
    'Asystent',
    'Sekretarka',
    'Specjalista IT',
    'Księgowy',
    'HR Specialist',
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController(
      text: widget.employee?.firstName ?? '',
    );
    _lastNameController = TextEditingController(
      text: widget.employee?.lastName ?? '',
    );
    _emailController = TextEditingController(
      text: widget.employee?.email ?? '',
    );
    _phoneController = TextEditingController(
      text: widget.employee?.phone ?? '',
    );
    _branchCodeController = TextEditingController(
      text: widget.employee?.branchCode ?? '',
    );
    _branchNameController = TextEditingController(
      text: widget.employee?.branchName ?? '',
    );
    _positionController = TextEditingController(
      text: widget.employee?.position ?? '',
    );
    _isActive = widget.employee?.isActive ?? true;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _branchCodeController.dispose();
    _branchNameController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  String? _validateName(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName jest wymagane';
    }
    if (value.trim().length < 2) {
      return '$fieldName musi mieć co najmniej 2 znaki';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email jest wymagany';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Nieprawidłowy format email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Telefon jest wymagany';
    }
    final phoneRegex = RegExp(r'^\+?[0-9\s\-\(\)]{9,15}$');
    if (!phoneRegex.hasMatch(value)) {
      return 'Nieprawidłowy format telefonu';
    }
    return null;
  }

  String? _validateBranchCode(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Kod filii jest wymagany';
    }
    if (value.trim().length < 2 || value.trim().length > 10) {
      return 'Kod filii musi mieć 2-10 znaków';
    }
    return null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('EmployeeForm: Validation failed');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('EmployeeForm: Submitting form...');
      debugPrint('  First Name: ${_firstNameController.text.trim()}');
      debugPrint('  Last Name: ${_lastNameController.text.trim()}');
      debugPrint('  Email: ${_emailController.text.trim()}');
      debugPrint('  Phone: ${_phoneController.text.trim()}');
      debugPrint('  Branch Code: ${_branchCodeController.text.trim()}');
      debugPrint('  Branch Name: ${_branchNameController.text.trim()}');
      debugPrint('  Position: ${_positionController.text.trim()}');
      debugPrint('  Is Active: $_isActive');

      final employee = Employee(
        id: widget.employee?.id ?? '',
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        branchCode: _branchCodeController.text.trim().toUpperCase(),
        branchName: _branchNameController.text.trim(),
        position: _positionController.text.trim(),
        isActive: _isActive,
        createdAt: widget.employee?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint(
        'EmployeeForm: Created employee object: ${employee.toFirestore()}',
      );

      if (widget.employee == null) {
        debugPrint('EmployeeForm: Creating new employee...');
        await _employeeService.createEmployee(employee);
        debugPrint('EmployeeForm: Employee created successfully');
      } else {
        debugPrint('EmployeeForm: Updating existing employee...');
        await _employeeService.updateEmployee(widget.employee!.id, employee);
        debugPrint('EmployeeForm: Employee updated successfully');
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.employee == null
                  ? 'Pracownik został dodany pomyślnie'
                  : 'Pracownik został zaktualizowany pomyślnie',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('EmployeeForm: Error occurred: $e');

      // Parse Firebase Console link if present
      String errorMessage = e.toString();
      final firebaseConsoleRegex = RegExp(
        r'https://console\.firebase\.google\.com[^\s]+',
      );
      final match = firebaseConsoleRegex.firstMatch(errorMessage);

      if (match != null) {
        debugPrint(
          'EmployeeForm: Firebase Console Link found: ${match.group(0)}',
        );
        debugPrint(
          'EmployeeForm: This is likely an index error. Please create the required index.',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Błąd podczas zapisywania pracownika: $e'),
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
                  Icon(Icons.person, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.employee == null
                          ? 'Dodaj pracownika'
                          : 'Edytuj pracownika',
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
                            child: TextFormField(
                              controller: _firstNameController,
                              decoration: const InputDecoration(
                                labelText: 'Imię *',
                                prefixIcon: Icon(Icons.person),
                              ),
                              validator: (value) =>
                                  _validateName(value, 'Imię'),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _lastNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nazwisko *',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                              validator: (value) =>
                                  _validateName(value, 'Nazwisko'),
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
                              controller: _emailController,
                              decoration: const InputDecoration(
                                labelText: 'Email *',
                                prefixIcon: Icon(Icons.email),
                                hintText: 'jan.kowalski@cosmopolitan.pl',
                              ),
                              validator: _validateEmail,
                              keyboardType: TextInputType.emailAddress,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: _phoneController,
                              decoration: const InputDecoration(
                                labelText: 'Telefon *',
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
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _branchCodeController,
                              decoration: const InputDecoration(
                                labelText: 'Kod filii *',
                                prefixIcon: Icon(Icons.location_city),
                                hintText: 'WAR, KRK, GDA',
                              ),
                              validator: _validateBranchCode,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(
                                  RegExp(r'[A-Za-z0-9]'),
                                ),
                                LengthLimitingTextInputFormatter(10),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _branchNameController,
                              decoration: const InputDecoration(
                                labelText: 'Nazwa filii *',
                                prefixIcon: Icon(Icons.business),
                                hintText: 'Warszawa Centrum',
                              ),
                              validator: (value) =>
                                  _validateName(value, 'Nazwa filii'),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _positions.contains(_positionController.text)
                            ? _positionController.text
                            : null,
                        decoration: const InputDecoration(
                          labelText: 'Stanowisko *',
                          prefixIcon: Icon(Icons.work),
                        ),
                        items: _positions.map((position) {
                          return DropdownMenuItem<String>(
                            value: position,
                            child: Text(position),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            _positionController.text = value;
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Stanowisko jest wymagane';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Aktywny'),
                        subtitle: Text(
                          _isActive
                              ? 'Pracownik jest aktywny'
                              : 'Pracownik jest nieaktywny',
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
                              widget.employee == null
                                  ? 'Dodaj pracownika'
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
