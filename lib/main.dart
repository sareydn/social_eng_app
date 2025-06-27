import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:docx_to_text/docx_to_text.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math';
import 'dart:developer' as log;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Document Analyzer',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DocumentAnalyzerPage(),
    );
  }
}

class DocumentAnalyzerPage extends StatefulWidget {
  @override
  _DocumentAnalyzerPageState createState() => _DocumentAnalyzerPageState();
}

class _DocumentAnalyzerPageState extends State<DocumentAnalyzerPage> {
  String? _selectedFileName;
  String? _documentContent;
  String? _aiResponse;
  bool _isLoading = false;
  String? _systemPrompt;
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadSystemPrompt();
  }

  // System prompt'u assets'dan yükle
  Future<void> _loadSystemPrompt() async {
    try {
      log.log('Attempting to load system prompt...');
      final String promptContent =
          await rootBundle.loadString('assets/prompts/prompts.txt');
      log.log(
          'Successfully loaded prompt content: ${promptContent.substring(0, min(50, promptContent.length))}...');
      setState(() {
        _systemPrompt = promptContent;
      });
    } catch (e, stackTrace) {
      log.log('System prompt yüklenirken hata: $e');
      log.log('Stack trace: $stackTrace');
      _systemPrompt =
          'Lütfen belgeyi analiz edin ve özetleyin.'; // Varsayılan prompt
    }
  }

  // Dosya seçme fonksiyonu
  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'docx'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _isLoading = true;
        });

        String filePath = result.files.single.path!;
        String extension = result.files.single.extension?.toLowerCase() ?? '';

        String content = '';

        if (extension == 'pdf') {
          content = await _extractPdfText(filePath);
        } else if (extension == 'docx') {
          content = await _extractDocxText(filePath);
        }

        setState(() {
          _documentContent = content;
          _isLoading = false;
        });

        // OpenAI API'ya istek at
        await _sendToOpenAI(content);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showError('Dosya seçilirken hata oluştu: $e');
    }
  }

  // PDF text çıkarma
  Future<String> _extractPdfText(String filePath) async {
    try {
      final File file = File(filePath);
      final Uint8List bytes = await file.readAsBytes();
      final PdfDocument document = PdfDocument(inputBytes: bytes);

      String text = '';
      for (int i = 0; i < document.pages.count; i++) {
        final PdfTextExtractor extractor = PdfTextExtractor(document);
        text += extractor.extractText(startPageIndex: i, endPageIndex: i);
      }

      document.dispose();
      return text;
    } catch (e) {
      throw 'PDF okuma hatası: $e';
    }
  }

  // DOCX text çıkarma
  Future<String> _extractDocxText(String filePath) async {
    try {
      final File file = File(filePath);
      final Uint8List bytes = await file.readAsBytes();
      final String text = docxToText(bytes);
      return text;
    } catch (e) {
      throw 'DOCX okuma hatası: $e';
    }
  }

  // OpenAI API'ya istek gönderme
  Future<void> _sendToOpenAI(String content) async {
    if (_systemPrompt == null) {
      _showError('System prompt yüklenemedi!');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      log.log('Sending request to OpenAI...');
      log.log('System prompt: $_systemPrompt');
      log.log('Content: $content');

      // OpenAI API anahtarınızı buraya ekleyin
      const String apiKey = 'YOUR_OPENAI_API_KEY_HERE';

      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-3.5-turbo',
          'messages': [
            {
              'role': 'system',
              'content': _systemPrompt,
            },
            {
              'role': 'user',
              'content': content,
            }
          ],
          'max_tokens': 1000,
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String aiResponseText = data['choices'][0]['message']['content'];

        setState(() {
          _aiResponse = aiResponseText;
          _isLoading = false;
        });
      } else {
        log.log('API Error Response: ${response.body}');
        log.log('Status Code: ${response.statusCode}');
        setState(() {
          _isLoading = false;
        });
        _showError(
            'OpenAI API hatası: ${response.statusCode} - ${response.body}');
      }
    } catch (e, stackTrace) {
      log.log('API Error: $e');
      log.log('Stack Trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
      _showError('API isteği başarısız: $e');
    }
  }

  Future<void> _pickAudioFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedFileName = result.files.single.name;
          _isLoading = true;
        });

        String filePath = result.files.single.path!;
        File audioFile = File(filePath);

        // Ses dosyasını Whisper API ile metne dönüştür
        const String apiKey = 'YOUR_OPENAI_API_KEY_HERE';
            
        String? transcribedText =
            await transcribeAudioWithWhisper(audioFile, apiKey);

        if (transcribedText != null) {
          setState(() {
            _documentContent = transcribedText;
            _isLoading = false;
          });

          // Elde edilen metni Chat API'ye gönder
          await _sendToOpenAI(transcribedText);
        } else {
          setState(() {
            _isLoading = false;
          });
          _showError('Ses dosyası metne dönüştürülemedi.');
        }
      }
    } catch (e) {
      log.log('Audio file error: $e');
      setState(() {
        _isLoading = false;
      });
      _showError('Ses dosyası işlenirken hata oluştu: $e');
    }
  }

  Future<String?> transcribeAudioWithWhisper(
      File audioFile, String apiKey) async {
    final uri = Uri.parse('https://api.openai.com/v1/audio/transcriptions');

    var request = http.MultipartRequest('POST', uri)
      ..headers['Authorization'] = 'Bearer $apiKey'
      ..fields['model'] = 'whisper-1'
      ..files.add(await http.MultipartFile.fromPath('file', audioFile.path));

    var response = await request.send();

    if (response.statusCode == 200) {
      var responseBody = await response.stream.bytesToString();
      var data = json.decode(responseBody);
      log.log('Whisper API Response: $data');
      return data['text']; // Ses dosyasının metin hâli
    } else {
      log.log('Whisper API Hata: ${response.statusCode}');
      log.log(await response.stream.bytesToString());
      return null;
    }
  }

  // Temizleme fonksiyonu
  void _clearAll() {
    setState(() {
      _selectedFileName = null;
      _documentContent = null;
      _aiResponse = null;
    });
  }

  // Hata gösterme
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Analyzer'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PDF/DOCX Dosya seçme butonu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickFile,
              icon: Icon(Icons.file_upload),
              label: Text('PDF veya DOCX Dosyası Seç'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
              ),
            ),

            SizedBox(height: 16),

            // Ses dosyası seçme butonu
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _pickAudioFile,
              icon: Icon(Icons.mic),
              label: Text('Ses Dosyası Seç'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),

            SizedBox(height: 16),

            // Seçilen dosya adı
            if (_selectedFileName != null)
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.description, color: Colors.blue),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Seçilen dosya: $_selectedFileName',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Loading indicator
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('İşleniyor...'),
                  ],
                ),
              ),

            // AI Cevabı
            if (_aiResponse != null && !_isLoading)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI Analiz Sonucu:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: SingleChildScrollView(
                          child: Text(
                            _aiResponse!,
                            style: TextStyle(
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            SizedBox(height: 16),

            // Temizle butonu
            if (_selectedFileName != null || _aiResponse != null)
              ElevatedButton.icon(
                onPressed: _clearAll,
                icon: Icon(Icons.clear),
                label: Text('Temizle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
