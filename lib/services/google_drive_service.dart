import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' show ValueNotifier, kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;

class GoogleDriveService {
  // 1. Private constructor
  GoogleDriveService._privateConstructor();

  // 2. Singleton instance
  static final GoogleDriveService _instance =
      GoogleDriveService._privateConstructor();

  // 3. Factory constructor
  factory GoogleDriveService() {
    return _instance;
  }

  // Scopes required for hidden AppData folder
  static const List<String> _scopes = [drive.DriveApi.driveAppdataScope];

  drive.DriveApi? _driveApi;
  GoogleSignInAccount? _currentUser;
  
  StreamSubscription<GoogleSignInAuthenticationEvent>? _authSubscription;
  Completer<GoogleSignInAccount>? _signInCompleter;
  
  /// ValueNotifier exposing the current login status reactively to the UI
  final ValueNotifier<bool> isSignedInNotifier = ValueNotifier<bool>(false);

  /// Returns the current signed-in user or null
  GoogleSignInAccount? get currentUser => _currentUser;

  /// Returns true if the user is currently signed in
  bool get isSignedIn => _currentUser != null;

  /// Returns the DriveApi instance if initialized, else null
  drive.DriveApi? get driveApi => _driveApi;

  /// Returns true if Google Sign-In is supported on the current platform
  bool get _isGoogleSignInSupported =>
      kIsWeb ||
      defaultTargetPlatform == TargetPlatform.android ||
      defaultTargetPlatform == TargetPlatform.iOS ||
      defaultTargetPlatform == TargetPlatform.macOS;

  /// Initialize the service by checking for silent sign-in
  Future<void> initialize() async {
    if (!_isGoogleSignInSupported) return;
    try {
      // 1. Initialize GoogleSignIn instance
      // clientId      → used on iOS/macOS/Web
      // serverClientId → required on Android (Web OAuth client ID for Credential Manager)
      await GoogleSignIn.instance.initialize(
        clientId: '934155222240-st2sob8505vc7mbgm6uvfs5d018al253.apps.googleusercontent.com',
        serverClientId: '934155222240-st2sob8505vc7mbgm6uvfs5d018al253.apps.googleusercontent.com',
      );

      // 2. Listen to authentication events
      _authSubscription ??= GoogleSignIn.instance.authenticationEvents.listen(
        (GoogleSignInAuthenticationEvent event) async {
          if (event is GoogleSignInAuthenticationEventSignIn) {
            _currentUser = event.user;
            isSignedInNotifier.value = true;
            // Notify any pending signIn() call that the user is now set
            if (_signInCompleter != null && !_signInCompleter!.isCompleted) {
              _signInCompleter!.complete(event.user);
            }
            // Initialize Drive API (fetch authorization)
            await _initializeDriveApi();
          } else if (event is GoogleSignInAuthenticationEventSignOut) {
            _currentUser = null;
            _driveApi = null;
            isSignedInNotifier.value = false;
          }
        },
        onError: (error) {
          print('Authentication Error: $error');
          if (_signInCompleter != null && !_signInCompleter!.isCompleted) {
            _signInCompleter!.completeError(error);
          }
        },
      );
    } catch (e) {
      // Ignore silent sign-in errors
      print('Silent sign-in failed: $e');
    }

    final prefs = await SharedPreferences.getInstance();
    final lastSyncMillis = prefs.getInt(_lastSyncKey);
    if (lastSyncMillis != null && lastSyncMillis > 0) {
      _lastSyncedTime = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
    }
  }

  /// Triggers the Google Sign-In flow. Throws on failure so callers can show errors.
  Future<void> signIn() async {
    if (!_isGoogleSignInSupported) {
      throw Exception('Google Sign-In is not supported on this platform.');
    }
    // Create a completer that will be resolved by the auth event listener
    _signInCompleter = Completer<GoogleSignInAccount>();
    try {
      // authenticate() triggers the sign-in UI; the result comes via the event stream
      await GoogleSignIn.instance.authenticate();

      // Wait for the stream event to fire and populate _currentUser
      await _signInCompleter!.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Sign-in timed out. Please try again.'),
      );
    } catch (error) {
      _signInCompleter = null;
      _currentUser = null;
      isSignedInNotifier.value = false;
      print('Sign-In Error: $error');
      rethrow; // propagate to SyncNotifier so UI can show the error
    }
    _signInCompleter = null;

    // Now request Drive scope authorization
    await authorize();
  }

  /// Request Drive scope authorization. Throws on failure so callers can show errors.
  Future<void> authorize() async {
    if (!_isGoogleSignInSupported) {
      throw Exception('Google Sign-In is not supported on this platform.');
    }
    if (_currentUser == null) {
      throw Exception('Not signed in. Please sign in first.');
    }
    // Try cached authorization first; if not available, request it
    GoogleSignInClientAuthorization? authorization;
    try {
      authorization = await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
    } catch (_) {
      // Not yet authorized — will request below
    }
    authorization ??= await _currentUser!.authorizationClient.authorizeScopes(_scopes);
    await _initializeDriveApi(authorization);
    if (_driveApi == null) {
      throw Exception('Failed to initialize Drive API after authorization.');
    }
  }

  /// Signs out the current user
  Future<void> signOut() async {
    if (!_isGoogleSignInSupported) return;
    await GoogleSignIn.instance.disconnect();
    _currentUser = null;
    _driveApi = null;
    isSignedInNotifier.value = false;
  }

  /// Initializes the Drive API client after a successful sign-in
  Future<void> _initializeDriveApi([GoogleSignInClientAuthorization? auth]) async {
    if (_currentUser == null) return;
    try {
      // The extension adds authClient() using the _currentUser's authorizationClient
      auth ??= await _currentUser!.authorizationClient.authorizationForScopes(_scopes);
      if (auth != null) {
         final authClient = auth.authClient(scopes: _scopes);
         _driveApi = drive.DriveApi(authClient);
         print('Drive API initialized successfully');
      } else {
        print('User has not authorised drive access');
      }
    } catch (e) {
      print('Error initializing Drive API: $e');
    }
  }

  // Make sure to cancel subscription when disposing
  void dispose() {
    _authSubscription?.cancel();
  }

  static const String _backupFileName = 'backup.json';
  DateTime? _lastSyncedTime;

  /// Returns the last time the data was successfully synced
  DateTime? get lastSyncedTime => _lastSyncedTime;

  /// Helper function with exponential backoff for network/API rate limit errors
  Future<T> _withRetry<T>(Future<T> Function() action, {int maxRetries = 3}) async {
    int retryCount = 0;
    while (true) {
      try {
        return await action();
      } catch (e) {
        if (retryCount >= maxRetries) {
          rethrow;
        }
        // Wait using exponential backoff: 2^retryCount seconds + random jitter
        final delayInSeconds = pow(2, retryCount).toInt();
        final jitterMs = Random().nextInt(1000);
        await Future.delayed(Duration(seconds: delayInSeconds, milliseconds: jitterMs));
        retryCount++;
      }
    }
  }

  /// Helper to find the backup.json file in the appDataFolder space
  Future<drive.File?> _getBackupFile() async {
    if (_driveApi == null) throw Exception('Drive API not initialized. Call signIn() first.');
    
    final fileList = await _withRetry(() => _driveApi!.files.list(
          spaces: 'appDataFolder',
          q: "name = '$_backupFileName'",
          $fields: 'files(id, name, modifiedTime)',
        ));

    if (fileList.files != null && fileList.files!.isNotEmpty) {
      return fileList.files!.first;
    }
    return null;
  }

  /// Uploads data to Google Drive as backup.json, creating or updating it.
  Future<void> uploadData(String jsonData) async {
    if (_driveApi == null) throw Exception('Drive API not initialized. Call signIn() first.');

    // Encode the data using UTF-8 to bytes and convert it into a stream
    final List<int> dataBytes = utf8.encode(jsonData);
    final Stream<List<int>> dataStream = Stream.fromIterable([dataBytes]);
    final media = drive.Media(dataStream, dataBytes.length);

    // Search for existing file
    final existingFile = await _getBackupFile();

    drive.File? resultFile;
    if (existingFile != null && existingFile.id != null) {
      // Update existing file
      final updateFileMeta = drive.File(); // We can pass metadata to update if needed
      resultFile = await _withRetry(() => _driveApi!.files.update(
            updateFileMeta,
            existingFile.id!,
            uploadMedia: media,
            $fields: 'id, modifiedTime',
          ));
    } else {
      // Create new file
      final createMeta = drive.File()
        ..name = _backupFileName
        ..parents = ['appDataFolder'];

      resultFile = await _withRetry(() => _driveApi!.files.create(
            createMeta,
            uploadMedia: media,
            $fields: 'id, modifiedTime',
          ));
    }

    if (resultFile?.modifiedTime != null) {
      _lastSyncedTime = resultFile!.modifiedTime;
    } else {
      _lastSyncedTime = DateTime.now();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, _lastSyncedTime!.millisecondsSinceEpoch);
  }

  /// Downloads and parses the backup.json from Google Drive.
  Future<String?> downloadData() async {
    if (_driveApi == null) throw Exception('Drive API not initialized. Call signIn() first.');

    final existingFile = await _getBackupFile();
    if (existingFile == null || existingFile.id == null) {
      return null; // Backup file not yet created
    }

    // Retrieve the media stream
    final drive.Media media = (await _withRetry(() => _driveApi!.files.get(
          existingFile.id!,
          downloadOptions: drive.DownloadOptions.fullMedia,
        ))) as drive.Media;

    // Reconstruct the bytes and decode back to string
    final List<int> dataStore = [];
    await media.stream.forEach((List<int> chunk) {
      dataStore.addAll(chunk);
    });

    final outputString = utf8.decode(dataStore);
    
    // Update last sync time from file metadata
    if (existingFile.modifiedTime != null) {
      _lastSyncedTime = existingFile.modifiedTime;
    } else {
      _lastSyncedTime = DateTime.now();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_lastSyncKey, _lastSyncedTime!.millisecondsSinceEpoch);

    return outputString;
  }

  static const String _lastSyncKey = 'last_sync_timestamp';

  /// Performs a background sync to Google Drive if it hasn't been synced in 7 days.
  /// 
  /// The [getLocalDataJson] function is a callback that should return the complete 
  /// JSON string representation of the local database to be uploaded.
  Future<void> checkAndSyncWeekly(Future<String> Function() getLocalDataJson) async {
    if (!isSignedIn) {
      return; // Cannot sync if not signed in
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncMillis = prefs.getInt(_lastSyncKey) ?? 0;
      final lastSyncDate = DateTime.fromMillisecondsSinceEpoch(lastSyncMillis);
      final currentDate = DateTime.now();

      final difference = currentDate.difference(lastSyncDate);

      // Only perform background sync if 2 minutes have passed (for testing)
      if (difference.inMinutes >= 2) {
        print('Executing lazy background sync (2 minutes testing)...');
        
        // Make sure Drive API is authorized and initialized before syncing 
        if (_driveApi == null) {
          try {
            await authorize();
          } catch (e) {
            print('Background sync failed: drive access not authorized. $e');
            return;
          }
        }

        // Get the actual data from the app's local database
        final String jsonDataToUpload = await getLocalDataJson();

        // Perform the upload
        await uploadData(jsonDataToUpload);

        // Update the timestamp on success
        await prefs.setInt(_lastSyncKey, DateTime.now().millisecondsSinceEpoch);
        print('Background sync completed successfully.');
      }
    } catch (e) {
      // Catch exceptions to ensure app doesn't crash on startup.
      // E.g. No internet connection, API rate limits, etc.
      print('Lazy weekly sync failed silently: $e');
    }
  }
}
