import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';

class DocumentEditorPage extends StatefulWidget {
  final int moduleNumber;
  const DocumentEditorPage({Key? key, required this.moduleNumber}) : super(key: key);

  @override
  State<DocumentEditorPage> createState() => _DocumentEditorPageState();
}

class _DocumentEditorPageState extends State<DocumentEditorPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  bool _saving = false;
  String? _saveStatus;
  
  // Text formatting state
  bool _isBold = false;
  bool _isItalic = false;
  bool _isUnderline = false;
  TextAlign _textAlign = TextAlign.left;
  double _fontSize = 16.0;

  // Image state
  List<String> _imageUrls = [];
  List<String> _imageNames = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = "New Document - Module ${widget.moduleNumber}";
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _toggleBold() {
    setState(() {
      _isBold = !_isBold;
    });
  }

  void _toggleItalic() {
    setState(() {
      _isItalic = !_isItalic;
    });
  }

  void _toggleUnderline() {
    setState(() {
      _isUnderline = !_isUnderline;
    });
  }

  void _setTextAlign(TextAlign align) {
    setState(() {
      _textAlign = align;
    });
  }

  void _changeFontSize(double size) {
    setState(() {
      _fontSize = size;
    });
  }

  Future<void> _insertImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          // Upload image to Cloudinary
          final dio = Dio();
          final formData = FormData.fromMap({
            'file': MultipartFile.fromBytes(
              file.bytes!,
              filename: file.name,
            ),
            'upload_preset': 'sia_app',
          });

          final response = await dio.post(
            'https://api.cloudinary.com/v1_1/demo/upload',
            data: formData,
          );

          final imageUrl = response.data['secure_url'];

          // Insert image reference in content
          final imageRef = '\n[IMAGE: ${file.name}]\n';
          final currentText = _contentController.text;
          final selection = _contentController.selection;
          final newText = currentText.replaceRange(
            selection.start,
            selection.end,
            imageRef,
          );
          
          _contentController.text = newText;
          _contentController.selection = TextSelection.collapsed(
            offset: selection.start + imageRef.length,
          );

          // Store image data
          _imageUrls.add(imageUrl);
          _imageNames.add(file.name);

          setState(() {});
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inserting image: $e')),
      );
    }
  }

  Future<void> _saveDocument() async {
    if (_saving) return;

    setState(() {
      _saving = true;
      _saveStatus = "Saving...";
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _saveStatus = "Error: User not authenticated";
          _saving = false;
        });
        return;
      }

      final content = _contentController.text;

      // Create HTML content with formatting
      final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
    <title>${_titleController.text}</title>
    <meta charset="utf-8">
    <style>
        body { 
            font-family: Arial, sans-serif; 
            margin: 20px; 
            font-size: ${_fontSize}px;
        }
        img { max-width: 100%; height: auto; }
        .content {
            text-align: ${_textAlign.name};
            font-weight: ${_isBold ? 'bold' : 'normal'};
            font-style: ${_isItalic ? 'italic' : 'normal'};
            text-decoration: ${_isUnderline ? 'underline' : 'none'};
        }
    </style>
</head>
<body>
    <h1>${_titleController.text}</h1>
    <div class="content">${content.replaceAll('\n', '<br>')}</div>
</body>
</html>
      ''';

      // Upload to Cloudinary
      final dio = Dio();
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          htmlContent.codeUnits,
          filename: 'document.html',
        ),
        'upload_preset': 'sia_app',
        'resource_type': 'raw',
      });

      final response = await dio.post(
        'https://api.cloudinary.com/v1_1/demo/upload',
        data: formData,
      );

      final cloudinaryUrl = response.data['secure_url'];

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('documents')
          .add({
        'title': _titleController.text,
        'content': content,
        'htmlContent': htmlContent,
        'cloudinaryUrl': cloudinaryUrl,
        'moduleNumber': widget.moduleNumber,
        'userId': user.uid,
        'imageUrls': _imageUrls,
        'imageNames': _imageNames,
        'formatting': {
          'isBold': _isBold,
          'isItalic': _isItalic,
          'isUnderline': _isUnderline,
          'textAlign': _textAlign.name,
          'fontSize': _fontSize,
        },
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      setState(() {
        _saveStatus = "Document saved successfully!";
        _saving = false;
      });

      // Navigate back after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    } catch (e) {
      setState(() {
        _saveStatus = "Error saving document: $e";
        _saving = false;
      });
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.format_bold, color: _isBold ? Colors.blue : null),
            onPressed: _toggleBold,
            tooltip: 'Bold',
          ),
          IconButton(
            icon: Icon(Icons.format_italic, color: _isItalic ? Colors.blue : null),
            onPressed: _toggleItalic,
            tooltip: 'Italic',
          ),
          IconButton(
            icon: Icon(Icons.format_underline, color: _isUnderline ? Colors.blue : null),
            onPressed: _toggleUnderline,
            tooltip: 'Underline',
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.format_align_left),
            onPressed: () => _setTextAlign(TextAlign.left),
            tooltip: 'Align Left',
          ),
          IconButton(
            icon: const Icon(Icons.format_align_center),
            onPressed: () => _setTextAlign(TextAlign.center),
            tooltip: 'Align Center',
          ),
          IconButton(
            icon: const Icon(Icons.format_align_right),
            onPressed: () => _setTextAlign(TextAlign.right),
            tooltip: 'Align Right',
          ),
          const VerticalDivider(),
          DropdownButton<double>(
            value: _fontSize,
            items: [12.0, 14.0, 16.0, 18.0, 20.0, 24.0, 28.0, 32.0]
                .map((size) => DropdownMenuItem(
                      value: size,
                      child: Text('${size.toInt()}'),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) _changeFontSize(value);
            },
          ),
          const VerticalDivider(),
          IconButton(
            icon: const Icon(Icons.image),
            onPressed: _insertImage,
            tooltip: 'Insert Image',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Document Editor - Module ${widget.moduleNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saving ? null : _saveDocument,
            tooltip: 'Save Document',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Document Title',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          if (_saveStatus != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8.0),
              color: _saveStatus!.contains('Error') ? Colors.red[100] : Colors.green[100],
              child: Text(
                _saveStatus!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _saveStatus!.contains('Error') ? Colors.red[900] : Colors.green[900],
                ),
              ),
            ),
          _buildToolbar(),
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _contentController,
                maxLines: null,
                expands: true,
                decoration: const InputDecoration(
                  hintText: 'Start typing your document...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
                style: TextStyle(
                  fontSize: _fontSize,
                  fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                ),
                textAlign: _textAlign,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 