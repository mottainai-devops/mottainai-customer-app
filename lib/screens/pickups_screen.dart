import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/api_service.dart';

class PickupsScreen extends StatefulWidget {
  const PickupsScreen({super.key});

  @override
  State<PickupsScreen> createState() => _PickupsScreenState();
}

class _PickupsScreenState extends State<PickupsScreen> {
  List<dynamic> _pickups = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadPickups();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_loadingMore &&
        _hasMore) {
      _loadMore();
    }
  }

  Future<void> _loadPickups({bool refresh = false}) async {
    if (refresh) {
      setState(() {
        _page = 1;
        _hasMore = true;
        _loading = true;
      });
    }
    try {
      final result = await ApiService.getPickups(page: 1, limit: 20);
      if (mounted) {
        setState(() {
          _pickups = result['pickups'] as List? ?? [];
          _loading = false;
          _hasMore = (_pickups.length == 20);
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    try {
      final result =
          await ApiService.getPickups(page: _page + 1, limit: 20);
      final newItems = result['pickups'] as List? ?? [];
      if (mounted) {
        setState(() {
          _page++;
          _pickups.addAll(newItems);
          _hasMore = newItems.length == 20;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAF8),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        foregroundColor: Colors.white,
        title: const Text('Pickup History',
            style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/request-pickup'),
            tooltip: 'Request Pickup',
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _pickups.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => _loadPickups(refresh: true),
                  color: const Color(0xFF1B5E20),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _pickups.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (context, i) {
                      if (i == _pickups.length) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(
                                color: Color(0xFF1B5E20)),
                          ),
                        );
                      }
                      return _PickupCard(pickup: _pickups[i]);
                    },
                  ),
                ),
      bottomNavigationBar: _buildBottomNav(context, 1),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_shipping_outlined,
              size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text('No pickups yet',
              style: TextStyle(color: Colors.grey[500], fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.push('/request-pickup'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1B5E20),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Request a Pickup'),
          ),
        ],
      ),
    );
  }
}

class _PickupCard extends StatelessWidget {
  final Map<String, dynamic> pickup;
  const _PickupCard({required this.pickup});

  @override
  Widget build(BuildContext context) {
    final status = pickup['status'] ?? 'pending';
    final binType = pickup['binType'] ?? '—';
    final qty = pickup['quantity'] ?? 1;
    final date = pickup['preferredDate'] != null
        ? _formatDate(pickup['preferredDate'].toString())
        : '—';
    final address = pickup['address'] ?? pickup['buildingAddress'] ?? '—';
    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF1B5E20).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.local_shipping_outlined,
                    color: Color(0xFF1B5E20), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(binType,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: Color(0xFF1A1A1A))),
                    Text('Qty: $qty · $date',
                        style:
                            TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              _statusBadge(status, statusColor),
            ],
          ),
          if (address != '—') ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.location_on_outlined,
                    size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
            fontSize: 10, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'confirmed':
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
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
}

Widget _buildBottomNav(BuildContext context, int currentIndex) {
  return Container(
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 12,
          offset: const Offset(0, -2),
        ),
      ],
    ),
    child: BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/pickups');
            break;
          case 2:
            context.go('/invoices');
            break;
          case 3:
            context.go('/profile');
            break;
        }
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      selectedItemColor: const Color(0xFF1B5E20),
      unselectedItemColor: Colors.grey[400],
      selectedFontSize: 11,
      unselectedFontSize: 11,
      elevation: 0,
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home'),
        BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Pickups'),
        BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            activeIcon: Icon(Icons.receipt_long),
            label: 'Invoices'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile'),
      ],
    ),
  );
}
