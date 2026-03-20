import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/sync_provider.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'web_signin_stub.dart' if (dart.library.js_interop) 'package:google_sign_in_web/web_only.dart' as web;

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final autoSync = ref.watch(autoSyncProvider);
    final driveService = GoogleDriveService();

    // Listen for conflict state to show dialog
    ref.listen<SyncStateData>(syncProvider, (previous, next) {
      if (next.state == SyncState.conflict) {
        _showConflictDialog(context, ref);
      } else if (next.state == SyncState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sync completed successfully!')),
        );
      } else if (next.state == SyncState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Sync error: ${next.errorMessage}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Sync Settings',
          style: GoogleFonts.nunito(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ],
              ),
              child: ValueListenableBuilder<bool>(
                valueListenable: driveService.isSignedInNotifier,
                builder: (context, isSignedIn, child) {
                  return isSignedIn
                      ? Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundImage: driveService.currentUser?.photoUrl != null
                              ? NetworkImage(driveService.currentUser!.photoUrl!)
                              : null,
                          child: driveService.currentUser?.photoUrl == null
                              ? const Icon(Icons.person, size: 30)
                              : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driveService.currentUser?.displayName ?? 'User',
                                style: GoogleFonts.nunito(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                driveService.currentUser?.email ?? '',
                                style: GoogleFonts.nunito(
                                  color: Colors.grey[600],
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.red),
                          onPressed: () => ref.read(syncProvider.notifier).signOut(),
                        )
                      ],
                    )
                  : Column(
                      children: [
                        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Not signed in to Google Drive',
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (kIsWeb)
                          web.renderButton()
                        else
                          ElevatedButton.icon(
                            onPressed: () => ref.read(syncProvider.notifier).signIn(),
                            icon: const Icon(Icons.login),
                            label: const Text('Sign In with Google'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          )
                      ],
                    );
                },
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Auto Sync Toggle
            SwitchListTile(
              title: Text(
                'Auto-sync weekly',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                'Automatically backup data every week when you open the app',
                style: GoogleFonts.nunito(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              value: autoSync,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) {
                ref.read(autoSyncProvider.notifier).toggle(val);
              },
            ),

            const SizedBox(height: 32),

            // Sync Information
            ValueListenableBuilder<bool>(
              valueListenable: driveService.isSignedInNotifier,
              builder: (context, isSignedIn, child) {
                if (!isSignedIn) return const SizedBox.shrink();
                return Column(
                  children: [
                    Text(
                      'Last Synced: ${driveService.lastSyncedTime != null ? _formatDateTime(driveService.lastSyncedTime!) : "Never"}',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const Spacer(),
                    // Sync Now Button
                    ElevatedButton(
                      onPressed: syncState.state == SyncState.syncing
                          ? null
                          : () => ref.read(syncProvider.notifier).handleSync(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 5,
                      ),
                      child: syncState.state == SyncState.syncing
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.sync),
                                const SizedBox(width: 8),
                                Text(
                                  'Sync Now',
                                  style: GoogleFonts.nunito(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                    )
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showConflictDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          'Sync Conflict Detected',
          style: GoogleFonts.nunito(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'We found existing data on Google Drive. What do you want to do?',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(syncProvider.notifier).resolveConflict(overwriteLocal: true);
            },
            child: const Text('Overwrite Local Data', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(syncProvider.notifier).resolveConflict(overwriteLocal: false);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
            child: const Text('Upload Local Data', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
           '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
