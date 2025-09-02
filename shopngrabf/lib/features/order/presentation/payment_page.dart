import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/loading_indicator.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order_model.dart';
import 'order_provider.dart';
import 'order_detail_page.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({
    super.key,
    required this.order,
  });

  final Order order;

  static const routeName = '/payment';

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _isProcessingPayment = false;
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  
  // Payment form controllers
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();
  final _upiIdController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    _selectedMethod = widget.order.paymentMethod;
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => _showExitConfirmation(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order summary card
            _buildOrderSummaryCard(),
            
            const SizedBox(height: 16),
            
            // Payment methods
            _buildPaymentMethodsCard(),
            
            const SizedBox(height: 16),
            
            // Payment form based on selected method
            _buildPaymentForm(),
            
            const SizedBox(height: 16),
            
            // Security info
            _buildSecurityInfoCard(),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: _buildPaymentBottomBar(),
    );
  }

  Widget _buildOrderSummaryCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order.orderNumber,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${widget.order.totalItems} items • Pickup from ${widget.order.pickupAddress.shopName}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  widget.order.formattedTotal,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your payment is secured with end-to-end encryption',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Payment Method',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Exclude cash since this is online payment page
            ...PaymentMethod.values.where((method) => method != PaymentMethod.cash).map((method) {
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: RadioListTile<PaymentMethod>(
                  value: method,
                  groupValue: _selectedMethod,
                  onChanged: (value) {
                    setState(() {
                      _selectedMethod = value!;
                    });
                  },
                  title: Row(
                    children: [
                      Icon(method.icon, size: 20),
                      const SizedBox(width: 12),
                      Text(method.title),
                    ],
                  ),
                  subtitle: Text(_getPaymentMethodDescription(method)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentForm() {
    switch (_selectedMethod) {
      case PaymentMethod.card:
        return _buildCardPaymentForm();
      case PaymentMethod.upi:
        return _buildUPIPaymentForm();
      case PaymentMethod.wallet:
        return _buildWalletPaymentForm();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildCardPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Card Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Card holder name
            TextFormField(
              controller: _cardHolderController,
              decoration: const InputDecoration(
                labelText: 'Cardholder Name',
                hintText: 'Enter name on card',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            
            const SizedBox(height: 16),
            
            // Card number
            TextFormField(
              controller: _cardNumberController,
              decoration: const InputDecoration(
                labelText: 'Card Number',
                hintText: '1234 5678 9012 3456',
                prefixIcon: Icon(Icons.credit_card),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: _formatCardNumber,
            ),
            
            const SizedBox(height: 16),
            
            // Expiry and CVV
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _expiryController,
                    decoration: const InputDecoration(
                      labelText: 'Expiry Date',
                      hintText: 'MM/YY',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: _formatExpiryDate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _cvvController,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                      prefixIcon: Icon(Icons.lock),
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 3,
                    obscureText: true,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Save card option
            CheckboxListTile(
              value: false,
              onChanged: null, // Disabled for demo
              title: const Text('Save this card for future payments'),
              subtitle: const Text('Your card details will be stored securely'),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIPaymentForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UPI Payment',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // UPI ID input
            TextFormField(
              controller: _upiIdController,
              decoration: const InputDecoration(
                labelText: 'UPI ID',
                hintText: 'yourname@paytm',
                prefixIcon: Icon(Icons.account_balance_wallet),
                border: OutlineInputBorder(),
                suffixText: '@upi',
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Quick UPI options
            Text(
              'Or pay with',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            
            const SizedBox(height: 12),
            
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _buildUPIAppButton('PhonePe', 'assets/icons/phonepe.png'),
                _buildUPIAppButton('Google Pay', 'assets/icons/gpay.png'),
                _buildUPIAppButton('Paytm', 'assets/icons/paytm.png'),
                _buildUPIAppButton('BHIM', 'assets/icons/bhim.png'),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info, color: Colors.blue, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'UPI payment is instant and secure. You will be redirected to your UPI app.',
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletPaymentForm() {
    final wallets = [
      {'name': 'Paytm Wallet', 'icon': Icons.account_balance_wallet, 'balance': '₹2,450'},
      {'name': 'PhonePe Wallet', 'icon': Icons.account_balance_wallet, 'balance': '₹1,200'},
      {'name': 'Amazon Pay', 'icon': Icons.account_balance_wallet, 'balance': '₹850'},
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Digital Wallets',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ...wallets.map((wallet) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: Icon(wallet['icon'] as IconData),
                  title: Text(wallet['name'] as String),
                  subtitle: Text('Available balance: ${wallet['balance']}'),
                  trailing: Radio<String>(
                    value: wallet['name'] as String,
                    groupValue: null, // No selection for demo
                    onChanged: (value) {
                      // Handle wallet selection
                    },
                  ),
                  onTap: () {
                    // Handle wallet selection
                  },
                ),
              );
            }).toList(),
            
            const SizedBox(height: 16),
            
            OutlinedButton.icon(
              onPressed: () {
                // Add new wallet
              },
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Add New Wallet'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUPIAppButton(String name, String iconPath) {
    return Container(
      width: 80,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.payment, size: 30), // In real app, use Image.asset(iconPath)
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shield, color: Colors.green),
                const SizedBox(width: 12),
                Text(
                  'Your payment is secure',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                const Icon(Icons.lock, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '256-bit SSL encryption',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.verified_user, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'PCI DSS compliant',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              children: [
                const Icon(Icons.privacy_tip, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Your card details are never stored',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Amount to pay
            Row(
              children: [
                Text(
                  'Amount to pay:',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  widget.order.formattedTotal,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Pay now button
            SizedBox(
              width: double.infinity,
              child: CustomButton(
                onPressed: _isProcessingPayment ? null : _processPayment,
                child: _isProcessingPayment
                    ? const LoadingIndicator(size: 20)
                    : Text('Pay ${widget.order.formattedTotal}'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Cancel payment
            TextButton(
              onPressed: _isProcessingPayment ? null : _showExitConfirmation,
              child: const Text('Cancel Payment'),
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  String _getPaymentMethodDescription(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return 'Credit/Debit cards accepted';
      case PaymentMethod.upi:
        return 'Pay using UPI apps like PhonePe, GPay';
      case PaymentMethod.wallet:
        return 'Use your digital wallet balance';
      default:
        return '';
    }
  }

  void _formatCardNumber(String value) {
    // Remove all non-digits
    String cleaned = value.replaceAll(RegExp(r'\D'), '');
    
    // Add spaces every 4 digits
    String formatted = '';
    for (int i = 0; i < cleaned.length; i += 4) {
      if (i + 4 < cleaned.length) {
        formatted += '${cleaned.substring(i, i + 4)} ';
      } else {
        formatted += cleaned.substring(i);
      }
    }
    
    _cardNumberController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  void _formatExpiryDate(String value) {
    // Remove all non-digits
    String cleaned = value.replaceAll(RegExp(r'\D'), '');
    
    // Add slash after 2 digits
    String formatted = '';
    if (cleaned.length >= 2) {
      formatted = '${cleaned.substring(0, 2)}/${cleaned.substring(2)}';
    } else {
      formatted = cleaned;
    }
    
    _expiryController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  Future<void> _processPayment() async {
    if (!_validatePaymentForm()) return;

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final orderProvider = context.read<OrderProvider>();
      
      // Prepare payment data based on selected method
      final paymentData = _preparePaymentData();
      
      // Process payment
      final paymentResult = await orderProvider.processPayment(
        widget.order.id,
        paymentData,
      );

      if (paymentResult != null && mounted) {
        if (paymentResult['success'] == true) {
          // Payment successful
          final transactionId = paymentResult['transactionId'] as String;
          
          // Verify payment
          final success = await orderProvider.verifyPayment(widget.order.id, transactionId);
          
          if (success && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PaymentSuccessPage(
                  order: widget.order,
                  transactionId: transactionId,
                ),
              ),
            );
          } else {
            _showPaymentFailedDialog('Payment verification failed');
          }
        } else {
          // Payment failed
          _showPaymentFailedDialog(paymentResult['error'] ?? 'Payment failed');
        }
      } else {
        _showPaymentFailedDialog('Payment processing failed');
      }
    } catch (e) {
      _showPaymentFailedDialog('Payment failed: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  bool _validatePaymentForm() {
    switch (_selectedMethod) {
      case PaymentMethod.card:
        if (_cardHolderController.text.trim().isEmpty) {
          _showError('Please enter cardholder name');
          return false;
        }
        if (_cardNumberController.text.replaceAll(' ', '').length < 16) {
          _showError('Please enter valid card number');
          return false;
        }
        if (_expiryController.text.length != 5) {
          _showError('Please enter valid expiry date');
          return false;
        }
        if (_cvvController.text.length != 3) {
          _showError('Please enter valid CVV');
          return false;
        }
        break;
      case PaymentMethod.upi:
        if (_upiIdController.text.trim().isEmpty) {
          _showError('Please enter UPI ID');
          return false;
        }
        break;
      case PaymentMethod.wallet:
        // Wallet validation would depend on selected wallet
        break;
    }
    return true;
  }

  Map<String, dynamic> _preparePaymentData() {
    final baseData = {
      'method': _selectedMethod.value,
      'amount': widget.order.total,
      'orderId': widget.order.id,
    };

    switch (_selectedMethod) {
      case PaymentMethod.card:
        baseData.addAll({
          'cardNumber': _cardNumberController.text.replaceAll(' ', ''),
          'expiryDate': _expiryController.text,
          'cvv': _cvvController.text,
          'cardHolder': _cardHolderController.text.trim(),
        });
        break;
      case PaymentMethod.upi:
        baseData.addAll({
          'upiId': _upiIdController.text.trim(),
        });
        break;
      case PaymentMethod.wallet:
        // Add wallet-specific data
        break;
    }

    return baseData;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showPaymentFailedDialog(String error) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Payment Failed'),
        content: Text(error),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Try Again'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailPage(orderId: widget.order.id),
                ),
              );
            },
            child: const Text('View Order'),
          ),
        ],
      ),
    );
  }

  void _showExitConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Payment?'),
        content: const Text('Your order has been placed but payment is pending. You can complete payment later from your orders.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Continue Payment'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailPage(orderId: widget.order.id),
                ),
              );
            },
            child: const Text('Exit'),
          ),
        ],
      ),
    );
  }
}
