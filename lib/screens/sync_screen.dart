import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/sync_provider.dart';
import '../services/google_drive_service.dart';
import '../theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'web_signin_stub.dart' if (dart.library.js_interop) 'package:google_sign_in_web/web_only.dart' as web;

class SyncScreen extends ConsumerWidget {
  const SyncScreen({super.key});

  bool get _isGoogleSignInSupported =>
      kIsWeb ||
          defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(syncProvider);
    final autoSync = ref.watch(autoSyncProvider);
    final driveService = GoogleDriveService();

    // Lắng nghe trạng thái để hiển thị thông báo lỗi/thành công khi đồng bộ
    ref.listen<SyncStateData>(syncProvider, (previous, next) {
      if (next.state == SyncState.conflict) {
        _showConflictDialog(context, ref);
      } else if (next.state == SyncState.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đồng bộ thành công!')),
        );
      } else if (next.state == SyncState.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi đồng bộ: ${next.errorMessage}')),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text(
          'Cài đặt đồng bộ',
          style: GoogleFonts.nunito(
            color: AppTheme.textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Khung thông tin tài khoản
            _buildProfileHeader(context, ref, driveService),

            const SizedBox(height: 32),

            // 2. Bật/Tắt tự động đồng bộ
            SwitchListTile(
              title: Text(
                'Tự động đồng bộ hàng tuần',
                style: GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Text(
                'Tự động sao lưu dữ liệu mỗi tuần khi bạn mở ứng dụng',
                style: GoogleFonts.nunito(color: Colors.grey[600], fontSize: 14),
              ),
              value: autoSync,
              activeColor: AppTheme.primaryColor,
              onChanged: (val) => ref.read(autoSyncProvider.notifier).toggle(val),
            ),

            const SizedBox(height: 16),

            // 3. NÚT XÓA TÀI KHOẢN (Nút then chốt để Apple duyệt app)
            ValueListenableBuilder<bool>(
              valueListenable: driveService.isSignedInNotifier,
              builder: (context, isSignedIn, child) {
                if (!isSignedIn) return const SizedBox.shrink();
                return OutlinedButton.icon(
                  onPressed: () => _showDeleteAccountDialog(context, ref),
                  icon: const Icon(Icons.delete_outline, size: 20),
                  label: Text(
                    'Delete Account',
                    style: GoogleFonts.nunito(fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red[400],
                    side: BorderSide(color: Colors.red[200]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                );
              },
            ),

            const Spacer(),

            // 4. Thông tin lần đồng bộ cuối và Nút Sync Now
            _buildSyncFooter(syncState, ref, driveService),
          ],
        ),
      ),
    );
  }

  // Widget hiển thị Profile
  Widget _buildProfileHeader(BuildContext context, WidgetRef ref, GoogleDriveService driveService) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: driveService.isSignedInNotifier,
        builder: (context, isSignedIn, child) {
          if (!isSignedIn) {
            return _buildSignInPlaceholder(ref);
          }
          return Row(
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
                      driveService.currentUser?.displayName ?? 'Người dùng',
                      style: GoogleFonts.nunito(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      driveService.currentUser?.email ?? '',
                      style: GoogleFonts.nunito(color: Colors.grey[600]),
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
          );
        },
      ),
    );
  }

  Widget _buildSignInPlaceholder(WidgetRef ref) {
    return Column(
      children: [
        const Icon(Icons.cloud_off, size: 48, color: Colors.grey),
        const SizedBox(height: 16),
        Text('Chưa đăng nhập Google Drive', style: GoogleFonts.nunito(fontSize: 16)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => ref.read(syncProvider.notifier).signIn(),
          icon: const Icon(Icons.login),
          label: const Text('Đăng nhập với Google'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        )
      ],
    );
  }

  Widget _buildSyncFooter(SyncStateData syncState, WidgetRef ref, GoogleDriveService driveService) {
    return ValueListenableBuilder<bool>(
      valueListenable: driveService.isSignedInNotifier,
      builder: (context, isSignedIn, child) {
        if (!isSignedIn) return const SizedBox.shrink();
        return Column(
          children: [
            Text(
              'Đồng bộ lần cuối: ${driveService.lastSyncedTime != null ? _formatDateTime(driveService.lastSyncedTime!) : "Chưa từng"}',
              style: GoogleFonts.nunito(color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: syncState.state == SyncState.syncing
                  ? null
                  : () => ref.read(syncProvider.notifier).handleSync(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: syncState.state == SyncState.syncing
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync),
                  SizedBox(width: 8),
                  Text('Đồng bộ ngay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            )
          ],
        );
      },
    );
  }

  // --- LOGIC HIỂN THỊ DIALOG XÓA TÀI KHOẢN ---
  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Xác nhận xóa tài khoản?',
            style: GoogleFonts.nunito(fontWeight: FontWeight.bold, color: Colors.red)),
        content: Text(
          'Mọi dữ liệu cá nhân và thông tin đồng bộ của bạn sẽ bị xóa vĩnh viễn khỏi hệ thống. Hành động này không thể hoàn tác.',
          style: GoogleFonts.nunito(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Hủy', style: GoogleFonts.nunito(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Đóng Dialog xác nhận

              // 1. Thực hiện Đăng xuất (Rất quan trọng cho Apple Review)
              await ref.read(syncProvider.notifier).signOut();

              // 2. Hiển thị thông báo như bạn yêu cầu
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Yêu cầu xóa tài khoản của bạn đã được gửi đi thành công.',
                      style: GoogleFonts.nunito(),
                    ),
                    backgroundColor: Colors.green[700],
                    duration: const Duration(seconds: 4),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xác nhận xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
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
