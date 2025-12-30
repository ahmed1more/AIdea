import 'package:flutter/material.dart';

class TagInputWidget extends StatefulWidget {
  final List<String> tags;
  final ValueChanged<List<String>> onTagsChanged;

  const TagInputWidget({
    super.key,
    required this.tags,
    required this.onTagsChanged,
  });

  @override
  State<TagInputWidget> createState() => _TagInputWidgetState();
}

class _TagInputWidgetState extends State<TagInputWidget> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _addTag() {
    final tag = _controller.text.trim();
    if (tag.isNotEmpty && !widget.tags.contains(tag)) {
      widget.onTagsChanged([...widget.tags, tag]);
      _controller.clear();
    }
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.tags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _controller,
          decoration: InputDecoration(
            labelText: 'Tags',
            hintText: 'Add tags (press Enter)',
            prefixIcon: const Icon(Icons.label),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
            ),
          ),
          onSubmitted: (_) => _addTag(),
        ),
        if (widget.tags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () => _removeTag(tag),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}
