import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hidden_drawer_menu/hidden_drawer_menu.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'appointment_detail_page.dart';
import 'login_page.dart';
import 'widgets/barcode_scanner_simple.dart';

void main() {
  initializeDateFormatting('tr', null).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('tr', 'TR'),
      supportedLocales: const [
        Locale('tr', 'TR'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Randevu Takvimi',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(0xFFEDE7F6),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String expertName = "Uzman Adı";
  List<dynamic> appointments = [];
  DateTime selectedDate = DateTime.now();
  bool isLoading = false;
  String errorMessage = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    _fetchAppointments(selectedDate);
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      expertName = prefs.getString('storedUzman') ?? "Uzman Adı";
    });
  }

  Future<void> _fetchAppointments(DateTime date) async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('storedToken');
    final storedUsername = prefs.getString('storedUsername');

    if (token == null) return;

    Map<String, dynamic> usermap = {
      "username": storedUsername,
      "token": token,
      "tarih": DateFormat('dd.MM.yyyy').format(date)
    };

    final url = Uri.parse('https://dndyazilim.com.tr/hzl/generalapi.php');
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
          'paramurl': "/DILASAYAN/hs/personeltakip/calender",
          'userdata': usermap,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        if (data['Durum'] == true) {
          setState(() {
            appointments = data['Randevular'] ?? [];
            if (appointments.isEmpty) {
              errorMessage = "Randevu bulunamadı.";
            }
          });
        }
      } else {
        setState(() {
          errorMessage = "Randevu bulunamadı.";
        });
      }
    } catch (error) {
      setState(() {
        errorMessage = "Randevu bulunamadı.";
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Material(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    DateFormat.yMMMM('tr').format(selectedDate),
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                  onDateChanged: (DateTime pickedDate) {
                    setState(() {
                      selectedDate = pickedDate;
                      Navigator.pop(context);
                      _fetchAppointments(selectedDate);
                    });
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return HiddenDrawerMenu(
      backgroundColorMenu: const Color(0xFFB2A69C),
      slidePercent: 50,
      initPositionSelected: 1,
      screens: [
        ScreenHiddenDrawer(
          ItemHiddenMenu(
            name: 'Ana Sayfa',
            baseStyle: const TextStyle(color: Colors.transparent),
            selectedStyle: const TextStyle(color: Colors.transparent),
          ),
          Scaffold(
            body: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 80,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Görsel yüklenemedi');
                    },
                  ),
                ),
                const Divider(color: Colors.white24),
              ],
            ),
          ),
        ),
        ScreenHiddenDrawer(
          ItemHiddenMenu(
            name: 'Randevu Listesi',
            baseStyle: const TextStyle(
                color: Colors.white, fontStyle: FontStyle.italic),
            selectedStyle: const TextStyle(color: Colors.black87),
          ),
          Scaffold(
            appBar: AppBar(
              title: Text(expertName,
                  style: const TextStyle(
                      color: Colors.white, fontStyle: FontStyle.italic)),
              backgroundColor: const Color(0xFFB2A69C),
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_today, color: Colors.white),
                  onPressed: () => _selectDate(context),
                ),
              ],
            ),
            backgroundColor: const Color(0xFFEDE7F6),
            body: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  color: Colors.black12,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDate =
                                selectedDate.subtract(const Duration(days: 1));
                            _fetchAppointments(selectedDate);
                          });
                        },
                        child: const Text('Geri'),
                      ),
                      Text(
                        DateFormat('dd.MM.yyyy').format(selectedDate),
                        style:
                            const TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            selectedDate = selectedDate.add(const Duration(days: 1));
                            _fetchAppointments(selectedDate);
                          });
                        },
                        child: const Text('İleri'),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (errorMessage.isNotEmpty)
                  Center(
                      child: Text(errorMessage,
                          style: const TextStyle(color: Colors.red)))
                else
                  Expanded(
                    child: appointments.isEmpty
                        ? const Center(
                            child: Text(
                              "Randevu bilgisi alınamadı.",
                              style: TextStyle(color: Colors.red),
                            ),
                          )
                        : ListView.builder(
                            itemCount: appointments.length,
                            itemBuilder: (context, index) {
                              final appointment = appointments[index];
                              Color appointmentColor = Color(
                                  (0xFFE1BEE7 + index * 100) % 0xFFFFFFFF);
                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 5.0),
                                decoration: BoxDecoration(
                                  color: appointmentColor,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: ListTile(
                                  title: Text(
                                    "${appointment['Customer']}",
                                    style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "${appointment['Service']} (${appointment['StartDate']} - ${appointment['FinishDate']})",
                                    style:
                                        const TextStyle(color: Colors.black54),
                                  ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            AppointmentDetailPage(
                                          rid: appointment['Rid'],
                                          backgroundColor: appointmentColor,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                  ),
              ],
            ),
          ),
        ),
        ScreenHiddenDrawer(
          ItemHiddenMenu(
            name: 'Yoklama',
            baseStyle: const TextStyle(
                color: Colors.white, fontStyle: FontStyle.italic),
            selectedStyle: const TextStyle(color: Colors.black87),
          ),
          const BarcodeScannerSimplePage(),
        ),
        ScreenHiddenDrawer(
          ItemHiddenMenu(
            name: 'Çıkış Yap',
            baseStyle: const TextStyle(
                color: Colors.white, fontStyle: FontStyle.italic),
            selectedStyle: const TextStyle(color: Colors.black87),
          ),
          Builder(
            builder: (context) {
              _logout();
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}
