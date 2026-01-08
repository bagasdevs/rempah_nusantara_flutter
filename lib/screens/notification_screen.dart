import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';
import 'package:rempah_nusantara/services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _allNotifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchNotifications();
  }

  Future<void> _fetchNotifications() async {
    if (!ApiService.isAuthenticated) {
      setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.getNotifications(limit: 50);
      final notifications =
          result['notifications'] as List<Map<String, dynamic>>;

      setState(() {
        _allNotifications = notifications.map((n) {
          return {
            'id': n['id'],
            'type': _mapNotificationType(n['type']),
            'title': n['title'] ?? '',
            'message': n['message'] ?? '',
            'timestamp': _formatTimestamp(n['created_at']),
            'isRead': n['is_read'] ?? false,
            'icon': _getIconForType(n['type']),
            'iconColor': _getColorForType(n['type']),
          };
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching notifications: $e');
      setState(() => _isLoading = false);
    }
  }

  String _mapNotificationType(String? type) {
    switch (type) {
      case 'order':
      case 'order_status':
      case 'payment':
        return 'order';
      case 'promotion':
      case 'promo':
        return 'promotion';
      case 'price_prediction':
        return 'price_prediction';
      case 'tengkulak_warning':
        return 'warning';
      default:
        return 'system';
    }
  }

  IconData _getIconForType(String? type) {
    switch (type) {
      case 'order':
      case 'order_status':
      case 'payment':
        return Icons.local_shipping;
      case 'promotion':
      case 'promo':
        return Icons.local_offer;
      case 'price_prediction':
        return Icons.trending_up;
      case 'tengkulak_warning':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  Color _getColorForType(String? type) {
    switch (type) {
      case 'order':
      case 'order_status':
      case 'payment':
        return AppColors.primary;
      case 'promotion':
      case 'promo':
        return AppColors.error;
      case 'price_prediction':
        return Colors.orange;
      case 'tengkulak_warning':
        return Colors.red;
      default:
        return AppColors.info;
    }
  }

  String _formatTimestamp(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        return '${diff.inMinutes} menit yang lalu';
      } else if (diff.inHours < 24) {
        return '${diff.inHours} jam yang lalu';
      } else if (diff.inDays < 7) {
        return '${diff.inDays} hari yang lalu';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return dateStr;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredNotifications(String filter) {
    if (filter == 'all') return _allNotifications;
    return _allNotifications
        .where((notification) => notification['type'] == filter)
        .toList();
  }

  void _markAsRead(int id) async {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _allNotifications[index]['isRead'] = true;
      }
    });

    try {
      await ApiService.markNotificationsAsRead(notificationId: id);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  void _markAllAsRead() async {
    setState(() {
      for (var notification in _allNotifications) {
        notification['isRead'] = true;
      }
    });

    try {
      await ApiService.markNotificationsAsRead(markAll: true);
    } catch (e) {
      print('Error marking all as read: $e');
    }
  }

  void _deleteNotification(int id) {
    setState(() {
      _allNotifications.removeWhere((n) => n['id'] == id);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Notifikasi dihapus'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _allNotifications.where((n) => !n['isRead']).length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.pop(),
          color: AppColors.textPrimary,
        ),
        title: Text(
          'Notifications',
          style: AppTextStyles.heading3.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: true,
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllAsRead,
              child: Text(
                'Mark All Read',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: AppTextStyles.bodyMedium,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Orders'),
            Tab(text: 'Harga'),
            Tab(text: 'Promo'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildNotificationList('all'),
                _buildNotificationList('order'),
                _buildNotificationList('price_prediction'),
                _buildNotificationList('promotion'),
              ],
            ),
    );
  }

  Widget _buildNotificationList(String filter) {
    final notifications = _getFilteredNotifications(filter);

    if (notifications.isEmpty) {
      return _buildEmptyState(filter);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _fetchNotifications();
      },
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSizes.paddingMedium),
        itemCount: notifications.length,
        separatorBuilder: (context, index) =>
            const SizedBox(height: AppSizes.spacingSmall),
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return _buildNotificationCard(notification);
        },
      ),
    );
  }

  Widget _buildNotificationCard(Map<String, dynamic> notification) {
    final isRead = notification['isRead'] as bool;

    return Dismissible(
      key: Key(notification['id'].toString()),
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSizes.paddingLarge),
        child: const Icon(Icons.delete, color: AppColors.surface, size: 28),
      ),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        _deleteNotification(notification['id']);
      },
      child: InkWell(
        onTap: () {
          _markAsRead(notification['id']);
          _handleNotificationTap(notification);
        },
        borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSizes.paddingMedium),
          decoration: BoxDecoration(
            color: isRead
                ? AppColors.surface
                : AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(AppSizes.radiusMedium),
            border: Border.all(
              color: isRead
                  ? AppColors.border
                  : AppColors.primary.withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (notification['iconColor'] as Color).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSmall),
                ),
                child: Icon(
                  notification['icon'] as IconData,
                  color: notification['iconColor'] as Color,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSizes.spacingMedium),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification['title'],
                            style: AppTextStyles.bodyLarge.copyWith(
                              fontWeight: isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),
                    Text(
                      notification['message'],
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSizes.spacingSmall),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.textSecondary.withOpacity(0.7),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          notification['timestamp'],
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String filter) {
    String message;
    IconData icon;

    switch (filter) {
      case 'order':
        message = 'Belum ada notifikasi pesanan';
        icon = Icons.shopping_bag_outlined;
        break;
      case 'promotion':
        message = 'Belum ada promo tersedia';
        icon = Icons.local_offer_outlined;
        break;
      case 'price_prediction':
        message = 'Belum ada prediksi harga';
        icon = Icons.trending_up_outlined;
        break;
      case 'warning':
        message = 'Tidak ada peringatan';
        icon = Icons.warning_amber_outlined;
        break;
      default:
        message = 'Belum ada notifikasi';
        icon = Icons.notifications_outlined;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.paddingLarge),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: AppColors.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: AppSizes.spacingMedium),
            Text(
              message,
              style: AppTextStyles.heading4.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSizes.spacingSmall),
            Text(
              'Notifikasi akan muncul di sini',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _handleNotificationTap(Map<String, dynamic> notification) {
    final type = notification['type'];

    switch (type) {
      case 'order':
        // Navigate to orders screen
        context.push('/orders');
        break;
      case 'promotion':
        // Navigate to promotion or products
        context.push('/products');
        break;
      case 'price_prediction':
        // Navigate to AI tools screen for price prediction
        context.push('/ai-tools');
        break;
      case 'warning':
        // Show dialog about the warning
        _showWarningDialog(notification);
        break;
      case 'system':
        // Show dialog or navigate to settings
        break;
      default:
        break;
    }
  }

  void _showWarningDialog(Map<String, dynamic> notification) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                notification['title'] ?? 'Peringatan',
                style: AppTextStyles.heading4,
              ),
            ),
          ],
        ),
        content: Text(
          notification['message'] ?? '',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Tutup'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to contact support
              context.push('/profile');
            },
            child: Text('Hubungi Admin'),
          ),
        ],
      ),
    );
  }
}
