import 'package:flutter/material.dart';
import 'dart:async';

void main() {
  runApp(const DeliveryPaymentApp());
}

class DeliveryPaymentApp extends StatelessWidget {
  const DeliveryPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar Delivery Payment',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const DeliveryScreen(),
    );
  }
}

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  // Delivery status
  String status = "Pending";
  
  // Animation controller variables
  double planePosition = 0.0;
  Timer? _timer;
  bool isAnimating = false;
  
  // Payment details
  bool paymentSent = false;
  String payerAccount = "GD7ABCDEFGHIJKLMNOPQRSTUVWXYZ123456";
  String shipperAccount = "GD8ABCDEFGHIJKLMNOPQRSTUVWXYZ123456";
  String assetCode = "PACK";
  String assetAmount = "100.00";
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
  
  void startDelivery() {
    // Reset if already completed
    if (status == "Delivered") {
      setState(() {
        status = "Pending";
        planePosition = 0.0;
        paymentSent = false;
      });
      return;
    }
    
    setState(() {
      status = "In Transit";
      isAnimating = true;
    });
    
    // Create animation timer
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        planePosition += 0.01;
        
        // Update status based on position
        if (planePosition >= 0.5 && status == "In Transit") {
          status = "Out for Delivery";
        }
        
        // Delivery complete
        if (planePosition >= 1.0) {
          status = "Delivered";
          isAnimating = false;
          timer.cancel();
          
          // Trigger payment after delivery
          triggerPayment();
        }
      });
    });
  }
  
  void triggerPayment() {
    // Simulate payment trigger to Stellar
    // In real app, this would call the Stellar SDK and smart contract
    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        paymentSent = true;
      });
      
      // Show payment confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment of $assetAmount $assetCode sent to shipper!'),
          duration: const Duration(seconds: 3),
        ),
      );
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stellar Delivery Payment'),
      ),
      body: Column(
        children: [
          // Status section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.shade50,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Package Status: $status',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Package ID: PKG12345',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          
          // Animation area
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              child: Stack(
                children: [
                  // Shipper location
                  Positioned(
                    left: 20,
                    top: 80,
                    child: Column(
                      children: [
                        Icon(
                          Icons.home_work,
                          size: 40,
                          color: Colors.blue.shade800,
                        ),
                        const Text('Shipper')
                      ],
                    ),
                  ),
                  
                  // Receiver location
                  Positioned(
                    right: 20,
                    top: 80,
                    child: Column(
                      children: [
                        Icon(
                          Icons.home,
                          size: 40,
                          color: Colors.green.shade800,
                        ),
                        const Text('Receiver')
                      ],
                    ),
                  ),
                  
                  // Dotted path
                  Positioned(
                    top: 100,
                    left: 70,
                    right: 70,
                    child: CustomPaint(
                      painter: DottedLinePainter(),
                      size: const Size(double.infinity, 1),
                    ),
                  ),
                  
                  // Paper plane
                  Positioned(
                    left: 70 + (MediaQuery.of(context).size.width - 140) * planePosition,
                    top: 90,
                    child: Transform.rotate(
                      angle: 0.3,
                      child: const Icon(
                        Icons.send,
                        size: 30,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Payment information section
          Container(
            padding: const EdgeInsets.all(16.0),
            color: paymentSent ? Colors.green.shade50 : Colors.grey.shade100,
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paymentSent 
                    ? 'Payment Completed ✓' 
                    : 'Payment (Will trigger on delivery)',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: paymentSent ? Colors.green.shade800 : Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Asset: $assetCode',
                  style: const TextStyle(fontSize: 14),
                ),
                Text(
                  'Amount: $assetAmount',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'From: ${payerAccount.substring(0, 6)}...${payerAccount.substring(payerAccount.length - 4)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'To: ${shipperAccount.substring(0, 6)}...${shipperAccount.substring(shipperAccount.length - 4)}',
                        style: const TextStyle(fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (paymentSent)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      'Transaction ID: TX${DateTime.now().millisecondsSinceEpoch}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Action button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: isAnimating ? null : startDelivery,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                status == "Delivered" ? 'Reset Delivery' : 'Start Delivery',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    
    const dashWidth = 8;
    const dashSpace = 5;
    double startX = 0;
    
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}