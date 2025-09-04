import 'package:flutter/material.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/theme.dart';
import 'package:url_launcher/url_launcher.dart';

class ContentItemCard extends StatelessWidget {
  final ContentItem item;
  final VoidCallback? onTap;
  final bool isDraggable;
  final bool isCompact;
  final bool isReadOnly;
  final bool showDate;

  const ContentItemCard({
    super.key,
    required this.item,
    this.onTap,
    this.isDraggable = false,
    this.isCompact = false,
    this.isReadOnly = false,
    this.showDate = false,
  });

  Widget _buildDateBox(BuildContext context) {
    final DateTime? displayDate = item.dateScheduled ?? item.datePublished;
    if (displayDate == null) return const SizedBox.shrink();
    
    final bool isScheduled = item.dateScheduled != null;
    final String dateText = _formatDate(displayDate);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isScheduled ? Icons.schedule : Icons.publish,
            size: 14,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          const SizedBox(width: 4),
          Text(
            dateText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == today) {
      return 'Today';
    } else if (dateOnly == today.add(const Duration(days: 1))) {
      return 'Tomorrow';
    } else if (dateOnly == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else {
      final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                     'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[date.month - 1]} ${date.day}';
    }
  }

  String _getContentTypeShortName(ContentType type) {
    switch (type) {
      case ContentType.featureCentricTutorial:
        return 'Tutorial';
      case ContentType.comparative:
        return 'Compare';
      case ContentType.conceptualRedefinition:
        return 'Vision';
      case ContentType.blueprintSeries:
        return 'Series';
      case ContentType.debugForensics:
        return 'Debug';
    }
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final contentTypeColor = ContentTypeColors.getColor(item.contentType.name, theme.brightness == Brightness.dark);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: contentTypeColor,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 8.0 : 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.isPrivate && isReadOnly ? 'Private Content' : item.title,
                      style: isCompact 
                          ? Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)
                          : Theme.of(context).textTheme.titleMedium,
                      maxLines: isCompact ? 1 : 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (showDate && (item.dateScheduled != null || item.datePublished != null)) ...[
                    const SizedBox(width: 8),
                    _buildDateBox(context),
                  ],
                  if (item.isPrivate && isReadOnly)
                    Icon(
                      Icons.lock,
                      size: isCompact ? 16 : 20,
                      color: Theme.of(context).colorScheme.outline,
                    )
                  else if (item.videoLink.isNotEmpty)
                    GestureDetector(
                      onTap: () => _launchVideoUrl(item.videoLink),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        child: Icon(
                          Icons.play_circle_filled,
                          size: isCompact ? 24 : 28,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                ],
              ),
              if (item.description.isNotEmpty && !isCompact && (!item.isPrivate || !isReadOnly)) ...[
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              if (!isCompact && (!item.isPrivate || !isReadOnly)) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    // Content Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: contentTypeColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: contentTypeColor,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _getContentTypeShortName(item.contentType),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: contentTypeColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (item.attachments.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _showAttachments(context, item.attachments),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.attach_file,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.attachments.length}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    if (item.url.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () => _launchUrl(item.url),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.link,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.url,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.primary,
                                  decoration: TextDecoration.underline,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isDraggable || isReadOnly) {
      return _buildContent(context);
    }

    return LongPressDraggable<ContentItem>(
      data: item,
      delay: const Duration(milliseconds: 500),
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 200,
          constraints: const BoxConstraints(maxHeight: 100),
          child: ContentItemCard(
            item: item,
            isCompact: true,
            isReadOnly: isReadOnly,
            showDate: showDate,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: _buildContent(context),
      ),
      child: _buildContent(context),
    );
  }

  Future<void> _launchVideoUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        debugPrint('Could not launch $url');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
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
        debugPrint('Could not launch $urlToLaunch');
      }
    } catch (e) {
      debugPrint('Error launching URL: $e');
    }
  }

  void _showAttachments(BuildContext context, List<String> attachments) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attachments'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: attachments.length,
              itemBuilder: (context, index) {
                final attachment = attachments[index];
                final bool isUrl = attachment.startsWith('http') || attachment.contains('www.');
                
                return ListTile(
                  dense: true,
                  leading: Icon(
                    isUrl ? Icons.link : Icons.attach_file,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    attachment,
                    style: TextStyle(
                      color: isUrl ? Theme.of(context).colorScheme.primary : null,
                      decoration: isUrl ? TextDecoration.underline : null,
                    ),
                  ),
                  onTap: isUrl ? () => _launchUrl(attachment) : null,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}