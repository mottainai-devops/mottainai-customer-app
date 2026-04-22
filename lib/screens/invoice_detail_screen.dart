import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
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

  @override
  void initState() {
    super.initState();
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
      // Initiate payment on backend — backend calls Paystack initialize API
      // and returns an authorization_url for the customer to complete payment
      final initResult = await ApiService.initiatePayment(widget.invoiceId, amount);
      
      if (initResult['success'] == true) {
        final authUrl = initResult['authorization_url'] as String?;
        final reference = initResult['reference'] as String?;
        
        if (authUrl != null) {
          // Open Paystack payment page in browser
          final uri = Uri.parse(authUrl);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
            // Show instructions to return after payment
            if (mounted) {
              _showPaymentInstructions(reference ?? '');
            }
          } else {
            _showSnack('Could not open payment page. Please try again.');
          }
        } else {
          _showSnack('Payment initiation failed. Please try again.');
        }
      } else {
        _showSnack(initResult['message']?.toString() ?? 'Payment initiation failed.');
      }
    } catch (e) {
      _showSnack('Payment error: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _paying = false);
    }
  }

  void _showPaymentInstructions(String reference) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.payment, color: Color(0xFF1B5E20)),
            SizedBox(width: 8),
            Text('Complete Payment'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'You have been redirected to the Paystack payment page. '
              'Complete your payment there, then return here and tap "I\'ve Paid" to verify.',
              style: TextStyle(fontSize: 14),
            ),
            if (reference.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Reference: $reference',
                  style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await _verifyPayment(reference);
            },
            child: const Text("I've Paid"),
          ),
        ],
      ),
    );
  }

  Future<void> _verifyPayment(String reference) async {
    if (reference.isEmpty) return;
    setState(() => _paying = true);
    try {
      final result = await ApiService.verifyPayment(reference);
      if (result['success'] == true) {
        _showSnack('Payment verified! Invoice has been updated.');
        await _loadInvoice();
      } else {
        _showSnack(
            result['message']?.toString() ??
            'Payment not yet confirmed. Please wait a moment and try again.');
      }
    } catch (e) {
      _showSnack('Verification error: ${e.toString()}');
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
          _detailRow('Customer ID', inv['customerId'] ?? inv['buildingId'] ?? inv['building_id'] ?? '—'),
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
