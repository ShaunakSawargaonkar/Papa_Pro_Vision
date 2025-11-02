import 'package:flutter/material.dart';

// DUMMY JUST TO SETUP NAVIGATION

class PaymentPage extends StatelessWidget {
  final bool isFirstPayment;
  
  const PaymentPage({
    super.key,
    required this.isFirstPayment,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCB853),
        title: Text(
          isFirstPayment ? 'Complete Payment' : 'Renew Subscription',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCB853),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFCB853).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.payment_rounded,
                      size: 80,
                      color: Colors.black,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isFirstPayment 
                          ? 'Welcome to Papa ProVision!' 
                          : 'Renew Your Subscription',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isFirstPayment
                          ? 'Complete your payment to start using all features'
                          : 'Your subscription has expired. Renew to continue using Papa ProVision',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                'Payment integration coming soon...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

