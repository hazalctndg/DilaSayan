import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String? username;
  String? password;
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;

  Future<void> _login() async {
    final url = Uri.parse('https://dndyazilim.com.tr/hzl/generalapi.php');

    setState(() {
      isLoading = true;
    });

    Map<String, dynamic> usermap = {"username": username, "password": password};

    try {
      final response = await http.post(url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'paramhost': "dnd.1cdrive-tr.com",
            'paramurl': "/DILASAYAN/hs/personeltakip/signin",
            'userdata': usermap
          }));

      print("Yanıt Başlıkları: ${response.headers}");
      print("Yanıt Gövdesi: ${response.body}");

      if (response.body.isEmpty) {
        _showErrorDialog("Sunucudan boş bir yanıt alındı.");
        return;
      }

      try {
        final data = jsonDecode(response.body);

        if (data['Durum'] == true) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('storedUsername', username!);
          await prefs.setString('storedToken', data['Token']);
          await prefs.setString('storedUzman', data['Uzman']);

          if (!mounted) return;

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => const HomePage()),
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Giriş Başarılı")),
          );
        } else {
          _showErrorDialog("Giriş başarısız: ${data['Hata']}");
        }
      } catch (e) {
        _showErrorDialog("Beklenmeyen veri formatı veya JSON hatası: $e");
      }
    } catch (error) {
      _showErrorDialog("Sunucuya bağlanırken bir hata oluştu: $error");
    }

    setState(() {
      isLoading = false;
    });
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hata'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: const Text('Tamam'),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF6A0572),
                  Color(0xFFAA3AB4),
                ],
              ),
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/images/signin_balls.png',
              fit: BoxFit.cover,
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.only(top: screenHeight * 0.25),
              child: Center(
                child: Column(
                  children: [
                    const Text(
                      'Giriş',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 30,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: <Widget>[
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.1),
                                labelText: "Kullanıcı Adı",
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                prefixIcon: Icon(Icons.person,
                                    size: screenHeight * 0.04),
                              ),
                              style: const TextStyle(color: Colors.black),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Kullanıcı adınızı giriniz";
                                }
                                return null;
                              },
                              onSaved: (value) {
                                username = value;
                              },
                            ),
                            const SizedBox(height: 15),
                            TextFormField(
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: Colors.black.withOpacity(0.1),
                                labelText: "Şifre",
                                labelStyle: const TextStyle(
                                  color: Colors.black,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10.0),
                                ),
                                prefixIcon:
                                    Icon(Icons.lock, size: screenHeight * 0.04),
                              ),
                              style: const TextStyle(color: Colors.black),
                              obscureText: true,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Şifre giriniz";
                                }
                                return null;
                              },
                              onSaved: (value) {
                                password = value;
                              },
                            ),
                            const SizedBox(height: 20),
                            isLoading
                                ? const CircularProgressIndicator()
                                : SizedBox(
                                    width: screenWidth * 0.8,
                                    child: ElevatedButton(
                                      onPressed: () {
                                        if (_formKey.currentState!.validate()) {
                                          _formKey.currentState!.save();
                                          _login();
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: EdgeInsets.symmetric(
                                            vertical: screenHeight * 0.02),
                                        backgroundColor:
                                            const Color(0xFFAA3AB4),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                      child: Text(
                                        'Giriş!',
                                        style: TextStyle(
                                          fontSize: screenHeight * 0.025,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            SizedBox(height: screenHeight * 0.1),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
