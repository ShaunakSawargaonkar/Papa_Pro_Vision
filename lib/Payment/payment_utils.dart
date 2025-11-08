import 'package:papa_pro_vision/enums.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentService {
  static List<Map<String, dynamic>> initialSubscriptionPlans = [
    {
      'duration': SubscriptionBundleType.oneMonth,
      'price': '₹299',
      'savings': null,
      'popular': false,
    },
    {
      'duration': SubscriptionBundleType.threeMonths,
      'price': '₹750',
      'savings': 'Save 16%',
      'popular': true,
    },
    {
      'duration': SubscriptionBundleType.sixMonths,
      'price': '₹1300',
      'savings': 'Save 28%',
      'popular': false,
    },
    {
      'duration': SubscriptionBundleType.oneYear,
      'price': '₹2300',
      'savings': 'Save 35%',
      'popular': false,
    },
  ];

  static Future<List<Map<String, dynamic>>> fetchPaymentCosts() async {
    print("Fetching payment costs from Firestore");
    List<Map<String, dynamic>> subscriptionPlans = initialSubscriptionPlans;
    final paymentCostSnapshot = await FirebaseFirestore.instance
        .collection('PaymentCost')
        .get();

    if (paymentCostSnapshot.docs.isNotEmpty) {
      final data = paymentCostSnapshot.docs[0].data();
      print("Payment Costs Data: $data");

      // Update subscription plans with fetched prices
      for (int i = 0; i < subscriptionPlans.length; i++) {
        final duration = subscriptionPlans[i]['duration'] as SubscriptionBundleType;
        final durationStr = duration.toString();
        if (data.containsKey(durationStr)) {
          subscriptionPlans[i]['price'] = '₹${data[durationStr]}';
        }
      }
      // Recalculate savings after updating prices
      subscriptionPlans = _calculateSavings(subscriptionPlans);
    }
    return subscriptionPlans;
  }
}

List<Map<String, dynamic>> _calculateSavings(List<Map<String, dynamic>> subscriptionPlans) {
  // Get monthly price for calculation
  final monthlyPriceStr =
      subscriptionPlans[0]['price']?.replaceAll(RegExp(r'[^\d]'), '') ?? '299';
  final monthlyPrice = int.tryParse(monthlyPriceStr) ?? 299;

  for (int i = 1; i < subscriptionPlans.length; i++) {
    final currentPriceStr =
        subscriptionPlans[i]['price']?.replaceAll(RegExp(r'[^\d]'), '') ?? '0';
    final currentPrice = int.tryParse(currentPriceStr) ?? 0;

    int months;
    switch (subscriptionPlans[i]['duration']) {
      case SubscriptionBundleType.threeMonths:
        months = 3;
        break;
      case SubscriptionBundleType.sixMonths:
        months = 6;
        break;
      case SubscriptionBundleType.oneYear:
        months = 12;
        break;
      case SubscriptionBundleType.oneMonth:
        months = 1;
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
  return subscriptionPlans;
}
