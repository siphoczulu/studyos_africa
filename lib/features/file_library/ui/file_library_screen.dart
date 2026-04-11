import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/db/app_db.dart';
import '../data/study_file.dart';

class FileLibraryScreen extends StatefulWidget {
  const FileLibraryScreen({super.key});

  @override
  State<FileLibraryScreen> createState() => _FileLibraryScreenState();
}

class _FileLibraryScreenState extends State<FileLibraryScreen> {
  bool _isLoading = true;
  List<StudyFile> _files = const [];

  @override
  void initState() {
    super.initState();
    _loadFiles();
  }

  Future<void> _loadFiles() async {
    setState(() {
      _isLoading = true;
    });

    final files = await AppDb.instance.getStudyFiles();

    if (!mounted) {
      return;
    }

    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png', 'gif', 'webp'],
    );

    if (result == null || result.files.isEmpty) {
      return;
    }

    final pickedFile = result.files.first;
    final path = pickedFile.path;
    if (path == null || path.isEmpty) {
      return;
    }

    final fileName = pickedFile.name;
    final lowerName = fileName.toLowerCase();
    final type = lowerName.endsWith('.pdf') ? 'pdf' : 'image';

    await AppDb.instance.insertStudyFile(
      name: fileName,
      path: path,
      type: type,
    );

    await _loadFiles();
  }

  Future<void> _openFile(StudyFile file) async {
    await OpenFilex.open(file.path);
  }

  Future<void> _confirmDelete(StudyFile file) async {
    final fileId = file.id;
    if (fileId == null) {
      return;
    }

    final shouldDelete =
        await showDialog<bool>(
          context: context,
          builder: (context) {
            return AlertDialog(
              title: const Text('Delete file?'),
              content: Text('Delete "${file.name}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: const Text('Delete'),
                ),
              ],
            );
          },
        ) ??
        false;

    if (!shouldDelete) {
      return;
    }

    await AppDb.instance.deleteStudyFile(fileId);
    await _loadFiles();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Library'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text('No files yet'))
          : ListView.builder(
              itemCount: _files.length,
              itemBuilder: (context, index) {
                final file = _files[index];
                return ListTile(
                  title: Text(file.name),
                  subtitle: Text(file.type),
                  onTap: () => _openFile(file),
                  onLongPress: () => _confirmDelete(file),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickFile,
        child: const Icon(Icons.add),
      ),
    );
  }
}
