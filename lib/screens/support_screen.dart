import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Support',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SizedBox(height: 8),
          _contactCard(
            icon: Icons.chat_outlined,
            iconColor: const Color(0xFF25D366),
            title: 'WhatsApp',
            subtitle: 'Chat with us on WhatsApp',
            onTap: () => _launch('https://wa.me/2348000000000'),
          ),
          const SizedBox(height: 12),
          _contactCard(
            icon: Icons.phone_outlined,
            iconColor: const Color(0xFF1B5E20),
            title: 'Call Us',
            subtitle: '+234 800 000 0000',
            onTap: () => _launch('tel:+2348000000000'),
          ),
          const SizedBox(height: 12),
          _contactCard(
            icon: Icons.email_outlined,
            iconColor: Colors.blue,
            title: 'Email',
            subtitle: 'info@mottainai.africa',
            onTap: () => _launch('mailto:info@mottainai.africa'),
          ),
          const SizedBox(height: 28),
          const Text(
            'Frequently Asked Questions',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF1A1A1A)),
          ),
          const SizedBox(height: 12),
          _faqItem(
            question: 'How do I request a pickup?',
            answer:
                'Tap "Request Pickup" on the home screen or from the Pickups tab. Fill in your bin type, quantity, preferred date, and address, then submit.',
          ),
          _faqItem(
            question: 'How do I pay my invoice?',
            answer:
                'Go to Invoices, tap on any outstanding invoice, and tap "Pay Now". You can pay securely with your debit card via Paystack.',
          ),
          _faqItem(
            question: 'My phone number is not recognised. What do I do?',
            answer:
                'On the login screen, tap "Don\'t have your phone? Use Building ID" and enter your Building ID and phone number to access your account.',
          ),
          _faqItem(
            question: 'How do I update my contact details?',
            answer:
                'Go to Profile, tap the edit icon in the top right, update your details, and tap "Save Changes".',
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _contactCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1A1A1A))),
                  Text(subtitle,
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _faqItem({required String question, required String answer}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(question,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A))),
        iconColor: const Color(0xFF1B5E20),
        collapsedIconColor: Colors.grey,
        children: [
          Text(answer,
              style: TextStyle(
                  fontSize: 13, color: Colors.grey[700], height: 1.5)),
        ],
      ),
    );
  }

  Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
