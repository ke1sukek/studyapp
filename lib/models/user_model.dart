class UserModel {
  final String name;
  final String photoURL;
  final int totalSeconds;
  final int todaySeconds;
  final String lastStudyDate;
  final int streak;
  final int createdAt;
  final int version;

  UserModel({
    required this.name,
    required this.photoURL,
    required this.totalSeconds,
    required this.todaySeconds,
    required this.lastStudyDate,
    required this.streak,
    required this.createdAt,
    required this.version,
  });

  factory UserModel.fromMap(Map data) {
    return UserModel(
      name: data['name'] ?? '',
      photoURL: data['photoURL'] ?? '',
      totalSeconds: data['totalSeconds'] ?? 0,
      todaySeconds: data['todaySeconds'] ?? 0,
      lastStudyDate: data['lastStudyDate'] ?? '',
      streak: data['streak'] ?? 0,
      createdAt: data['createdAt'] ?? 0,
      version: data['version'] ?? 1,
    );
  }
}