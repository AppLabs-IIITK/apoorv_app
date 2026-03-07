import 'dart:io';

import 'package:apoorv_app/api.dart';
import 'package:apoorv_app/providers/app_config_provider.dart';
import 'package:apoorv_app/providers/user_info_provider.dart';
import 'package:apoorv_app/screens/homepage/feed/single_feed.dart';
import 'package:apoorv_app/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../constants.dart';
import '../../../widgets/spinning_apoorv.dart';

class FeedScreen extends StatefulWidget {
  static const routeName = '/feed';
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  Future<Map<String, dynamic>>? _myFuture;
  bool _editMode = false;

  static final _supabase = Supabase.instance.client;

  Future<String> _uploadFeedImage(String imagePath) async {
    final file = File(imagePath);
    final fileExt = imagePath.split('.').last;
    final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
    await _supabase.storage
        .from('assets')
        .upload('feed_images/$fileName', file);
    return fileName;
  }

  String _getFeedImageUrl(String fileNameOrUrl) {
    if (fileNameOrUrl.startsWith('http')) return fileNameOrUrl;
    return _supabase.storage
        .from('assets')
        .getPublicUrl('feed_images/$fileNameOrUrl');
  }

  Future<bool> _confirmDelete() async {
    final res = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Constants.blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Feed Item',
                  style: TextStyle(
                    color: Constants.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to delete this feed item? This will remove it for everyone.',
                  style: TextStyle(color: Constants.creamColor),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Constants.creamColor),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Constants.redColor,
                        foregroundColor: Constants.whiteColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
    return res == true;
  }

  @override
  void initState() {
    super.initState();
    _updateFeedData();
  }

  Future<void> _updateFeedData() async {
    setState(() {
      _myFuture = APICalls().getFeed(context.read<UserProvider>().idToken);
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _myFuture,
        builder: (BuildContext context, AsyncSnapshot snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return const Scaffold(
                body: Center(
                  child: SpinningApoorv(),
                ),
              );

            case ConnectionState.done:
            default:
              if (snapshot.hasError) {
                return Scaffold(
                  body: Center(child: Text(snapshot.error.toString())),
                );
              } else if (snapshot.hasData) {
                if (snapshot.data['error'] != null) {
                  var e = snapshot.data['error'] as String;
                  var message = "";
                  if (e.contains("connection")) {
                    message =
                        "There was a connection error! Check your connection and try again";
                  } else {
                    message = e;
                  }
                  Future.delayed(
                      const Duration(seconds: 1),
                      () {
                        if (!context.mounted) return;
                        dialogBuilder(context, message: message,
                                function: () {
                          _updateFeedData();
                          Navigator.of(context).pop();
                        });
                      });

                  return const Scaffold(body: Center(child: SpinningApoorv()));
                } else if (snapshot.data['success']) {
                  var providerContext = context.read<UserProvider>();
                  final config = context.watch<AppConfigProvider>();
                  final canManageContent = config.canManageContent;

                  var data = (snapshot.data['body'] as List?) ?? [];

                  Future<void> persistFeed(List updated) async {
                    final body = updated
                        .map((e) => Map<String, dynamic>.from(e as Map))
                        .toList();
                    final res = await APICalls().updateFeed(
                      body,
                      context.read<UserProvider>().idToken,
                    );
                    if (!context.mounted) return;
                    if (res['success'] == true) {
                      await _updateFeedData();
                    } else {
                      final msg =
                          (res['error'] ?? 'Failed to update feed').toString();
                      dialogBuilder(context, message: msg, function: () {
                        Navigator.of(context).pop();
                      });
                    }
                  }

                  Future<void> showAddOrEditDialog({int? index}) async {
                    final idx = index;
                    final isEdit = idx != null;
                    final existing =
                        isEdit ? (data[idx] as Map) : <String, dynamic>{};
                    final rawPriority = existing['priority'];

                    final item = await showDialog<Map<String, dynamic>>(
                      context: context,
                      builder: (ctx) {
                        return _FeedItemEditorDialog(
                          isEdit: isEdit,
                          initialTitle: (existing['title'] ?? '').toString(),
                          initialText: (existing['text'] ?? '').toString(),
                          initialPriority: rawPriority == true || rawPriority == 1,
                          initialImageUrl:
                              (existing['imageUrl'] ?? '').toString().trim(),
                          onPickImage: () async {
                            final picker = ImagePicker();
                            final XFile? picked = await picker.pickImage(
                              source: ImageSource.gallery,
                            );
                            if (picked == null) throw Exception('cancelled');
                            final fileName = await _uploadFeedImage(picked.path);
                            return _getFeedImageUrl(fileName);
                          },
                        );
                      },
                    );

                    if (item == null) return;
                    final updated = List.from(data);
                    if (isEdit) {
                      updated[idx] = item;
                    } else {
                      updated.add(item);
                    }
                    await persistFeed(updated);
                  }

                  return Scaffold(
                    floatingActionButton: FloatingActionButton(
                      heroTag: null,
                      onPressed: () => _updateFeedData(),
                      child: const Icon(Icons.refresh_rounded),
                    ),
                    body: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: MediaQuery.of(context).size.height / 4,
                            decoration: const BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Constants.gradientHigh,
                                    Constants.gradientMid,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.center,
                                ),
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(30),
                                  bottomRight: Radius.circular(30),
                                )),
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  horizontal:
                                      MediaQuery.of(context).size.width * 0.07),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          "Welcome,\n${providerContext.userName.split(' ')[0]}",
                                          style: const TextStyle(
                                            color: Constants.blackColor,
                                            fontSize: 36,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'GOT'
                                          ),
                                          softWrap: true,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Image.asset(
                                    "assets/images/Apoorv-logo.png",
                                    height: MediaQuery.of(context).size.height /
                                        5.9,
                                    width:
                                        MediaQuery.of(context).size.width / 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal:
                                    MediaQuery.of(context).size.width * 0.05),
                            width: double.infinity,
                            child: canManageContent
                                ? Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        "Feed",
                                        style: TextStyle(
                                          color: Constants.whiteColor,
                                          fontSize: 30,
                                        ),
                                        textAlign: TextAlign.left,
                                      ),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () {
                                          setState(() {
                                            _editMode = !_editMode;
                                          });
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(4),
                                          child: Icon(
                                            _editMode
                                                ? Icons.check
                                                : Icons.edit,
                                            color: Constants.whiteColor,
                                            size: 22,
                                          ),
                                        ),
                                      )
                                    ],
                                  )
                                : const Text(
                                    "Feed",
                                    style: TextStyle(
                                      color: Constants.whiteColor,
                                      fontSize: 30,
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                          ),
                          Constants.gap,
                          // ListView.builder( {
                          if (data.isEmpty)
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "Wow, such empty",
                                  style: TextStyle(fontSize: 24),
                                ),
                              ),
                            ),

                          Expanded(
                            child: ListView.builder(
                                primary: false,
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                itemCount: data.length +
                                    (canManageContent && _editMode ? 1 : 0),
                                itemBuilder: (BuildContext context, int i) {
                                  if (canManageContent &&
                                      _editMode &&
                                      i == data.length) {
                                    return Card(
                                      margin: EdgeInsets.only(
                                        left: MediaQuery.of(context).size.width * 0.03,
                                        right: MediaQuery.of(context).size.width * 0.03,
                                        bottom: MediaQuery.of(context).size.width * 0.03,
                                      ),
                                      color: Constants.blackColor,
                                      child: InkWell(
                                        onTap: () => showAddOrEditDialog(),
                                        child: const Padding(
                                          padding: EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              Icon(Icons.add,
                                                  color: Constants.creamColor),
                                              SizedBox(width: 12),
                                              Text(
                                                'Add feed item',
                                                style: TextStyle(
                                                  color: Constants.creamColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }

                                  var message = data[i]['title'];
                                  if (data[i]['text'] != null) {
                                    message =
                                        "${data[i]['title']}\n${data[i]['text']}";
                                  }

                                  final imageUrl = data[i]['imageUrl']?.toString();
                                  return SingleFeed(
                                    index: i,
                                    title: message,
                                    priority: data[i]['priority'],
                                    imageUrl:
                                        (imageUrl != null && imageUrl.isNotEmpty)
                                            ? imageUrl
                                            : null,
                                    editMode: canManageContent && _editMode,
                                    onEdit: () => showAddOrEditDialog(index: i),
                                    onDelete: () async {
                                      final ok = await _confirmDelete();
                                      if (!ok) return;
                                      final updated = List.from(data);
                                      updated.removeAt(i);
                                      await persistFeed(updated);
                                    },
                                  );
                                }),
                          ),
                          // Constants.gap,
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(child: Text(snapshot.data['message']));
                }
              } else {
                return const Scaffold(body: Center(child: SpinningApoorv()));
              }
          }
        });
  }
}

class _FeedItemEditorDialog extends StatefulWidget {
  const _FeedItemEditorDialog({
    required this.isEdit,
    required this.initialTitle,
    required this.initialText,
    required this.initialPriority,
    required this.initialImageUrl,
    required this.onPickImage,
  });

  final bool isEdit;
  final String initialTitle;
  final String initialText;
  final bool initialPriority;
  final String initialImageUrl;
  final Future<String> Function() onPickImage;

  @override
  State<_FeedItemEditorDialog> createState() => _FeedItemEditorDialogState();
}

class _FeedItemEditorDialogState extends State<_FeedItemEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _textController;
  bool _priority = false;
  String _imageUrl = '';
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _textController = TextEditingController(text: widget.initialText);
    _priority = widget.initialPriority;
    _imageUrl = widget.initialImageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: const TextStyle(color: Constants.creamColor),
      hintStyle: const TextStyle(color: Constants.creamColor),
      enabledBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Constants.redColor),
      ),
      focusedBorder: const UnderlineInputBorder(
        borderSide: BorderSide(color: Constants.whiteColor),
      ),
    );
  }

  Future<void> _pickImage() async {
    if (_uploading) return;
    setState(() {
      _uploading = true;
    });
    try {
      final url = await widget.onPickImage();
      if (!mounted) return;
      setState(() {
        _imageUrl = url;
      });
    } catch (e) {
      // User cancelled picker or upload failed.
      if (!mounted) return;
      final msg = e.toString();
      if (!msg.contains('cancelled')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload image: $e'),
            backgroundColor: Constants.redColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _uploading = false;
        });
      }
    }
  }

  void _save() {
    final t = _titleController.text.trim();
    if (t.isEmpty) return;

    final item = <String, dynamic>{
      'title': t,
      'priority': _priority,
    };
    final txt = _textController.text.trim();
    if (txt.isNotEmpty) item['text'] = txt;
    final img = _imageUrl.trim();
    if (img.isNotEmpty) item['imageUrl'] = img;
    Navigator.of(context).pop(item);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Constants.blackColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.isEdit ? 'Edit Feed Item' : 'Add Feed Item',
                style: const TextStyle(
                  color: Constants.whiteColor,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Constants.whiteColor),
                decoration: _decoration('Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                style: const TextStyle(color: Constants.whiteColor),
                decoration: _decoration('Text (optional)'),
                maxLines: 3,
              ),
              const SizedBox(height: 12),
              if (_imageUrl.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrl,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: _uploading ? null : _pickImage,
                    icon: _uploading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Constants.creamColor,
                            ),
                          )
                        : const Icon(Icons.image, color: Constants.creamColor),
                    label: const Text(
                      'Add Image',
                      style: TextStyle(color: Constants.creamColor),
                    ),
                  ),
                  if (_imageUrl.isNotEmpty)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _imageUrl = '';
                        });
                      },
                      child: const Text(
                        'Remove',
                        style: TextStyle(color: Constants.creamColor),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Priority',
                  style: TextStyle(color: Constants.creamColor),
                ),
                value: _priority,
                activeColor: Constants.redColor,
                onChanged: (v) {
                  setState(() {
                    _priority = v;
                  });
                },
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _uploading ? null : () => Navigator.of(context).pop(),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Constants.creamColor),
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Constants.redColor,
                      foregroundColor: Constants.whiteColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _uploading ? null : _save,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
