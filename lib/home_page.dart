
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  String _extractedText = '';
  final picker = ImagePicker();

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() => _image = File(picked.path));
      await recognizeText(_image!);
    }
  }

  Future<void> recognizeText(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final visionText = await textRecognizer.processImage(inputImage);
    _extractedText = visionText.text;
    textRecognizer.close();
    setState(() {});
    await parseAndSave(_extractedText);
  }

  Future<void> parseAndSave(String rawText) async {
    String nombre = RegExp(r'Nombre[: ]*(.*)')
            .firstMatch(rawText)?.group(1)?.trim() ?? 'Desconocido';
    String categoria = RegExp(r'Categoria[: ]*(.*)')
            .firstMatch(rawText)?.group(1)?.trim() ?? 'SinCategoria';
    String piso = RegExp(r'Piso[: ]*([\d.]+)')
            .firstMatch(rawText)?.group(1)?.trim() ?? '0.0';

    final data = {
      'nombre': nombre,
      'categoria': categoria,
      'piso': double.tryParse(piso) ?? 0.0,
      'rawText': rawText,
      'timestamp': FieldValue.serverTimestamp(),
    };

    final docId = '\${nombre}_\${categoria}';
    await FirebaseFirestore.instance
        .collection('resultados')
        .doc(docId)
        .set(data);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Datos guardados: \$nombre (\$categoria)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('HP Gym OCR')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover),
            SizedBox(height: 10),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Tomar Imagen'),
              onPressed: pickImage,
            ),
            SizedBox(height: 20),
            Expanded(
              child: SingleChildScrollView(
                child: Text(_extractedText.isEmpty
                    ? 'No se ha extraído texto'
                    : _extractedText),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
