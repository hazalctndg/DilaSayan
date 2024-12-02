import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppointmentDetailPage extends StatefulWidget {
  final Color backgroundColor;
  final String rid;

  const AppointmentDetailPage({
    super.key,
    required this.backgroundColor,
    required this.rid,
  });

  @override
  _AppointmentDetailPageState createState() => _AppointmentDetailPageState();
}

class _AppointmentDetailPageState extends State<AppointmentDetailPage> {
  Map<String, dynamic>? appointmentDetails;
  bool isLoading = true;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _fetchAppointmentDetails();
  }

  Future<void> _fetchAppointmentDetails() async {
    final url = Uri.parse('https://dndyazilim.com.tr/hzl/generalapi.php');

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('storedToken');
    final storedUsername = prefs.getString('storedUsername');

    if (token == null) return;

    Map<String, dynamic> usermap = {
      "username": storedUsername,
      "token": token,
      "rid": widget.rid
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Access-Control-Allow-Origin': '*',
          'Access-Control-Allow-Credentials': 'true',
          'Access-Control-Allow-Methods': 'GET,HEAD,OPTIONS,POST,PUT',
          'Access-Control-Allow-Headers':
              'Origin, X-Requested-With, Content-Type, Accept',
        },
        body: jsonEncode({
          'paramhost': "dnd.1cdrive-tr.com",
          'paramurl': "/DILASAYAN/hs/personeltakip/randevubilgisi",
          'userdata': usermap,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['Durum'] == true) {
          setState(() {
            appointmentDetails = data;
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage = "Randevu detayları alınamadı.";
          isLoading = false;
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Bir hata oluştu: $error";
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Randevu Detayları"),
        backgroundColor: Colors.deepPurple,
      ),
      body: Container(
        color: widget.backgroundColor,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : appointmentDetails != null
                ? Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Card(
                      color: widget.backgroundColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                      elevation: 0, // Set to 0 for seamless background
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Müşteri: ${appointmentDetails!['Musteri']}",
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.deepPurple,
                              ),
                            ),
                            const SizedBox(height: 8.0),
                            _buildDetailRow(
                                "Telefon", appointmentDetails!['Telefon']),
                            _buildDetailRow(
                                "Bakiye", appointmentDetails!['Bakiye']),
                            _buildDetailRow(
                                "Hizmet", appointmentDetails!['Hizmet']),
                            _buildDetailRow(
                                "Başlangıç", appointmentDetails!['Baslangic']),
                            _buildDetailRow(
                                "Bitiş", appointmentDetails!['Bitis']),
                            const SizedBox(height: 20),
                            Center(
                              child: Lottie.asset(
                                'assets/images/randevu.json',
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          Text(value),
        ],
      ),
    );
  }
}
