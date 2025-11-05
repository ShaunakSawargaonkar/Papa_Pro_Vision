import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';

class PaymentGateway extends StatefulWidget {
  final bool isFirstPayment;

  const PaymentGateway({super.key, required this.isFirstPayment});

  @override
  _PaymentGatewayState createState() => _PaymentGatewayState();
}

class _PaymentGatewayState extends State<PaymentGateway> {
  late Razorpay _razorpay;
  int selectedPlan = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> subscriptionPlans = [
    {'duration': '1 Month', 'price': '₹299', 'savings': null, 'popular': false},
    {
      'duration': '3 Months',
      'price': '₹750',
      'savings': 'Save 16%',
      'popular': true,
    },
    {
      'duration': '6 Months',
      'price': '₹1300',
      'savings': 'Save 28%',
      'popular': false,
    },
    {
      'duration': '1 Year',
      'price': '₹2300',
      'savings': 'Save 35%',
      'popular': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCB853),
      appBar: AppBar(
        title: const Text('', semanticsLabel: 'Payment Gateway'),
        backgroundColor: const Color(0xFFFCB853),
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                semanticsLabel: 'Loading payment options, please wait',
              ),
            )
          : SafeArea(
              child: Center(
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 550),
                  margin: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 16.0,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        // Header - Compact
                        Column(
                          children: [
                            Icon(
                              Icons.payment,
                              size: 40,
                              color: const Color(0xFFFCB853),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              widget.isFirstPayment
                                  ? 'Choose Your Plan'
                                  : 'Renew Subscription',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFCB853),
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Select a subscription plan to unlock premium features',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Subscription Plans - Grid Layout for Compact View
                        Expanded(
                          flex: 3,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 1.0,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                ),
                            itemCount: subscriptionPlans.length,
                            itemBuilder: (context, index) {
                              final plan = subscriptionPlans[index];
                              final isSelected = selectedPlan == index;

                              return InkWell(
                                onTap: () {
                                  HapticFeedback.selectionClick();
                                  setState(() => selectedPlan = index);
                                },
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(
                                            0xFFFCB853,
                                          ).withOpacity(0.1)
                                        : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? const Color(0xFFFCB853)
                                          : Colors.grey[300]!,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: Stack(
                                    children: [
                                      // Popular Badge
                                      if (plan['popular'])
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 6,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'POPULAR',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 8,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),

                                      // Content
                                      Row(
                                        children: [
                                          // Selection Indicator (Radio Button)
                                          Container(
                                            width: 16,
                                            height: 16,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: isSelected
                                                    ? const Color(0xFFFCB853)
                                                    : Colors.grey[400]!,
                                                width: 2,
                                              ),
                                              color: isSelected
                                                  ? const Color(0xFFFCB853)
                                                  : Colors.transparent,
                                            ),
                                            child: isSelected
                                                ? const Icon(
                                                    Icons.check,
                                                    size: 10,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),

                                          const SizedBox(width: 8),

                                          // Text Content Column
                                          Expanded(
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Duration
                                                Text(
                                                  plan['duration'],
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
                                                  ),
                                                ),

                                                const SizedBox(height: 4),

                                                // Price
                                                Text(
                                                  plan['price'],
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Color(0xFFFCB853),
                                                  ),
                                                ),

                                                // Savings
                                                if (plan['savings'] !=
                                                    null) ...[
                                                  const SizedBox(height: 4),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                    decoration: BoxDecoration(
                                                      color: Colors.green[50],
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            6,
                                                          ),
                                                      border: Border.all(
                                                        color:
                                                            Colors.green[200]!,
                                                      ),
                                                    ),
                                                    child: Text(
                                                      plan['savings'],
                                                      style: TextStyle(
                                                        fontSize: 9,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            Colors.green[700],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Features Section - Compact
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue[200]!,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.star,
                                color: Colors.blue[700],
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Unlimited access • Priority support • No ads • Advanced features',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Payment Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              HapticFeedback.mediumImpact();
                              final amount = int.parse(
                                subscriptionPlans[selectedPlan]['price']
                                    .replaceAll('₹', '')
                                    .replaceAll(',', '')
                                    .trim(),
                              );
                              openCheckout(amount);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFCB853),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: Text(
                              'Pay ${subscriptionPlans[selectedPlan]['price']} - Continue',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Security Note - Compact
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.security,
                              size: 14,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Secure payment powered by Razorpay',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _initializePaymentCosts();
  }

  Future<void> _initializePaymentCosts() async {
    try {
      // Fetch payment costs from Firestore
      print("Fetching payment costs from Firestore");
      final paymentCostSnapshot = await FirebaseFirestore.instance
          .collection('PaymentCost')
          .get();

      if (paymentCostSnapshot.docs.isNotEmpty) {
        final data = paymentCostSnapshot.docs[0].data();
        print("Payment Costs Data: $data");

        // Update subscription plans with fetched prices
        setState(() {
          for (int i = 0; i < subscriptionPlans.length; i++) {
            final duration = subscriptionPlans[i]['duration'];
            if (data.containsKey(duration)) {
              subscriptionPlans[i]['price'] = '₹${data[duration]}';
            }
          }
          // Recalculate savings after updating prices
          _calculateSavings();
        });
      }
    } catch (e) {
      print('Error fetching payment costs: $e');
      // Keep default prices if fetch fails
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _calculateSavings() {
    // Get monthly price for calculation
    final monthlyPriceStr =
        subscriptionPlans[0]['price']?.replaceAll(RegExp(r'[^\d]'), '') ??
        '299';
    final monthlyPrice = int.tryParse(monthlyPriceStr) ?? 299;

    for (int i = 1; i < subscriptionPlans.length; i++) {
      final currentPriceStr =
          subscriptionPlans[i]['price']?.replaceAll(RegExp(r'[^\d]'), '') ??
          '0';
      final currentPrice = int.tryParse(currentPriceStr) ?? 0;

      int months;
      switch (subscriptionPlans[i]['duration']) {
        case '3 Months':
          months = 3;
          break;
        case '6 Months':
          months = 6;
          break;
        case '1 Year':
          months = 12;
          break;
        default:
          months = 1;
      }

      final expectedPrice = monthlyPrice * months;
      if (currentPrice < expectedPrice) {
        final savingsPercent =
            ((expectedPrice - currentPrice) / expectedPrice * 100).round();
        subscriptionPlans[i]['savings'] = 'Save $savingsPercent%';
      } else {
        subscriptionPlans[i]['savings'] = null;
      }
    }
  }

  void _initializeRazorpay() {
    try {
      _razorpay = Razorpay();
      _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
      _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentErrorSafely);
      _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
      print("Razorpay initialized successfully");
    } catch (e) {
      print("Error initializing Razorpay: $e");
      // Show error to user with better styling
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Payment gateway initialization failed. Please restart the app.',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        }
      });
    }
  }

  void _handlePaymentErrorSafely(dynamic response) {
    try {
      // Try to handle as PaymentFailureResponse first
      if (response is PaymentFailureResponse) {
        _handlePaymentError(response);
      } else {
        // Handle raw response data
        print("Raw payment error response: $response");
        String errorMessage = "Payment failed";

        if (response != null) {
          if (response is String) {
            errorMessage = "Payment failed: $response";
          } else if (response is Map) {
            errorMessage =
                "Payment failed: ${response['error'] ?? response.toString()}";
          } else {
            errorMessage = "Payment failed: ${response.toString()}";
          }
        }

        Fluttertoast.showToast(
          msg: errorMessage,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      print("Error in safe payment error handler: $e");
      Fluttertoast.showToast(
        msg: "Payment failed - Unable to process error",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  @override
  void dispose() {
    try {
      _razorpay.clear();
    } catch (e) {
      print("Error clearing Razorpay: $e");
    }
    super.dispose();
  }

  void openCheckout(int price) async {
    print("Opening checkout for amount: ₹$price");
    HapticFeedback.mediumImpact();

    // Validate inputs
    if (price <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.white),
                SizedBox(width: 12),
                Text('Invalid payment amount'),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
      return;
    }

    var options = <String, dynamic>{
      'key': 'rzp_test_RaVDdVb2vZXMGO',
      'amount': price * 100, // Amount in paise
      'name': 'Papa Pro Vision',
      'description':
          'Premium Subscription - ${subscriptionPlans[selectedPlan]['duration']}',
      'timeout': 300, // 5 minutes timeout
      'prefill': <String, String>{},
      'external': <String, List<String>>{
        'wallets': ['paytm', 'gpay', 'phonepe', 'amazonpay'],
      },
      'theme': <String, String>{'color': '#FCB853'}, // Match our theme color
    };

    try {
      print("Opening Razorpay with options: $options");

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text('Opening payment gateway...'),
              ],
            ),
            backgroundColor: const Color(0xFFFCB853),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      _razorpay.open(options);
    } catch (e) {
      print("Error in openCheckout: $e");
      HapticFeedback.heavyImpact();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Failed to open payment gateway: ${e.toString()}",
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => openCheckout(price),
            ),
          ),
        );
      }
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    HapticFeedback.lightImpact();

    // Show success message with professional styling
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      'Welcome to Papa Pro Vision Premium',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

      // Navigate after a short delay to show the success message
      await Future.delayed(const Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    HapticFeedback.heavyImpact();

    String errorMessage = "Payment failed";

    try {
      // Handle the response more safely
      if (response.code != null) {
        errorMessage = "Payment failed: ${response.code}";
        if (response.message != null && response.message!.isNotEmpty) {
          errorMessage = "Payment failed: ${response.message}";
        }
      } else {
        errorMessage =
            "Payment failed - ${response.message ?? 'Unknown error'}";
      }
    } catch (e) {
      print("Error handling payment failure: $e");
      errorMessage = "Payment failed - Unable to process error details";
    }

    print("Payment Error: $errorMessage");

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Payment Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      errorMessage.replaceFirst('Payment failed: ', ''),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white,
            onPressed: () {
              final amount = int.parse(
                subscriptionPlans[selectedPlan]['price']
                    .replaceAll('₹', '')
                    .replaceAll(',', '')
                    .trim(),
              );
              openCheckout(amount);
            },
          ),
        ),
      );
    }
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.account_balance_wallet, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'External wallet selected: ${response.walletName ?? 'Wallet'}',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.blue,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}
