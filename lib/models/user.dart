class User {
  final String uid;
  final String email;
  final String name;
  final String? photoUrl;
  final bool isPremium;
  final List<String> purchasedTools;
  final DateTime createdAt;

  User({required this.uid, required this.email, required this.name, this.photoUrl, this.isPremium = false, this.purchasedTools = const [], required this.createdAt});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(uid: json['uid'], email: json['email'], name: json['name'], photoUrl: json['photoUrl'], isPremium: json['isPremium'] ?? false, purchasedTools: List<String>.from(json['purchasedTools'] ?? []), createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now());
  }

  Map<String, dynamic> toJson() {
    return {'uid': uid, 'email': email, 'name': name, 'photoUrl': photoUrl, 'isPremium': isPremium, 'purchasedTools': purchasedTools, 'createdAt': createdAt.toIso8601String()};
  }

  User copyWith({String? uid, String? email, String? name, String? photoUrl, bool? isPremium, List<String>? purchasedTools, DateTime? createdAt}) {
    return User(uid: uid ?? this.uid, email: email ?? this.email, name: name ?? this.name, photoUrl: photoUrl ?? this.photoUrl, isPremium: isPremium ?? this.isPremium, purchasedTools: purchasedTools ?? this.purchasedTools, createdAt: createdAt ?? this.createdAt);
  }
}
