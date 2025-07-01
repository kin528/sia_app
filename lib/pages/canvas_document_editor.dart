import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:file_picker/file_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:dio/dio.dart';

class CanvasDocumentEditor extends StatefulWidget {
  final int moduleNumber;
  const CanvasDocumentEditor({Key? key, required this.moduleNumber}) : super(key: key);

  @override
  State<CanvasDocumentEditor> createState() => _CanvasDocumentEditorState();
}

class _CanvasDocumentEditorState extends State<CanvasDocumentEditor> {
  final TextEditingController _titleController = TextEditingController();
  final List<_CanvasElement> _elements = [];
  int? _selectedIndex;
  bool _saving = false;
  String? _saveStatus;

  // Cropping state
  final CropController _cropController = CropController();
  Uint8List? _croppingImage;

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  void _addTextBox() {
    setState(() {
      _elements.add(_CanvasElement.text(
        text: 'Double tap to edit',
        rect: Rect.fromLTWH(100, 100, 200, 60),
      ));
      _selectedIndex = _elements.length - 1;
    });
  }

  Future<void> _addImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    if (result != null && result.files.single.bytes != null) {
      setState(() {
        _croppingImage = result.files.single.bytes;
      });
    }
  }

  void _onCropped(Uint8List croppedData) async {
    // Upload cropped image to Cloudinary
    setState(() { _saveStatus = "Uploading image..."; });
    const cloudName = 'dzvz9o8kz';
    const uploadPreset = 'uploadPreset';
    final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
    final multipartFile = MultipartFile.fromBytes(croppedData, filename: 'canvas_image_${DateTime.now().millisecondsSinceEpoch}.png');
    final formData = FormData.fromMap({
      'file': multipartFile,
      'upload_preset': uploadPreset,
    });
    final response = await Dio().post(uploadUrl, data: formData);
    if (response.statusCode == 200 && response.data['secure_url'] != null) {
      final imageUrl = response.data['secure_url'] as String;
      setState(() {
        _elements.add(_CanvasElement.image(
          url: imageUrl,
          rect: Rect.fromLTWH(120, 120, 200, 200),
        ));
        _selectedIndex = _elements.length - 1;
        _croppingImage = null;
        _saveStatus = null;
      });
    } else {
      setState(() {
        _saveStatus = "Failed to upload image.";
        _croppingImage = null;
      });
    }
  }

  Future<void> _saveDocument() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() { _saveStatus = "Please enter a document title."; });
      return;
    }
    if (_elements.isEmpty) {
      setState(() { _saveStatus = "Please add some content."; });
      return;
    }
    setState(() { _saving = true; _saveStatus = "Saving document..."; });
    try {
      final layout = _elements.map((e) => e.toJson()).toList();
      final fileName = "${_titleController.text.trim().replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json";
      final layoutJson = layout.toString();
      final bytes = layoutJson.codeUnits;
      const cloudName = 'dzvz9o8kz';
      const uploadPreset = 'uploadPreset';
      final uploadUrl = 'https://api.cloudinary.com/v1_1/$cloudName/raw/upload';
      final multipartFile = MultipartFile.fromBytes(bytes, filename: fileName);
      final formData = FormData.fromMap({
        'file': multipartFile,
        'upload_preset': uploadPreset,
      });
      final response = await Dio().post(uploadUrl, data: formData);
      if (response.statusCode == 200 && response.data['secure_url'] != null) {
        final docUrl = response.data['secure_url'] as String;
        final user = FirebaseAuth.instance.currentUser;
        final collectionName = 'module${widget.moduleNumber}_canvas_documents';
        final doc = FirebaseFirestore.instance.collection(collectionName).doc();
        await doc.set({
          'userId': user?.uid ?? 'anonymous',
          'docUrl': docUrl,
          'fileName': fileName,
          'title': _titleController.text.trim(),
          'layout': layout,
          'uploadedAt': FieldValue.serverTimestamp(),
          'isNewDocument': true,
          'isCanvas': true,
        });
        setState(() { _saveStatus = "Document saved successfully!"; });
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      } else {
        setState(() { _saveStatus = "Failed to save document."; });
      }
    } catch (e) {
      setState(() { _saveStatus = "Error saving document: $e"; });
    } finally {
      setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final maxWidth = isWide ? 1000.0 : double.infinity;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Canvas Document Editor - Module ${widget.moduleNumber}",
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
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              icon: const Icon(Icons.text_fields),
                              label: const Text("Add Text Box"),
                              onPressed: _addTextBox,
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              icon: const Icon(Icons.image),
                              label: const Text("Add Image"),
                              onPressed: _addImage,
                            ),
                          ],
                        ),
                      ),
                      // Canvas Area
                      Container(
                        width: 800,
                        height: 600,
                        color: Colors.white,
                        child: Stack(
                          children: [
                            for (int i = 0; i < _elements.length; i++)
                              _CanvasElementWidget(
                                key: ValueKey(i),
                                element: _elements[i],
                                selected: _selectedIndex == i,
                                onTap: () {
                                  setState(() { _selectedIndex = i; });
                                },
                                onChanged: (rect) {
                                  setState(() { _elements[i] = _elements[i].copyWith(rect: rect); });
                                },
                                onTextChanged: (text) {
                                  setState(() { _elements[i] = _elements[i].copyWith(text: text); });
                                },
                              ),
                            // Cropping overlay
                            if (_croppingImage != null)
                              Positioned.fill(
                                child: Container(
                                  color: Colors.black54,
                                  child: Center(
                                    child: Card(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16.0),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 400,
                                              height: 400,
                                              child: Crop(
                                                image: _croppingImage!,
                                                controller: _cropController,
                                                onCropped: (result) {
                                                  if (result is CropSuccess) {
                                                    _onCropped(result.croppedImage);
                                                  } else if (result is CropFailure) {
                                                    setState(() { _saveStatus = "Cropping failed: ${result.toString()}"; });
                                                  }
                                                },
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                ElevatedButton(
                                                  onPressed: () => setState(() { _croppingImage = null; }),
                                                  child: const Text("Cancel"),
                                                ),
                                                const SizedBox(width: 16),
                                                ElevatedButton(
                                                  onPressed: () => _cropController.crop(),
                                                  child: const Text("Crop & Insert"),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
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

class _CanvasElement {
  final String type; // 'text' or 'image'
  final String? text;
  final String? url;
  final Rect rect;
  _CanvasElement.text({required this.text, required this.rect}) : type = 'text', url = null;
  _CanvasElement.image({required this.url, required this.rect}) : type = 'image', text = null;
  _CanvasElement copyWith({String? text, String? url, Rect? rect}) => _CanvasElement._(type, text ?? this.text, url ?? this.url, rect ?? this.rect);
  _CanvasElement._(this.type, this.text, this.url, this.rect);
  Map<String, dynamic> toJson() => {
    'type': type,
    'text': text,
    'url': url,
    'rect': {'left': rect.left, 'top': rect.top, 'width': rect.width, 'height': rect.height},
  };
}

class _CanvasElementWidget extends StatefulWidget {
  final _CanvasElement element;
  final bool selected;
  final VoidCallback onTap;
  final ValueChanged<Rect> onChanged;
  final ValueChanged<String>? onTextChanged;
  const _CanvasElementWidget({Key? key, required this.element, required this.selected, required this.onTap, required this.onChanged, this.onTextChanged}) : super(key: key);
  @override
  State<_CanvasElementWidget> createState() => _CanvasElementWidgetState();
}

class _CanvasElementWidgetState extends State<_CanvasElementWidget> {
  late Rect rect;
  bool dragging = false;
  @override
  void initState() {
    super.initState();
    rect = widget.element.rect;
  }
  @override
  void didUpdateWidget(covariant _CanvasElementWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.element.rect != widget.element.rect) {
      rect = widget.element.rect;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanUpdate: (details) {
          setState(() {
            rect = rect.translate(details.delta.dx, details.delta.dy);
            widget.onChanged(rect);
          });
        },
        child: TransformableBox(
          rect: rect,
          onChanged: (result, details) {
            setState(() {
              rect = result.rect;
              widget.onChanged(rect);
            });
          },
          enabledHandles: const {
            HandlePosition.topLeft,
            HandlePosition.topRight,
            HandlePosition.bottomLeft,
            HandlePosition.bottomRight,
          },
          contentBuilder: (context, rect, isDragging) {
            return Container(
              decoration: BoxDecoration(
                border: widget.selected ? Border.all(color: Colors.blue, width: 2) : null,
              ),
              child: widget.element.type == 'image'
                  ? Image.network(widget.element.url!, fit: BoxFit.contain)
                  : _EditableTextBox(
                      text: widget.element.text!,
                      onChanged: widget.onTextChanged,
                    ),
            );
          },
        ),
      ),
    );
  }
}

class _EditableTextBox extends StatefulWidget {
  final String text;
  final ValueChanged<String>? onChanged;
  const _EditableTextBox({Key? key, required this.text, this.onChanged}) : super(key: key);
  @override
  State<_EditableTextBox> createState() => _EditableTextBoxState();
}

class _EditableTextBoxState extends State<_EditableTextBox> {
  late TextEditingController _controller;
  bool _editing = false;
  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.text);
  }
  @override
  void didUpdateWidget(covariant _EditableTextBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) {
      _controller.text = widget.text;
    }
  }
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: () {
        setState(() { _editing = true; });
      },
      child: _editing
          ? TextField(
              controller: _controller,
              autofocus: true,
              onSubmitted: (val) {
                setState(() { _editing = false; });
                if (widget.onChanged != null) widget.onChanged!(val);
              },
              onChanged: (val) {
                if (widget.onChanged != null) widget.onChanged!(val);
              },
            )
          : Text(
              widget.text,
              style: const TextStyle(fontSize: 18),
            ),
    );
  }
} 