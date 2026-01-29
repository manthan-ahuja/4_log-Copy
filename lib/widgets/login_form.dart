import 'package:flutter/material.dart';

class LoginForm extends StatelessWidget {
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(bool) onPasswordFocus;
  final Function(double) onTextChange;

  const LoginForm({
    super.key,
    required this.emailController,
    required this.passwordController,
    required this.onPasswordFocus,
    required this.onTextChange,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (val) => onTextChange(val.length * 2),
        ),
        const SizedBox(height: 16),
        Focus(
          onFocusChange: onPasswordFocus,
          child: TextField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
        ),
      ],
    );
  }
}
