import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/validators/validators.dart';
import '../../../data/models/savings_model.dart';
import '../../../data/repositories/savings_repository.dart';
import '../../../shared/widgets/rupiah_input.dart';

class EditSavingsScreen extends StatefulWidget {
  final SavingsModel savings;
  const EditSavingsScreen({super.key, required this.savings});

  @override
  State<EditSavingsScreen> createState() => _EditSavingsScreenState();
}

class _EditSavingsScreenState extends State<EditSavingsScreen> {
  late final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController(text: widget.savings.name);
  late final _targetCtrl = TextEditingController(
    text: widget.savings.targetAmount.toString(),
  );
  late final _descCtrl = TextEditingController(
    text: widget.savings.description ?? '',
  );
  late String _category = widget.savings.category ?? savingsCategories.first;
  late DateTime? _deadline = widget.savings.deadline != null
      ? DateTime.tryParse(widget.savings.deadline!)
      : null;

  final _repo = SavingsRepository();
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final target = int.parse(
      _targetCtrl.text.replaceAll(RegExp(r'[^0-9]'), ''),
    );
    final now = DateTime.now().toIso8601String();
    final updated = SavingsModel(
      id: widget.savings.id,
      userId: widget.savings.userId,
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
      category: _category,
      targetAmount: target,
      startDate: widget.savings.startDate,
      deadline: _deadline?.toIso8601String().substring(0, 10),
      createdAt: widget.savings.createdAt,
      updatedAt: now,
    );
    await _repo.update(updated);
    setState(() => _loading = false);
    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradient),
        ),
        title: const Text('Edit Tabungan'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _card(
                children: [
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nama Tabungan *',
                      prefixIcon: Icon(Icons.savings_outlined),
                    ),
                    validator: (v) => Validators.required(v, 'Nama Tabungan'),
                  ),
                  const SizedBox(height: 16),
                  RupiahInput(
                    controller: _targetCtrl,
                    label: 'Target Nominal *',
                    validator: Validators.amount,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    items: savingsCategories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setState(() => _category = v!),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Deskripsi (Opsional)',
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate:
                            _deadline ??
                            DateTime.now().add(const Duration(days: 30)),
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setState(() => _deadline = picked);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.inputBorder),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_outlined,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Tenggat Waktu',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                _deadline != null
                                    ? '${_deadline!.day.toString().padLeft(2, '0')}/${_deadline!.month.toString().padLeft(2, '0')}/${_deadline!.year}'
                                    : 'Tidak ditentukan',
                                style: const TextStyle(fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 50),
                        side: const BorderSide(color: AppColors.primary),
                        foregroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loading ? null : _save,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Simpan Perubahan'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}
