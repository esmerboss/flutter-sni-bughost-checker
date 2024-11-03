import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper.instance.initializeDatabase();
  runApp(const SniCheckerApp());
}

class SniCheckerApp extends StatefulWidget {
  const SniCheckerApp({Key? key}) : super(key: key);

  @override
  _SniCheckerAppState createState() => _SniCheckerAppState();
}

class _SniCheckerAppState extends State<SniCheckerApp> {
  bool _isDarkTheme = true;

  @override
  void initState() {
    super.initState();
    _loadThemeSetting();
  }

  void _loadThemeSetting() async {
    int? themeSetting = await DatabaseHelper.instance.getThemeSetting();
    if (themeSetting != null) {
      setState(() {
        _isDarkTheme = themeSetting == 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SNI Checker',
      theme: _isDarkTheme ? ThemeData.dark() : ThemeData.light(),
      home: SniCheckerHomePage(toggleTheme: _toggleTheme),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isDarkTheme = !_isDarkTheme;
      DatabaseHelper.instance.insertThemeSetting(_isDarkTheme ? 1 : 0);
    });
  }
}

class SniCheckerHomePage extends StatefulWidget {
  final VoidCallback toggleTheme;

  const SniCheckerHomePage({required this.toggleTheme, Key? key}) : super(key: key);

  @override
  _SniCheckerHomePageState createState() => _SniCheckerHomePageState();
}

class _SniCheckerHomePageState extends State<SniCheckerHomePage> {
  final TextEditingController _controller = TextEditingController();
  final List<String> _hosts = [];
  final List<String> _successHosts = [];
  int _successCount = 0;
  int _failCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadPreviousHosts();
  }

  void _loadPreviousHosts() async {
    String? previousHosts = await DatabaseHelper.instance.getPreviousHosts();
    if (previousHosts != null) {
      setState(() {
        _controller.text = previousHosts;
      });
    }
  }

  void _checkSniForHosts() async {
    await DatabaseHelper.instance.insertHosts(_controller.text);
    setState(() {
      _isLoading = true;
      _successHosts.clear();
      _successCount = 0;
      _failCount = 0;
      _hosts.clear();
    });

    List<String> hosts = _controller.text.split('\n');
    List<String> updatedHosts = [];
    int successCount = 0;
    int failCount = 0;
    List<String> successHosts = [];

    for (String host in hosts) {
      host = host.trim();
      if (host.isNotEmpty) {
        bool result = await _checkSni(host);
        updatedHosts.add('$host - ${result ? "Success" : "Fail"}');
        if (result) {
          successHosts.add(host);
          successCount++;
        } else {
          failCount++;
        }
      }
    }

    setState(() {
      _hosts.addAll(updatedHosts);
      _successHosts.addAll(successHosts);
      _successCount = successCount;
      _failCount = failCount;
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

  void _clearAll() async {
    await DatabaseHelper.instance.clearDatabase();
    setState(() {
      _controller.clear();
      _hosts.clear();
      _successHosts.clear();
      _successCount = 0;
      _failCount = 0;
    });
  }

  void _copyToClipboard() {
    if (_successHosts.isNotEmpty) {
      String content = _successHosts.join('\n');
      Clipboard.setData(ClipboardData(text: content));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Success hosts copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SNI Checker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearAll,
          ),
          IconButton(
            icon: Icon(_isDarkTheme(context) ? Icons.dark_mode : Icons.light_mode),
            onPressed: widget.toggleTheme,
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  controller: _controller,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter hosts (one per line)',
                  ),
                  maxLines: 5,
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _pickFile,
                  child: const Text('Load from File'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _clearAll,
                  child: const Text('Clear All'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : _checkSniForHosts,
                  child: const Text('Check SNI'),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: TextEditingController(text: _hosts.join('\n')),
                  maxLines: 10,
                  readOnly: true,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Hosts Log',
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Success: $_successCount'),
                    Text('Fail: $_failCount'),
                    const SizedBox(height: 10),
                    const Text('Successful Hosts:', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: TextEditingController(text: _successHosts.join('\n')),
                      maxLines: 5,
                      readOnly: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _copyToClipboard,
                      child: const Text('Copy to Clipboard'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isDarkTheme(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark;
  }
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<void> initializeDatabase() async {
    _database = await _initDatabase();
  }

  Future<Database> _initDatabase() async {
    String path = p.join(await getDatabasesPath(), 'sni_checker.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE settings (id INTEGER PRIMARY KEY, theme INTEGER, hosts TEXT)'
        );
      },
    );
  }

  Future<void> insertHosts(String hosts) async {
    Database db = await instance.database;
    await db.insert(
      'settings',
      {'id': 1, 'hosts': hosts},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getPreviousHosts() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('settings', where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      return result.first['hosts'] as String?;
    }
    return null;
  }

  Future<int?> getThemeSetting() async {
    Database db = await instance.database;
    List<Map<String, dynamic>> result = await db.query('settings', columns: ['theme'], where: 'id = ?', whereArgs: [1]);
    if (result.isNotEmpty) {
      return result.first['theme'] as int?;
    }
    return null;
  }

  Future<void> insertThemeSetting(int theme) async {
    Database db = await instance.database;
    await db.insert(
      'settings',
      {'id': 1, 'theme': theme},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearDatabase() async {
    Database db = await instance.database;
    await db.delete('settings');
  }
}
