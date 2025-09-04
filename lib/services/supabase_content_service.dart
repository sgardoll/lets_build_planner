import 'package:lets_build_planner/models/content_item.dart';
import 'package:lets_build_planner/supabase/supabase_config.dart';
import 'package:uuid/uuid.dart';

/// Content service that handles all content calendar operations with Supabase
class SupabaseContentService {
  static const String _tableName = 'content_items';
  static const _uuid = Uuid();

  /// Get all content items for the current user
  static Future<List<ContentItem>> getAllContentItems() async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final data = await SupabaseService.select(
        _tableName,
        filters: {'user_id': userId},
        orderBy: 'created_at',
        ascending: false,
      );

      return data.map((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load content items: $e');
    }
  }

  /// Get content items for a specific date
  static Future<List<ContentItem>> getContentItemsByDate(DateTime date) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      // Get start and end of the day
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .gte('date_scheduled', startOfDay.toIso8601String())
          .lt('date_scheduled', endOfDay.toIso8601String())
          .order('date_scheduled');

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load content items for date: $e');
    }
  }

  /// Get undated content items (no scheduled date)
  static Future<List<ContentItem>> getUndatedContentItems() async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .isFilter('date_scheduled', null)
          .order('created_at', ascending: false);

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load undated content items: $e');
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
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final id = _uuid.v4();
      final now = DateTime.now();
      
      final contentItem = ContentItem(
        id: id,
        userId: userId,
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
        createdAt: now,
        updatedAt: now,
      );

      final result = await SupabaseService.insert(
        _tableName,
        contentItem.toJson(),
      );

      if (result.isNotEmpty) {
        return ContentItem.fromJson(result.first);
      } else {
        throw Exception('Failed to create content item: Empty result from database');
      }
    } catch (e) {
      throw Exception('Failed to create content item: $e');
    }
  }

  /// Update an existing content item
  static Future<ContentItem> updateContentItem(ContentItem contentItem) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      if (contentItem.userId != userId) {
        throw Exception('Not authorized to update this content item');
      }

      final result = await SupabaseService.update(
        _tableName,
        contentItem.toJson(),
        filters: {'id': contentItem.id, 'user_id': userId},
      );

      if (result.isNotEmpty) {
        return ContentItem.fromJson(result.first);
      } else {
        throw Exception('Failed to update content item: Empty result from database');
      }
    } catch (e) {
      throw Exception('Failed to update content item: $e');
    }
  }

  /// Delete a content item
  static Future<void> deleteContentItem(String contentItemId) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      await SupabaseService.delete(
        _tableName,
        filters: {'id': contentItemId, 'user_id': userId},
      );
    } catch (e) {
      throw Exception('Failed to delete content item: $e');
    }
  }

  /// Schedule a content item for a specific date
  static Future<ContentItem> scheduleContentItem(
    String contentItemId,
    DateTime scheduledDate,
  ) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final result = await SupabaseService.update(
        _tableName,
        {'date_scheduled': scheduledDate.toIso8601String()},
        filters: {'id': contentItemId, 'user_id': userId},
      );

      if (result.isNotEmpty) {
        return ContentItem.fromJson(result.first);
      } else {
        throw Exception('Failed to schedule content item: Empty result from database');
      }
    } catch (e) {
      throw Exception('Failed to schedule content item: $e');
    }
  }

  /// Unschedule a content item (remove scheduled date)
  static Future<ContentItem> unscheduleContentItem(String contentItemId) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final result = await SupabaseService.update(
        _tableName,
        {'date_scheduled': null},
        filters: {'id': contentItemId, 'user_id': userId},
      );

      if (result.isNotEmpty) {
        return ContentItem.fromJson(result.first);
      } else {
        throw Exception('Failed to unschedule content item: Empty result from database');
      }
    } catch (e) {
      throw Exception('Failed to unschedule content item: $e');
    }
  }

  /// Mark a content item as published
  static Future<ContentItem> markAsPublished(
    String contentItemId,
    DateTime publishedDate,
  ) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final result = await SupabaseService.update(
        _tableName,
        {'date_published': publishedDate.toIso8601String()},
        filters: {'id': contentItemId, 'user_id': userId},
      );

      if (result.isNotEmpty) {
        return ContentItem.fromJson(result.first);
      } else {
        throw Exception('Failed to mark content item as published: Empty result from database');
      }
    } catch (e) {
      throw Exception('Failed to mark content item as published: $e');
    }
  }

  /// Get content items by month for calendar view
  static Future<List<ContentItem>> getContentItemsByMonth(
    int year,
    int month,
  ) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .gte('date_scheduled', startOfMonth.toIso8601String())
          .lt('date_scheduled', endOfMonth.toIso8601String())
          .order('date_scheduled');

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load content items for month: $e');
    }
  }

  /// Search content items by title or description
  static Future<List<ContentItem>> searchContentItems(String query) async {
    try {
      final userId = SupabaseAuth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .or('title.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false);

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search content items: $e');
    }
  }

  /// Get all public (non-private) content items across all users
  static Future<List<ContentItem>> getAllPublicContentItems({int? limit}) async {
    try {
      dynamic query = SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('is_private', false)
          .order('created_at', ascending: false);
      if (limit != null) {
        query = query.limit(limit);
      }
      final result = await query;
      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load public content items: $e');
    }
  }

  /// Get public (non-private) content items for a specific user (for sharing view)
  static Future<List<ContentItem>> getPublicContentItems(String userId) async {
    try {
      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .eq('is_private', false)
          .order('created_at', ascending: false);

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load public content items: $e');
    }
  }

  /// Get public content items for a specific date and user
  static Future<List<ContentItem>> getPublicContentItemsByDate(String userId, DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .eq('is_private', false)
          .gte('date_scheduled', startOfDay.toIso8601String())
          .lt('date_scheduled', endOfDay.toIso8601String())
          .order('date_scheduled');

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load public content items for date: $e');
    }
  }

  /// Get public undated content items for a user
  static Future<List<ContentItem>> getPublicUndatedContentItems(String userId) async {
    try {
      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .eq('is_private', false)
          .isFilter('date_scheduled', null)
          .order('created_at', ascending: false);

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load public undated content items: $e');
    }
  }

  /// Get public content items by month for a user
  static Future<List<ContentItem>> getPublicContentItemsByMonth(
    String userId,
    int year,
    int month,
  ) async {
    try {
      final startOfMonth = DateTime(year, month, 1);
      final endOfMonth = DateTime(year, month + 1, 1);

      final result = await SupabaseConfig.client
          .from(_tableName)
          .select('*')
          .eq('user_id', userId)
          .eq('is_private', false)
          .gte('date_scheduled', startOfMonth.toIso8601String())
          .lt('date_scheduled', endOfMonth.toIso8601String())
          .order('date_scheduled');

      return result.map<ContentItem>((json) => ContentItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load public content items for month: $e');
    }
  }
}