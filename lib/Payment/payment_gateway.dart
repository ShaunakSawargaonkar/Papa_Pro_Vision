// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:papa_pro_vision/UI/home_screen.dart';
// import 'package:papa_pro_vision/UI/RegisterPage/registration_page.dart';
// import 'package:razorpay_flutter/razorpay_flutter.dart';

// import 'package:fluttertoast/fluttertoast.dart';

// class PaymentGateway extends StatefulWidget {
//   DateTime currentDate;
//   String email;
//   String mobileNo;
//   String userName;

//   PaymentGateway({
//     required this.currentDate,
//     required this.email,
//     required this.mobileNo,
//     required this.userName,
//   });
//   @override
//   _PaymentGatewayState createState() => _PaymentGatewayState();
// }

// class _PaymentGatewayState extends State<PaymentGateway> {
//   late Razorpay _razorpay;

//   @override
//   Widget build(BuildContext context) {
//     var height = MediaQuery.of(context).size.height;
//     var width = MediaQuery.of(context).size.width;

//     return Scaffold(
//       appBar: AppBar(
//         title: Text(
//           "Let See - Subscription",
//           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
//         ),
//         centerTitle: true,
//       ),
//       backgroundColor: Colors.black,
//       body: Padding(
//         padding: EdgeInsets.all(height * 0.02),
//         child: ListView(
//           //crossAxisAlignment: CrossAxisAlignment.center,
//           children: [
//             Center(
//               child: CircleAvatar(
//                 backgroundImage: AssetImage('assets/logo_color.png'),
//                 radius: height * 0.11,
//                 backgroundColor: Colors.white,
//               ),
//             ),
//             SizedBox(height: height * 0.02),
//             Center(
//               child: Text(
//                 "Together We See",
//                 style: TextStyle(
//                   fontWeight: FontWeight.bold,
//                   fontSize: height * 0.03,
//                   color: Color(0xff2e91a0),
//                 ),
//               ),
//             ),
//             SizedBox(height: height * 0.05),
//             Center(
//               // TODO make it look appeleaing
//               child: Text(
//                 "Hey ${widget.userName},\n\n"
//                 "Perks of Subscribing* - \n"
//                 "\t >	Latest AI Models\n"
//                 "\t >	You speak and we see\n"
//                 "\t >	One stop to stop your dependancy\n",
//                 // "Of all divisions at one place ",
//                 style: TextStyle(fontSize: height * 0.024, color: Colors.white),
//               ),
//             ),
//             SizedBox(height: height * 0.03),
//             Center(
//               child: Column(
//                 children: [
//                   ElevatedButton(
//                     child: Text("Pay ₹100/-"),
//                     style: ElevatedButton.styleFrom(),
//                     onPressed: () {
//                       openCheckout(100);
//                     },
//                   ),
//                   SizedBox(height: height * 0.005),
//                   IconButton(
//                     icon: Icon(Icons.logout, color: Color(0xff2e91a0)),
//                     onPressed: () {
//                       showDialog(
//                         context: context,
//                         builder: (ctx) {
//                           return AlertDialog(
//                             content: Text(
//                               "Are you sure you want to go to registration Page?",
//                             ),
//                             actions: [
//                               TextButton(
//                                 onPressed: () => Navigator.pop(ctx),
//                                 child: Text("No"),
//                               ),
//                               TextButton(
//                                 onPressed: () async {
//                                   await FirebaseAuth.instance.signOut();

//                                   Navigator.pop(ctx);
//                                   Navigator.pushReplacement(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder: (c) => RegistrationPage(),
//                                     ),
//                                   );
//                                 },
//                                 child: Text("Yes"),
//                               ),
//                             ],
//                           );
//                         },
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   void initState() {
//     super.initState();
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
//   }

//   @override
//   void dispose() {
//     super.dispose();
//     _razorpay.clear();
//   }

//   void openCheckout(int price) async {
//     var options = {
//       'key': 'rzp_test_RaTx04PCOjFncj',
//       'amount': price,
//       'name': 'Let See',
//       'description': 'Monthly Subscription',
//       'prefill': {'contact': "7796264225", 'email': "Test@mail.com"},
//       'external': {
//         'wallets': ['paytm'],
//       },
//     };

//     try {
//       _razorpay.open(options);
//     } catch (e) {}
//   }

//   void _handlePaymentSuccess(PaymentSuccessResponse response) async {
//     // Timestamp ts = Timestamp.fromDate(widget.currentDate);
//     // await FirebaseFirestore.instance
//     //     .collection('users')
//     //     .doc(_auth.currentUser!.uid)
//     //     .update({'rechargeDate': ts, 'paymentID': response.paymentId});
//     print("Payment Success!!!!!");
//     Fluttertoast.showToast(
//       msg: "Payment Successful! \n Welcome to LetSee",
//       backgroundColor: Colors.green,
//       toastLength: Toast.LENGTH_SHORT,
//     );
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(builder: (context) => HomeScreen()),
//     );
//   }

//   void _handlePaymentError(PaymentFailureResponse response) {
//     //Have a look
//     // var message,walletName;
//     // Object responseHere=response ?? {message:"hi",walletName:"Yo"};

//     Fluttertoast.showToast(
//       msg: "ERROR: " + response.code.toString() + " - Message",
//       toastLength: Toast.LENGTH_SHORT,
//     );

//     // Fluttertoast.showToast(
//     //     msg: "ERROR: " + response.code.toString() + " - " + response.message,
//     //     toastLength: Toast.LENGTH_SHORT);
//   }

//   void _handleExternalWallet(ExternalWalletResponse response) {
//     // Fluttertoast.showToast(
//     //     msg: "EXTERNAL_WALLET: " + response.walletName,
//     //     toastLength: Toast.LENGTH_SHORT);

//     Fluttertoast.showToast(
//       msg: "EXTERNAL_WALLET: Wallet Name",
//       toastLength: Toast.LENGTH_SHORT,
//     );
//   }
// }
