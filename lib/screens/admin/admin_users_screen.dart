import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  bool _isLoading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  Map<String, dynamic> _pagination = {};

  // Filters
  String? _selectedRole;
  String? _selectedStatus;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  final _dateFormat = DateFormat('dd MMM yyyy', 'id_ID');

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers({int offset = 0}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await ApiService.getAdminUsers(
        limit: 20,
        offset: offset,
        role: _selectedRole,
        status: _selectedStatus,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
      );

      setState(() {
        _users = result['users'];
        _pagination = result['pagination'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _updateUserRole(String userId, String newRole) async {
    try {
      await ApiService.updateAdminUser(userId: userId, role: newRole);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Role berhasil diubah menjadi $newRole'),
          backgroundColor: Colors.green,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengubah role: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _toggleBanUser(
    String userId,
    bool isBanned,
    String? banReason,
  ) async {
    try {
      await ApiService.updateAdminUser(
        userId: userId,
        isBanned: isBanned,
        banReason: banReason,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isBanned ? 'Pengguna diblokir' : 'Pengguna diaktifkan'),
          backgroundColor: isBanned ? Colors.orange : Colors.green,
        ),
      );
      _loadUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _deleteUser(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Pengguna'),
        content: Text(
          'Apakah Anda yakin ingin menghapus pengguna "$email"?\n\nTindakan ini tidak dapat dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteAdminUser(userId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pengguna berhasil dihapus'),
            backgroundColor: Colors.green,
          ),
        );
        _loadUsers();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menghapus: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBanDialog(String userId, String email) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Blokir Pengguna'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Blokir pengguna "$email"?'),
            SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: InputDecoration(
                labelText: 'Alasan (opsional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _toggleBanUser(
                userId,
                true,
                reasonController.text.isNotEmpty ? reasonController.text : null,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: Text('Blokir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog(String userId, String currentRole) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Ubah Role'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.person, color: Colors.blue),
              title: Text('Pembeli'),
              selected: currentRole == 'buyer',
              onTap: () {
                Navigator.pop(context);
                if (currentRole != 'buyer') {
                  _updateUserRole(userId, 'buyer');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.store, color: Colors.orange),
              title: Text('Penjual'),
              selected: currentRole == 'seller',
              onTap: () {
                Navigator.pop(context);
                if (currentRole != 'seller') {
                  _updateUserRole(userId, 'seller');
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.red),
              title: Text('Admin'),
              selected: currentRole == 'admin',
              onTap: () {
                Navigator.pop(context);
                if (currentRole != 'admin') {
                  _updateUserRole(userId, 'admin');
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kelola Pengguna'),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: Icon(Icons.refresh), onPressed: () => _loadUsers()),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilters(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    return Container(
      color: Colors.grey[100],
      padding: EdgeInsets.all(12),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Cari pengguna...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                        _loadUsers();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onSubmitted: (value) {
              setState(() {
                _searchQuery = value;
              });
              _loadUsers();
            },
          ),
          SizedBox(height: 12),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'Semua Role',
                  selected: _selectedRole == null,
                  onTap: () {
                    setState(() {
                      _selectedRole = null;
                    });
                    _loadUsers();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Pembeli',
                  selected: _selectedRole == 'buyer',
                  color: Colors.blue,
                  onTap: () {
                    setState(() {
                      _selectedRole = 'buyer';
                    });
                    _loadUsers();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Penjual',
                  selected: _selectedRole == 'seller',
                  color: Colors.orange,
                  onTap: () {
                    setState(() {
                      _selectedRole = 'seller';
                    });
                    _loadUsers();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Admin',
                  selected: _selectedRole == 'admin',
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      _selectedRole = 'admin';
                    });
                    _loadUsers();
                  },
                ),
                SizedBox(width: 16),
                Container(width: 1, height: 24, color: Colors.grey[400]),
                SizedBox(width: 16),
                _buildFilterChip(
                  label: 'Aktif',
                  selected: _selectedStatus == 'active',
                  color: Colors.green,
                  onTap: () {
                    setState(() {
                      _selectedStatus = _selectedStatus == 'active'
                          ? null
                          : 'active';
                    });
                    _loadUsers();
                  },
                ),
                SizedBox(width: 8),
                _buildFilterChip(
                  label: 'Diblokir',
                  selected: _selectedStatus == 'banned',
                  color: Colors.red,
                  onTap: () {
                    setState(() {
                      _selectedStatus = _selectedStatus == 'banned'
                          ? null
                          : 'banned';
                    });
                    _loadUsers();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    Color? color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? (color ?? Colors.deepOrange).withOpacity(0.2)
              : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? (color ?? Colors.deepOrange) : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? (color ?? Colors.deepOrange) : Colors.grey[700],
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.deepOrange),
            SizedBox(height: 16),
            Text('Memuat data pengguna...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Gagal memuat data',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600]),
              ),
              SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadUsers(),
                icon: Icon(Icons.refresh),
                label: Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepOrange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Tidak ada pengguna ditemukan',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadUsers(),
      child: ListView.builder(
        padding: EdgeInsets.all(12),
        itemCount: _users.length + (_pagination['has_more'] == true ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _users.length) {
            return _buildLoadMoreButton();
          }
          return _buildUserCard(_users[index]);
        },
      ),
    );
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    final isBanned = user['is_banned'] == true;
    final role = user['role'] ?? 'buyer';

    Color roleColor;
    IconData roleIcon;
    switch (role) {
      case 'admin':
        roleColor = Colors.red;
        roleIcon = Icons.admin_panel_settings;
        break;
      case 'seller':
        roleColor = Colors.orange;
        roleIcon = Icons.store;
        break;
      default:
        roleColor = Colors.blue;
        roleIcon = Icons.person;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => _showUserDetail(user),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: roleColor.withOpacity(0.2),
                    backgroundImage: user['avatar_url'] != null
                        ? NetworkImage(user['avatar_url'])
                        : null,
                    child: user['avatar_url'] == null
                        ? Text(
                            (user['full_name'] ?? user['email'] ?? 'U')
                                .toString()
                                .substring(0, 1)
                                .toUpperCase(),
                            style: TextStyle(
                              color: roleColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          )
                        : null,
                  ),
                  if (isBanned)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.block, color: Colors.white, size: 12),
                      ),
                    ),
                ],
              ),
              SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user['full_name'] ?? user['email'] ?? '-',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: roleColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(roleIcon, size: 12, color: roleColor),
                              SizedBox(width: 4),
                              Text(
                                _formatRole(role),
                                style: TextStyle(
                                  color: roleColor,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      user['email'] ?? '-',
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 12,
                          color: Colors.grey[500],
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Bergabung: ${_formatDate(user['created_at'])}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                        if (isBanned) ...[
                          SizedBox(width: 8),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'DIBLOKIR',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // Actions
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                onSelected: (action) {
                  switch (action) {
                    case 'role':
                      _showRoleDialog(user['id'], role);
                      break;
                    case 'ban':
                      _showBanDialog(user['id'], user['email'] ?? '-');
                      break;
                    case 'unban':
                      _toggleBanUser(user['id'], false, null);
                      break;
                    case 'delete':
                      _deleteUser(user['id'], user['email'] ?? '-');
                      break;
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'role',
                    child: Row(
                      children: [
                        Icon(Icons.swap_horiz, size: 20),
                        SizedBox(width: 8),
                        Text('Ubah Role'),
                      ],
                    ),
                  ),
                  if (!isBanned)
                    PopupMenuItem(
                      value: 'ban',
                      child: Row(
                        children: [
                          Icon(Icons.block, size: 20, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Blokir',
                            style: TextStyle(color: Colors.orange),
                          ),
                        ],
                      ),
                    )
                  else
                    PopupMenuItem(
                      value: 'unban',
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle,
                            size: 20,
                            color: Colors.green,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Aktifkan',
                            style: TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Hapus', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadMoreButton() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: ElevatedButton(
          onPressed: () {
            final currentOffset = _pagination['offset'] ?? 0;
            final limit = _pagination['limit'] ?? 20;
            _loadUsers(offset: currentOffset + limit);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.deepOrange,
            foregroundColor: Colors.white,
          ),
          child: Text('Muat Lebih Banyak'),
        ),
      ),
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepOrange.withOpacity(0.2),
                  child: Text(
                    (user['full_name'] ?? user['email'] ?? 'U')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Center(
                child: Text(
                  user['full_name'] ?? '-',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ),
              Center(
                child: Text(
                  user['email'] ?? '-',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
              SizedBox(height: 24),
              _buildDetailRow('ID', user['id'] ?? '-'),
              _buildDetailRow('Role', _formatRole(user['role'])),
              _buildDetailRow(
                'Status',
                user['is_banned'] == true ? 'Diblokir' : 'Aktif',
              ),
              if (user['business_name'] != null)
                _buildDetailRow('Bisnis', user['business_name']),
              _buildDetailRow('Terdaftar', _formatDate(user['created_at'])),
              if (user['last_sign_in_at'] != null)
                _buildDetailRow(
                  'Login Terakhir',
                  _formatDate(user['last_sign_in_at']),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  String _formatRole(String? role) {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'seller':
        return 'Penjual';
      case 'buyer':
        return 'Pembeli';
      default:
        return role ?? '-';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '-';
    try {
      final date = DateTime.parse(dateStr);
      return _dateFormat.format(date);
    } catch (e) {
      return dateStr;
    }
  }
}
