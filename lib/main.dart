import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

void main() => runApp(SniCheckerApp());

class SniCheckerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNI Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SniCheckerHomePage(),
    );
  }
}

class SniCheckerHomePage extends StatefulWidget {
  @override
  _SniCheckerHomePageState createState() => _SniCheckerHomePageState();
}

class _SniCheckerHomePageState extends State<SniCheckerHomePage> {
  final TextEditingController _controller = TextEditingController();
  List<String> _hosts = [];
  List<String> _successHosts = [];
  int _successCount = 0;
  int _failCount = 0;
  bool _isLoading = false;

  void _checkSniForHosts() async {
    setState(() {
      _isLoading = true;
      _successHosts.clear();
      _successCount = 0;
      _failCount = 0;
    });

    List<String> hosts = _controller.text.split('\n');
    for (String host in hosts) {
      host = host.trim();
      if (host.isNotEmpty) {
        bool result = await _checkSni(host);
        setState(() {
          if (result) {
            _successHosts.add(host);
            _successCount++;
          } else {
            _failCount++;
          }
          _hosts.add('${host} - ${result ? "Success" : "Fail"}');
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<bool> _checkSni(String hostname) async {
    try {
      final url = Uri.https(hostname, '');
      final response = await http.get(url);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['txt']);
    if (result != null) {
      File file = File(result.files.single.path!);
      String content = await file.readAsString();
      setState(() {
        _controller.text = content;
      });
    }
  }

  void _copyToClipboard() {
    if (_successHosts.isNotEmpty) {
      String content = _successHosts.join('\n');
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Success hosts copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SNI Checker'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter hosts (one per line)',
              ),
              maxLines: 5,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickFile,
              child: Text('Load from File'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _checkSniForHosts,
              child: Text('Check SNI'),
            ),
            SizedBox(height: 20),
            if (_isLoading)
              CircularProgressIndicator(),
            Expanded(
              child: ListView.builder(
                itemCount: _hosts.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(_hosts[index]),
                  );
                },
              ),
            ),
            if (!_isLoading)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Success: $_successCount'),
                  Text('Fail: $_failCount'),
                  SizedBox(height: 10),
                  if (_successHosts.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Successful Hosts:', style: TextStyle(fontWeight: FontWeight.bold)),
                        TextField(
                          controller: TextEditingController(text: _successHosts.join('\n')),
                          maxLines: 5,
                          readOnly: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _copyToClipboard,
                          child: Text('Copy to Clipboard'),
                        ),
                      ],
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
