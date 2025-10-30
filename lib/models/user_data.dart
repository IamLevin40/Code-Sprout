import 'package:cloud_firestore/cloud_firestore.dart';

/// UserData model class that represents user information stored in Firestore.
/// Structure:
/// {
///   "accountInformation": {
///     "username": string
///   },
///   "interaction": {
///     "hasPlayedTutorial": boolean,
///     "hasLearnedModule": boolean
///   }
/// }
class UserData {
  final String uid;
  final String username;
  final bool hasPlayedTutorial;
  final bool hasLearnedModule;

  UserData({
    required this.uid,
    required this.username,
    this.hasPlayedTutorial = false,
    this.hasLearnedModule = false,
  });

  // Reference to Firestore users collection
  static CollectionReference get _usersCollection =>
      FirebaseFirestore.instance.collection('users');

  /// Create UserData from Firestore document snapshot
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    
    if (data == null) {
      throw Exception('Document data is null');
    }

    final accountInfo = data['accountInformation'] as Map<String, dynamic>? ?? {};
    final interaction = data['interaction'] as Map<String, dynamic>? ?? {};

    return UserData(
      uid: doc.id,
      username: accountInfo['username'] as String? ?? '',
      hasPlayedTutorial: interaction['hasPlayedTutorial'] as bool? ?? false,
      hasLearnedModule: interaction['hasLearnedModule'] as bool? ?? false,
    );
  }

  /// Convert UserData to Firestore document format
  Map<String, dynamic> toFirestore() {
    return {
      'accountInformation': {
        'username': username,
      },
      'interaction': {
        'hasPlayedTutorial': hasPlayedTutorial,
        'hasLearnedModule': hasLearnedModule,
      },
    };
  }

  /// Convert UserData to JSON for local storage
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'username': username,
      'hasPlayedTutorial': hasPlayedTutorial,
      'hasLearnedModule': hasLearnedModule,
    };
  }

  /// Create UserData from JSON (for local storage)
  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      uid: json['uid'] as String,
      username: json['username'] as String? ?? '',
      hasPlayedTutorial: json['hasPlayedTutorial'] as bool? ?? false,
      hasLearnedModule: json['hasLearnedModule'] as bool? ?? false,
    );
  }

  /// Save user data to Firestore (creates or updates document)
  Future<void> save() async {
    try {
      await _usersCollection.doc(uid).set(toFirestore());
    } catch (e) {
      throw Exception('Failed to save user data: $e');
    }
  }

  /// Load user data from Firestore by UID
  static Future<UserData?> load(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }

      return UserData.fromFirestore(doc);
    } catch (e) {
      throw Exception('Failed to load user data: $e');
    }
  }

  /// Get username for a specific user
  static Future<String?> getUsername(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return null;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final accountInfo = data?['accountInformation'] as Map<String, dynamic>?;
      return accountInfo?['username'] as String?;
    } catch (e) {
      throw Exception('Failed to get username: $e');
    }
  }

  /// Get hasPlayedTutorial status for a specific user
  static Future<bool> getHasPlayedTutorial(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final interaction = data?['interaction'] as Map<String, dynamic>?;
      return interaction?['hasPlayedTutorial'] as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to get hasPlayedTutorial: $e');
    }
  }

  /// Get hasLearnedModule status for a specific user
  static Future<bool> getHasLearnedModule(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      
      if (!doc.exists) {
        return false;
      }

      final data = doc.data() as Map<String, dynamic>?;
      final interaction = data?['interaction'] as Map<String, dynamic>?;
      return interaction?['hasLearnedModule'] as bool? ?? false;
    } catch (e) {
      throw Exception('Failed to get hasLearnedModule: $e');
    }
  }

  /// Update username
  /// Note: Use FirestoreService.updateUserData() for automatic cache syncing
  Future<void> updateUsername(String newUsername) async {
    try {
      await _usersCollection.doc(uid).update({
        'accountInformation.username': newUsername,
      });
    } catch (e) {
      throw Exception('Failed to update username: $e');
    }
  }

  /// Update hasPlayedTutorial status
  /// Note: Use FirestoreService.updateUserData() for automatic cache syncing
  Future<void> updateHasPlayedTutorial(bool value) async {
    try {
      await _usersCollection.doc(uid).update({
        'interaction.hasPlayedTutorial': value,
      });
    } catch (e) {
      throw Exception('Failed to update hasPlayedTutorial: $e');
    }
  }

  /// Update hasLearnedModule status
  /// Note: Use FirestoreService.updateUserData() for automatic cache syncing
  Future<void> updateHasLearnedModule(bool value) async {
    try {
      await _usersCollection.doc(uid).update({
        'interaction.hasLearnedModule': value,
      });
    } catch (e) {
      throw Exception('Failed to update hasLearnedModule: $e');
    }
  }

  /// Create a copy of UserData with updated fields
  UserData copyWith({
    String? username,
    bool? hasPlayedTutorial,
    bool? hasLearnedModule,
  }) {
    return UserData(
      uid: uid,
      username: username ?? this.username,
      hasPlayedTutorial: hasPlayedTutorial ?? this.hasPlayedTutorial,
      hasLearnedModule: hasLearnedModule ?? this.hasLearnedModule,
    );
  }
}
