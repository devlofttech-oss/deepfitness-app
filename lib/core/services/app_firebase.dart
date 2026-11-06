import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:deepfitness/core/config/firebase_config.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appFirebaseProvider = Provider<AppFirebase>(
  (ref) => AppFirebase(),
);

/// Single point the app reaches Firebase through.
///
/// Repositories take this rather than calling `FirebaseFirestore.instance`
/// directly, so tests can hand in a fake and so a build with no Firebase
/// project configured fails with a readable message instead of a plugin crash.
class AppFirebase {
  // A named parameter cannot start with an underscore, so these cannot be
  // initializing formals even though the fields are private.
  // ignore_for_file: prefer_initializing_formals
  AppFirebase({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) : _auth = auth,
       _firestore = firestore,
       _storage = storage;

  static bool _isInitialized = false;

  static void markInitialized() {
    _isInitialized = true;
  }

  static void markUnavailable() {
    _isInitialized = false;
  }

  final FirebaseAuth? _auth;
  final FirebaseFirestore? _firestore;
  final FirebaseStorage? _storage;

  bool get isConfigured {
    if (_auth != null || _firestore != null) return true;
    return FirebaseConfig.isConfigured && _isInitialized;
  }

  FirebaseAuth get auth => _auth ?? FirebaseAuth.instance;

  FirebaseFirestore get firestore => _firestore ?? FirebaseFirestore.instance;

  FirebaseStorage get storage => _storage ?? FirebaseStorage.instance;

  String? get currentUserId => isConfigured ? auth.currentUser?.uid : null;

  /// Throws when Firebase was never initialised, so screens surface
  /// "not configured" rather than a plugin-level MissingPluginException.
  void requireConfigured() {
    if (!isConfigured) {
      throw StateError(
        'Firebase is not configured. Run flutterfire configure, or pass the '
        'FIREBASE_* dart-defines.',
      );
    }
  }

  String requireUserId() {
    requireConfigured();
    final uid = auth.currentUser?.uid;
    if (uid == null) throw StateError('You are not logged in.');
    return uid;
  }
}

/// Collection names. Plural snake_case, per the developer guide.
class FirestorePaths {
  const FirestorePaths._();

  static const String members = 'members';
  static const String trainers = 'trainers';
  static const String exercises = 'exercises';
  static const String workoutPlans = 'workout_plans';
  static const String assignedPlans = 'assigned_plans';
  static const String completionLogs = 'completion_logs';
  static const String measurements = 'measurements';
  static const String events = 'events';
  static const String eventRsvps = 'event_rsvps';
  static const String groupClasses = 'group_classes';
  static const String classSessions = 'class_sessions';
  static const String bookings = 'bookings';
  static const String announcements = 'announcements';

  // Diet is hidden in the UI but the data model is retained.
  static const String dietPlans = 'diet_plans';
  static const String dietLogs = 'diet_logs';
  static const String waterLogs = 'water_logs';
}
