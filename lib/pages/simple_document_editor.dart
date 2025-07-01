import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

class SimpleDocumentEditor extends StatefulWidget {
  final int moduleNumber;
  
  const SimpleDocumentEditor({
    super.key,
    required this.moduleNumber,
  });

  @override
  State<SimpleDocumentEditor> createState() => _SimpleDocumentEditorState();
}

class _SimpleDocumentEditorState extends State<SimpleDocumentEditor> {
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
  bool _uploadingImage = false;

  // Inline content state
  List<_DocBlock> _blocks = [];
  int _selectedBlockIndex = -1;

  @override
  void initState() {
    super.initState();
    _titleController.text = "New Document - Module ${widget.moduleNumber}";
    _blocks = [
      _DocBlock.text("")
    ];
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

  // Helper to parse content into blocks (text and images)
  void _parseContentToBlocks(String content) {
    final regex = RegExp(r'\[IMAGE: ([^\]]+)\]');
    final matches = regex.allMatches(content);
    List<_DocBlock> blocks = [];
    int lastEnd = 0;
    for (final match in matches) {
      if (match.start > lastEnd) {
        blocks.add(_DocBlock.text(content.substring(lastEnd, match.start)));
      }
      final imageName = match.group(1)!;
      final imageIndex = _imageNames.indexOf(imageName);
      if (imageIndex != -1) {
        blocks.add(_DocBlock.image(_imageUrls[imageIndex], imageName));
      } else {
        blocks.add(_DocBlock.text(match.group(0)!));
      }
      lastEnd = match.end;
    }
    if (lastEnd < content.length) {
      blocks.add(_DocBlock.text(content.substring(lastEnd)));
    }
    setState(() {
      _blocks = blocks.isEmpty ? [_DocBlock.text("")] : blocks;
    });
  }

  // Helper to convert blocks back to content string
  String _blocksToContent() {
    return _blocks.map((b) => b.isImage ? '[IMAGE: ${b.imageName}]' : b.text).join();
  }

  // Insert image at selected position
  void _insertImageAt(int index, String imageUrl, String imageName) {
    setState(() {
      _blocks.insert(index, _DocBlock.image(imageUrl, imageName));
      _imageUrls.add(imageUrl);
      _imageNames.add(imageName);
    });
  }

  // Drag-and-drop reorder
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex--;
      final block = _blocks.removeAt(oldIndex);
      _blocks.insert(newIndex, block);
    });
  }

  Future<void> _insertImage() async {
    setState(() {
      _uploadingImage = true;
    });
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null) {
        final file = result.files.single;
        final fileName = file.name;
        setState(() {
          _saveStatus = "Uploading image...";
        });
        // Upload image to Cloudinary
        const cloudName = 'dzvz9o8kz';
        const uploadPreset = 'uploadPreset';
        final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
        MultipartFile multipartFile;
        if (kIsWeb) {
          if (file.bytes == null) {
            throw Exception("No file bytes found for web upload.");
          }
          multipartFile = MultipartFile.fromBytes(
            file.bytes!,
            filename: fileName,
          );
        } else {
          if (file.path == null) {
            throw Exception("No file path found for mobile upload.");
          }
          multipartFile = await MultipartFile.fromFile(
            file.path!,
            filename: fileName,
          );
        }
        final formData = FormData.fromMap({
          'file': multipartFile,
          'upload_preset': uploadPreset,
        });
        final response = await Dio().post(uploadUrl, data: formData);
        if (response.statusCode == 200 && response.data['secure_url'] != null) {
          final imageUrl = response.data['secure_url'] as String;
          setState(() {
            _saveStatus = "Image uploaded successfully!";
          });
          // Insert image at selected block index or at the end
          int insertAt = _selectedBlockIndex >= 0 ? _selectedBlockIndex + 1 : _blocks.length;
          _insertImageAt(insertAt, imageUrl, fileName);
        } else {
          setState(() {
            _saveStatus = "Failed to upload image.";
          });
        }
      }
    } catch (e) {
      setState(() {
        _saveStatus = "Error uploading image: $e";
      });
    } finally {
      setState(() {
        _uploadingImage = false;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() {
        _saveStatus = "Please enter a document title.";
      });
      return;
    }
    if (_blocks.where((b) => b.isText && b.text.trim().isNotEmpty).isEmpty && _blocks.where((b) => b.isImage).isEmpty) {
      setState(() {
        _saveStatus = "Please enter some content.";
      });
      return;
    }
    setState(() {
      _saving = true;
      _saveStatus = "Saving document...";
    });
    try {
      final fileName = "${_titleController.text.trim().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.txt";
      final documentContent = _blocksToContent();
      final bytes = documentContent.codeUnits;
      const cloudName = 'dzvz9o8kz';
      const uploadPreset = 'uploadPreset';
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';
      final multipartFile = MultipartFile.fromBytes(
        bytes,
        filename: fileName,
      );
      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': uploadPreset,
      });
      final response = await Dio().post(uploadUrl, data: formData);
      if (response.statusCode == 200 && response.data['secure_url'] != null) {
        final docUrl = response.data['secure_url'] as String;
        final user = FirebaseAuth.instance.currentUser;
        final collectionName = 'module${widget.moduleNumber}_documents';
        final doc = FirebaseFirestore.instance.collection(collectionName).doc();
        await doc.set({
          'userId': user?.uid ?? 'anonymous',
          'docUrl': docUrl,
          'fileName': fileName,
          'title': _titleController.text.trim(),
          'content': documentContent,
          'imageUrls': _imageUrls,
          'imageNames': _imageNames,
          'uploadedAt': FieldValue.serverTimestamp(),
          'isNewDocument': true,
        });
        setState(() {
          _saveStatus = "Document saved successfully!";
        });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() {
          _saveStatus = "Failed to save document.";
        });
      }
    } catch (e) {
      setState(() {
        _saveStatus = "Error saving document: $e";
      });
    } finally {
      setState(() {
        _saving = false;
      });
    }
  }

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          // Font size dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[400]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: DropdownButton<double>(
              value: _fontSize,
              underline: const SizedBox(),
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
          ),
          const SizedBox(width: 16),
          
          // Bold button
          IconButton(
            icon: Icon(Icons.format_bold, color: _isBold ? Colors.blue : Colors.grey[600]),
            onPressed: _toggleBold,
            tooltip: 'Bold',
          ),
          
          // Italic button
          IconButton(
            icon: Icon(Icons.format_italic, color: _isItalic ? Colors.blue : Colors.grey[600]),
            onPressed: _toggleItalic,
            tooltip: 'Italic',
          ),
          
          // Underline button
          IconButton(
            icon: Icon(Icons.format_underline, color: _isUnderline ? Colors.blue : Colors.grey[600]),
            onPressed: _toggleUnderline,
            tooltip: 'Underline',
          ),
          
          const SizedBox(width: 16),
          
          // Insert Image button
          IconButton(
            icon: Icon(Icons.image, color: Colors.green[600]),
            onPressed: _uploadingImage ? null : _insertImage,
            tooltip: 'Insert Image',
          ),
          
          const SizedBox(width: 16),
          
          // Alignment buttons
          IconButton(
            icon: Icon(Icons.format_align_left, color: _textAlign == TextAlign.left ? Colors.blue : Colors.grey[600]),
            onPressed: () => _setTextAlign(TextAlign.left),
            tooltip: 'Align Left',
          ),
          
          IconButton(
            icon: Icon(Icons.format_align_center, color: _textAlign == TextAlign.center ? Colors.blue : Colors.grey[600]),
            onPressed: () => _setTextAlign(TextAlign.center),
            tooltip: 'Align Center',
          ),
          
          IconButton(
            icon: Icon(Icons.format_align_right, color: _textAlign == TextAlign.right ? Colors.blue : Colors.grey[600]),
            onPressed: () => _setTextAlign(TextAlign.right),
            tooltip: 'Align Right',
          ),
          
          IconButton(
            icon: Icon(Icons.format_align_justify, color: _textAlign == TextAlign.justify ? Colors.blue : Colors.grey[600]),
            onPressed: () => _setTextAlign(TextAlign.justify),
            tooltip: 'Justify',
          ),
        ],
      ),
    );
  }

  Widget _buildInlineEditor() {
    return ReorderableListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      onReorder: _onReorder,
      children: [
        for (int i = 0; i < _blocks.length; i++)
          _blocks[i].isImage
              ? ListTile(
                  key: ValueKey('img_$i'),
                  title: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBlockIndex = i;
                      });
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedBlockIndex == i ? Colors.blue : Colors.grey[300]!,
                          width: _selectedBlockIndex == i ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Image.network(
                        _blocks[i].imageUrl!,
                        height: 100,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                  subtitle: Text(_blocks[i].imageName ?? '', style: const TextStyle(fontSize: 10)),
                )
              : ListTile(
                  key: ValueKey('txt_$i'),
                  title: TextFormField(
                    initialValue: _blocks[i].text,
                    maxLines: null,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter text...',
                    ),
                    style: TextStyle(
                      fontSize: _fontSize,
                      fontWeight: _isBold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: _isItalic ? FontStyle.italic : FontStyle.normal,
                      decoration: _isUnderline ? TextDecoration.underline : TextDecoration.none,
                    ),
                    textAlign: _textAlign,
                    onChanged: (val) {
                      _blocks[i] = _DocBlock.text(val);
                    },
                    onTap: () {
                      setState(() {
                        _selectedBlockIndex = i;
                      });
                    },
                  ),
                ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final maxWidth = isWide ? 1000.0 : double.infinity;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Create New Document - Module ${widget.moduleNumber}",
          style: TextStyle(fontSize: isWide ? 20 : 16),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_saving)
            TextButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Save",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              onPressed: _saveDocument,
            ),
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Card(
                  elevation: 12,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(isWide ? 28 : 18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title Input
                      Padding(
                        padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Document Title",
                              style: TextStyle(
                                fontSize: isWide ? 18 : 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _titleController,
                              decoration: InputDecoration(
                                hintText: "Enter document title...",
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                filled: true,
                                fillColor: Colors.grey[50],
                              ),
                              style: TextStyle(fontSize: isWide ? 16 : 14),
                            ),
                          ],
                        ),
                      ),
                      
                      // Toolbar
                      _buildToolbar(),
                      
                      // Inline Editor
                      Container(
                        height: isWide ? 500 : 400,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.white,
                        ),
                        child: _buildInlineEditor(),
                      ),
                      
                      // Status Message
                      if (_saveStatus != null)
                        Padding(
                          padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: _saveStatus!.contains("Error") || _saveStatus!.contains("Failed")
                                  ? Colors.red[50]
                                  : Colors.green[50],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _saveStatus!.contains("Error") || _saveStatus!.contains("Failed")
                                    ? Colors.red[200]!
                                    : Colors.green[200]!,
                              ),
                            ),
                            child: Text(
                              _saveStatus!,
                              style: TextStyle(
                                color: _saveStatus!.contains("Error") || _saveStatus!.contains("Failed")
                                    ? Colors.red[700]
                                    : Colors.green[700],
                                fontWeight: FontWeight.bold,
                                fontSize: isWide ? 16 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      
                      // Save Button
                      if (!_saving)
                        Padding(
                          padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.save, size: 24),
                              label: const Text(
                                "Save Document",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(vertical: isWide ? 20 : 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(isWide ? 16 : 12),
                                ),
                                elevation: 6,
                              ),
                              onPressed: _saveDocument,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper class for document blocks
class _DocBlock {
  final String text;
  final String? imageUrl;
  final String? imageName;
  bool get isImage => imageUrl != null;
  bool get isText => imageUrl == null;
  _DocBlock.text(this.text)
      : imageUrl = null,
        imageName = null;
  _DocBlock.image(this.imageUrl, this.imageName) : text = "";
} 