import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../routes.dart';

// Logo Widget (giữ nguyên)
class _StylizedSLogo extends StatelessWidget {
  final Color backgroundColor;
  final Color textColor;
  final double circleSize;
  final double letterSize;

  const _StylizedSLogo({
    this.backgroundColor = Colors.pinkAccent,
    this.textColor = Colors.white,
    this.circleSize = 60.0,
    this.letterSize = 36.0,
  });

  @override
  Widget build(BuildContext context) {
    final String? logoFontFamily = Theme.of(context).textTheme.headlineSmall?.fontFamily;
    return Container(
      width: circleSize,
      height: circleSize,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 6.0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(
          'S',
          style: TextStyle(
            fontFamily: logoFontFamily,
            fontSize: letterSize,
            fontWeight: FontWeight.w900,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _forgotPasswordEmailController = TextEditingController();

  bool _isLoginMode = true;
  bool _rememberCredentials = false;
  bool _passwordVisible = false;
  bool _confirmPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
    _passwordVisible = false;
    _confirmPasswordVisible = false;
  }

  Future<void> _loadSavedCredentials() async {
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final savedEmail = await appProvider.getSavedEmail();
    final savedPassword = await appProvider.getSavedPassword();

    if (savedEmail != null && savedEmail.isNotEmpty && savedPassword != null && savedPassword.isNotEmpty) {
      if (mounted) {
        setState(() {
          _emailController.text = savedEmail;
          _passwordController.text = savedPassword;
          _rememberCredentials = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _forgotPasswordEmailController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appProvider = Provider.of<AppProvider>(context, listen: false);
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLoginMode) {
        await appProvider.signIn(email, password);
      } else {
        await appProvider.register(email, password);
      }

      if (!mounted) return;

      if (appProvider.currentUser != null) {
        if (_rememberCredentials) {
          await appProvider.saveEmail(email);
          await appProvider.savePassword(password);
        } else {
          await appProvider.clearSavedEmail();
          await appProvider.clearSavedPassword();
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorToShow = appProvider.errorMessage ?? e.toString().replaceFirst('Exception: ', '');
        // Sử dụng addPostFrameCallback để đảm bảo context hợp lệ khi hiển thị SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Kiểm tra lại mounted bên trong callback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorToShow),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    final appProvider = Provider.of<AppProvider>(context, listen: false);
    try {
      await appProvider.signInWithGoogle();

      if (!mounted) return;

      if (appProvider.currentUser != null) {
        await appProvider.clearSavedEmail();
        await appProvider.clearSavedPassword();
        if (mounted) {
          Navigator.pushReplacementNamed(context, Routes.home);
        }
      }
    } catch (e) {
      if (mounted) {
        final errorToShow = appProvider.errorMessage ?? e.toString().replaceFirst('Exception: ', '');
        // Sử dụng addPostFrameCallback để đảm bảo context hợp lệ khi hiển thị SnackBar
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) { // Kiểm tra lại mounted bên trong callback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorToShow),
                backgroundColor: Colors.redAccent,
                duration: const Duration(seconds: 4),
              ),
            );
          }
        });
      }
    }
  }

  void _showForgotPasswordDialog() {
    _forgotPasswordEmailController.text = _emailController.text;
    final GlobalKey<FormState> dialogFormKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Quên Mật Khẩu'),
          content: Form(
            key: dialogFormKey,
            child: TextFormField(
              controller: _forgotPasswordEmailController,
              decoration: const InputDecoration(labelText: 'Nhập email của bạn'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email.';
                if (!value.contains('@') || !value.contains('.')) return 'Email không hợp lệ.';
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (dialogFormKey.currentState!.validate()) {
                  final email = _forgotPasswordEmailController.text.trim();
                  final appProvider = Provider.of<AppProvider>(context, listen: false);
                  Navigator.of(dialogContext).pop();
                  try {
                    await appProvider.sendPasswordResetEmail(email);
                    if (!mounted) return;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if(mounted){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Email đặt lại mật khẩu đã được gửi đến $email (nếu tài khoản tồn tại).'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  } catch (e) {
                    if (!mounted) return;
                    final errorToShow = appProvider.errorMessage ?? e.toString().replaceFirst('Exception: ', '');
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if(mounted){
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(errorToShow),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    });
                  }
                }
              },
              child: const Text('Gửi Email'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final isLoading = appProvider.isLoading;
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const _StylizedSLogo(),
                const SizedBox(height: 16),
                Text(
                  'S.Budget',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                Text(
                  _isLoginMode ? 'Chào mừng trở lại!' : 'Tạo tài khoản mới',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                Card(
                  elevation: theme.cardTheme.elevation ?? 2,
                  shape: theme.cardTheme.shape ?? RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          TextFormField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email_outlined, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) return 'Vui lòng nhập email.';
                              if (!value.contains('@') || !value.contains('.')) return 'Email không hợp lệ.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              labelText: 'Mật khẩu',
                              prefixIcon: Icon(Icons.lock_outline_rounded, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                  color: theme.inputDecorationTheme.suffixIconColor ?? Colors.grey,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _passwordVisible = !_passwordVisible;
                                  });
                                },
                              ),
                            ),
                            obscureText: !_passwordVisible,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Vui lòng nhập mật khẩu.';
                              if (!_isLoginMode && value.length < 6) return 'Mật khẩu phải có ít nhất 6 ký tự.';
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          if (!_isLoginMode)
                            Column(
                              children: [
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  decoration: InputDecoration(
                                    labelText: 'Xác nhận mật khẩu',
                                    prefixIcon: Icon(Icons.lock_reset_rounded, color: theme.inputDecorationTheme.prefixIconColor ?? theme.colorScheme.primary),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _confirmPasswordVisible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                        color: theme.inputDecorationTheme.suffixIconColor ?? Colors.grey,
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _confirmPasswordVisible = !_confirmPasswordVisible;
                                        });
                                      },
                                    ),
                                  ),
                                  obscureText: !_confirmPasswordVisible,
                                  validator: (value) {
                                    if (value != _passwordController.text) return 'Mật khẩu không khớp.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                              ],
                            ),
                          if (_isLoginMode)
                            Padding(
                              padding: const EdgeInsets.only(top: 0, bottom: 16.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: 24, height: 24,
                                        child: Checkbox(
                                          value: _rememberCredentials,
                                          onChanged: isLoading ? null : (value) {
                                            setState(() {
                                              _rememberCredentials = value!;
                                            });
                                          },
                                          visualDensity: VisualDensity.compact,
                                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      GestureDetector(
                                          onTap: isLoading ? null : () => setState(() => _rememberCredentials = !_rememberCredentials),
                                          child: Text('Ghi nhớ đăng nhập', style: theme.textTheme.bodySmall)
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: isLoading ? null : _showForgotPasswordDialog,
                                    child: Text('Quên mật khẩu?', style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.primary)),
                                    style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                                  ),
                                ],
                              ),
                            ),
                          ElevatedButton(
                            onPressed: isLoading ? null : _submitForm,
                            style: theme.elevatedButtonTheme.style?.copyWith(
                              padding: MaterialStateProperty.all(const EdgeInsets.symmetric(vertical: 14)),
                            ),
                            child: isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text(_isLoginMode ? 'ĐĂNG NHẬP' : 'ĐĂNG KÝ', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: <Widget>[
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text("HOẶC", style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600])),
                    ),
                    const Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: SizedBox(
                    width: 24,
                    height: 24,
                    child: Image.network(
                      'http://pngimg.com/uploads/google/google_PNG19635.png',
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.g_mobiledata_rounded, size: 24),
                    ),
                  ),
                  label: const Text('Đăng nhập với Google'),
                  onPressed: isLoading ? null : _signInWithGoogle,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.black87, backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade300),
                    elevation: 1,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: isLoading ? null : () {
                    setState(() {
                      _isLoginMode = !_isLoginMode;
                      _formKey.currentState?.reset();
                      if (!_rememberCredentials || !_isLoginMode) {
                        _emailController.clear();
                      }
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                      Provider.of<AppProvider>(context, listen: false).clearError();
                    });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                  ),
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
                      children: [
                        TextSpan(text: _isLoginMode ? 'Chưa có tài khoản? ' : 'Đã có tài khoản? '),
                        TextSpan(
                          text: _isLoginMode ? 'Tạo tài khoản mới' : 'Đăng nhập ngay',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                            decorationColor: theme.colorScheme.primary.withOpacity(0.7),
                            decorationThickness: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
