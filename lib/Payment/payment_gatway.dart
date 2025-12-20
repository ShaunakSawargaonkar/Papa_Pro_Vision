import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:papa_pro_vision/Payment/payment_utils.dart';
import 'package:papa_pro_vision/enums.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:papa_pro_vision/Helper/DatabaseHelper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentGateway extends StatefulWidget {
  final bool isFirstPayment;
  final DocumentReference referralKeyRef;
  final String phoneNumber;
  final String userUID;

  const PaymentGateway({
    super.key,
    required this.isFirstPayment,
    required this.referralKeyRef,
    required this.phoneNumber,
    required this.userUID,
  });

  @override
  _PaymentGatewayState createState() => _PaymentGatewayState();
}

class _PaymentGatewayState extends State<PaymentGateway> {
  late Razorpay _razorpay;
  int selectedPlan = 0;
  bool isLoading = true;

  List<Map<String, dynamic>> subscriptionPlans = PaymentService.initialSubscriptionPlans;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _initializePaymentCosts();
  }

  Future<void> _initializePaymentCosts() async {
    try {
      // Fetch payment costs from Firestore
      subscriptionPlans = await PaymentService.fetchPaymentCosts();
      if (mounted) {
        setState(() {
          subscriptionPlans = subscriptionPlans;
          isLoading = false;
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
      'key': 'rzp_live_Rs0d9WEg1h6UPg',
      'amount': price * 100, // Amount in paise
      'name': 'Let See',
      'description':
          'Premium Subscription - ${subscriptionPlans[selectedPlan]['duration'].toString()}',
      'timeout': 300, // 5 minutes timeout
      'prefill': <String, String>{'contact': widget.phoneNumber},
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

      await DatabaseHelper.setSubscriptionInformation(referralKeyRef: widget.referralKeyRef, subscriptionBundleType: subscriptionPlans[selectedPlan]['duration'] as SubscriptionBundleType);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(userUID: widget.userUID)));
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

  Widget _buildPlanCard(
    int index,
    double screenWidth,
    double screenHeight,
    bool isTablet,
    double durationTextSize,
    double priceTextSize,
    double originalPriceTextSize,
    double savingsTextSize,
    double badgeTextSize,
  ) {
    final plan = subscriptionPlans[index];
    final isSelected = selectedPlan == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => selectedPlan = index);
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFCB853) : Colors.grey[50],
          borderRadius: BorderRadius.circular(
            screenWidth * 0.03,
          ), // 3% of screen width
          border: Border.all(
            color: isSelected ? const Color(0xFFFCB853) : Colors.grey[300]!,
            width: isTablet ? 3 : 2, // Thicker border on tablets
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFFCB853).withOpacity(0.3),
                    blurRadius: screenWidth * 0.02, // 2% of screen width
                    offset: Offset(
                      0,
                      screenHeight * 0.004,
                    ), // 0.4% of screen height
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: screenWidth * 0.01, // 1% of screen width
                    offset: Offset(
                      0,
                      screenHeight * 0.002,
                    ), // 0.2% of screen height
                  ),
                ],
        ),
        child: Stack(
          children: [
            if (plan['popular'])
              Positioned(
                top: screenHeight * 0.01, // 1% of screen height
                right: screenWidth * 0.02, // 2% of screen width
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02, // 2% of screen width
                    vertical: screenHeight * 0.005, // 0.5% of screen height
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.02,
                    ), // 2% of screen width
                  ),
                  child: Text(
                    'POPULAR',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeTextSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (widget.isFirstPayment && (plan['duration'] as SubscriptionBundleType) == SubscriptionBundleType.oneMonth)
              Positioned(
                top: screenHeight * 0.01, // 1% of screen height
                left: screenWidth * 0.02, // 2% of screen width
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02, // 2% of screen width
                    vertical: screenHeight * 0.005, // 0.5% of screen height
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(
                      screenWidth * 0.02,
                    ), // 2% of screen width
                  ),
                  child: Text(
                    'First month free',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: badgeTextSize,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04, // 4% of screen width
                vertical: screenWidth * 0.04, // 4% of screen width
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Add equal padding for "First month free" badge to keep content centered
                  if (widget.isFirstPayment && (plan['duration'] as SubscriptionBundleType) == SubscriptionBundleType.oneMonth)
                    SizedBox(
                      height: screenHeight * 0.035,
                    ) // 3.5% padding to balance the badge
                  else
                    SizedBox(
                      height: screenHeight * 0.01,
                    ), // Small padding for other cards
                  Text(
                    plan['duration'].toString(),
                    style: TextStyle(
                      fontSize: durationTextSize,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: screenHeight * 0.015,
                  ), // 1.5% of screen height
                  // Show slashed original price and new price side by side for first month free
                  if (widget.isFirstPayment &&
                      (plan['duration'] as SubscriptionBundleType) == SubscriptionBundleType.oneMonth &&
                      plan['originalPrice'] != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          plan['originalPrice'],
                          style: TextStyle(
                            fontSize: originalPriceTextSize,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? Colors.white70
                                : Colors.grey[600],
                            decoration: TextDecoration.lineThrough,
                            decorationThickness: 2,
                          ),
                        ),
                        SizedBox(
                          width: screenWidth * 0.02,
                        ), // Space between prices
                        Text(
                          plan['price'],
                          style: TextStyle(
                            fontSize: priceTextSize,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : const Color(0xFFFCB853),
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      plan['price'],
                      style: TextStyle(
                        fontSize: priceTextSize,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFFFCB853),
                      ),
                    ),
                  if (plan['savings'] != null) ...[
                    SizedBox(
                      height: screenHeight * 0.01,
                    ), // 1% of screen height
                    Text(
                      plan['savings'],
                      style: TextStyle(
                        fontSize: savingsTextSize,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : Colors.green,
                      ),
                    ),
                  ],
                  // Add bottom padding for 1 Month card to balance the top badge
                  if (widget.isFirstPayment && (plan['duration'] as SubscriptionBundleType) == SubscriptionBundleType.oneMonth)
                    SizedBox(
                      height: screenHeight * 0.035,
                    ) // 3.5% padding to balance
                  else
                    SizedBox(
                      height: screenHeight * 0.01,
                    ), // Small padding for other cards
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = screenWidth > 600;
    final isLargeScreen = screenWidth > 900;

    // Define all text sizes at the top
    final durationTextSize = isTablet
        ? 22.0
        : (screenWidth * 0.04).clamp(18.0, 22.0);
    final priceTextSize = isTablet
        ? 32.0
        : (screenWidth * 0.06).clamp(24.0, 32.0);
    final originalPriceTextSize = isTablet
        ? 20.0
        : (screenWidth * 0.045).clamp(16.0, 20.0);
    final savingsTextSize = isTablet
        ? 14.0
        : (screenWidth * 0.03).clamp(10.0, 14.0);
    final badgeTextSize = isTablet
        ? 12.0
        : (screenWidth * 0.025).clamp(8.0, 12.0);

    // Responsive spacing and sizing
    final horizontalPadding = screenWidth * 0.05; // 5% of screen width
    final verticalPadding = isLandscape
        ? screenHeight * 0.03
        : screenHeight * 0.02; // Adjusted for landscape
    final containerBorderRadius =
        screenWidth * 0.05; // 5% of screen width, max 25
    final maxContainerWidth = isLargeScreen
        ? 600.0
        : (isTablet ? screenWidth * 0.8 : screenWidth * 0.95);

    return Scaffold(
      backgroundColor: const Color(0xFFFCB853),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCB853),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                semanticsLabel: 'Loading, please wait',
              ),
            )
          : SafeArea(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxContainerWidth),
                  margin: EdgeInsets.symmetric(
                    horizontal: horizontalPadding,
                    vertical: verticalPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(
                      containerBorderRadius.clamp(15.0, 25.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: screenWidth * 0.025, // 2.5% of screen width
                        offset: Offset(
                          0,
                          screenHeight * 0.006,
                        ), // 0.6% of screen height
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      Container(
                        padding: EdgeInsets.all(
                          screenWidth * 0.06,
                        ), // 6% of screen width
                        child: Column(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: (screenWidth * 0.15).clamp(
                                50.0,
                                80.0,
                              ), // 15% of screen width, clamped between 50-80
                              color: const Color(0xFFFCB853),
                            ),
                            SizedBox(
                              height: screenHeight * 0.02,
                            ), // 2% of screen height
                            Text(
                              widget.isFirstPayment
                                  ? 'Complete Payment'
                                  : 'Renew Subscription',
                              style: TextStyle(
                                fontSize: isTablet
                                    ? 32
                                    : (screenWidth * 0.07).clamp(
                                        24.0,
                                        32.0,
                                      ), // Dynamic font size
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFCB853),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),

                      // Subscription Plans
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.06,
                          ), // 6% of screen width
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLargeScreen
                                      ? 4
                                      : (isTablet
                                            ? 3
                                            : 2), // Responsive column count
                                  childAspectRatio: isTablet
                                      ? 0.9
                                      : 0.85, // Slightly taller cards on tablets
                                  crossAxisSpacing:
                                      screenWidth * 0.03, // 3% of screen width
                                  mainAxisSpacing:
                                      screenHeight *
                                      0.015, // 1.5% of screen height
                                ),
                            itemCount: subscriptionPlans.length,
                            itemBuilder: (context, index) => _buildPlanCard(
                              index,
                              screenWidth,
                              screenHeight,
                              isTablet,
                              durationTextSize,
                              priceTextSize,
                              originalPriceTextSize,
                              savingsTextSize,
                              badgeTextSize,
                            ),
                          ),
                        ),
                      ),

                      // Continue Button
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.06,
                        ), // 6% of screen width
                        padding: EdgeInsets.only(
                          bottom: screenHeight * 0.02, // 2% of screen height
                          top: screenHeight * 0.02, // 2% of screen height
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            HapticFeedback.mediumImpact();
                            openCheckout(
                              int.parse(
                                subscriptionPlans[selectedPlan]['price']
                                    .replaceAll('₹', '')
                                    .replaceAll(',', '')
                                    .trim(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFCB853),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical:
                                  screenHeight * 0.02, // 2% of screen height
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ), // 3% of screen width
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'Continue with ${subscriptionPlans[selectedPlan]['duration'].toString()} - ${subscriptionPlans[selectedPlan]['price']}',
                            style: TextStyle(
                              fontSize: isTablet
                                  ? 20
                                  : (screenWidth * 0.045).clamp(
                                      16.0,
                                      20.0,
                                    ), // Dynamic font size
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
