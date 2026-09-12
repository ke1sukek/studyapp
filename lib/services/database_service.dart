import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DatabaseService {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();

  // =========================
  // ユーザー
  // =========================

  Future<Map?> getUser(String uid) async {
    final snapshot = await _db.child('users/$uid').get();

    if (!snapshot.exists) {
      return null;
    }

    return Map<String, dynamic>.from(snapshot.value as Map);
  }

  Future<void> createUser({
    required String uid,
    required String name,
    required String photoURL,
  }) async {
    await _db.child('users/$uid').set({
      'name': name,
      'photoURL': photoURL,
      'totalSeconds': 0,
      'todaySeconds': 0,
      'lastStudyDate': '',
      'streak': 0,
      'createdAt': DateTime.now().millisecondsSinceEpoch,
      'version': 1,
      'online': true,
    });
  }

  // users/{uid} が存在することを保証する
  Future<void> ensureUser(User user) async {
    final userData = await getUser(user.uid);

    if (userData == null) {
      await createUser(
        uid: user.uid,
        name: user.displayName ?? '',
        photoURL: user.photoURL ?? '',
      );
    }
  }

  // ユーザーデータをリアルタイム監視
  Stream<Map?> userStream(String uid) {
    return _db.child('users/$uid').onValue.map((event) {
      final value = event.snapshot.value;

      if (value == null) {
        return null;
      }

      return Map<String, dynamic>.from(value as Map);
    });
  }

  Future<void> updateStudyData({
    required String uid,
    required int totalSeconds,
    required int todaySeconds,
    required String lastStudyDate,
  }) async {
    await _db.child('users/$uid').update({
      'totalSeconds': totalSeconds,
      'todaySeconds': todaySeconds,
      'lastStudyDate': lastStudyDate,
    });
  }

  Future<void> updateStreak({
    required String uid,
    required int streak,
    required String lastStudyDate,
  }) async {
    await _db.child('users/$uid').update({
      'streak': streak,
      'lastStudyDate': lastStudyDate,
    });
  }

  Future<void> updateName({
    required String uid,
    required String name,
  }) async {
    await _db.child('users/$uid/name').set(name);
  }

  // =========================
  // オンライン状態
  // =========================

  Future<void> setOnline(String uid) async {
    final onlineRef = _db.child('users/$uid/online');

    await onlineRef.onDisconnect().set(false);

    await onlineRef.set(true);
  }

  Future<void> setOffline(String uid) async {
    await _db.child('users/$uid/online').set(false);
  }

  Stream<bool> onlineStream(String uid) {
    return _db.child('users/$uid/online').onValue.map((event) {
      return event.snapshot.value == true;
    });
  }

  // =========================
  // ユーザー検索
  // =========================

  Future<List<Map<String, dynamic>>> searchUsers(
    String keyword,
  ) async {
    final snapshot = await _db
        .child('users')
        .orderByChild('name')
        .startAt(keyword)
        .endAt('$keyword\uf8ff')
        .get();

    if (!snapshot.exists) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return data.entries.map((entry) {
      final user = Map<String, dynamic>.from(entry.value as Map);

      return {
        'uid': entry.key,
        ...user,
      };
    }).toList();
  }

  // =========================
  // フレンド
  // =========================

  Future<List<String>> getFriendUids(String uid) async {
    final snapshot = await _db.child('friends/$uid').get();

    if (!snapshot.exists) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return data.keys.toList();
  }

  Future<List<Map<String, dynamic>>> getFriends(String uid) async {
    final friendUids = await getFriendUids(uid);

    final friends = <Map<String, dynamic>>[];

    for (final friendUid in friendUids) {
      final user = await getUser(friendUid);

      if (user != null) {
        friends.add({
          'uid': friendUid,
          ...user,
        });
      }
    }

    return friends;
  }

  Future<void> addFriend({
    required String myUid,
    required String friendUid,
  }) async {
    await _db.update({
      'friends/$myUid/$friendUid': true,
      'friends/$friendUid/$myUid': true,
    });
  }

  Future<void> removeFriend({
    required String myUid,
    required String friendUid,
  }) async {
    await _db.update({
      'friends/$myUid/$friendUid': null,
      'friends/$friendUid/$myUid': null,
    });
  }

  // =========================
  // 友達申請
  // =========================

  Future<void> sendFriendRequest({
    required String senderUid,
    required String receiverUid,
  }) async {
    final sender = await getUser(senderUid);

    if (sender == null) {
      throw Exception('送信者のユーザー情報がありません');
    }

    await _db
        .child('friendRequests/$receiverUid/$senderUid')
        .set({
      'sentAt': DateTime.now().millisecondsSinceEpoch,
      'name': sender['name'] ?? '',
      'photoURL': sender['photoURL'] ?? '',
    });
  }

  Future<List<Map<String, dynamic>>> getFriendRequests(
    String uid,
  ) async {
    final snapshot = await _db.child('friendRequests/$uid').get();

    if (!snapshot.exists) {
      return [];
    }

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    return data.entries.map((entry) {
      final request = Map<String, dynamic>.from(entry.value as Map);

      return {
        'uid': entry.key,
        ...request,
      };
    }).toList();
  }

  Future<void> acceptFriendRequest({
    required String myUid,
    required String senderUid,
  }) async {
    await _db.update({
      'friends/$myUid/$senderUid': true,
      'friends/$senderUid/$myUid': true,
      'friendRequests/$myUid/$senderUid': null,
    });
  }

  Future<void> rejectFriendRequest({
    required String myUid,
    required String senderUid,
  }) async {
    await _db
        .child('friendRequests/$myUid/$senderUid')
        .remove();
  }

  Future<void> cancelFriendRequest({
    required String senderUid,
    required String receiverUid,
  }) async {
    await _db
        .child('friendRequests/$receiverUid/$senderUid')
        .remove();
  }
}