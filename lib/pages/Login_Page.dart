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
  bool _isLoginMode = true;
  ThemeMode _currentThemeMode = ThemeMode.system;

  final List<ThemeMode> _themeModes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

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
        return 'Sistem Teması';
      case ThemeMode.light:
        return 'Açık Tema';
      case ThemeMode.dark:
        return 'Koyu Tema';
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
        SnackBar(content: Text('Lütfen tüm alanları doldurun')),
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
        SnackBar(content: Text('Lütfen tüm alanları doldurun')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Şifreler eşleşmiyor')),
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
                            color: Theme.of(context).colorScheme.secondaryContainer,
                            size: 24,
                          ),
                        ),
                        SizedBox(width: 16),
                        Text(
                          'Projify',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    _buildHeaderButton(
                      icon: Icons.dark_mode,
                      text: _getThemeModeName(_currentThemeMode),
                      onPressed: () => _showThemeMenu(context),
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
                        _isLoginMode ? 'Hoş Geldiniz!' : 'Hesap Oluştur',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 32),
                      _buildTextField(
                        controller: _emailController,
                        label: 'E-posta',
                        icon: Icons.email,
                      ),
                      SizedBox(height: 24),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Şifre',
                        icon: Icons.lock,
                        isPassword: true,
                      ),
                      if (!_isLoginMode) ...[
                        SizedBox(height: 24),
                        _buildTextField(
                          controller: _confirmPasswordController,
                          label: 'Şifreyi Onayla',
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
                          _isLoginMode ? 'Giriş Yap' : 'Kayıt Ol',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).textTheme.headlineLarge?.color,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      TextButton(
                        onPressed: _toggleAuthMode,
                        child: Text(
                          _isLoginMode ? 'Hesabınız yok mu? Kayıt Olun' : 'Zaten bir hesabınız var mı? Giriş Yapın',
                          style: TextStyle(
                            color: Colors.blue,
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
}