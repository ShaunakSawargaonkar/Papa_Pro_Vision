import 'package:flutter/material.dart';
import 'package:papa_pro_vision/UI/RegisterPage/registration_page.dart';
import 'package:papa_pro_vision/UI/home_Screen.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import 'package:fluttertoast/fluttertoast.dart';

class PaymentGateway extends StatefulWidget {
  final DateTime currentDate;
  final String email;
  final String mobileNo;
  final String userName;

  const PaymentGateway({
    super.key,
    required this.currentDate,
    required this.email,
    required this.mobileNo,
    required this.userName,
  });

  @override
  _PaymentGatewayState createState() => _PaymentGatewayState();
}

class _PaymentGatewayState extends State<PaymentGateway> {
  late Razorpay _razorpay;

  @override
  Widget build(BuildContext context) {
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "PICTIRA - Subscription",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        centerTitle: true,
      ),
      backgroundColor: Color(0xfff2f3f7),
      body: Padding(
        padding: EdgeInsets.all(height * 0.02),
        child: ListView(
          //crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Center(
              child: CircleAvatar(
                backgroundImage: AssetImage('images/pictira.png'),
                radius: height * 0.11,
                backgroundColor: Colors.black12,
              ),
            ),
            SizedBox(height: height * 0.02),
            Center(
              child: Text(
                "Together We Studyy",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: height * 0.03,
                  color: Color(0xff2e91a0),
                ),
              ),
            ),
            SizedBox(height: height * 0.05),
            Center(
              // TODO make it look appeleaing
              child: Text(
                "Hey ${widget.userName},\n\n"
                "Perks of Subscribing* - \n"
                "\t >	Textbooks & Reference Books\n"
                "\t >	Study Notes\n"
                "\t >	Previous Question Papers and MCQs\n"
                "\t >	Placement Resources and alumni connect portal\n",
                // "Of all divisions at one place ",
                style: TextStyle(
                  fontSize: height * 0.025,
                  color: Color(0xff31394c),
                ),
              ),
            ),
            SizedBox(height: height * 0.007),
            Text(
              "*Contents are subject to availability",
              style: TextStyle(fontSize: height * 0.02, color: Colors.black),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: height * 0.03),
            Center(
              // child: ElevatedButton(
              //     onPressed: openCheckout,
              //     child: Text("Pay ₹9/-")
              // )
              child: Column(
                children: [
                  ElevatedButton(
                    child: Text("Pay ₹100/-"),
                    onPressed: () {
                      openCheckout(100);
                    },
                  ),
                  SizedBox(height: height * 0.005),
                  IconButton(
                    icon: Icon(Icons.logout, color: Color(0xff2e91a0)),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (ctx) {
                          return AlertDialog(
                            content: Text("Are you sure you want to logout?"),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text("No"),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  // while(Navigator.canPop(context)){ // Navigator.canPop return true if can pop
                                  //   Navigator.pop(context);
                                  // }
                                  //Navigator.popUntil(context, (Route<dynamic> route) => route.isFirst);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (c) => RegistrationPage(),
                                    ),
                                  );
                                },
                                child: Text("Yes"),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
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
      'name': 'PICTIRA',
      'description': 'Monthly Subscription',
      'timeout': 300, // 5 minutes timeout
      'prefill': <String, String>{
        'contact': widget.mobileNo,
        'email': widget.email,
      },
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
