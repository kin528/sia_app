import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
// Only import dart:html on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class Module1Page extends StatefulWidget {
  const Module1Page({super.key});

  @override
  State<Module1Page> createState() => _Module1PageState();
}

class _Module1PageState extends State<Module1Page> {
  bool _uploading = false;
  String? _uploadStatus;
  String? _docUrl;

  Stream<QuerySnapshot<Map<String, dynamic>>> getUploadsStream() {
    return FirebaseFirestore.instance
        .collection('module1_documents')
        .orderBy('uploadedAt', descending: true)
        .snapshots();
  }

  Future<void> _pickAndUploadDocument() async {
    setState(() {
      _uploadStatus = null;
      _docUrl = null;
    });

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['doc', 'docx'],
      withData: true,
    );

    if (result == null) {
      setState(() {
        _uploadStatus = 'No file selected.';
      });
      return;
    }

    final file = result.files.single;
    final fileName = file.name;

    setState(() {
      _uploading = true;
      _uploadStatus = "Uploading to Cloudinary...";
    });

    try {
      const cloudName = 'dzvz9o8kz';
      const uploadPreset =
          'uploadPreset'; // Change to your actual upload preset
      final uploadUrl =
          'https://api.cloudinary.com/v1_1/$cloudName/raw/upload'; // Use /raw/upload

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
        final docUrl = response.data['secure_url'] as String;
        setState(() {
          _docUrl = docUrl;
          _uploadStatus = "Upload successful! Saving to Firestore...";
        });

        // Save to Firestore
        final user = FirebaseAuth.instance.currentUser;
        final doc =
            FirebaseFirestore.instance.collection('module1_documents').doc();

        await doc.set({
          'userId': user?.uid ?? 'anonymous',
          'docUrl': docUrl,
          'fileName': fileName,
          'uploadedAt': FieldValue.serverTimestamp(),
        });

        setState(() {
          _uploadStatus = "Document uploaded and saved!";
        });
      } else {
        setState(() {
          _uploadStatus = "Cloudinary upload failed.";
        });
      }
    } catch (e) {
      setState(() {
        _uploadStatus = "Error: $e";
      });
    } finally {
      setState(() {
        _uploading = false;
      });
    }
  }

  Future<void> _deleteUpload(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('module1_documents')
          .doc(docId)
          .delete();
      setState(() {
        _uploadStatus = "Document deleted!";
      });
    } catch (e) {
      setState(() {
        _uploadStatus = "Error deleting: $e";
      });
    }
  }

  Future<void> _openDocument(String url) async {
    if (kIsWeb) {
      // Instead of Google Docs Viewer, use Microsoft Office Online Viewer for doc/docx.
      String fileUrl = url;
      if (fileUrl.endsWith('.doc') || fileUrl.endsWith('.docx')) {
        // Microsoft Office Viewer supports public URLs
        fileUrl =
            'https://view.officeapps.live.com/op/view.aspx?src=${Uri.encodeComponent(fileUrl)}';
      }
      html.window.open(fileUrl, '_blank');
    } else {
      final uri = Uri.parse(url);
      if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
        throw Exception("Could not launch $url");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadsStream = getUploadsStream();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Module 1 - Document Upload"),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Upload your Document to Cloudinary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.upload_file),
                label: const Text("Select and Upload Document"),
                onPressed: _uploading ? null : _pickAndUploadDocument,
              ),
              const SizedBox(height: 24),
              if (_uploadStatus != null)
                Text(
                  _uploadStatus!,
                  style: TextStyle(
                    color: _uploadStatus!.contains("Error") ||
                            _uploadStatus!.contains("failed") ||
                            _uploadStatus!.contains("deleted")
                        ? Colors.red
                        : Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
              if (_docUrl != null) ...[
                const SizedBox(height: 24),
                SelectableText("Document URL:\n$_docUrl",
                    textAlign: TextAlign.center),
              ],
              if (_uploading)
                const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: CircularProgressIndicator(),
                ),
              const SizedBox(height: 32),
              const Divider(),
              const Text(
                "All Uploaded Documents",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: uploadsStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }
                    final docs = snapshot.data?.docs ?? [];
                    if (docs.isEmpty) {
                      return const Text("No uploads yet.");
                    }
                    return ListView.separated(
                      itemCount: docs.length,
                      separatorBuilder: (context, i) => const Divider(),
                      itemBuilder: (context, i) {
                        final data = docs[i].data();
                        final docId = docs[i].id;
                        return ListTile(
                          leading: const Icon(Icons.description),
                          title: Text(data['fileName'] ?? 'Document'),
                          subtitle: Text(data['docUrl'] ?? ''),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.open_in_new),
                                tooltip: "Open Document",
                                onPressed: () async {
                                  final url = data['docUrl'];
                                  if (url != null) {
                                    await _openDocument(url);
                                  }
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                tooltip: "Delete Document",
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Delete Document"),
                                      content: const Text(
                                          "Are you sure you want to delete this document?"),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text("Cancel"),
                                        ),
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text("Delete",
                                              style:
                                                  TextStyle(color: Colors.red)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true) {
                                    _deleteUpload(docId);
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
