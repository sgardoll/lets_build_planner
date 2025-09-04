import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' show Platform;

class ContentEditDialog extends StatefulWidget {
  final ContentItem item;
  final Function(ContentItem) onSave;
  final Function(ContentItem)? onDelete;
  final bool isReadOnly;

  const ContentEditDialog({
    super.key,
    required this.item,
    required this.onSave,
    this.onDelete,
    this.isReadOnly = false,
  });

  @override
  State<ContentEditDialog> createState() => _ContentEditDialogState();
}

class _ContentEditDialogState extends State<ContentEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _urlController;
  late TextEditingController _videoLinkController;
  late TextEditingController _attachmentController;
  late TextEditingController _outlineController;
  late List<String> _attachments;
  DateTime? _dateScheduled;
  DateTime? _datePublished;
  late bool _isPrivate;
  late ContentType _contentType;
  late FocusNode _titleFocusNode;
  late bool _isNewItem;

  @override
  void initState() {
    super.initState();
    _isNewItem = widget.item.id.isEmpty;
    _titleController = TextEditingController(text: widget.item.title);
    _descriptionController = TextEditingController(text: widget.item.description);
    _urlController = TextEditingController(text: widget.item.url);
    _videoLinkController = TextEditingController(text: widget.item.videoLink);
    _attachmentController = TextEditingController();
    _outlineController = TextEditingController(
      text: widget.item.outline.isEmpty ? widget.item.contentType.outlineTemplate : widget.item.outline
    );
    _attachments = List<String>.from(widget.item.attachments);
    _dateScheduled = widget.item.dateScheduled;
    _datePublished = widget.item.datePublished;
    _isPrivate = widget.item.isPrivate;
    _contentType = widget.item.contentType;
    _titleFocusNode = FocusNode();
    
    // Auto-focus and select text for new items
    if (_isNewItem && !widget.isReadOnly) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _titleFocusNode.requestFocus();
        _titleController.selection = TextSelection(baseOffset: 0, extentOffset: _titleController.text.length);
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _videoLinkController.dispose();
    _attachmentController.dispose();
    _outlineController.dispose();
    _titleFocusNode.dispose();
    super.dispose();
  }

  void _addAttachment() {
    if (_attachmentController.text.trim().isNotEmpty) {
      setState(() {
        _attachments.add(_attachmentController.text.trim());
        _attachmentController.clear();
      });
    }
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      
      if (result != null) {
        String fileName = result.files.single.name;
        String? filePath = result.files.single.path;
        
        setState(() {
          _attachments.add(fileName + (filePath != null ? ' ($filePath)' : ''));
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking file: $e')),
      );
    }
  }

  void _removeAttachment(int index) {
    setState(() {
      _attachments.removeAt(index);
    });
  }

  Future<void> _selectDate(BuildContext context, bool isScheduled) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isScheduled ? _dateScheduled ?? DateTime.now() : _datePublished ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      setState(() {
        if (isScheduled) {
          _dateScheduled = picked;
        } else {
          _datePublished = picked;
        }
      });
    }
  }

  void _save() {
    final updatedItem = widget.item.copyWith(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      url: _urlController.text.trim(),
      videoLink: _videoLinkController.text.trim(),
      attachments: _attachments,
      dateScheduled: _dateScheduled,
      datePublished: _datePublished,
      isPrivate: _isPrivate,
      contentType: _contentType,
      outline: _outlineController.text.trim(),
      clearDateScheduled: _dateScheduled == null,
      clearDatePublished: _datePublished == null,
    );
    widget.onSave(updatedItem);
    Navigator.of(context).pop();
  }

  String _getOutlineHintText() {
    switch (_contentType) {
      case ContentType.featureCentricTutorial:
        return 'Structure for feature launches/updates: Promise → Problem → Solution → Demo → Value → Results';
      case ContentType.comparative:
        return 'Multi-tool comparison: Workflow stages → Tool variants → Decision points → Cost/time analysis';
      case ContentType.conceptualRedefinition:
        return 'Thought leadership: Provocation → Historical context → New model → Case studies → Practical tools';
      case ContentType.blueprintSeries:
        return 'Multi-episode project: Architecture → Build phases → Integration → Testing → Next steps';
      case ContentType.debugForensics:
        return 'Live debugging for trust-building: Problem reproduction → Hypotheses → Investigation → Fix → Prevention';
    }
  }

  Future<void> _delete() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Content'),
          content: const Text('Are you sure you want to delete this content item? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed == true && widget.onDelete != null) {
      widget.onDelete!(widget.item);
      Navigator.of(context).pop();
    }
  }

  Future<void> _launchVideoUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }

  Future<void> _launchUrl(String url) async {
    try {
      // Add https:// if no protocol is specified
      String urlToLaunch = url;
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        urlToLaunch = 'https://$url';
      }
      
      final uri = Uri.parse(urlToLaunch);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $urlToLaunch')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error launching URL: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('MMM dd, yyyy');
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
          maxWidth: 600,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.isReadOnly ? 'Content Details' : (_isNewItem ? 'New Content' : 'Edit Content'),
                  style: theme.textTheme.headlineSmall,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!widget.isReadOnly) ...[
                      // Privacy Toggle in top right
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Private',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(width: 4),
                      Switch(
                        value: _isPrivate,
                        onChanged: (value) => setState(() => _isPrivate = value),
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      const SizedBox(width: 8),
                    ],
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // Title
                  TextField(
                    controller: _titleController,
                    focusNode: _titleFocusNode,
                    enabled: !widget.isReadOnly,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 12),

                  // Content Type Dropdown
                  IgnorePointer(
                    ignoring: widget.isReadOnly,
                    child: DropdownButtonFormField<ContentType>(
                      value: _contentType,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        labelText: 'Content Type',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      items: ContentType.values.map((type) {
                        return DropdownMenuItem(
                          value: type,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  type.displayName,
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                                Text(
                                  '(${type.description})',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                      onChanged: widget.isReadOnly ? null : (ContentType? newType) {
                        if (newType != null) {
                          setState(() {
                            final oldType = _contentType;
                            _contentType = newType;
                            // Update outline template if current outline is empty or matches the old template
                            if (_outlineController.text.isEmpty || _outlineController.text.trim() == oldType.outlineTemplate.trim()) {
                              _outlineController.text = newType.outlineTemplate;
                            }
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                    
                  // Description
                  SizedBox(
                    height: 120,
                    child: TextField(
                      controller: _descriptionController,
                      enabled: !widget.isReadOnly,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Outline
                  SizedBox(
                    height: 120,
                    child: TextField(
                      controller: _outlineController,
                      enabled: !widget.isReadOnly,
                      decoration: InputDecoration(
                        labelText: 'Outline Structure',
                        border: const OutlineInputBorder(),
                        isDense: true,
                        alignLabelWithHint: true,
                        helperText: _getOutlineHintText(),
                        helperMaxLines: 3,
                      ),
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      style: const TextStyle(fontFamily: 'monospace'),
                    ),
                  ),
                  const SizedBox(height: 12),
                    
                  // URL and Video Link in a row for space efficiency
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _urlController,
                          enabled: !widget.isReadOnly,
                          decoration: const InputDecoration(
                            labelText: 'URL',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_urlController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _launchUrl(_urlController.text),
                          icon: Icon(
                            Icons.link,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Open URL',
                        ),
                      ],
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _videoLinkController,
                          enabled: !widget.isReadOnly,
                          decoration: const InputDecoration(
                            labelText: 'Video Link',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      if (_videoLinkController.text.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _launchVideoUrl(_videoLinkController.text),
                          icon: Icon(
                            Icons.play_circle_filled,
                            size: 28,
                            color: theme.colorScheme.primary,
                          ),
                          tooltip: 'Open Video',
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                    
                    
                  // Attachments
                  if (!widget.isReadOnly) ...[
                    Row(
                      children: [
                        Text(
                          'Attachments',
                          style: theme.textTheme.titleSmall,
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: _pickFile,
                          icon: const Icon(Icons.attach_file),
                          tooltip: 'Upload File',
                          iconSize: 20,
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _attachmentController,
                            decoration: const InputDecoration(
                              hintText: 'Or enter URL/attachment name',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            onSubmitted: (_) => _addAttachment(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _addAttachment,
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  ] else if (_attachments.isNotEmpty) ...[
                    Text(
                      'Attachments',
                      style: theme.textTheme.titleSmall,
                    ),
                  ],
                  const SizedBox(height: 8),
                  
                  // Attachment list
                  if (_attachments.isNotEmpty)
                    Container(
                      height: _attachments.length > 3 ? 120 : _attachments.length * 40.0,
                      decoration: BoxDecoration(
                        border: Border.all(color: theme.dividerColor),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _attachments.length,
                        itemBuilder: (context, index) {
                          final attachment = _attachments[index];
                          final bool isUrl = attachment.startsWith('http') || attachment.contains('www.');
                          
                          return ListTile(
                            dense: true,
                            leading: Icon(
                              isUrl ? Icons.link : Icons.attach_file, 
                              size: 16,
                              color: isUrl ? theme.colorScheme.primary : null,
                            ),
                            title: Text(
                              attachment,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isUrl ? theme.colorScheme.primary : null,
                                decoration: isUrl ? TextDecoration.underline : null,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                            onTap: isUrl ? () => _launchUrl(attachment) : null,
                            trailing: widget.isReadOnly ? null : IconButton(
                              icon: const Icon(Icons.delete, size: 16),
                              onPressed: () => _removeAttachment(index),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 12),
                    
                  // Dates in a more compact layout
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Scheduled',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: widget.isReadOnly ? null : () => _selectDate(context, true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 14,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _dateScheduled != null
                                            ? dateFormat.format(_dateScheduled!)
                                            : 'None',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_dateScheduled != null && !widget.isReadOnly)
                                      GestureDetector(
                                        onTap: () => setState(() => _dateScheduled = null),
                                        child: Icon(
                                          Icons.clear,
                                          size: 14,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Published',
                              style: theme.textTheme.labelMedium,
                            ),
                            const SizedBox(height: 4),
                            InkWell(
                              onTap: widget.isReadOnly ? null : () => _selectDate(context, false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: theme.dividerColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.publish,
                                      size: 14,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                    ),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        _datePublished != null
                                            ? dateFormat.format(_datePublished!)
                                            : 'None',
                                        style: theme.textTheme.bodySmall,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (_datePublished != null && !widget.isReadOnly)
                                      GestureDetector(
                                        onTap: () => setState(() => _datePublished = null),
                                        child: Icon(
                                          Icons.clear,
                                          size: 14,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            if (!widget.isReadOnly)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.onDelete != null && !_isNewItem)
                    TextButton(
                      onPressed: _delete,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: const Text('Delete'),
                    )
                  else
                    const SizedBox.shrink(),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save'),
                      ),
                    ],
                  ),
                ],
              )
            else
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}