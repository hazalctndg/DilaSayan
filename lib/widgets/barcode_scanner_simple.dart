import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '/home_page.dart';

class BarcodeScannerSimplePage extends StatefulWidget {
  const BarcodeScannerSimplePage({super.key});

  @override
  State<BarcodeScannerSimplePage> createState() =>
      _BarcodeScannerSimplePageState();
}

class _BarcodeScannerSimplePageState extends State<BarcodeScannerSimplePage> {
  final MobileScannerController cameraController = MobileScannerController();
  Barcode? _barcode;
  bool isScanned = false;
  bool isScanning = true;

  String? token;
  String? uzman;
  String? subeKodu;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      token = prefs.getString('storedToken');
      uzman = prefs.getString('storedUsername');
      subeKodu = prefs.getString('storedSubeKodu') ?? "000000002";
    });
  }

  Future<void> sendDataToServer(String barcodeData) async {
    final url = Uri.parse(
        'https://dnd.1cdrive-tr.com/DILASAYAN/hs/personeltakip/yoklama');

    if (token == null || uzman == null || subeKodu == null) {
      print("Token, uzman veya şube kodu bilgisi bulunamadı.");
      return;
    }

    // Barcode data split logic
    List<String> parts = barcodeData.split(';');
    if (parts.length < 2) {
      print("Geçersiz QR kod verisi formatı.");
      return;
    }

    String yoklamaID = parts[0];

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization':
              'Basic ${base64Encode(utf8.encode('administrator:dnd2396'))}',
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
          'Access-Control-Allow-Headers': 'Content-Type, Authorization'
        },
        body: jsonEncode({
          'username': uzman,
          'subekodu': subeKodu,
          'yoklamaID': yoklamaID,
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        print("Veri başarıyla gönderildi.");
      } else {
        print("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      print("Bağlantı hatası: $e");
    }
  }

  void _handleBarcode(BarcodeCapture barcodes) {
    if (mounted && barcodes.barcodes.isNotEmpty) {
      setState(() {
        _barcode = barcodes.barcodes.firstOrNull;
        isScanned = true;
        isScanning = false;
      });

      cameraController.stop();

      if (_barcode?.rawValue != null) {
        sendDataToServer(_barcode!.rawValue!).then((_) {
          Future.delayed(const Duration(seconds: 1), () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => const HomePage()),
            );
          });
        });
      }
    }
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Uzman Giriş-Çıkış'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: cameraController,
            onDetect: _handleBarcode,
          ),
          Positioned.fill(
            child: Stack(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.5),
                ),
                Center(
                  child: Container(
                    width: 250,
                    height: 250,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isScanned ? Colors.green : Colors.red,
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Center(
                  child: ClipPath(
                    clipper: _InverseClipper(),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        color: Colors.black.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: isScanning
                      ? const Text(
                          "Lütfen bekleyin...",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : Text(
                          " ${_barcode?.rawValue}",
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InverseClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path()
      ..addRect(Rect.fromLTRB(0, 0, size.width, size.height))
      ..addRect(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: 250,
        height: 250,
      ))
      ..fillType = PathFillType.evenOdd;
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
