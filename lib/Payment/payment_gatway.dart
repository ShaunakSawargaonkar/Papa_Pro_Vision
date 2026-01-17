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

  List<Map<String, dynamic>> subscriptionPlans =
      PaymentService.initialSubscriptionPlans;

  // Responsive constants
  static const Color primaryColor = Color(0xFFFCB853);
  static const Color accentGreen = Colors.green;
  static const Color accentBlue = Colors.blue;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _initializePaymentCosts();
  }

  // Helper method to get responsive values - safe to call after build
  Map<String, double> _getResponsiveValues() {
    final screenWidth = MediaQuery.of(context).size.width;
    return {
      'borderRadius': (screenWidth * 0.03).clamp(8.0, 16.0),
      'iconSize': (screenWidth * 0.04).clamp(20.0, 32.0),
      'padding': (screenWidth * 0.04).clamp(12.0, 24.0),
      'spacing': (screenWidth * 0.02).clamp(8.0, 16.0),
      'snackBarBorderRadius': (screenWidth * 0.03).clamp(8.0, 12.0),
    };
  }

  List<Map<String, dynamic>> _getDisplayPlans(
    List<Map<String, dynamic>> allPlans,
  ) {
    List<Map<String, dynamic>> displayPlans = [];

    if (widget.isFirstPayment) {
      // Show firstMonthFree plan first
      final firstMonthFreePlan = allPlans.firstWhere(
        (plan) =>
            (plan['duration'] as SubscriptionBundleType) ==
            SubscriptionBundleType.firstMonthFree,
        orElse: () => {},
      );
      if (firstMonthFreePlan.isNotEmpty) {
        displayPlans.add(firstMonthFreePlan);
      }
    } else {
      // Show oneMonth plan first (without first month free)
      final oneMonthPlan = allPlans.firstWhere(
        (plan) =>
            (plan['duration'] as SubscriptionBundleType) ==
            SubscriptionBundleType.oneMonth,
        orElse: () => {},
      );
      if (oneMonthPlan.isNotEmpty) {
        displayPlans.add(oneMonthPlan);
      }
    }

    // Add 3 months, 6 months, and 1 year plans
    displayPlans.addAll(
      allPlans.where((plan) {
        final duration = plan['duration'] as SubscriptionBundleType;
        return duration == SubscriptionBundleType.threeMonths ||
            duration == SubscriptionBundleType.sixMonths ||
            duration == SubscriptionBundleType.oneYear;
      }),
    );

    return displayPlans;
  }

  Future<void> _initializePaymentCosts() async {
    try {
      // Fetch payment costs from Firestore
      final allPlans = await PaymentService.fetchPaymentCosts();
      if (mounted) {
        setState(() {
          subscriptionPlans = _getDisplayPlans(allPlans);
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error fetching payment costs: $e');
      // Use filtered default plans if fetch fails
      subscriptionPlans = _getDisplayPlans(
        PaymentService.initialSubscriptionPlans,
      );
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
          final responsive = _getResponsiveValues();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: responsive['iconSize']! * 0.8,
                  ),
                  SizedBox(width: responsive['spacing']),
                  Expanded(
                    child: Text(
                      'Payment gateway initialization failed. Please restart the app.',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.035)
                            .clamp(12.0, 16.0),
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: Colors.red,
              duration: Duration(
                seconds: (MediaQuery.of(context).size.width > 600 ? 4 : 5),
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                  responsive['snackBarBorderRadius']!,
                ),
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
      'name': 'Letsee',
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
      'theme': <String, String>{'color': '#FCB853'},
    };

    try {
      print("Opening Razorpay with options: $options");
      print(
        "Razorpay Flutter Version: Check your pubspec.yaml for razorpay_flutter version",
      );

      // Show loading indicator
      if (mounted) {
        final responsive = _getResponsiveValues();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: responsive['iconSize']! * 0.6,
                  height: responsive['iconSize']! * 0.6,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: responsive['spacing']),
                Text(
                  'Opening payment gateway...',
                  style: TextStyle(
                    fontSize: (MediaQuery.of(context).size.width * 0.035).clamp(
                      12.0,
                      16.0,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: primaryColor,
            duration: Duration(
              seconds: (MediaQuery.of(context).size.width > 600 ? 1 : 2),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                responsive['snackBarBorderRadius']!,
              ),
            ),
          ),
        );
      }

      _razorpay.open(options);
    } catch (e) {
      print("Error in openCheckout: $e");
      HapticFeedback.heavyImpact();

      if (mounted) {
        final responsive = _getResponsiveValues();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: responsive['iconSize']! * 0.8,
                ),
                SizedBox(width: responsive['spacing']),
                Expanded(
                  child: Text(
                    "Failed to open payment gateway: ${e.toString()}",
                    style: TextStyle(
                      fontSize: (MediaQuery.of(context).size.width * 0.035)
                          .clamp(12.0, 16.0),
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: Duration(
              seconds: (MediaQuery.of(context).size.width > 600 ? 3 : 4),
            ),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                responsive['snackBarBorderRadius']!,
              ),
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
      final responsive = _getResponsiveValues();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: responsive['iconSize']! * 0.8,
              ),
              SizedBox(width: responsive['spacing']),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Successful!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: (MediaQuery.of(context).size.width * 0.04)
                            .clamp(14.0, 18.0),
                      ),
                    ),
                    Text(
                      'Welcome to Papa Pro Vision Premium',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.032)
                            .clamp(12.0, 16.0),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: accentGreen,
          duration: Duration(
            seconds: (MediaQuery.of(context).size.width > 600 ? 2 : 3),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive['snackBarBorderRadius']!,
            ),
          ),
        ),
      );

      // Navigate after a short delay to show the success message
      await Future.delayed(const Duration(seconds: 1));

      await DatabaseHelper.setSubscriptionInformation(
        referralKeyRef: widget.referralKeyRef,
        subscriptionBundleType:
            subscriptionPlans[selectedPlan]['duration']
                as SubscriptionBundleType,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userUID: widget.userUID),
        ),
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
      final responsive = _getResponsiveValues();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: responsive['iconSize']! * 0.8,
              ),
              SizedBox(width: responsive['spacing']),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Payment Failed',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: (MediaQuery.of(context).size.width * 0.04)
                            .clamp(14.0, 18.0),
                      ),
                    ),
                    Text(
                      errorMessage.replaceFirst('Payment failed: ', ''),
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.032)
                            .clamp(12.0, 16.0),
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(
            seconds: (MediaQuery.of(context).size.width > 600 ? 3 : 4),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive['snackBarBorderRadius']!,
            ),
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
      final responsive = _getResponsiveValues();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: responsive['iconSize']! * 0.8,
              ),
              SizedBox(width: responsive['spacing']),
              Expanded(
                child: Text(
                  'External wallet selected: ${response.walletName ?? 'Wallet'}',
                  style: TextStyle(
                    fontSize: (MediaQuery.of(context).size.width * 0.035).clamp(
                      12.0,
                      16.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: accentBlue,
          duration: Duration(
            seconds: (MediaQuery.of(context).size.width > 600 ? 1 : 2),
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              responsive['snackBarBorderRadius']!,
            ),
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
          color: isSelected ? primaryColor : Colors.grey[50],
          borderRadius: BorderRadius.circular(screenWidth * 0.03),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.grey[300]!,
            width: isTablet ? 3 : 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: primaryColor.withOpacity(0.3),
                    blurRadius: screenWidth * 0.02,
                    offset: Offset(0, screenHeight * 0.004),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: screenWidth * 0.01,
                    offset: Offset(0, screenHeight * 0.002),
                  ),
                ],
        ),
        child: Stack(
          children: [
            // if (plan['popular'])
            //   Positioned(
            //     top: screenHeight * 0.01,
            //     right: screenWidth * 0.02,
            //     child: Container(
            //       padding: EdgeInsets.symmetric(
            //         horizontal: screenWidth * 0.02,
            //         vertical: screenHeight * 0.005,
            //       ),
            //       decoration: BoxDecoration(
            //         color: accentGreen,
            //         borderRadius: BorderRadius.circular(screenWidth * 0.02),
            //       ),
            //       child: Text(
            //         'POPULAR',
            //         style: TextStyle(
            //           color: Colors.white,
            //           fontSize: badgeTextSize,
            //           fontWeight: FontWeight.bold,
            //         ),
            //       ),
            //     ),
            //   ),
            if (widget.isFirstPayment &&
                (plan['duration'] as SubscriptionBundleType) ==
                    SubscriptionBundleType.firstMonthFree)
              Positioned(
                top: screenHeight * 0.01,
                left: screenWidth * 0.02,
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.02,
                    vertical: screenHeight * 0.005,
                  ),
                  decoration: BoxDecoration(
                    color: accentGreen,
                    borderRadius: BorderRadius.circular(screenWidth * 0.02),
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
                horizontal: screenWidth * 0.02,
                vertical: screenWidth * 0.02,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.isFirstPayment &&
                      (plan['duration'] as SubscriptionBundleType) ==
                          SubscriptionBundleType.firstMonthFree)
                    SizedBox(height: screenHeight * 0.035)
                  else
                    SizedBox(height: screenHeight * 0.01),
                  Text(
                    plan['duration'].toString(),
                    style: TextStyle(
                      fontSize: durationTextSize,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: screenHeight * 0.015),
                  if (widget.isFirstPayment &&
                      (plan['duration'] as SubscriptionBundleType) ==
                          SubscriptionBundleType.firstMonthFree &&
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
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          plan['price'],
                          style: TextStyle(
                            fontSize: priceTextSize,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : primaryColor,
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
                        color: isSelected ? Colors.white : primaryColor,
                      ),
                    ),
                  // if (plan['savings'] != null && !widget.isFirstPayment) ...[
                  //   SizedBox(height: screenHeight * 0.01),
                  //   Text(
                  //     // plan['savings'],
                  //     "Hi",
                  //     style: TextStyle(
                  //       fontSize: savingsTextSize,
                  //       fontWeight: FontWeight.w600,
                  //       color: isSelected ? Colors.white70 : accentGreen,
                  //     ),
                  //   ),
                  // ],
                  if (widget.isFirstPayment &&
                      (plan['duration'] as SubscriptionBundleType) ==
                          SubscriptionBundleType.firstMonthFree)
                    SizedBox(height: screenHeight * 0.035)
                  else
                    SizedBox(height: screenHeight * 0.01),
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

    // Responsive text sizes
    final durationTextSize = isTablet
        ? (screenWidth * 0.04).clamp(18.0, 24.0)
        : (screenWidth * 0.04).clamp(16.0, 22.0);
    final priceTextSize = isTablet
        ? (screenWidth * 0.06).clamp(26.0, 36.0)
        : (screenWidth * 0.06).clamp(20.0, 32.0);
    final originalPriceTextSize = isTablet
        ? (screenWidth * 0.045).clamp(16.0, 24.0)
        : (screenWidth * 0.045).clamp(14.0, 20.0);
    final savingsTextSize = isTablet
        ? (screenWidth * 0.032).clamp(12.0, 16.0)
        : (screenWidth * 0.03).clamp(10.0, 14.0);
    final badgeTextSize = isTablet
        ? (screenWidth * 0.028).clamp(10.0, 14.0)
        : (screenWidth * 0.025).clamp(8.0, 12.0);
    final headerTextSize = isTablet
        ? (screenWidth * 0.07).clamp(28.0, 40.0)
        : (screenWidth * 0.07).clamp(24.0, 32.0);
    final buttonTextSize = isTablet
        ? (screenWidth * 0.045).clamp(18.0, 24.0)
        : (screenWidth * 0.045).clamp(14.0, 20.0);

    // Responsive spacing
    final horizontalPadding = screenWidth * 0.05;
    final verticalPadding = isLandscape
        ? screenHeight * 0.02
        : screenHeight * 0.02;
    final containerBorderRadius = (screenWidth * 0.05).clamp(12.0, 25.0);
    final maxContainerWidth = isLargeScreen
        ? 700.0
        : (isTablet ? screenWidth * 0.85 : screenWidth * 0.95);

    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
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
                    borderRadius: BorderRadius.circular(containerBorderRadius),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: screenWidth * 0.025,
                        offset: Offset(0, screenHeight * 0.006),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header Section
                      Container(
                        padding: EdgeInsets.all(screenWidth * 0.06),
                        child: Column(
                          children: [
                            Icon(
                              Icons.workspace_premium,
                              size: (screenWidth * 0.15).clamp(50.0, 80.0),
                              color: primaryColor,
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              widget.isFirstPayment
                                  ? 'Complete Payment'
                                  : 'Renew Subscription',
                              style: TextStyle(
                                fontSize: headerTextSize,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
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
                          ),
                          child: GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: isLargeScreen
                                      ? 4
                                      : (isTablet ? 2 : 2),
                                  childAspectRatio: isTablet ? 0.9 : 0.85,
                                  crossAxisSpacing: screenWidth * 0.03,
                                  mainAxisSpacing: screenHeight * 0.015,
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
                        ),
                        padding: EdgeInsets.only(
                          bottom: screenHeight * 0.02,
                          top: screenHeight * 0.02,
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
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              vertical: screenHeight * 0.02,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                screenWidth * 0.03,
                              ),
                            ),
                            elevation: 3,
                          ),
                          child: Text(
                            'Continue with ${subscriptionPlans[selectedPlan]['duration'].toString()} - ${subscriptionPlans[selectedPlan]['price']}',
                            style: TextStyle(
                              fontSize: buttonTextSize,
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
