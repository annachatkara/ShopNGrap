// Forgot password page UI
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../shared/widgets/loading_indicator.dart';
import 'auth_provider.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  static const routeName = '/forgot-password';

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetEmail() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.forgotPassword(
      email: _emailController.text.trim(),
    );

    if (success && mounted) {
      setState(() {
        _emailSent = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reset instructions sent to your email'),
          backgroundColor: Colors.green,
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Failed to send reset email'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forgot Password'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: _emailSent ? _buildEmailSentView() : _buildFormView(),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          
          // Icon
          Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(
                Icons.lock_reset,
                size: 40,
                color: Theme.of(context).primaryColor,
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Title
          Text(
            'Reset Password',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),
          
          // Description
          Text(
            'Enter your email address and we\'ll send you instructions to reset your password.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 32),
          
          // Email Field
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: Validators.email,
            onFieldSubmitted: (_) => _sendResetEmail(),
            decoration: const InputDecoration(
              labelText: 'Email Address',
              hintText: 'Enter your email',
              prefixIcon: Icon(Icons.email_outlined),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Send Button
          Consumer<AuthProvider>(
            builder: (context, authProvider, child) {
              if (authProvider.isLoading) {
                return const CustomButton(
                  onPressed: null,
                  child: LoadingIndicator(size: 20),
                );
              }
              
              return CustomButton(
                onPressed: _sendResetEmail,
                child: const Text('Send Reset Instructions'),
              );
            },
          ),
          
          const SizedBox(height: 16),
          
          // Back to Login
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Back to Sign In'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailSentView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 60),
        
        // Success Icon
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 60,
              color: Colors.green,
            ),
          ),
        ),
        
        const SizedBox(height: 32),
        
        // Title
        Text(
          'Check Your Email',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 16),
        
        // Description
        Text(
          'We\'ve sent password reset instructions to\n${_emailController.text}',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 32),
        
        // Open Email Button
        CustomButton(
          onPressed: () {
            // This would ideally open the email app
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening email app...')),
            );
          },
          child: const Text('Open Email App'),
        ),
        
        const SizedBox(height: 16),
        
        // Resend Button
        TextButton(
          onPressed: () {
            setState(() {
              _emailSent = false;
            });
          },
          child: const Text('Didn\'t receive email? Try again'),
        ),
        
        const SizedBox(height: 16),
        
        // Back to Login
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}
