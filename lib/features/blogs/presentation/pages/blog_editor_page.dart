import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../providers/blog_providers.dart';

class BlogEditorPage extends ConsumerStatefulWidget {
  final int? id;
  final String? initialName;
  final String? initialDescription;

  const BlogEditorPage({
    super.key,
    this.id,
    this.initialName,
    this.initialDescription,
  });

  @override
  ConsumerState<BlogEditorPage> createState() =>
      _BlogEditorPageState();
}

class _BlogEditorPageState
    extends ConsumerState<BlogEditorPage> {
  late final TextEditingController name;
  late final TextEditingController description;

  XFile? image;
  bool loading = false;

  @override
  void initState() {
    super.initState();

    name = TextEditingController(
      text: widget.initialName,
    );

    description = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    name.dispose();
    description.dispose();
    super.dispose();
  }

  Future<void> pick() async {
    final selected = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );

    if (selected != null) {
      setState(() => image = selected);
    }
  }

  Future<void> save() async {
    if (name.text.trim().isEmpty ||
        description.text.trim().isEmpty) {
      return;
    }

    setState(() => loading = true);

    try {
      if (widget.id == null) {
        await ref.read(blogsProvider.notifier).create(
              name.text.trim(),
              description.text.trim(),
              image,
            );
      } else {
        await ref.read(blogsProvider.notifier).updateBlog(
              widget.id!,
              name.text.trim(),
              description.text.trim(),
              image,
            );
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.id == null ? 'Write a story' : 'Edit story',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(22),
        children: [
          TextField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Title',
              prefixIcon: Icon(Icons.title_rounded),
            ),
          ),

          const SizedBox(height: 16),

          TextField(
            controller: description,
            maxLines: 9,
            decoration: const InputDecoration(
              labelText: 'Story',
              alignLabelWithHint: true,
              prefixIcon: Padding(
                padding: EdgeInsets.only(bottom: 130),
                child: Icon(Icons.subject_rounded),
              ),
            ),
          ),

          const SizedBox(height: 16),

          InkWell(
            onTap: pick,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black12,
                ),
              ),
              child: Center(
                child: image == null
                    ? const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text('Add a cover image'),
                        ],
                      )
                    : Text(
                        image!.name,
                        overflow: TextOverflow.ellipsis,
                      ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          SizedBox(
            height: 54,
            child: FilledButton(
              onPressed: loading ? null : save,
              child: loading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    )
                  : Text(
                      widget.id == null
                          ? 'Publish story'
                          : 'Save changes',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}