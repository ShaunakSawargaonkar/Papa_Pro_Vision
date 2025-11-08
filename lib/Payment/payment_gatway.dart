import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:papa_pro_vision/UI/RegisterPage/payment_page.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    return PaymentPage(
      isFirstPayment: widget.isFirstPayment,
      onPayment: openCheckout,
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

    final prefs = await SharedPreferences.getInstance();
    final phoneNumber = prefs.getString('contactNumber') ?? '+91';
    var options = <String, dynamic>{
      'key': 'rzp_test_RaVDdVb2vZXMGO',
      'amount': price * 100, // Amount in paise
      'name': 'Let See',
      'description':
          'Premium Subscription - ${subscriptionPlans[selectedPlan]['duration']}',
      'timeout': 300, // 5 minutes timeout
      'prefill': <String, String>{'contact': phoneNumber},
      'config': <String, dynamic>{
        'display': <String, dynamic>{
          'hide': [
            <String, String>{'method': 'emi'},
            <String, String>{'method': 'wallet'},
            <String, String>{'method': 'paylater'},
          ],
          'preferences': <String, dynamic>{'show_default_blocks': true},
        },
      },
      'theme': <String, String>{'color': '#FCB853'}, // Match our theme color
    };

    try {
      print("Opening Razorpay with options: $options");
      print(
        "Razorpay Flutter Version: Check your pubspec.yaml for razorpay_flutter version",
      );

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
                      'Welcome to Letsee Premium',
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
