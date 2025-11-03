import 'package:flutter/material.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:papa_pro_vision/UI/RegisterPage/payment_page.dart';
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

  @override
  Widget build(BuildContext context) {
    return PaymentPage(
      isFirstPayment: widget.isFirstPayment,
      onPayment: (int amount) => openCheckout(amount),
    );
  }

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
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
      // Show error to user
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Fluttertoast.showToast(
          msg: "Payment gateway initialization failed",
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
        );
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

    // Validate inputs
    if (price <= 0) {
      Fluttertoast.showToast(
        msg: "Invalid payment amount",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
      return;
    }

    var options = <String, dynamic>{
      'key': 'rzp_test_RaVDdVb2vZXMGO',
      'amount': price * 100, // Amount in paise
      'name': 'LetSee',
      'description': 'User Subscription',
      'timeout': 300, // 5 minutes timeout
      'prefill': <String, String>{},
      'external': <String, List<String>>{
        'wallets': ['paytm'],
      },
      'theme': <String, String>{'color': '#2e91a0'},
    };

    try {
      print("Opening Razorpay with options: $options");
      _razorpay.open(options);
    } catch (e) {
      print("Error in openCheckout: $e");
      Fluttertoast.showToast(
        msg: "Failed to open payment gateway: ${e.toString()}",
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Timestamp ts = Timestamp.fromDate(widget.currentDate);
    // await FirebaseFirestore.instance
    //     .collection('users')
    //     .doc(_auth.currentUser!.uid)
    //     .update({'rechargeDate': ts, 'paymentID': response.paymentId});
    Fluttertoast.showToast(
      msg: "Payment Successful! \n Welcome to IRA",
      // msg: "Payment Successful! Thank You " + response.paymentId,
      toastLength: Toast.LENGTH_SHORT,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => HomeScreen()),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    String errorMessage = "Payment failed";

    try {
      // Handle the response more safely
      if (response.code != null) {
        errorMessage = "ERROR: ${response.code}";
        if (response.message != null && response.message!.isNotEmpty) {
          errorMessage += " - ${response.message}";
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
    Fluttertoast.showToast(
      msg: errorMessage,
      toastLength: Toast.LENGTH_SHORT,
      backgroundColor: Colors.red,
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    // Fluttertoast.showToast(
    //     msg: "EXTERNAL_WALLET: " + response.walletName,
    //     toastLength: Toast.LENGTH_SHORT);

    Fluttertoast.showToast(
      msg: "EXTERNAL_WALLET: Wallet Name",
      toastLength: Toast.LENGTH_SHORT,
    );
  }
}
