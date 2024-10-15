import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mime_flutter/widgets/dialog_with_textfield.dart';

class TagEditorPage extends StatefulWidget {
  const TagEditorPage({super.key, required this.tags});

  final Set<String> tags;

  static const routePath = "/tag-editor";
  static const routeName = "Tag Editor";

  @override
  State<TagEditorPage> createState() => _TagEditorPageState();
}

class _TagEditorPageState extends State<TagEditorPage> {
  Set<String> tags = {};

  @override
  void initState() {
    super.initState();
    tags = Set.from(widget.tags);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Tags"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: () {
              context.pop(tags);
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: tags.length,
        itemBuilder: (context, index) {
          final tag = tags.elementAt(index);
          return ListTile(
            title: Text(tag),
            trailing: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                setState(() {
                  tags.remove(tag);
                });
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newTag = await showDialog<String>(
            context: context,
            builder: (context) {
              return DialogWithTextfield(
                title: "Add Tag",
                hintText: "Enter tag",
                labelText: "Tag",
                validator: (value) {
                  if (value?.trim().isEmpty ?? true) {
                    return "Tag cannot be empty";
                  }

                  if (tags.contains(value)) {
                    return "Tag already exists";
                  }

                  return null;
                },
              );
            },
          );

          if (newTag != null) {
            setState(() {
              tags.add(newTag);
            });
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
