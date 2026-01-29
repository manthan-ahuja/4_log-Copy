import 'package:flutter/material.dart';

class SignupForm extends StatelessWidget {
  final TextEditingController usernameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final Function(bool) onPasswordFocus;
  final Function(double) onTextChange;

  const SignupForm({
    super.key,
    required this.usernameController,
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
          controller: usernameController,
          decoration: const InputDecoration(labelText: 'Username'),
          onChanged: (val) => onTextChange(val.length * 2),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          onChanged: (val) => onTextChange(val.length * 2),
        ),
        const SizedBox(height: 12),
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
