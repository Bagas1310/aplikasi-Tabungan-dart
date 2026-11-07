import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/services/export_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/hemat_repository.dart';
import '../../../data/repositories/savings_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../shared/formatters/formatters.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => ProfileScreenState();
}

class ProfileScreenState extends State<ProfileScreen> {
  final _authRepo = AuthRepository();
  final _savingsRepo = SavingsRepository();
  final _txRepo = TransactionRepository();
  final _hematRepo = HematRepository();

  UserModel? _user;
  int _totalBalance = 0;
  int _savingsCount = 0;
  String _avatarKey = 'initial';
  bool _reminderEnabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = await _authRepo.getCurrentUser();
    if (user == null) return;

    final total = await _savingsRepo.getTotalBalance(user.id!);
    final count = await _savingsRepo.getActiveSavingsCount(user.id!);

    final reminder = await NotificationService.isReminderEnabled();

    if (!mounted) return;
    setState(() {
      _user = user;
      _totalBalance = total;
      _savingsCount = count;
      _reminderEnabled = reminder;
      _loading = false;
    });
  }

  Widget _buildPlaceholderAvatar({double fontSize = 32}) {
    final initial = (_user?.name.isNotEmpty == true)
        ? _user!.name.trim()[0].toUpperCase()
        : 'U';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _showAvatarPicker() async {
    if (_user == null) return;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Foto Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Tombol Kamera
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.camera);
                },
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Ambil Foto dengan Kamera'),
              ),
              const SizedBox(height: 12),
              // Tombol Galeri
              OutlinedButton.icon(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await _pickImage(ImageSource.gallery);
                },
                icon: const Icon(Icons.photo_library_rounded),
                label: const Text('Pilih dari Galeri'),
              ),
              const SizedBox(height: 16),
              // Tombol Hapus Foto
              if (_user?.profileImage != null &&
                  _user!.profileImage!.isNotEmpty)
                Row(
                  children: [
                    const Icon(
                      Icons.delete_outline,
                      size: 18,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await _clearProfileImage();
                      },
                      icon: const Icon(Icons.delete_outline, size: 18),
                      label: const Text('Hapus Foto Profil'),
                    ),
                  ],
                ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await ImagePicker().pickImage(source: source);
      if (image == null || _user == null) return;

      final directory = await getApplicationDocumentsDirectory();
      final savedImage = File('${directory.path}/profile_${_user!.id}.jpg');

      if (await savedImage.exists()) await savedImage.delete();
      await savedImage.writeAsBytes(await image.readAsBytes(), flush: true);

      // Bersihkan image cache agar foto baru langsung muncul
      await FileImage(savedImage).evict();

      await _authRepo.updateProfileImage(_user!.id!, savedImage.path);

      if (!mounted) return;
      // Update the local model immediately; the database remains the source of truth.
      setState(() {
        _user = _user!.copyWith(profileImage: savedImage.path);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil diperbarui!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal mengambil foto: $e')));
      }
    }
  }

  Future<void> _clearProfileImage() async {
    if (_user != null) {
      await _authRepo.updateProfileImage(_user!.id!, null);
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Foto profil berhasil dihapus!'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void refresh() => _loadData();

  String _formatJoinDate(String? isoDate) {
    if (isoDate == null || isoDate.isEmpty) return '-';
    try {
      final date = DateTime.parse(isoDate);
      return DateFormatter.full(date);
    } catch (_) {
      return isoDate.substring(0, 10);
    }
  }

  // --- Avatar bawaan ---
  // ignore: unused_element
  void _showEmojiAvatarPicker() {
    final avatarOptions = [
      {'key': 'initial', 'label': 'Inisial Nama', 'icon': null},
      {'key': 'icon_person', 'label': 'Pengguna', 'icon': Icons.person},
      {'key': 'emoji_fire', 'label': 'Api Streak', 'emoji': '🔥'},
      {'key': 'emoji_rocket', 'label': 'Roket', 'emoji': '🚀'},
      {'key': 'emoji_diamond', 'label': 'Permata', 'emoji': '💎'},
      {'key': 'emoji_wallet', 'label': 'Dompet', 'emoji': '💼'},
      {'key': 'emoji_star', 'label': 'Bintang', 'emoji': '⭐'},
      {'key': 'emoji_target', 'label': 'Target', 'emoji': '🎯'},
      {
        'key': 'icon_savings',
        'label': 'Tabungan',
        'icon': Icons.savings_outlined,
      },
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Pilih Avatar Profil',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sesuaikan tampilan foto profil akun BAGASSPACXE Anda.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.1,
                ),
                itemCount: avatarOptions.length,
                itemBuilder: (_, i) {
                  final opt = avatarOptions[i];
                  final key = opt['key'] as String;
                  final label = opt['label'] as String;
                  final isSelected = _avatarKey == key;

                  return InkWell(
                    onTap: () async {
                      if (_user != null) {
                        final prefs = await SharedPreferences.getInstance();
                        await prefs.setString('user_avatar_${_user!.id}', key);
                      }
                      setState(() => _avatarKey = key);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Avatar profil berhasil diubah!'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      }
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.12)
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (opt['emoji'] != null)
                            Text(
                              opt['emoji'] as String,
                              style: const TextStyle(fontSize: 28),
                            )
                          else if (opt['icon'] != null)
                            Icon(
                              opt['icon'] as IconData,
                              size: 28,
                              color: AppColors.primary,
                            )
                          else
                            Text(
                              (_user?.name.isNotEmpty == true)
                                  ? _user!.name.trim()[0].toUpperCase()
                                  : 'U',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatarWidget({double fontSize = 32}) {
    // Prioritas 1: Foto profil dari database (user.profileImage)
    if (_user?.profileImage != null && _user!.profileImage!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: Image.file(
          File(_user!.profileImage!),
          width: fontSize * 3,
          height: fontSize * 3,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _buildPlaceholderAvatar(fontSize: fontSize),
        ),
      );
    }

    // Prioritas 2: Emoji/Icon dari SharedPreferences
    if (_avatarKey == 'initial' || _avatarKey.isEmpty) {
      final initial = (_user?.name.isNotEmpty == true)
          ? _user!.name.trim()[0].toUpperCase()
          : 'U';
      return Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final emojiMap = {
      'emoji_fire': '🔥',
      'emoji_rocket': '🚀',
      'emoji_diamond': '💎',
      'emoji_wallet': '💼',
      'emoji_star': '⭐',
      'emoji_target': '🎯',
    };

    if (emojiMap.containsKey(_avatarKey)) {
      return Center(
        child: Text(
          emojiMap[_avatarKey]!,
          style: TextStyle(fontSize: fontSize),
        ),
      );
    }

    if (_avatarKey == 'icon_savings') {
      return Icon(
        Icons.savings_outlined,
        size: fontSize + 6,
        color: Colors.white,
      );
    }

    return Icon(Icons.person, size: fontSize + 6, color: Colors.white);
  }

  // --- 2. Edit Profil & Ganti Password ---
  Future<void> _showEditProfileDialog() async {
    if (_user == null) return;

    final nameCtrl = TextEditingController(text: _user!.name);
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool changePassword = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Profil Pengguna',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () {
                        setModalState(() => changePassword = !changePassword);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Icon(
                              changePassword
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              color: AppColors.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Ganti Kata Sandi (Password)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (changePassword) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: oldPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi Lama',
                          prefixIcon: Icon(Icons.lock_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: newPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Kata Sandi Baru (min 6 karakter)',
                          prefixIcon: Icon(Icons.lock_reset_rounded),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: confirmPassCtrl,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Konfirmasi Kata Sandi Baru',
                          prefixIcon: Icon(Icons.lock_rounded),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final newName = nameCtrl.text.trim();
                          if (newName.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Nama lengkap tidak boleh kosong',
                                ),
                              ),
                            );
                            return;
                          }

                          // 1. Simpan Nama
                          if (newName != _user!.name) {
                            await _authRepo.updateProfile(_user!.id!, newName);
                          }

                          // 2. Simpan Password jika dicentang
                          if (changePassword) {
                            final oldP = oldPassCtrl.text;
                            final newP = newPassCtrl.text;
                            final confirmP = confirmPassCtrl.text;

                            if (oldP.isEmpty) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Masukkan kata sandi lama Anda',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            if (newP.length < 6) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Kata sandi baru minimal 6 karakter',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }
                            if (newP != confirmP) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Konfirmasi kata sandi tidak cocok',
                                    ),
                                  ),
                                );
                              }
                              return;
                            }

                            final res = await _authRepo.updatePassword(
                              _user!.id!,
                              oldP,
                              newP,
                            );
                            if (!res.success) {
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  SnackBar(content: Text(res.message)),
                                );
                              }
                              return;
                            }
                          }

                          if (ctx.mounted) Navigator.pop(ctx);
                          await _loadData();
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profil berhasil diperbarui'),
                              ),
                            );
                          }
                        },
                        child: const Text('Simpan Perubahan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- 3. Toggle Notifikasi ---
  Future<void> _toggleNotification(bool value) async {
    setState(() => _reminderEnabled = value);
    await NotificationService.setReminderEnabled(value);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Pengingat harian diaktifkan (19:00 WIB)'
                : 'Pengingat harian dinonaktifkan',
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // --- 4. Ekspor Data Laporan ---
  Future<String> _generateReportText() async {
    if (_user == null) return '';

    final savings = await _savingsRepo.getSavings(_user!.id!);
    final txs = await _txRepo.getByUser(_user!.id!);
    final hematSummary = await _hematRepo.getSummary(_user!.id!);
    final hematTxs = await _hematRepo.getTransactions(_user!.id!);

    final buffer = StringBuffer();
    buffer.writeln('========================================');
    buffer.writeln('LAPORAN KEUANGAN BAGASSPACXE');
    buffer.writeln('Nama: ${_user!.name}');
    buffer.writeln('Email: ${_user!.email}');
    buffer.writeln('Waktu Ekspor: ${DateFormatter.full(DateTime.now())}');
    buffer.writeln('========================================\n');

    buffer.writeln('[1. RINGKASAN REKAPITULASI]');
    buffer.writeln(
      'Total Saldo Tabungan: ${CurrencyFormatter.format(_totalBalance)}',
    );
    buffer.writeln('Jumlah Target Tabungan: $_savingsCount target');
    buffer.writeln(
      'Sisa Saldo Kas Harian (Hemat): ${CurrencyFormatter.format(hematSummary.currentBalance)}\n',
    );

    buffer.writeln('[2. DAFTAR TARGET TABUNGAN]');
    buffer.writeln('No,Nama,Kategori,Target,Terkumpul,Sisa,Progres');
    if (savings.isEmpty) {
      buffer.writeln('(Belum ada tabungan tercatat)');
    } else {
      for (var i = 0; i < savings.length; i++) {
        final s = savings[i];
        buffer.writeln(
          '${i + 1},"${s.name}","${s.category ?? '-'}",${s.targetAmount},${s.currentAmount},${s.remaining},${s.progressPercent.toStringAsFixed(1)}%',
        );
      }
    }

    buffer.writeln('\n[3. RIWAYAT TRANSAKSI TABUNGAN]');
    buffer.writeln('Tanggal,Tabungan,Tipe,Nominal,Catatan');
    if (txs.isEmpty) {
      buffer.writeln('(Belum ada riwayat transaksi)');
    } else {
      for (final t in txs) {
        buffer.writeln(
          '"${t.transactionDate}","${t.savingsName ?? '-'}","${t.type}",${t.amount},"${t.note ?? '-'}"',
        );
      }
    }

    buffer.writeln('\n[4. CATATAN ARUS KAS (HEMAT)]');
    buffer.writeln(
      'Saldo Awal: ${CurrencyFormatter.format(hematSummary.initialBalance)}',
    );
    buffer.writeln(
      'Total Pemasukan: ${CurrencyFormatter.format(hematSummary.totalIncome)}',
    );
    buffer.writeln(
      'Total Pengeluaran: ${CurrencyFormatter.format(hematSummary.totalExpense)}',
    );
    buffer.writeln(
      'Sisa Saldo: ${CurrencyFormatter.format(hematSummary.currentBalance)}\n',
    );
    buffer.writeln('Tanggal,Tipe,Kategori,Nominal,Keterangan');
    if (hematTxs.isEmpty) {
      buffer.writeln('(Belum ada catatan transaksi harian)');
    } else {
      for (final h in hematTxs) {
        buffer.writeln(
          '"${h.date}","${h.type}","${h.category ?? '-'}","${h.amount}","${h.note ?? '-'}"',
        );
      }
    }

    return buffer.toString();
  }

  Future<void> _showExportDialog() async {
    // Show loading dengan SizedBox constraint jelas
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Dialog(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text('Mengambil data...'),
            ],
          ),
        ),
      ),
    );

    try {
      final report = await _generateReportText();
      if (!mounted) return;

      // Tutup loading
      Navigator.pop(context);

      final timestamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '-')
          .substring(0, 19);
      final fileName = 'BAGASSPACXE_Laporan_$timestamp.txt';

      if (!mounted) return;

      // Show result modal dengan constraint jelas
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return DraggableScrollableSheet(
            initialChildSize: 0.9,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            expand: false,
            builder: (_, scrollController) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 20,
                  right: 20,
                  top: 20,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ekspor Data & Laporan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Data ringkasan tabungan, transaksi, dan catatan harian.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Preview dengan ukuran fixed
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.inputBorder),
                        ),
                        child: SingleChildScrollView(
                          controller: scrollController,
                          child: Text(
                            report,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Tombol aksi dengan wrap untuk prevent overflow
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Tutup'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: report),
                            );
                            if (ctx.mounted) Navigator.pop(ctx);
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Laporan disalin!'),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Salin'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final file = await ExportService.saveReportToFile(
                                report,
                                fileName,
                              );
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      file != null
                                          ? 'Tersimpan: $fileName'
                                          : 'Gagal menyimpan',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.save_rounded, size: 18),
                          label: const Text('Simpan'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              await ExportService.shareReport(report, fileName);
                              if (ctx.mounted) Navigator.pop(ctx);
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.progress,
                          ),
                          icon: const Icon(Icons.share_rounded, size: 18),
                          label: const Text('Bagikan'),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    } catch (e) {
      // Tutup loading jika ada error
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error mengambil data: $e')));
      }
    }
  }

  // --- 5. Tentang Aplikasi (About) ---
  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                gradient: AppColors.gradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.savings_rounded,
                size: 36,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'BAGASSPACXE',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Versi 1.0.0',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Aplikasi manajemen tabungan dan pencatatan arus kas harian (Hemat) offline-first untuk membantu mewujudkan resolusi dan target finansial Anda secara disiplin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: AppColors.progress,
                ),
                SizedBox(width: 6),
                Text(
                  '100% Offline-First SQLite • Data Aman',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Dibuat oleh Tim Pengembang BAGASSPACXE',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ),
        ],
      ),
    );
  }

  // --- 6. Logout ---
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text(
          'Apakah Anda yakin ingin keluar dari akun? Seluruh data tabungan tetap tersimpan aman di database lokal HP Anda.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Batal'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.deleteButton,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Keluar Akun'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _authRepo.logout();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildStatsCard(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildAccountSettingsCard(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildReportAndAppCard(),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 28,
        left: 20,
        right: 20,
      ),
      decoration: const BoxDecoration(gradient: AppColors.gradient),
      child: Column(
        children: [
          // Avatar dengan tombol ganti
          Stack(
            children: [
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8),
                    width: 2.5,
                  ),
                ),
                child: _buildAvatarWidget(),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _showAvatarPicker,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _user?.name ?? '-',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _user?.email ?? '',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  size: 13,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  'Bergabung sejak ${_formatJoinDate(_user?.createdAt)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  CurrencyFormatter.format(_totalBalance),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Total Tabungan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 40, color: AppColors.inputBorder),
          Expanded(
            child: Column(
              children: [
                Text(
                  '$_savingsCount',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Tujuan Tabungan',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountSettingsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Pengaturan Akun',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _actionTile(
            icon: Icons.person_outline_rounded,
            label: 'Edit Profil & Kata Sandi',
            subtitle: 'Ubah nama lengkap atau kata sandi akun',
            onTap: _showEditProfileDialog,
          ),
          Divider(
            height: 0,
            indent: 64,
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
          ListTile(
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: const Text(
              'Pengingat Harian',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            subtitle: const Text(
              'Notifikasi streak pukul 19:00 WIB',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            trailing: Switch.adaptive(
              value: _reminderEnabled,
              activeThumbColor: AppColors.primary,
              onChanged: _toggleNotification,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportAndAppCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 16, top: 16, bottom: 8),
            child: Text(
              'Laporan & Informasi',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          _actionTile(
            icon: Icons.file_download_outlined,
            label: 'Ekspor Data & Laporan',
            subtitle: 'Lihat atau salin ringkasan data format teks/CSV',
            onTap: _showExportDialog,
          ),
          Divider(
            height: 0,
            indent: 64,
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
          _actionTile(
            icon: Icons.info_outline_rounded,
            label: 'Tentang Aplikasi',
            subtitle: 'Versi v1.0.0 & Informasi Pembuat',
            onTap: _showAboutDialog,
          ),
          Divider(
            height: 0,
            indent: 64,
            color: AppColors.inputBorder.withValues(alpha: 0.5),
          ),
          _actionTile(
            icon: Icons.logout_rounded,
            label: 'Keluar',
            subtitle: 'Keluar dari sesi akun saat ini',
            color: AppColors.deleteButton,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    String? subtitle,
    Color? color,
    required VoidCallback onTap,
  }) {
    final c = color ?? AppColors.primary;
    return ListTile(
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: c, size: 20),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: color ?? AppColors.textPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            )
          : null,
      trailing: const Icon(
        Icons.chevron_right,
        color: AppColors.textSecondary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
