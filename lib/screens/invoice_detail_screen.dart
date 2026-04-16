import 'package:flutter/material.dart';
import 'package:flutter_paystack/flutter_paystack.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  Map<String, dynamic>? _invoice;
  bool _loading = true;
  bool _paying = false;
  final _paystackPlugin = PaystackPlugin();

  @override
  void initState() {
    super.initState();
    _paystackPlugin.initialize(publicKey: AppConstants.paystackPublicKey);
    _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    try {
      final result = await ApiService.getInvoiceDetail(widget.invoiceId);
      if (mounted) {
        setState(() {
          _invoice = result['invoice'] as Map<String, dynamic>?;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _payNow() async {
    if (_invoice == null) return;
    final auth = context.read<AuthProvider>();
    final email = auth.profile?['email'] ?? 'customer@mottainai.africa';
    final amount = double.tryParse(
            (_invoice!['balance_due'] ?? _invoice!['total'] ?? 0)
                .toString()) ??
        0;

    if (amount <= 0) {
      _showSnack('Invoice is already paid or has zero balance');
      return;
    }

    setState(() => _paying = true);

    try {
      // Initiate on backend to get reference
      final initResult = await ApiService.initiatePayment(
          widget.invoiceId, amount);
      final reference = initResult['reference'] as String? ??
          'MTC-${DateTime.now().millisecondsSinceEpoch}';

      final charge = Charge()
        ..amount = (amount * 100).toInt() // Paystack uses kobo
        ..reference = reference
        ..email = email;

      final response = await _paystackPlugin.checkout(
        context,
        method: CheckoutMethod.card,
        charge: charge,
      );

      if (!mounted) return;

      if (response.status == true) {
        // Verify on backend
        final verifyResult =
            await ApiService.verifyPayment(response.reference ?? reference);
        if (verifyResult['success'] == true) {
          _showSnack('Payment successful! Invoice has been updated.');
          await _loadInvoice(); // Refresh invoice status
        } else {
          _showSnack('Payment received but verification pending. Please contact support if not updated.');
        }
      } else {
        _showSnack('Payment was not completed.');
      }
    } catch (e) {
      _showSnack('Payment error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _paying = false);
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
        title: Text(
          _invoice != null
              ? 'Invoice #${_invoice!['invoice_number'] ?? ''}'
              : 'Invoice Detail',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _invoice == null
              ? const Center(child: Text('Invoice not found'))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final inv = _invoice!;
    final status = inv['status'] ?? 'unpaid';
    final isPaid = status.toString().toLowerCase() == 'paid';
    final amount = inv['total'] ?? inv['balance_due'] ?? 0;
    final balanceDue = inv['balance_due'] ?? amount;
    final statusColor = isPaid ? Colors.green : Colors.orange;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Status banner
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Icon(
                isPaid ? Icons.check_circle : Icons.pending_outlined,
                color: statusColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    status.toString().toUpperCase(),
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                        fontSize: 16),
                  ),
                  Text(
                    isPaid
                        ? 'This invoice has been paid'
                        : 'Payment is outstanding',
                    style: TextStyle(
                        color: statusColor.withOpacity(0.8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Invoice details
        _detailCard(children: [
          _detailRow('Invoice Number',
              '#${inv['invoice_number'] ?? inv['_id'] ?? '—'}'),
          _detailRow('Date',
              inv['date'] != null ? _formatDate(inv['date'].toString()) : '—'),
          _detailRow('Due Date',
              inv['due_date'] != null
                  ? _formatDate(inv['due_date'].toString())
                  : '—'),
          _detailRow('Customer', inv['customer_name'] ?? '—'),
          _detailRow('Building ID', inv['building_id'] ?? '—'),
        ]),
        const SizedBox(height: 16),

        // Amount breakdown
        _detailCard(children: [
          _detailRow('Sub Total', '₦${_formatAmount(inv['sub_total'] ?? amount)}'),
          if (inv['tax'] != null)
            _detailRow('Tax', '₦${_formatAmount(inv['tax'])}'),
          const Divider(),
          _detailRow('Total', '₦${_formatAmount(amount)}',
              bold: true, valueColor: const Color(0xFF1B5E20)),
          if (!isPaid)
            _detailRow('Balance Due', '₦${_formatAmount(balanceDue)}',
                bold: true, valueColor: Colors.red),
        ]),
        const SizedBox(height: 28),

        // Pay button
        if (!isPaid)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: _paying ? null : _payNow,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1B5E20),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _paying
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white)),
                    )
                  : const Icon(Icons.payment),
              label: Text(
                _paying
                    ? 'Processing...'
                    : 'Pay ₦${_formatAmount(balanceDue)}',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _detailCard({required List<Widget> children}) {
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
      child: Column(children: children),
    );
  }

  Widget _detailRow(String label, String value,
      {bool bold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 13, color: Colors.grey[600])),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w500,
              color: valueColor ?? const Color(0xFF1A1A1A),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final dt = DateTime.parse(dateStr);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatAmount(dynamic amount) {
    try {
      final num = double.parse(amount.toString());
      return num.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]},',
      );
    } catch (_) {
      return amount.toString();
    }
  }
}
