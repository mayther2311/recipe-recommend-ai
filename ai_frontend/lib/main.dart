import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      colorSchemeSeed: Colors.orange, // 暖色系で食欲をそそるテーマ
    ),
    home: const AiApp(),
  ));
}

class AiApp extends StatefulWidget {
  const AiApp({super.key});
  @override
  _AiAppState createState() => _AiAppState();
}

class _AiAppState extends State<AiApp> {
  List<dynamic> _ingredients = [];
  List<dynamic> _menus = [];
  XFile? _imageFile;
  bool _isLoading = false;
  final picker = ImagePicker();

  Future<void> uploadImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() {
      _imageFile = pickedFile;
      _isLoading = true;
      _ingredients = [];
      _menus = [];
    });

    try {
      var request = http.MultipartRequest('POST', Uri.parse('http://localhost:8000/upload/'));
      var bytes = await pickedFile.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('file', bytes, filename: pickedFile.name));
      
      var response = await request.send();
      var responseData = await response.stream.bytesToString();
      var data = jsonDecode(responseData);

      setState(() {
        _ingredients = data['detected_ingredients'] ?? [];
        _menus = data['menus'] ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() { 
        _isLoading = false;
        _ingredients = ["エラーが発生しました"];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("献立提案アプリ", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 写真表示エリア
            Card(
              elevation: 3,
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: _imageFile == null 
                ? Container(
                    height: 220, 
                    width: double.infinity, 
                    color: Colors.grey[200], 
                    child: const Icon(Icons.kitchen, size: 80, color: Colors.grey)
                  )
                : Image.network(_imageFile!.path, height: 250, width: double.infinity, fit: BoxFit.cover),
            ),
            
            const SizedBox(height: 24),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            
            // 1. 認識された食材セクション
            if (!_isLoading && _ingredients.isNotEmpty) ...[
              const Text("🔍 認識された食材", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _ingredients.map((i) => Chip(
                  label: Text(i.toString()),
                  backgroundColor: Colors.orange[50],
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                )).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // 2. 献立提案セクション
            if (!_isLoading && _menus.isNotEmpty) ...[
              const Text("🍽️ 本日の献立提案", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ..._menus.map((menu) => _buildMenuCard(menu)).toList(),
            ],
            
            const SizedBox(height: 30),
            
            // スキャンボタン
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton.icon(
                onPressed: uploadImage,
                icon: const Icon(Icons.auto_awesome),
                label: const Text("冷蔵庫をスキャンして献立を作る", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 献立1つ分を表示するカード（開閉式）
  Widget _buildMenuCard(dynamic menu) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(menu['title'], style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.orange)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text("🔥 ${menu['calories']}  |  🥗 ${menu['nutrients'].join(', ')}", style: TextStyle(color: Colors.grey[700])),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const Text("👨‍🍳 作り方", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                ...(menu['instructions'] as List).map((step) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text("・ $step"),
                )).toList(),
                const SizedBox(height: 16),
                const Text("🛒 足りない食材", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.redAccent)),
                Text(menu['missing_items'].isEmpty ? "なし（完璧です！）" : menu['missing_items'].join(', ')),
              ],
            ),
          )
        ],
      ),
    );
  }
}