import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerListViewPage extends StatefulWidget {
  const BarcodeScannerListViewPage({super.key});

  @override
  State<BarcodeScannerListViewPage> createState() =>
      _BarcodeScannerListViewPageState();
}

class _BarcodeScannerListViewPageState
    extends State<BarcodeScannerListViewPage> {
  Barcode? _barcode;
  List<String> scannedBarcodes = []; // Okunan kodları tutmak için bir liste

  // QR kodu sonucu gösteren widget
  Widget _buildBarcodeResult(Barcode? value) {
    if (value == null) {
      return const Text(
        'Tara bacım!',
        style: TextStyle(color: Colors.white),
      );
    }
    return Text(
      value.displayValue ?? 'Kör oldum aşkım, değer yok',
      style: const TextStyle(color: Colors.deepPurple),
    );
  }

  // QR kod taraması algılayıcı
  void _onBarcodeDetect(BarcodeCapture barcodes) {
    if (barcodes.barcodes.isNotEmpty) {
      setState(() {
        _barcode = barcodes.barcodes.first;
        // Eğer değer varsa, listeye ekle
        if (_barcode?.displayValue != null) {
          scannedBarcodes
              .add(_barcode!.displayValue!); // Okunan değeri listeye ekliyoruz
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Simple Scanner'),
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _onBarcodeDetect,
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              color: Colors.black54,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildBarcodeResult(_barcode),
                  const SizedBox(height: 10),
                  const Text(
                    'Okunan kodlar:',
                    style: TextStyle(color: Colors.white),
                  ),
                  // Tüm okunan kodları göster
                  for (var code in scannedBarcodes)
                    Text(
                      code,
                      style: const TextStyle(color: Colors.green),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
