import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;

import 'package:stellar_flutter_sdk/stellar_flutter_sdk.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supply_blockchain/requests.dart';

void main() {
  runApp(const DeliveryPaymentApp());
}

class DeliveryPaymentApp extends StatelessWidget {
  const DeliveryPaymentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stellar Delivery Payment',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
        fontFamily: 'Poppins',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      themeMode: ThemeMode.system,
      home: const DeliveryScreen(),
    );
  }
}

class DeliveryScreen extends StatefulWidget {
  const DeliveryScreen({super.key});

  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen>
    with TickerProviderStateMixin {
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
  String? transactionHash;

  // Additional animation controllers
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late AnimationController _packageController;

  // Animation status indicators
  List<bool> checkpoints = [false, false, false, false];

  // Progress animation
  late Animation<double> _progressAnimation;
  late AnimationController _progressController;

  // Weather effects
  final List<CloudPosition> clouds = [];
  Timer? _cloudTimer;

  // Package location
  double packagePosition = 0.0;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _packageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );

    _progressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Generate clouds
    for (int i = 0; i < 8; i++) {
      clouds.add(
        CloudPosition(
          left: math.Random().nextDouble() * 400,
          top: 40 + math.Random().nextDouble() * 100,
          size: 30 + math.Random().nextDouble() * 30,
          speed: 0.5 + math.Random().nextDouble() * 1.0,
          opacity: 0.3 + math.Random().nextDouble() * 0.5,
        ),
      );
    }

    // Start cloud animation
    _startCloudAnimation();
  }

  void _startCloudAnimation() {
    _cloudTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      setState(() {
        for (var cloud in clouds) {
          cloud.left -= cloud.speed;
          if (cloud.left < -50) {
            cloud.left = MediaQuery.of(context).size.width + 50;
            cloud.top = 40 + math.Random().nextDouble() * 100;
            cloud.size = 30 + math.Random().nextDouble() * 30;
            cloud.speed = 0.5 + math.Random().nextDouble() * 1.0;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _cloudTimer?.cancel();
    _bounceController.dispose();
    _rotationController.dispose();
    _scaleController.dispose();
    _slideController.dispose();
    _fadeController.dispose();
    _packageController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  void startDelivery() {
    // Reset if already completed
    if (status == "Delivered") {
      setState(() {
        status = "Pending";
        planePosition = 0.0;
        packagePosition = 0.0;
        paymentSent = false;
        checkpoints = [false, false, false, false];
      });

      _bounceController.reset();
      _rotationController.reset();
      _scaleController.reset();
      _slideController.reset();
      _fadeController.reset();
      _packageController.reset();
      _progressController.reset();
      return;
    }

    setState(() {
      status = "In Transit";
      isAnimating = true;
    });

    // Start animations
    _bounceController.repeat(reverse: true);
    _rotationController.repeat();
    _scaleController.forward();
    _fadeController.forward();
    _progressController.forward();

    // Delivery progress animation
    _progressController.addListener(() {
      setState(() {
        planePosition = _progressAnimation.value;
        packagePosition = _progressAnimation.value;

        // Update checkpoints
        if (planePosition >= 0.25 && !checkpoints[0]) {
          checkpoints[0] = true;
          _showCheckpointSnackbar("Package picked up");
        }

        if (planePosition >= 0.5 && !checkpoints[1]) {
          checkpoints[1] = true;
          status = "Out for Delivery";
          _showCheckpointSnackbar("Package in transit");
        }

        if (planePosition >= 0.75 && !checkpoints[2]) {
          checkpoints[2] = true;
          _showCheckpointSnackbar("Almost there");
        }

        if (planePosition >= 1.0 && !checkpoints[3]) {
          checkpoints[3] = true;
          status = "Delivered";
          isAnimating = false;

          // Show delivery animation
          _packageController.forward();
          _showCheckpointSnackbar("Package delivered!");

          // Trigger payment
          triggerPayment();
        }
      });
    });
  }

  void _showCheckpointSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      ),
    );
  }

  // Stellar SDK setup
  final StellarSDK sdk = StellarSDK.TESTNET; // Use .PUBLIC for mainnet
  final Network network = Network.TESTNET; // Use .PUBLIC for mainnet

  Future<void> triggerPayment() async {
    // Payment logic would go here

    invokeIncrementContract();

    Future.delayed(const Duration(seconds: 1), () {
      setState(() {
        paymentSent = true;
        transactionHash = "TX${DateTime.now().millisecondsSinceEpoch}";
      });

      // Show payment confirmation with nicer animation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Payment Completed',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$assetAmount $assetCode sent to shipper',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Custom app bar with animated background
          SliverAppBar(
            expandedHeight: 160.0,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Stellar Delivery',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors:
                            isDarkMode
                                ? [
                                  Colors.indigo.shade900,
                                  Colors.deepPurple.shade800,
                                ]
                                : [
                                  Colors.indigo.shade500,
                                  Colors.deepPurple.shade400,
                                ],
                      ),
                    ),
                  ),

                  // Animated clouds
                  ...clouds
                      .map(
                        (cloud) => Positioned(
                          left: cloud.left,
                          top: cloud.top,
                          child: Opacity(
                            opacity: cloud.opacity,
                            child: Icon(
                              Icons.cloud,
                              size: cloud.size,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ],
              ),
            ),
          ),

          // Main content
          SliverToBoxAdapter(
            child: Column(
              children: [
                // Status card
                Card(
                  margin: const EdgeInsets.all(16),
                  elevation: 4,
                  shadowColor: Theme.of(
                    context,
                  ).colorScheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Package Status',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                          status == "Pending"
                                              ? Icons.hourglass_empty
                                              : status == "In Transit"
                                              ? Icons.local_shipping
                                              : status == "Out for Delivery"
                                              ? Icons.departure_board
                                              : Icons.check_circle,
                                          color:
                                              status == "Delivered"
                                                  ? Colors.green
                                                  : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                          size: 24,
                                        )
                                        .animate(
                                          onPlay:
                                              (controller) =>
                                                  controller.repeat(),
                                        )
                                        .scale(
                                          delay: 1.seconds,
                                          duration: 600.ms,
                                          begin: const Offset(1, 1),
                                          end: const Offset(1.2, 1.2),
                                        )
                                        .then()
                                        .scale(
                                          duration: 600.ms,
                                          begin: const Offset(1.2, 1.2),
                                          end: const Offset(1, 1),
                                        ),
                                    const SizedBox(width: 8),
                                    Text(
                                      status,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            status == "Delivered"
                                                ? Colors.green
                                                : Theme.of(
                                                  context,
                                                ).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'PKG12345',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color:
                                      Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: planePosition,
                            minHeight: 10,
                            backgroundColor:
                                Theme.of(context).colorScheme.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              status == "Delivered"
                                  ? Colors.green
                                  : Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Checkpoint indicators
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _checkpointIndicator('Pickup', checkpoints[0]),
                            _checkpointIndicator('Transit', checkpoints[1]),
                            _checkpointIndicator('Arriving', checkpoints[2]),
                            _checkpointIndicator('Delivered', checkpoints[3]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                // Delivery animation area
                Container(
                  height: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Stack(
                    children: [
                      // Path line
                      Positioned(
                        top: 100,
                        left: 60,
                        right: 60,
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(1.5),
                          ),
                        ),
                      ),

                      // Shipper location
                      Positioned(
                        left: 20,
                        top: 80,
                        child: Column(
                          children: [
                            RotationTransition(
                              turns: Tween(begin: 0.0, end: 0.05)
                                  .chain(CurveTween(curve: Curves.elasticInOut))
                                  .animate(_bounceController),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color:
                                      checkpoints[0]
                                          ? Colors.green.withOpacity(0.2)
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.warehouse,
                                  size: 24,
                                  color:
                                      checkpoints[0]
                                          ? Colors.green
                                          : Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Shipper',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      // Receiver location
                      Positioned(
                        right: 20,
                        top: 80,
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    checkpoints[3]
                                        ? Colors.green.withOpacity(0.2)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.home,
                                size: 24,
                                color:
                                    checkpoints[3]
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Receiver',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      // Delivery vehicle animation
                      Positioned(
                        left: 60 + (screenWidth - 120) * planePosition,
                        top:
                            isAnimating
                                ? 80 + math.sin(planePosition * 4 * math.pi) * 5
                                : 80,
                        child: Transform.rotate(
                          angle:
                              isAnimating
                                  ? 0.1 +
                                      math.sin(planePosition * 6 * math.pi) *
                                          0.1
                                  : 0.0,
                          child: ScaleTransition(
                            scale: Tween<double>(begin: 1.0, end: 1.3).animate(
                              CurvedAnimation(
                                parent: _bounceController,
                                curve: Curves.elasticOut,
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primary.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: RotationTransition(
                                turns: Tween(
                                  begin: 0.0,
                                  end: 0.0,
                                ).animate(_rotationController),
                                child: Icon(
                                  Icons.local_shipping,
                                  size: 26,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Package animation at delivery
                      if (status == "Delivered")
                        Positioned(
                          right: 40,
                          bottom: 60,
                          child: ScaleTransition(
                            scale: _packageController,
                            child: SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, -1),
                                end: Offset.zero,
                              ).animate(_packageController),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.inventory_2,
                                  color: Colors.amber,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Payment information card
                Card(
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  elevation: 4,
                  shadowColor:
                      paymentSent
                          ? Colors.green.withOpacity(0.3)
                          : Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color:
                                    paymentSent
                                        ? Colors.green.withOpacity(0.2)
                                        : Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                paymentSent
                                    ? Icons.paid
                                    : Icons.payments_outlined,
                                color:
                                    paymentSent
                                        ? Colors.green
                                        : Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  paymentSent
                                      ? 'Payment Completed'
                                      : 'Payment Details',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        paymentSent
                                            ? Colors.green.shade700
                                            : Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  paymentSent
                                      ? 'Transaction successful'
                                      : 'Will trigger on delivery completion',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Payment details
                        Row(
                          children: [
                            Expanded(
                              child: _paymentInfoItem(
                                'Asset',
                                assetCode,
                                Icons.token,
                              ),
                            ),
                            Expanded(
                              child: _paymentInfoItem(
                                'Amount',
                                assetAmount,
                                Icons.attach_money,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        // Addresses with better formatting
                        _addressInfoItem(
                          'From',
                          payerAccount,
                          Icons.account_balance_wallet,
                        ),

                        const SizedBox(height: 8),

                        _addressInfoItem(
                          'To',
                          shipperAccount,
                          Icons.shopping_cart,
                        ),

                        // Transaction hash (when payment is sent)
                        if (paymentSent)
                          Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.receipt_long,
                                  size: 16,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'TX: ${transactionHash!}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.green.shade700,
                                      fontFamily: 'Courier',
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),

      // Floating action button for controlling delivery
      floatingActionButton: FloatingActionButton.extended(
        onPressed: isAnimating ? null : startDelivery,
        backgroundColor:
            isAnimating
                ? Theme.of(context).colorScheme.surfaceVariant
                : status == "Delivered"
                ? Colors.amber
                : Theme.of(context).colorScheme.primary,
        foregroundColor:
            isAnimating
                ? Theme.of(context).colorScheme.onSurfaceVariant
                : Theme.of(context).colorScheme.onPrimary,
        elevation: 4,
        icon: Icon(status == "Delivered" ? Icons.replay : Icons.play_arrow),
        label: Text(
          status == "Delivered" ? 'Reset Delivery' : 'Start Delivery',
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Helper widgets
  Widget _checkpointIndicator(String label, bool isCompleted) {
    return Column(
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color:
                isCompleted
                    ? Colors.green
                    : Theme.of(context).colorScheme.surfaceVariant,
            shape: BoxShape.circle,
            border: Border.all(
              color:
                  isCompleted
                      ? Colors.green.shade700
                      : Theme.of(context).colorScheme.primary.withOpacity(0.5),
              width: 2,
            ),
          ),
          child:
              isCompleted
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color:
                isCompleted
                    ? Colors.green.shade700
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: isCompleted ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _paymentInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _addressInfoItem(String label, String address, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    address.substring(0, 6),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '...',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    address.substring(address.length - 4),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'Courier',
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// Cloud animation model
class CloudPosition {
  double left;
  double top;
  double size;
  double speed;
  double opacity;

  CloudPosition({
    required this.left,
    required this.top,
    required this.size,
    required this.speed,
    required this.opacity,
  });
}

// Add this to your pubspec.yaml:
// dependencies:
//   flutter_animate: ^4.1.1+1
