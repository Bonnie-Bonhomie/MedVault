import 'package:flutter/material.dart';

import '../barrel_export.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AppUser?>(
      future: AuthService.instance.loadProfile(),
      builder: (context, snapshot) {
        final user = snapshot.data;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.mist,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      (user?.fullName.isNotEmpty ?? false)
                          ? user!.fullName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'Loading…',
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user?.pharmacyName ?? ''} · '
                          '${user?.role.name ?? ''}',
                          style: const TextStyle(color: AppColors.inkSoft),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.category_outlined),
              title: const Text('Categories'),
              subtitle: const Text('Group medicines for faster searching'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.local_shipping_outlined),
              title: const Text('Suppliers'),
              subtitle: const Text('Who you reorder from'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SuppliersScreen()),
              ),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.logout),
              title: const Text('Sign out'),
              onTap: () => AuthService.instance.signOut(),
            ),
          ],
        );
      },
    );
  }
}

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = InventoryService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Category>>(
        stream: service.watchCategories(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.category_outlined,
              title: 'No categories yet',
              message: 'Add categories such as antibiotics or analgesics to '
                  'keep the medicine list easy to scan.',
              actionLabel: 'Add category',
              onAction: () => _edit(context, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: items.length,
            itemBuilder: (context, i) => Card(
              child: ListTile(
                title: Text(items[i].name),
                subtitle: items[i].description.isEmpty
                    ? null
                    : Text(items[i].description),
                onTap: () => _edit(context, items[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => service.deleteCategory(items[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Category? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final description =
        TextEditingController(text: existing?.description ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add category' : 'Edit category'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: description,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await InventoryService.instance.saveCategory(Category(
                id: existing?.id ?? '',
                name: name.text.trim(),
                description: description.text.trim(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class SuppliersScreen extends StatelessWidget {
  const SuppliersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = InventoryService.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Suppliers')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _edit(context, null),
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder<List<Supplier>>(
        stream: service.watchSuppliers(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snapshot.data!;
          if (items.isEmpty) {
            return EmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'No suppliers yet',
              message: 'Add the distributors you buy from so reorder lists '
                  'show who to contact.',
              actionLabel: 'Add supplier',
              onAction: () => _edit(context, null),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: items.length,
            itemBuilder: (context, i) => Card(
              child: ListTile(
                title: Text(items[i].name),
                subtitle: Text(
                  [items[i].phone, items[i].address]
                      .where((s) => s.isNotEmpty)
                      .join(' · '),
                ),
                onTap: () => _edit(context, items[i]),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => service.deleteSupplier(items[i].id),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _edit(BuildContext context, Supplier? existing) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final phone = TextEditingController(text: existing?.phone ?? '');
    final email = TextEditingController(text: existing?.email ?? '');
    final address = TextEditingController(text: existing?.address ?? '');

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(existing == null ? 'Add supplier' : 'Edit supplier'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: address,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (name.text.trim().isEmpty) return;
              await InventoryService.instance.saveSupplier(Supplier(
                id: existing?.id ?? '',
                name: name.text.trim(),
                phone: phone.text.trim(),
                email: email.text.trim(),
                address: address.text.trim(),
              ));
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
