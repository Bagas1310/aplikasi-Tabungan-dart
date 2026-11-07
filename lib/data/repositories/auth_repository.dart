import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../database/database_helper.dart';
import '../models/user_model.dart';

class AuthRepository {
  final _db = DatabaseHelper.instance;

  String _hashPassword(String password) =>
      sha256.convert(utf8.encode(password)).toString();

  Future<({bool success, String message})> register(
    String name,
    String email,
    String password,
  ) async {
    final db = await _db.database;
    final existing = await db.query(
      'users',
      where: 'email = ?',
      whereArgs: [email.trim().toLowerCase()],
    );
    if (existing.isNotEmpty) {
      return (success: false, message: 'Email sudah terdaftar');
    }
    await db.insert('users', {
      'name': name.trim(),
      'email': email.trim().toLowerCase(),
      'password_hash': _hashPassword(password),
      'created_at': DateTime.now().toIso8601String(),
    });
    return (success: true, message: 'Pendaftaran berhasil');
  }

  Future<UserModel?> login(String email, String password) async {
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'email = ? AND password_hash = ?',
      whereArgs: [email.trim().toLowerCase(), _hashPassword(password)],
    );
    if (results.isEmpty) return null;
    final user = UserModel.fromMap(results.first);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    return user;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_id');
  }

  Future<UserModel?> getCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    if (userId == null) return null;
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (results.isEmpty) return null;
    return UserModel.fromMap(results.first);
  }

  Future<void> updateProfile(int userId, String name) async {
    final db = await _db.database;
    await db.update(
      'users',
      {'name': name.trim()},
      where: 'id = ?',
      whereArgs: [userId],
    );
  }

  Future<void> updateProfileImage(int userId, String? imagePath) async {
    final db = await _db.database;
    final updated = await db.update(
      'users',
      {'profile_image': imagePath},
      where: 'id = ?',
      whereArgs: [userId],
    );
    if (updated != 1) {
      throw StateError('Pengguna tidak ditemukan: $userId');
    }
  }

  Future<({bool success, String message})> updatePassword(
    int userId,
    String oldPassword,
    String newPassword,
  ) async {
    final db = await _db.database;
    final results = await db.query(
      'users',
      where: 'id = ? AND password_hash = ?',
      whereArgs: [userId, _hashPassword(oldPassword)],
    );
    if (results.isEmpty) {
      return (success: false, message: 'Kata sandi saat ini tidak cocok');
    }
    await db.update(
      'users',
      {'password_hash': _hashPassword(newPassword)},
      where: 'id = ?',
      whereArgs: [userId],
    );
    return (success: true, message: 'Kata sandi berhasil diubah');
  }
}
