class Business {
  final String id;
  final String name;
  final String industry;
  final String description;
  final String? logo;
  final String ownerId;
  final DateTime createdAt;
  final Map<String, dynamic>? additionalInfo;

  Business({required this.id, required this.name, required this.industry, required this.description, this.logo, required this.ownerId, required this.createdAt, this.additionalInfo});

  factory Business.fromJson(Map<String, dynamic> json) {
    return Business(id: json['id'], name: json['name'], industry: json['industry'], description: json['description'], logo: json['logo'], ownerId: json['ownerId'], createdAt: DateTime.parse(json['createdAt']), additionalInfo: json['additionalInfo']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'industry': industry, 'description': description, 'logo': logo, 'ownerId': ownerId, 'createdAt': createdAt.toIso8601String(), 'additionalInfo': additionalInfo};
  }

  Business copyWith({String? id, String? name, String? industry, String? description, String? logo, String? ownerId, DateTime? createdAt, Map<String, dynamic>? additionalInfo}) {
    return Business(
      id: id ?? this.id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      description: description ?? this.description,
      logo: logo ?? this.logo,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
      additionalInfo: additionalInfo ?? this.additionalInfo,
    );
  }
}
