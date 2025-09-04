import 'package:flutter/material.dart';
import 'package:lets_build_planner/supabase/supabase_config.dart';
import 'package:lets_build_planner/screens/home_page.dart';

class AuthPage extends StatefulWidget {
  final bool isDialog;
  
  const AuthPage({super.key, this.isDialog = false});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isSignUp = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _authenticate() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      if (_isSignUp) {
        await SupabaseAuth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully! Please check your email to confirm.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        await SupabaseAuth.signIn(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        if (mounted) {
          if (widget.isDialog) {
            Navigator.of(context).pop(); // Close dialog
            // The parent HomePage will automatically refresh due to auth state change
          } else {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _continueAsGuest() async {
    if (widget.isDialog) {
      Navigator.of(context).pop(); // Close dialog, stay in read-only mode
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authForm = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _isSignUp ? 'Create Account' : 'Sign In',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Email',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.lock),
          ),
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            _errorMessage,
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _authenticate,
            child: _isLoading
                ? const CircularProgressIndicator()
                : Text(_isSignUp ? 'Sign Up' : 'Sign In'),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => setState(() {
            _isSignUp = !_isSignUp;
            _errorMessage = '';
          }),
          child: Text(
            _isSignUp 
                ? 'Already have an account? Sign in'
                : 'Need an account? Sign up',
          ),
        ),
        const SizedBox(height: 24),
        const Divider(),
        const SizedBox(height: 16),
        Text(
          'Or continue without an account',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: _continueAsGuest,
          icon: const Icon(Icons.visibility),
          label: const Text('View as Guest'),
        ),
      ],
    );

    if (widget.isDialog) {
      return authForm;
    }

    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'assets/images/v0-horiz.png',
          height: 40,
          fit: BoxFit.contain,
        ),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: authForm,
            ),
          ),
        ),
      ),
    );
  }
}