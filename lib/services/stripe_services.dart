import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/stripe_config.dart';


class StripeServices {

  static const Map<String, String> _testTokens = {

    '1212121212121212' : 'tok_visa',
    '3434343434343434' : 'tok_visa_debit',
    '5656565656565656' : 'tok_mastercard',
    '7878787878787878' : 'tok_mastercard_debit',
    '9090909090909090' : 'tok_chargeDeclined',
    '2323232323232323' : 'tok_chargeDeclineInsufficientFunds',
  };


  static Future<Map<String, dynamic>> processPayment ({
    required double amount,
    required String cardNumber,
    required String expMonth,
    required String expYear,
    required String cvc,
  }) async {
    final amountInCentavos = (amount * 100).round().toString();
    final cleanCard = cardNumber.replaceAll('', '');
    final token = _testTokens[cleanCard];

    if (token == null) {
      return <String, dynamic> {
        'success' : false,
        'error' : 'unknown test card'
      };

    }

    try {

      final response = await http.post(
          Uri.parse('${StripeConfig.apiUrl}/payment_intents'),
          headers: <String, String> {
            'Authorization' : 'Bearer ${StripeConfig.secretKey}',
            'Content-Type' : 'application/x-www-form-urlencoded',
          },
          body: <String, String> {
            'amount' : amountInCentavos,
            'currency' : 'php',
            'payment_method_types[]' : 'card',
            'payment_method_data[type]' : 'card',
            'payment_method_data[card][token]' : token,
            'confirm' : 'true',
          }
      );

      final data = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode == 200 && data['status'] == 'succeeded') {
        final paidAmount = (data['amount'] as num) / 100;
        return <String, dynamic> {
          'success' : true,
          'id' : data['id'].toString(),
          'amount' : paidAmount,
          'status' : data['status'].toString(),
        };
      } else {
        final errorMsg = data['error'] is Map
            ? (data['error'] as Map)['message']?.toString() ?? 'payment failed'
            : 'payment failed';
        return <String, dynamic> {
          'success' : false,
          'error' : errorMsg,
        };
      }

    } catch (e) {
      return<String, dynamic> {
        'success' : false,
        'error' : e.toString(),
      };
    }
  }
}