class UserProfile {
  final String name;

  /// The exact interest option labels the user tapped, e.g.
  /// ["Machine Learning", "Astrophysics"]. Kept for display purposes
  /// (e.g. showing chips back in Settings as selected).
  final List<String> interests;

  /// Deduplicated backend subject keys derived from `interests`, e.g.
  /// ["computer-science", "space"]. Used to pick which subject to fetch.
  final List<String> matchedSubjects;

  const UserProfile({
    required this.name,
    required this.interests,
    required this.matchedSubjects,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'interests': interests,
        'matchedSubjects': matchedSubjects,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      interests: (json['interests'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      matchedSubjects: (json['matchedSubjects'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );
  }
}
