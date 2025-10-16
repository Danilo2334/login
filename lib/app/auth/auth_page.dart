import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
    });
  }

  Future<void> _handleAuth() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final client = Supabase.instance.client;

    try {
      if (_isLogin) {
        final response = await client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        if (response.session != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bienvenido de vuelta')),
          );
        }
      } else {
        await client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cuenta creada. Revisa tu correo.')),
        );
        setState(() => _isLogin = true);
      }
    } on AuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isLogin
              ? 'Error al iniciar sesion'
              : 'Error al crear la cuenta'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1F1C2C), Color(0xFF928DAB)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'auth-logo',
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24),
                      ),
                      child: const Icon(
                        Icons.lock_outline,
                        color: Colors.white,
                        size: 42,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    _isLogin ? 'Iniciar sesion' : 'Crear cuenta',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Card(
                    elevation: 16,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 32,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _isLogin
                                  ? 'Bienvenido de nuevo, ingresa tus datos'
                                  : 'Crea una cuenta para comenzar',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyLarge,
                            ),
                            const SizedBox(height: 28),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                labelText: 'Correo electronico',
                                prefixIcon: Icon(Icons.mail_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Ingresa tu correo';
                                }
                                final email = value.trim();
                                final emailRegex =
                                    RegExp(r'^[^@]+@[^@]+\.[^@]+');
                                if (!emailRegex.hasMatch(email)) {
                                  return 'Ingresa un correo valido';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 18),
                            TextFormField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: const InputDecoration(
                                labelText: 'Contrasena',
                                prefixIcon: Icon(Icons.lock_outline),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ingresa tu contrasena';
                                }
                                if (value.length < 6) {
                                  return 'La contrasena debe tener al menos 6 caracteres';
                                }
                                return null;
                              },
                            ),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 250),
                              child: _isLogin
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      key: const ValueKey('confirm-pass'),
                                      padding:
                                          const EdgeInsets.only(top: 18.0),
                                      child: TextFormField(
                                        controller: _confirmPasswordController,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          labelText: 'Confirmar contrasena',
                                          prefixIcon:
                                              Icon(Icons.verified_user_outlined),
                                        ),
                                        validator: (value) {
                                          if (_isLogin) {
                                            return null;
                                          }
                                          if (value == null || value.isEmpty) {
                                            return 'Confirma tu contrasena';
                                          }
                                          if (value !=
                                              _passwordController.text) {
                                            return 'Las contrasenas no coinciden';
                                          }
                                          return null;
                                        },
                                      ),
                                    ),
                            ),
                            const SizedBox(height: 32),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleAuth,
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.6,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            Colors.white,
                                          ),
                                        ),
                                      )
                                    : Text(
                                        _isLogin ? 'Entrar' : 'Crear cuenta',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            TextButton(
                              onPressed: _isLoading ? null : _toggleMode,
                              child: Text(
                                _isLogin
                                    ? 'No tienes cuenta? Registrate'
                                    : 'Ya tienes cuenta? Inicia sesion',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
