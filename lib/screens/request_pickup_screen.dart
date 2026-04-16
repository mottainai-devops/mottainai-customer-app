import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../constants.dart';
import '../services/api_service.dart';

class RequestPickupScreen extends StatefulWidget {
  const RequestPickupScreen({super.key});

  @override
  State<RequestPickupScreen> createState() => _RequestPickupScreenState();
}

class _RequestPickupScreenState extends State<RequestPickupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _notesController = TextEditingController();

  String? _selectedBinType;
  int _quantity = 1;
  DateTime? _preferredDate;
  bool _submitting = false;

  @override
  void dispose() {
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 60)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF1B5E20),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _preferredDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBinType == null) {
      _showSnack('Please select a bin type');
      return;
    }
    if (_preferredDate == null) {
      _showSnack('Please select a preferred date');
      return;
    }

    setState(() => _submitting = true);
    try {
      final result = await ApiService.requestPickup({
        'binType': _selectedBinType,
        'quantity': _quantity,
        'preferredDate': _preferredDate!.toIso8601String(),
        'address': _addressController.text.trim(),
        'notes': _notesController.text.trim(),
      });

      if (!mounted) return;
      if (result['success'] == true) {
        _showSnack('Pickup request submitted successfully!');
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) context.pop();
      } else {
        _showSnack(result['message'] ?? 'Failed to submit request');
      }
    } catch (_) {
      _showSnack('Network error. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Request Pickup',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _sectionCard(
              title: 'Bin Details',
              children: [
                _label('Bin Type'),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedBinType,
                  decoration: _inputDecoration('Select bin type'),
                  items: AppConstants.binTypes
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => _selectedBinType = v),
                  validator: (v) => v == null ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _label('Quantity'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _counterButton(
                      icon: Icons.remove,
                      onTap: () {
                        if (_quantity > 1) setState(() => _quantity--);
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          '$_quantity',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    _counterButton(
                      icon: Icons.add,
                      onTap: () {
                        if (_quantity < 10) setState(() => _quantity++);
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Schedule',
              children: [
                _label('Preferred Pickup Date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F5F5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined,
                            color: Color(0xFF1B5E20), size: 20),
                        const SizedBox(width: 12),
                        Text(
                          _preferredDate != null
                              ? '${_preferredDate!.day}/${_preferredDate!.month}/${_preferredDate!.year}'
                              : 'Select a date',
                          style: TextStyle(
                            fontSize: 14,
                            color: _preferredDate != null
                                ? const Color(0xFF1A1A1A)
                                : Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _sectionCard(
              title: 'Location',
              children: [
                _label('Pickup Address'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _addressController,
                  decoration: _inputDecoration('Enter pickup address'),
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _label('Additional Notes (optional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  decoration: _inputDecoration('Any special instructions...'),
                  maxLines: 3,
                ),
              ],
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B5E20),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text('Submit Request',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard(
      {required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF1B5E20))),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _label(String text) {
    return Text(text,
        style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: Color(0xFF333333)));
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      filled: true,
      fillColor: const Color(0xFFF5F5F5),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            const BorderSide(color: Color(0xFF1B5E20), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1),
      ),
    );
  }

  Widget _counterButton(
      {required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1B5E20).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF1B5E20), size: 20),
      ),
    );
  }
}
