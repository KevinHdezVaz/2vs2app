// lib/services/wallet_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:Frutia/model/Wallet.dart';
import 'package:Frutia/services/storage_service.dart';
import 'package:Frutia/utils/constantes.dart';
 
class WalletService {
  final StorageService storage = StorageService();
  
   WalletService();
  
  Future<Wallet> getWallet() async {
    final token = await storage.getToken();
    final response = await http.get(
      Uri.parse('$baseUrl/wallet'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return Wallet.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Error al cargar el monedero: ${response.body}');
    }
  }
  
  Future<void> addReferralPoints(String referralCode) async {
    final token = await storage.getToken();
    final response = await http.post(
      Uri.parse('$baseUrl/wallet/referral'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'referral_code': referralCode}),
    );
    if (response.statusCode != 200) {
      throw Exception('Error al agregar puntos: ${response.body}');
    }
  }
}