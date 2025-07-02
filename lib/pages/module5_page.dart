import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';
import 'simple_document_editor.dart';
// Only import dart:html on web
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

const String adminUid = 'QVyiObd7HoXTyNQaoxBzRSW0HGK2';

class Module5Page extends StatefulWidget {
  const Module5Page({super.key});

  @override
  State<Module5Page> createState() => _Module5PageState();
}

class _Module5PageState extends State<Module5Page> {
  bool _uploading = false;
  String? _uploadStatus;
  String? _docUrl;

  Stream<QuerySnapshot<Map<String, dynamic>>> getUploadsStream() {
    return FirebaseFirestore.instance
        .collection('module5_documents')
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
            FirebaseFirestore.instance.collection('module5_documents').doc();

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
          .collection('module5_documents')
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
    final isAdmin = FirebaseAuth.instance.currentUser?.uid == adminUid;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final maxWidth = isWide ? 500.0 : double.infinity;

    return Container(
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
            padding: EdgeInsets.all(isWide ? 32.0 : 12.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Card(
                elevation: 12,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(isWide ? 28 : 18),
                ),
                child: Padding(
                  padding: EdgeInsets.all(isWide ? 32.0 : 16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.black87),
                            tooltip: 'Back',
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                      Icon(Icons.cloud_upload_rounded,
                          size: isWide ? 64 : 44, color: Theme.of(context).primaryColor),
                      SizedBox(height: isWide ? 20 : 12),
                      Text(
                        "Module 5 - Document Upload",
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontSize: isWide ? 28 : 20,
                            ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Upload your .doc or .docx file to Cloudinary and view all your uploads below.",
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontSize: isWide ? 18 : 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        child: _uploadStatus != null
                            ? Padding(
                                key: ValueKey(_uploadStatus),
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Text(
                                  _uploadStatus!,
                                  style: TextStyle(
                                    color: _uploadStatus!.contains("Error") ||
                                            _uploadStatus!.contains("failed") ||
                                            _uploadStatus!.contains("deleted")
                                        ? Colors.red
                                        : Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: isWide ? 18 : 14,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                      if (isAdmin)
                        Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          alignment: WrapAlignment.center,
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.upload_file, size: 28),
                                label: const Text(
                                  "Select and Upload Document",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(context).primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isWide ? 22 : 16, horizontal: isWide ? 32 : 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isWide ? 20 : 14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: _uploading ? null : _pickAndUploadDocument,
                              ),
                            ),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.note_add, size: 28),
                                label: const Text(
                                  "Create Document",
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(vertical: isWide ? 22 : 16, horizontal: isWide ? 32 : 24),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isWide ? 20 : 14),
                                  ),
                                  elevation: 6,
                                ),
                                onPressed: () async {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("How to Create a DOCX Document"),
                                      content: const Text(
                                        "To create a .docx document, you must use an existing Microsoft account, or create and edit a .docx file using Microsoft Word, LibreOffice, or another editor on your computer. Then upload it here.\n\nIf you already have a Microsoft account, you can use Office Online Word to create your document.",
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            if (kIsWeb) {
                                              html.window.open('https://www.office.com/launch/word', '_blank');
                                            } else {
                                              final uri = Uri.parse('https://www.office.com/launch/word');
                                              launchUrl(uri, mode: LaunchMode.externalApplication);
                                            }
                                          },
                                          child: const Text("Open Office Online Word"),
                                        ),
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: const Text("Close"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      if (_docUrl != null) ...[
                        const SizedBox(height: 18),
                        SelectableText(
                          "Document URL:\n$_docUrl",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: isWide ? 16 : 12, color: Colors.blueAccent),
                        ),
                      ],
                      if (_uploading)
                        const Padding(
                          padding: EdgeInsets.only(top: 24),
                          child: CircularProgressIndicator(),
                        ),
                      const SizedBox(height: 32),
                      const Divider(),
                      Row(
                        children: [
                          Icon(Icons.folder_open_rounded, color: Theme.of(context).primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            "All Uploaded Documents",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: isWide ? 20 : 16),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: isWide ? 320 : 220,
                        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: uploadsStream,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return Text('Error: \\${snapshot.error}');
                            }
                            final docs = snapshot.data?.docs ?? [];
                            if (docs.isEmpty) {
                              return const Center(child: Text("No uploads yet."));
                            }
                            return ListView.separated(
                              itemCount: docs.length,
                              separatorBuilder: (context, i) => const SizedBox(height: 10),
                              itemBuilder: (context, i) {
                                final data = docs[i].data();
                                final docId = docs[i].id;
                                return Card(
                                  elevation: 3,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(isWide ? 18 : 10),
                                  ),
                                  child: ListTile(
                                    leading: const Icon(Icons.description, color: Colors.blueAccent),
                                    title: Text(data['fileName'] ?? 'Document', style: TextStyle(fontWeight: FontWeight.w600, fontSize: isWide ? 18 : 14)),
                                    subtitle: Text(data['docUrl'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: isWide ? 14 : 11)),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.open_in_new, color: Colors.green),
                                          tooltip: "Open Document",
                                          onPressed: () async {
                                            final url = data['docUrl'];
                                            if (url != null) {
                                              await _openDocument(url);
                                            }
                                          },
                                        ),
                                        if (isAdmin)
                                          IconButton(
                                            icon: const Icon(Icons.delete, color: Colors.red),
                                            tooltip: "Delete Document",
                                            onPressed: () async {
                                              final confirm = await showDialog<bool>(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text("Delete Document"),
                                                  content: const Text("Are you sure you want to delete this document?"),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, false),
                                                      child: const Text("Cancel"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () => Navigator.pop(context, true),
                                                      child: const Text("Delete", style: TextStyle(color: Colors.red)),
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
            ),
          ),
        ),
      ),
    );
  }
} 