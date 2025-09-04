import 'dart:convert';

enum ContentType {
  featureCentricTutorial,
  comparative,
  conceptualRedefinition,
  blueprintSeries,
  debugForensics;

  String get displayName {
    switch (this) {
      case ContentType.featureCentricTutorial:
        return 'Feature-centric Tutorial';
      case ContentType.comparative:
        return 'Comparative';
      case ContentType.conceptualRedefinition:
        return 'Conceptual Redefinition / Vision-setting';
      case ContentType.blueprintSeries:
        return 'Blueprint Series';
      case ContentType.debugForensics:
        return 'Debug/forensics Live Fix';
    }
  }

  String get description {
    switch (this) {
      case ContentType.featureCentricTutorial:
        return 'launches, updates';
      case ContentType.comparative:
        return 'multi-tool and/or multi-vendor';
      case ContentType.conceptualRedefinition:
        return 'thought leadership';
      case ContentType.blueprintSeries:
        return 'project-based, multi-episode';
      case ContentType.debugForensics:
        return 'trust-building';
    }
  }

  String get outlineTemplate {
    switch (this) {
      case ContentType.featureCentricTutorial:
        return '''• Promise line
• Problem snapshot tied to the feature
• Solution overview with criteria
• Visual map
• Demo spine (setup → core use → validation → edge case)
• Value callouts
• Measurable finish
• Next steps and branches
• Transparency and roadmap''';
      case ContentType.comparative:
        return '''• Promise line
• Problem snapshot framed as a workflow (ingest → transform → orchestrate → deliver)
• Solution overview with evaluation matrix (criteria slide)
• Visual map of the end-to-end pipeline
• Demo spine in stages; each stage shows 2–3 tool variants
• Decision points per stage: when to use which
• Cost/time/risk callouts
• Measurable finish with an at-a-glance summary
• Next steps: choose-your-own-path by role''';
      case ContentType.conceptualRedefinition:
        return '''• Provocation: name the bad frame, define the better one
• Historical arc: why the old frame existed
• New mental model with levels of abstraction
• Case studies or short proof clips
• Criteria for evaluating platforms under the new model
• Practical starter pack (templates, patterns)
• Call for feedback and community contributions''';
      case ContentType.blueprintSeries:
        return '''Episode structure:
• Promise line + recap of previous episode
• Today's objective and acceptance criteria
• Visual map zoomed to current layer
• Demo spine (task chunks)
• Integration tests or validations
• Risks and mitigations
• Homework and resources

Series arc:
• Episode 1: Architecture and scaffolding
• Episode 2 - X
• Episode X: Round-up and Next Steps''';
      case ContentType.debugForensics:
        return '''• Problem snapshot: reproduce the bug
• Hypotheses list (ranked)
• Instrumentation (logs, metrics, traces)
• Fix attempts (narrate tradeoffs)
• Root cause and lesson
• Preventative guardrails''';
    }
  }

  static ContentType fromString(String value) {
    switch (value) {
      case 'featureCentricTutorial':
        return ContentType.featureCentricTutorial;
      case 'comparative':
        return ContentType.comparative;
      case 'conceptualRedefinition':
        return ContentType.conceptualRedefinition;
      case 'blueprintSeries':
        return ContentType.blueprintSeries;
      case 'debugForensics':
        return ContentType.debugForensics;
      default:
        return ContentType.featureCentricTutorial;
    }
  }
}

class ContentItem {
  final String id;
  final String? userId;
  String title;
  String description;
  String url;
  List<String> attachments;
  DateTime? dateScheduled;
  DateTime? datePublished;
  String videoLink;
  bool isPrivate;
  ContentType contentType;
  String outline;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ContentItem({
    required this.id,
    this.userId,
    required this.title,
    this.description = '',
    this.url = '',
    this.attachments = const [],
    this.dateScheduled,
    this.datePublished,
    this.videoLink = '',
    this.isPrivate = false,
    this.contentType = ContentType.featureCentricTutorial,
    this.outline = '',
    this.createdAt,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'title': title,
    'description': description,
    'url': url,
    'attachments': attachments,
    'date_scheduled': dateScheduled?.toIso8601String(),
    'date_published': datePublished?.toIso8601String(),
    'video_link': videoLink,
    'is_private': isPrivate,
    'content_type': contentType.name,
    'outline': outline,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
  };

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
    id: json['id'],
    userId: json['user_id'],
    title: json['title'] ?? '',
    description: json['description'] ?? '',
    url: json['url'] ?? '',
    attachments: List<String>.from(json['attachments'] ?? []),
    dateScheduled: json['date_scheduled'] != null
        ? DateTime.parse(json['date_scheduled'])
        : null,
    datePublished: json['date_published'] != null
        ? DateTime.parse(json['date_published'])
        : null,
    videoLink: json['video_link'] ?? '',
    isPrivate: json['is_private'] ?? false,
    contentType: json['content_type'] != null ? ContentType.fromString(json['content_type']) : ContentType.featureCentricTutorial,
    outline: json['outline'] ?? '',
    createdAt: json['created_at'] != null
        ? DateTime.parse(json['created_at'])
        : null,
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'])
        : null,
  );

  ContentItem copyWith({
    String? title,
    String? description,
    String? url,
    List<String>? attachments,
    DateTime? dateScheduled,
    DateTime? datePublished,
    String? videoLink,
    bool? isPrivate,
    ContentType? contentType,
    String? outline,
    bool clearDateScheduled = false,
    bool clearDatePublished = false,
  }) => ContentItem(
    id: id,
    userId: userId,
    title: title ?? this.title,
    description: description ?? this.description,
    url: url ?? this.url,
    attachments: attachments ?? this.attachments,
    dateScheduled: clearDateScheduled ? null : (dateScheduled ?? this.dateScheduled),
    datePublished: clearDatePublished ? null : (datePublished ?? this.datePublished),
    videoLink: videoLink ?? this.videoLink,
    isPrivate: isPrivate ?? this.isPrivate,
    contentType: contentType ?? this.contentType,
    outline: outline ?? this.outline,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}