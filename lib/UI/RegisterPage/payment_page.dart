import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// DUMMY JUST TO SETUP NAVIGATION

class PaymentPage extends StatefulWidget {
  final bool isFirstPayment;
  final Function(int) onPayment;

  const PaymentPage({
    super.key,
    required this.isFirstPayment,
    required this.onPayment,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
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
  void initState() {
    super.initState();
    _initializePaymentCosts();
  }

  Future<void> _initializePaymentCosts() async {
    try {
      // Fetch payment costs from Firestore
      print("Inside initializePaymentCosts");
      final paymentCostSnapshot = await FirebaseFirestore.instance
          .collection('PaymentCost')
          .get();

      if (paymentCostSnapshot.docs.isNotEmpty) {
        // Create a map for faster lookup
        // final data = doc.data();
        final data = paymentCostSnapshot.docs[0].data();
        print("Payment Costs Data: ${data['1 Month']}");
        // Update subscription plans with fetched prices
        setState(() {
          for (int i = 0; i < subscriptionPlans.length; i++) {
            subscriptionPlans[i]['price'] =
                data['${subscriptionPlans[i]['duration']}'].toString();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFCB853),
        title: Text(
          widget.isFirstPayment ? 'Complete Payment' : 'Renew Subscription',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFCB853)),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCB853),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFCB853).withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 60,
                          color: Colors.black,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          widget.isFirstPayment
                              ? 'Choose Your Plan'
                              : 'Select Renewal Plan',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Unlock all premium features',
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Subscription Plans
                  Expanded(
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.85,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                      itemCount: subscriptionPlans.length,
                      itemBuilder: (context, index) {
                        final plan = subscriptionPlans[index];
                        final isSelected = selectedPlan == index;

                        return GestureDetector(
                          onTap: () => setState(() => selectedPlan = index),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFCB853)
                                  : Colors.grey[900],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFCB853)
                                    : Colors.grey[700]!,
                                width: 2,
                              ),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFFFCB853,
                                        ).withOpacity(0.3),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Stack(
                              children: [
                                if (plan['popular'])
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'POPULAR',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        plan['duration'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        plan['price'],
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: isSelected
                                              ? Colors.black
                                              : const Color(0xFFFCB853),
                                        ),
                                      ),
                                      if (plan['savings'] != null) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          plan['savings'],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isSelected
                                                ? Colors.black87
                                                : Colors.green,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Continue Button
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(top: 16),
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onPayment(
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
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 5,
                      ),
                      child: Text(
                        'Continue with ${subscriptionPlans[selectedPlan]['duration']} - ${subscriptionPlans[selectedPlan]['price']}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
