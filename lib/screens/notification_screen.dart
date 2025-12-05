import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:rempah_nusantara/config/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _allNotifications = [
    {
      'id': 1,
      'type': 'order',
      'title': 'Pesanan Dikirim',
      'message': 'Pesanan #12345 sedang dalam perjalanan',
      'timestamp': '2 jam yang lalu',
      'isRead': false,
      'icon': Icons.local_shipping,
      'iconColor': AppColors.primary,
    },
    {
      'id': 2,
      'type': 'promotion',
      'title': 'Diskon 20% Hari Ini!',
      'message': 'Dapatkan diskon 20% untuk semua produk rempah pilihan',
      'timestamp': '5 jam yang lalu',
      'isRead': false,
      'icon': Icons.local_offer,
      'iconColor': AppColors.error,
    },
    {
      'id': 3,
      'type': 'order',
      'title': 'Pesanan Selesai',
      'message': 'Pesanan #12344 telah selesai. Berikan rating Anda!',
      'timestamp': '1 hari yang lalu',
      'isRead': true,
      'icon': Icons.check_circle,
      'iconColor': AppColors.success,
    },
    {
      'id': 4,
      'type': 'system',
      'title': 'Update Aplikasi',
      'message': 'Versi baru tersedia dengan fitur-fitur menarik',
      'timestamp': '2 hari yang lalu',
      'isRead': true,
      'icon': Icons.system_update,
      'iconColor': AppColors.info,
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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

  void _markAsRead(int id) {
    setState(() {
      final index = _allNotifications.indexWhere((n) => n['id'] == id);
      if (index != -1) {
        _allNotifications[index]['isRead'] = true;
      }
    });
  }

  void _markAllAsRead() {
    setState(() {
      for (var notification in _allNotifications) {
        notification['isRead'] = true;
      }
    });
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
            Tab(text: 'Promotions'),
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
        setState(() {
          _isLoading = true;
        });
        // TODO: Fetch notifications from API
        await Future.delayed(const Duration(seconds: 1));
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
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
        message = 'No order notifications yet';
        icon = Icons.shopping_bag_outlined;
        break;
      case 'promotion':
        message = 'No promotions available';
        icon = Icons.local_offer_outlined;
        break;
      default:
        message = 'No notifications yet';
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
              'When you receive notifications, they will appear here',
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
        // Navigate to order detail
        // Extract order ID from message if needed
        // context.push('/order/12345');
        break;
      case 'promotion':
        // Navigate to promotion or products
        context.push('/products');
        break;
      case 'system':
        // Show dialog or navigate to settings
        break;
      default:
        break;
    }
  }
}
