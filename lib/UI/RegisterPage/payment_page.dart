import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    {
      'duration': '1 Month',
      'price': '₹299',
      'originalPrice': null,
      'savings': null,
      'popular': false,
    },
    {
      'duration': '3 Months',
      'price': '₹750',
      'originalPrice': null,
      'savings': 'Save 16%',
      'popular': true,
    },
    {
      'duration': '6 Months',
      'price': '₹1300',
      'originalPrice': null,
      'savings': 'Save 28%',
      'popular': false,
    },
    {
      'duration': '1 Year',
      'price': '₹2300',
      'originalPrice': null,
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
            final originalPrice = data['${subscriptionPlans[i]['duration']}']
                .toString();
            subscriptionPlans[i]['originalPrice'] = originalPrice;

            if (widget.isFirstPayment &&
                subscriptionPlans[i]['duration'] == '1 Month') {
              subscriptionPlans[i]['price'] = '₹1';
            } else {
              subscriptionPlans[i]['price'] = originalPrice;
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

  Widget _buildPlanCard(
    int index,
    double screenWidth,
    double screenHeight,
    bool isTablet,
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
                      fontSize: isTablet
                          ? 12
                          : (screenWidth * 0.025).clamp(
                              8.0,
                              12.0,
                            ), // Dynamic font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            if (widget.isFirstPayment && plan['duration'] == '1 Month')
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
                      fontSize: isTablet
                          ? 12
                          : (screenWidth * 0.025).clamp(
                              8.0,
                              12.0,
                            ), // Dynamic font size
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(screenWidth * 0.04), // 4% of screen width
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    plan['duration'],
                    style: TextStyle(
                      fontSize: isTablet
                          ? 18
                          : (screenWidth * 0.04).clamp(
                              14.0,
                              18.0,
                            ), // Dynamic font size
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(
                    height: screenHeight * 0.015,
                  ), // 1.5% of screen height
                  // Show slashed original price for first month free
                  if (widget.isFirstPayment &&
                      plan['duration'] == '1 Month' &&
                      plan['originalPrice'] != null) ...[
                    Text(
                      plan['originalPrice'],
                      style: TextStyle(
                        fontSize: isTablet
                            ? 20
                            : (screenWidth * 0.045).clamp(
                                16.0,
                                20.0,
                              ), // Dynamic font size
                        fontWeight: FontWeight.w500,
                        color: isSelected ? Colors.white70 : Colors.grey[600],
                        decoration: TextDecoration.lineThrough,
                        decorationThickness: 2,
                      ),
                    ),
                    SizedBox(
                      height: screenHeight * 0.005,
                    ), // 0.5% of screen height
                  ],
                  Text(
                    plan['price'],
                    style: TextStyle(
                      fontSize: isTablet
                          ? 28
                          : (screenWidth * 0.06).clamp(
                              20.0,
                              28.0,
                            ), // Dynamic font size
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
                        fontSize: isTablet
                            ? 14
                            : (screenWidth * 0.03).clamp(
                                10.0,
                                14.0,
                              ), // Dynamic font size
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white70 : Colors.green,
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
        title: Text(
          widget.isFirstPayment ? 'Complete Payment' : 'Renew Subscription',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: isTablet ? 20 : 18,
          ),
          semanticsLabel: 'Payment Page',
        ),
        centerTitle: true,
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
                                  ? 'Choose Your Plan'
                                  : 'Select Renewal Plan',
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
                            'Continue with ${subscriptionPlans[selectedPlan]['duration']} - ${subscriptionPlans[selectedPlan]['price']}',
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
