import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../domain/order_model.dart';
import 'order_detail_page.dart';

class PaymentSuccessPage extends StatefulWidget {
  const PaymentSuccessPage({
    super.key,
    required this.order,
    required this.transactionId,
  });

  final Order order;
  final String transactionId;

  static const routeName = '/payment-success';

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    
    // Start confetti animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _confettiController.play();
    });
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back navigation
      child: Scaffold(
        body: Stack(
          children: [
            // Confetti animation
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Colors.green,
                  Colors.blue,
                  Colors.pink,
                  Colors.orange,
                  Colors.purple
                ],
              ),
            ),
            
            // Main content
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 60),
                    
                    // Success animation
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.green, width: 3),
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 60,
                        color: Colors.green,
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Success message
                    Text(
                      'Payment Successful!',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Your order has been placed and payment confirmed.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[600],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Payment details card
                    _buildPaymentDetailsCard(),
                    
                    const SizedBox(height: 24),
                    
                    // Order details card
                    _buildOrderDetailsCard(),
                    
                    const Spacer(),
                    
                    // Action buttons
                    _buildActionButtons(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  'Payment Details',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailRow('Amount Paid', widget.order.formattedTotal, isHighlighted: true),
            _buildDetailRow('Payment Method', widget.order.paymentMethod.title),
            _buildDetailRow('Transaction ID', widget.transactionId),
            _buildDetailRow('Payment Time', Formatters.dateTime(DateTime.now())),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetailsCard() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag, color: Colors.orange),
                const SizedBox(width: 12),
                Text(
                  'Order Information',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            _buildDetailRow('Order Number', widget.order.orderNumber, isHighlighted: true),
            _buildDetailRow('Items', '${widget.order.totalItems} items'),
            _buildDetailRow('Pickup From', widget.order.pickupAddress.shopName),
            _buildDetailRow('Pickup Address', widget.order.pickupAddress.shortAddress),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? Theme.of(context).primaryColor : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Primary action - View order
        SizedBox(
          width: double.infinity,
          child: CustomButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (context) => OrderDetailPage(orderId: widget.order.id),
                ),
                (route) => route.isFirst,
              );
            },
            child: const Text('View Order Details'),
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Secondary actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _downloadReceipt,
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Download Receipt'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _sharePayment,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Continue shopping
        TextButton.icon(
          onPressed: () {
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/', // Home route
              (route) => false,
            );
          },
          icon: const Icon(Icons.shopping_cart, size: 18),
          label: const Text('Continue Shopping'),
        ),
      ],
    );
  }

  void _downloadReceipt() {
    // TODO: Implement receipt download
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt download will be available soon'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _sharePayment() {
    final shareText = '''
Payment Successful! 

Order: ${widget.order.orderNumber}
Amount: ${widget.order.formattedTotal}
Transaction ID: ${widget.transactionId}

Pickup from: ${widget.order.pickupAddress.shopName}
${widget.order.pickupAddress.shortAddress}

Thank you for your order!
    ''';
    
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing payment details...')),
    );
  }
}
