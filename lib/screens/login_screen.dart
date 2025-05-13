import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailC = TextEditingController();
  final _passC = TextEditingController();
  bool _isLogin = true;

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailC,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (v) => v != null && v.contains('@') ? null : 'Email không hợp lệ',
              ),
              TextFormField(
                controller: _passC,
                decoration: const InputDecoration(labelText: 'Mật khẩu'),
                obscureText: true,
                validator: (v) => v != null && v.length >= 6 ? null : 'Mật khẩu ≥ 6 ký tự',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (!_formKey.currentState!.validate()) return;
                  try {
                    if (_isLogin) {
                      await prov.signIn(_emailC.text, _passC.text);
                    } else {
                      await prov.register(_emailC.text, _passC.text);
                    }
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const HomeScreen()),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                },
                child: Text(_isLogin ? 'Đăng nhập' : 'Đăng ký'),
              ),
              TextButton(
                onPressed: () => setState(() => _isLogin = !_isLogin),
                child: Text(_isLogin ? 'Chưa có tài khoản? Đăng ký' : 'Đã có tài khoản? Đăng nhập'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}