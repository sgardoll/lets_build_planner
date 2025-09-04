import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/services/supabase_content_service.dart';
import 'package:lets_build_planner/supabase/supabase_config.dart';

class ContentService {
  static const String _contentKey = 'content_items';
  static const Uuid _uuid = Uuid();

  /// Check if user is authenticated
  static bool get isAuthenticated => SupabaseAuth.isAuthenticated;

  /// Load all content items (uses Supabase if authenticated, SharedPreferences otherwise)
  static Future<List<ContentItem>> loadContentItems() async {
    if (isAuthenticated) {
      try {
        return await SupabaseContentService.getAllContentItems();
      } catch (e) {
        // Fallback to local storage if Supabase fails
        return await _loadFromLocalStorage();
      }
    } else {
      return await _loadFromLocalStorage();
    }
  }

  /// Save content items (uses Supabase if authenticated, SharedPreferences otherwise)
  static Future<void> saveContentItems(List<ContentItem> items) async {
    if (isAuthenticated) {
      // When authenticated, don't save to local storage as Supabase handles persistence
      return;
    } else {
      await _saveToLocalStorage(items);
    }
  }

  /// Load content items from local storage
  static Future<List<ContentItem>> _loadFromLocalStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final String? itemsJson = prefs.getString(_contentKey);
    
    if (itemsJson == null) {
      // Return sample data if no saved data exists
      return _getSampleData();
    }
    
    final List<dynamic> itemsList = json.decode(itemsJson);
    return itemsList.map((item) => ContentItem.fromJson(item)).toList();
  }

  /// Save content items to local storage
  static Future<void> _saveToLocalStorage(List<ContentItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final String itemsJson = json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_contentKey, itemsJson);
  }

  /// Get content items for a specific date
  static Future<List<ContentItem>> getContentItemsByDate(DateTime date) async {
    if (isAuthenticated) {
      try {
        return await SupabaseContentService.getContentItemsByDate(date);
      } catch (e) {
        return await _getLocalContentItemsByDate(date);
      }
    } else {
      return await _getLocalContentItemsByDate(date);
    }
  }

  /// Get undated content items
  static Future<List<ContentItem>> getUndatedContentItems() async {
    if (isAuthenticated) {
      try {
        return await SupabaseContentService.getUndatedContentItems();
      } catch (e) {
        return await _getLocalUndatedContentItems();
      }
    } else {
      return await _getLocalUndatedContentItems();
    }
  }

  /// Create a new content item
  static Future<ContentItem> createContentItem({
    required String title,
    String description = '',
    String url = '',
    List<String> attachments = const [],
    DateTime? dateScheduled,
    DateTime? datePublished,
    String videoLink = '',
    bool isPrivate = false,
    ContentType contentType = ContentType.featureCentricTutorial,
    String outline = '',
  }) async {
    if (isAuthenticated) {
      return await SupabaseContentService.createContentItem(
        title: title,
        description: description,
        url: url,
        attachments: attachments,
        dateScheduled: dateScheduled,
        datePublished: datePublished,
        videoLink: videoLink,
        isPrivate: isPrivate,
        contentType: contentType,
        outline: outline,
      );
    } else {
      return ContentItem(
        id: generateId(),
        title: title,
        description: description,
        url: url,
        attachments: attachments,
        dateScheduled: dateScheduled,
        datePublished: datePublished,
        videoLink: videoLink,
        isPrivate: isPrivate,
        contentType: contentType,
        outline: outline.isEmpty ? contentType.outlineTemplate : outline,
      );
    }
  }

  /// Update a content item
  static Future<ContentItem> updateContentItem(ContentItem contentItem) async {
    if (isAuthenticated) {
      return await SupabaseContentService.updateContentItem(contentItem);
    } else {
      // For local storage, return the updated item as-is
      return contentItem;
    }
  }

  /// Delete a content item
  static Future<void> deleteContentItem(String contentItemId) async {
    if (isAuthenticated) {
      await SupabaseContentService.deleteContentItem(contentItemId);
    }
    // For local storage, deletion is handled in the UI by removing from the list
  }

  /// Schedule a content item for a specific date
  static Future<ContentItem> scheduleContentItem(
    String contentItemId,
    DateTime scheduledDate,
  ) async {
    if (isAuthenticated) {
      return await SupabaseContentService.scheduleContentItem(contentItemId, scheduledDate);
    } else {
      throw Exception('Scheduling requires authentication');
    }
  }

  /// Local helper methods
  static Future<List<ContentItem>> _getLocalContentItemsByDate(DateTime date) async {
    final items = await _loadFromLocalStorage();
    return items.where((item) {
      if (item.dateScheduled == null) return false;
      final itemDate = item.dateScheduled!;
      return itemDate.year == date.year &&
             itemDate.month == date.month &&
             itemDate.day == date.day;
    }).toList();
  }

  static Future<List<ContentItem>> _getLocalUndatedContentItems() async {
    final items = await _loadFromLocalStorage();
    return items.where((item) => item.dateScheduled == null).toList();
  }

  static String generateId() => _uuid.v4();

  static List<ContentItem> _getSampleData() => [
    ContentItem(
      id: generateId(),
      title: 'Instagram Story - Behind the Scenes',
      description: 'Share behind-the-scenes content from our latest product photoshoot',
      url: 'https://instagram.com/company',
      attachments: ['photo1.jpg', 'photo2.jpg'],
      videoLink: 'https://youtube.com/watch?v=sample1',
      contentType: ContentType.featureCentricTutorial,
      outline: ContentType.featureCentricTutorial.outlineTemplate,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    ContentItem(
      id: generateId(),
      title: 'Blog Post - Industry Trends 2024',
      description: 'Comprehensive analysis of emerging trends in our industry for the upcoming year',
      url: 'https://blog.company.com/trends-2024',
      attachments: ['research_data.pdf'],
      contentType: ContentType.conceptualRedefinition,
      outline: ContentType.conceptualRedefinition.outlineTemplate,
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    ContentItem(
      id: generateId(),
      title: 'LinkedIn Article - Leadership Tips',
      description: 'Share insights about effective leadership in remote work environments',
      url: 'https://linkedin.com/company',
      contentType: ContentType.comparative,
      outline: ContentType.comparative.outlineTemplate,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    ContentItem(
      id: generateId(),
      title: 'YouTube Video - Product Demo',
      description: 'Detailed walkthrough of our latest product features and benefits',
      attachments: ['script.pdf', 'thumbnail.png'],
      videoLink: 'https://youtube.com/watch?v=demo2024',
      contentType: ContentType.blueprintSeries,
      outline: ContentType.blueprintSeries.outlineTemplate,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    ContentItem(
      id: generateId(),
      title: 'Twitter Thread - Tips & Tricks',
      description: 'Quick tips thread about productivity hacks for entrepreneurs',
      url: 'https://twitter.com/company',
      contentType: ContentType.debugForensics,
      outline: ContentType.debugForensics.outlineTemplate,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ContentItem(
      id: generateId(),
      title: 'Newsletter - Monthly Update',
      description: 'Monthly newsletter featuring company updates, achievements, and upcoming events',
      attachments: ['newsletter_template.html'],
      contentType: ContentType.featureCentricTutorial,
      outline: ContentType.featureCentricTutorial.outlineTemplate,
      createdAt: DateTime.now(),
    ),
    ContentItem(
      id: generateId(),
      title: 'Facebook Post - Community Spotlight',
      description: 'Highlight a community member and their success story with our product',
      url: 'https://facebook.com/company',
      attachments: ['testimonial_image.jpg'],
      contentType: ContentType.comparative,
      outline: ContentType.comparative.outlineTemplate,
      createdAt: DateTime.now(),
    ),
    ContentItem(
      id: generateId(),
      title: 'TikTok Video - Quick Tutorial',
      description: 'Short-form video showing a quick tutorial or life hack related to our niche',
      videoLink: 'https://tiktok.com/@company/video/123456',
      contentType: ContentType.conceptualRedefinition,
      outline: ContentType.conceptualRedefinition.outlineTemplate,
      createdAt: DateTime.now(),
    ),
  ];
}