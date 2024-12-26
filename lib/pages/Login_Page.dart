import 'package:flutter/material.dart';
import 'project_details_page.dart';
import 'models.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  final Function(ThemeMode) toggleTheme;

  LoginPage({required this.toggleTheme});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _selectedLanguage = 'Türkçe';
  bool _isLoginMode = true;
  ThemeMode _currentThemeMode = ThemeMode.system;

  final List<String> _languages = ['Türkçe', 'English'];
  final List<ThemeMode> _themeModes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  Map<String, Map<String, String>> _localizedTexts = {
    'Türkçe': {
      'appName': 'Projify',
      'welcomeText': 'Hoş Geldiniz!',
      'createAccount': 'Hesap Oluştur',
      'login': 'Giriş Yap',
      'register': 'Kayıt Ol',
      'email': 'E-posta',
      'password': 'Şifre',
      'confirmPassword': 'Şifreyi Onayla',
      'noAccount': 'Hesabınız yok mu? Kayıt Olun',
      'haveAccount': 'Zaten bir hesabınız var mı? Giriş Yapın',
      'selectLanguage': 'Dil Seçin',
      'selectTheme': 'Tema Seçin',
      'lightTheme': 'Açık Tema',
      'darkTheme': 'Koyu Tema',
      'systemTheme': 'Sistem Teması',
      'emptyFields': 'Lütfen tüm alanları doldurun',
      'fillAllFields': 'Lütfen tüm alanları doldurun',
      'passwordMismatch': 'Şifreler eşleşmiyor',
    },
    'English': {
      'appName': 'Projify',
      'welcomeText': 'Welcome!',
      'createAccount': 'Create Account',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'confirmPassword': 'Confirm Password',
      'noAccount': 'Don\'t have an account? Register',
      'haveAccount': 'Already have an account? Login',
      'selectLanguage': 'Select Language',
      'selectTheme': 'Select Theme',
      'lightTheme': 'Light Theme',
      'darkTheme': 'Dark Theme',
      'systemTheme': 'System Theme',
      'emptyFields': 'Please fill all fields',
      'fillAllFields': 'Please fill all fields',
      'passwordMismatch': 'Passwords do not match',
    },
  };

  String _getLocalizedText(String key) {
    return _localizedTexts[_selectedLanguage]?[key] ?? key;
  }

  void _selectLanguage(String? language) {
    if (language != null) {
      setState(() {
        _selectedLanguage = language;
      });
    }
  }

  void _selectTheme(ThemeMode? themeMode) {
    if (themeMode != null) {
      setState(() {
        _currentThemeMode = themeMode;
        widget.toggleTheme(themeMode);
      });
    }
  }

  String _getThemeModeName(ThemeMode themeMode) {
    switch (themeMode) {
      case ThemeMode.system:
        return _getLocalizedText('systemTheme');
      case ThemeMode.light:
        return _getLocalizedText('lightTheme');
      case ThemeMode.dark:
        return _getLocalizedText('darkTheme');
    }
  }

  void _toggleAuthMode() {
    setState(() {
      _isLoginMode = !_isLoginMode;
    });
  }

  void _handleAuth() {
    if (_isLoginMode) {
      _performLogin();
    } else {
      _performRegistration();
    }
  }

  Future<void> _performLogin() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLocalizedText('emptyFields'))),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'kEmail': email,
          'kSifre': password,
        }),
      );

      if (response.statusCode == 200) {
        final userData = json.decode(response.body);
        Kullanici currentUser = Kullanici(
          kID: userData['kID'],
          kEmail: email,
          kSifre: password,
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailsPage(
              projects: [],
              currentUser: currentUser,
              initialLanguage: _selectedLanguage,
              initialThemeMode: _currentThemeMode,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Giriş başarısız. Lütfen bilgilerinizi kontrol edin.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı hatası oluştu.')),
      );
    }
  }

  Future<void> _performRegistration() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String confirmPassword = _confirmPasswordController.text;

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLocalizedText('fillAllFields'))),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_getLocalizedText('passwordMismatch'))),
      );
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('http://localhost:3000/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'kEmail': email,
          'kSifre': password,
        }),
      );

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Kayıt başarılı! Kullanıcı ID: ${responseData['userId']}')),
        );
      } else {
        final responseData = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(responseData['error'] ?? 'Kayıt başarısız.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bağlantı hatası oluştu.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).primaryColor.withOpacity(0.1),
              Theme.of(context).colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(32),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.dashboard,
                            color: Theme.of(context).primaryColor,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          _getLocalizedText('appName'),
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildHeaderButton(
                          icon: Icons.dark_mode,
                          text: _getThemeModeName(_currentThemeMode),
                          onPressed: () => _showThemeMenu(context),
                        ),
                        SizedBox(width: 16),
                        _buildHeaderButton(
                          icon: Icons.language,
                          text: _selectedLanguage,
                          onPressed: () => _showLanguageMenu(context),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 48),

                Container(
                  constraints: BoxConstraints(maxWidth: 400),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Text(
                        _isLoginMode ? _getLocalizedText('welcomeText') : _getLocalizedText('createAccount'),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 32),
                      _buildTextField(
                        controller: _emailController,
                        label: _getLocalizedText('email'),
                        icon: Icons.email,
                      ),
                      SizedBox(height: 24),
                      _buildTextField(
                        controller: _passwordController,
                        label: _getLocalizedText('password'),
                        icon: Icons.lock,
                        isPassword: true,
                      ),
                      if (!_isLoginMode) ...[
                        SizedBox(height: 24),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: _getLocalizedText('confirmPassword'),
                          icon: Icons.lock,
                          isPassword: true,
                        ),
                      ],
                      SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _handleAuth,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          minimumSize: Size(double.infinity, 48),
                        ),
                        child: Text(
                          _isLoginMode ? _getLocalizedText('login') : _getLocalizedText('register'),
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.surface,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(
                          _isLoginMode ? _getLocalizedText('noAccount') : _getLocalizedText('haveAccount'),
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderButton({
    required IconData icon,
    required String text,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      elevation: 1,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 20, color: Theme.of(context).colorScheme.secondary),
              SizedBox(width: 8),
              Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword,
      style: Theme.of(context).textTheme.bodyMedium,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: Theme.of(context).textTheme.bodyMedium,
        prefixIcon: Icon(icon, color: Theme.of(context).colorScheme.secondary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).primaryColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
      ),
    );
  }

  void _showThemeMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _themeModes.map((mode) => ListTile(
            title: Text(
              _getThemeModeName(mode),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () {
              _selectTheme(mode);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  void _showLanguageMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        color: Theme.of(context).colorScheme.surface,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((language) => ListTile(
            title: Text(
              language,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            onTap: () {
              _selectLanguage(language);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }
}