import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/smtp_settings.dart';
import '../../services/smtp_service.dart';
import '../../theme/app_theme_professional.dart';
import '../../widgets/custom_text_form_field.dart';
import '../../providers/auth_provider.dart';

// Ujednolicony tooltip RBAC (powielony lokalnie – rozważ przeniesienie do wspólnego pliku constants)
const String kRbacNoPermissionTooltip = 'Brak uprawnień – rola user';

class SmtpSettingsScreen extends StatefulWidget {
  const SmtpSettingsScreen({super.key});

  @override
  State<SmtpSettingsScreen> createState() => _SmtpSettingsScreenState();
}

class _SmtpSettingsScreenState extends State<SmtpSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late SmtpService _smtpService;
  SmtpSettings? _currentSettings;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isSaving = false;
  bool _obscurePassword = true;

  final _hostController = TextEditingController();
  final _portController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  SmtpSecurity _selectedSecurity = SmtpSecurity.tls;

  @override
  void initState() {
    super.initState();
    _smtpService = SmtpService();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      _currentSettings = await _smtpService.getSmtpSettings();
      if (_currentSettings != null) {
        _hostController.text = _currentSettings!.host;
        _portController.text = _currentSettings!.port.toString();
        _usernameController.text = _currentSettings!.username;
        _passwordController.text = _currentSettings!.password;
        _selectedSecurity = _currentSettings!.security;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Błąd podczas ładowania ustawień: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveSettings() async {
    // Ochrona backendowa w UI – szybki exit jeśli brak uprawnień
    final isAdmin = Provider.of<AuthProvider>(context, listen: false).isAdmin;
    if (!isAdmin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Brak uprawnień do zapisu (tylko podgląd).'),
        ),
      );
      return;
    }
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isSaving = true;
        _errorMessage = null;
      });

      final newSettings = SmtpSettings(
        host: _hostController.text.trim(),
        port: int.parse(_portController.text.trim()),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        security: _selectedSecurity,
      );

      try {
        await _smtpService.saveSmtpSettings(newSettings);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ustawienia SMTP zostały zapisane.'),
            backgroundColor: AppThemePro.accentGold,
          ),
        );
      } catch (e) {
        setState(() {
          _errorMessage = 'Błąd podczas zapisywania ustawień: $e';
        });
      } finally {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = Provider.of<AuthProvider>(context).isAdmin;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ustawienia Serwera SMTP'),
        backgroundColor: AppThemePro.backgroundPrimary,
        elevation: 0,
      ),
      backgroundColor: AppThemePro.backgroundPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: AbsorbPointer(
                    absorbing: !canEdit,
                    child: Opacity(
                      opacity: canEdit ? 1.0 : 0.85,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Konfiguracja serwera wychodzącego (SMTP)',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Wprowadź dane swojego serwera SMTP, aby umożliwić wysyłanie wiadomości e-mail z aplikacji.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 32),
                          CustomTextFormField(
                            controller: _hostController,
                            labelText: 'Host SMTP',
                            hintText: 'np. smtp.example.com',
                            validator: (value) =>
                                value!.isEmpty ? 'Pole jest wymagane' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: _portController,
                            labelText: 'Port',
                            hintText: 'np. 587',
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            validator: (value) {
                              if (value!.isEmpty) return 'Pole jest wymagane';
                              if (int.tryParse(value) == null)
                                return 'Nieprawidłowy numer portu';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<SmtpSecurity>(
                            value: _selectedSecurity,
                            onChanged: (SmtpSecurity? newValue) {
                              setState(() {
                                _selectedSecurity = newValue!;
                              });
                            },
                            items: SmtpSecurity.values.map((
                              SmtpSecurity security,
                            ) {
                              return DropdownMenuItem<SmtpSecurity>(
                                value: security,
                                child: Text(security.name.toUpperCase()),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              labelText: 'Zabezpieczenia',
                              border: OutlineInputBorder(),
                            ),
                            dropdownColor: AppThemePro.backgroundSecondary,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: _usernameController,
                            labelText: 'Nazwa użytkownika',
                            hintText: 'np. user@example.com',
                            validator: (value) =>
                                value!.isEmpty ? 'Pole jest wymagane' : null,
                          ),
                          const SizedBox(height: 16),
                          CustomTextFormField(
                            controller: _passwordController,
                            labelText: 'Hasło',
                            obscureText: _obscurePassword,
                            validator: (value) =>
                                value!.isEmpty ? 'Pole jest wymagane' : null,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              ElevatedButton.icon(
                                onPressed: (!canEdit || _isSaving)
                                    ? null
                                    : _saveSettings,
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.save),
                                label: Text(
                                  _isSaving
                                      ? 'Zapisywanie...'
                                      : canEdit
                                      ? 'Zapisz zmiany'
                                      : 'Tylko podgląd',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppThemePro.accentGold,
                                  foregroundColor: Colors.black,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 24,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (!canEdit)
                            Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                kRbacNoPermissionTooltip,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
