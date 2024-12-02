import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart'; // Ana sayfa için varsayılan bir sayfa ekledik
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr', null);

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('storedToken');
  final storedUsername = prefs.getString('storedUsername');

  runApp(MyApp(storedUsername: storedUsername, token: token));
}

class MyApp extends StatelessWidget {
  final dynamic storedUsername;
  final dynamic token;

  const MyApp({super.key, this.storedUsername, this.token});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Expert Login',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        primaryColor: Colors.blue,
      ),
      debugShowCheckedModeBanner: false,
      home: token != null ? const HomePage() : const LoginPage(),
    );
  }
}

Future<void> fetchData() async {
  final url =
      Uri.parse('https://dnd.1cdrive-tr.com/DILASAYAN/hs/personeltakip/signin');
  final response = await http.post(
    url,
    headers: {
      'Authorization':
          'Basic ${base64Encode(utf8.encode('administrator:dnd2396'))}',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Credentials': 'true',
      'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS,POST,PUT',
      'Access-Control-Allow-Headers':
          'Origin, X-Requested-With, Content-Type, Accept',
    },
    body:
        jsonEncode({'username': 'your_username', 'password': 'your_password'}),
  );

  if (response.statusCode == 200) {
    print("Başarıyla veri alındı: ${response.body}");
  } else {
    print("Veri alınamadı. Hata: ${response.statusCode}");
  }
}
