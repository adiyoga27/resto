import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/settings_service.dart';
import '../../models/user.dart';
import '../../config/theme.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});
  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final _svc = SettingsService();
  List<UserModel> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _init());
  }

  void _init() {
    final auth = context.read<AuthProvider>();
    _svc.init(auth.restaurantId);
    _svc.addListener(_onUsersChanged);
  }

  void _onUsersChanged() {
    if (mounted) {
      setState(() {
        _users = _svc.users;
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _svc.removeListener(_onUsersChanged);
    super.dispose();
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    String role = 'cashier';
    String? error;

    showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            child: Container(
              padding: const EdgeInsets.all(24),
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Tambah Pengguna',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Nama',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                        validator: (v) =>
                            v?.isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: emailCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: phoneCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Telepon',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: passCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.lock_outlined),
                        ),
                        obscureText: true,
                        validator: (v) =>
                            v?.isEmpty == true ? 'Wajib diisi' : null,
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.badge_outlined),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'cashier', child: Text('Kasir')),
                          DropdownMenuItem(
                              value: 'kitchen', child: Text('Dapur')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => role = v ?? 'cashier'),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 12),
                        Text(error!,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center),
                      ],
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          setDialogState(() => error = null);
                          final result = await _svc.createUser(
                            nameCtrl.text.trim(),
                            emailCtrl.text.trim(),
                            passCtrl.text,
                            phoneCtrl.text.trim(),
                            role,
                          );
                          if (result != null) {
                            setDialogState(() => error = result);
                          } else {
                            Navigator.pop(c);
                          }
                        },
                        icon: const Icon(Icons.person_add),
                        label: const Text('Buat Pengguna'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(c),
                        child: const Text('Batal'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(UserModel user) {
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus Pengguna'),
        content: Text('Yakin hapus ${user.name}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Batal')),
          TextButton(
            onPressed: () {
              _svc.deleteUser(user.uid);
              Navigator.pop(c);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pengguna'), actions: [
        IconButton(
          icon: const Icon(Icons.person_add),
          tooltip: 'Tambah Pengguna',
          onPressed: _showAddUserDialog,
        ),
      ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _users.isEmpty
              ? Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.group_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text('Belum ada pengguna'),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _showAddUserDialog,
                      icon: const Icon(Icons.person_add),
                      label: const Text('Tambah Pengguna'),
                    ),
                  ]),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _users.length,
                  itemBuilder: (_, i) {
                    final user = _users[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppTheme.secondaryColor.withAlpha(20),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: AppTheme.secondaryColor,
                                fontWeight: FontWeight.w700),
                          ),
                        ),
                        title: Text(user.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.email,
                                style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: user.role == 'superadmin'
                                    ? Colors.purple.withAlpha(25)
                                    : user.role == 'cashier'
                                        ? Colors.blue.withAlpha(25)
                                        : Colors.orange.withAlpha(25),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                user.role.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: user.role == 'superadmin'
                                      ? Colors.purple
                                      : user.role == 'cashier'
                                          ? Colors.blue
                                          : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                        trailing: user.role != 'superadmin'
                            ? PopupMenuButton<String>(
                                onSelected: (action) {
                                  if (action == 'delete') {
                                    _confirmDelete(user);
                                  } else if (action == 'cashier') {
                                    _svc.updateUserRole(user.uid, 'cashier');
                                  } else if (action == 'kitchen') {
                                    _svc.updateUserRole(user.uid, 'kitchen');
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                      value: 'cashier',
                                      child: Text('Jadikan Kasir')),
                                  const PopupMenuItem(
                                      value: 'kitchen',
                                      child: Text('Jadikan Dapur')),
                                  const PopupMenuItem(
                                      value: 'delete',
                                      child: Text('Hapus',
                                          style: TextStyle(color: Colors.red))),
                                ],
                              )
                            : null,
                      ),
                    );
                  },
                ),
    );
  }
}
