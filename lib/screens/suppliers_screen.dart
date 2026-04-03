import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/models/supplier.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/app_sidebar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'package:ismart_shop/widgets/expandable_fab.dart';
import 'package:ismart_shop/screens/customers_screen.dart';
import 'package:ismart_shop/screens/voice_recording_screen.dart';
import 'package:ismart_shop/screens/categories_screen.dart';
import 'package:ismart_shop/screens/receipts_screen.dart';
import 'package:ismart_shop/screens/expenses_screen.dart';

class SuppliersScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const SuppliersScreen({super.key, this.onNavigate});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<Supplier> _suppliers = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String? userId = authProvider.userModel?.id;

      debugPrint(
          'Loading suppliers - userId: $userId, isAuthenticated: ${authProvider.isAuthenticated}');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _suppliers = [];
          _isLoading = false;
        });
        return;
      }

      // Load from local SQLite first (offline-first)
      final localSuppliers = await LocalDatabaseService.getSuppliers(userId);

      setState(() {
        _suppliers = localSuppliers
            .map((local) => Supplier(
                  id: local.firebaseId ?? local.id,
                  name: local.name,
                  phone: local.phone,
                  email: local.email,
                  address: local.address,
                  products: local.productsList,
                  totalPurchases: local.totalPurchases,
                  notes: local.notes,
                  userId: local.userId,
                  createdAt: local.createdAt,
                  updatedAt: local.updatedAt,
                  isActive: local.isActive,
                ))
            .toList();
        _isLoading = false;
      });

      debugPrint('Loaded ${_suppliers.length} suppliers from local database');

      // Try to sync with Firestore if online
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('suppliers')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        // Update local database with Firebase data (avoid duplicates)
        for (final doc in snapshot.docs) {
          final supplier = Supplier.fromFirestore(doc);

          // Check if we already have this supplier locally (by firebaseId)
          final existingSupplier =
              await LocalDatabaseService.getSupplierByFirebaseId(doc.id);

          if (existingSupplier != null) {
            // Update existing record
            final updatedSupplier = existingSupplier.copyWith(
              name: supplier.name,
              phone: supplier.phone,
              email: supplier.email,
              address: supplier.address,
              products: supplier.products.join(', '),
              totalPurchases: supplier.totalPurchases,
              notes: supplier.notes,
              syncStatus: SyncStatus.synced,
            );
            await LocalDatabaseService.updateSupplier(updatedSupplier);
          } else {
            // Insert new record
            final localSupplier = LocalSupplier(
              id: doc.id,
              name: supplier.name,
              phone: supplier.phone,
              email: supplier.email,
              address: supplier.address,
              products: supplier.products.join(', '),
              totalPurchases: supplier.totalPurchases,
              notes: supplier.notes,
              userId: supplier.userId,
              createdAt: supplier.createdAt,
              updatedAt: supplier.updatedAt,
              isActive: supplier.isActive,
              syncStatus: SyncStatus.synced,
              firebaseId: doc.id,
            );
            await LocalDatabaseService.insertSupplier(localSupplier);
          }
        }

        // Reload from local database
        final updatedSuppliers =
            await LocalDatabaseService.getSuppliers(userId);
        setState(() {
          _suppliers = updatedSuppliers
              .map((local) => Supplier(
                    id: local.firebaseId ?? local.id,
                    name: local.name,
                    phone: local.phone,
                    email: local.email,
                    address: local.address,
                    products: local.productsList,
                    totalPurchases: local.totalPurchases,
                    notes: local.notes,
                    userId: local.userId,
                    createdAt: local.createdAt,
                    updatedAt: local.updatedAt,
                    isActive: local.isActive,
                  ))
              .toList();
        });
      } catch (e) {
        debugPrint('Firestore sync failed (non-critical): $e');
      }
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading suppliers: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Supplier> get _filteredSuppliers {
    return _suppliers.where((supplier) {
      return _searchQuery.isEmpty ||
          supplier.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (supplier.phone?.contains(_searchQuery) ?? false);
    }).toList();
  }

  void _handleSidebarNavigation(int index) {
    if (index < 0) {
      switch (index) {
        case -1:
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const CustomersScreen()));
          break;
        case -2:
          break;
        case -3:
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const CategoriesScreen()));
          break;
        case -4:
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const ReceiptsScreen()));
          break;
        case -5:
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const ExpensesScreen()));
          break;
      }
    } else {
      Navigator.popUntil(context, (route) => route.isFirst);
      widget.onNavigate?.call(index);
    }
  }

  void _handleBottomNav(int index) {
    Navigator.popUntil(context, (route) => route.isFirst);
    widget.onNavigate?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      drawer:
          AppSidebar(currentIndex: -2, onNavigate: _handleSidebarNavigation),
      appBar: IOSNavigationBar(
        title: 'Suppliers',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: Icon(CupertinoIcons.line_horizontal_3,
              color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: isDarkMode
                ? IOSDarkColors.systemBackground
                : IOSColors.systemBackground,
            padding: const EdgeInsets.all(IOSSpacing.md),
            child: CupertinoSearchTextField(
              placeholder: 'Search suppliers...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Supplier list
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredSuppliers.isEmpty
                    ? IOSEmptyState(
                        icon: CupertinoIcons.cube_box,
                        title: 'No Suppliers',
                        subtitle: _searchQuery.isEmpty
                            ? 'Add suppliers to track your purchases'
                            : 'Try a different search term',
                        action: _searchQuery.isEmpty
                            ? IOSButton(
                                title: 'Add Supplier',
                                onPressed: () =>
                                    _showAddSupplierDialog(context),
                              )
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(IOSSpacing.md),
                        itemCount: _filteredSuppliers.length,
                        itemBuilder: (context, index) {
                          final supplier = _filteredSuppliers[index];
                          return _SupplierCard(
                            supplier: supplier,
                            onTap: () =>
                                _showSupplierDetails(context, supplier),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: ExpandableFab(
        actions: [
          FabAction(
            label: 'Voice',
            icon: CupertinoIcons.mic_fill,
            color: IOSColors.secondary,
            onPressed: () {
              Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (_) => const VoiceRecordingScreen(),
                ),
              );
            },
          ),
          FabAction(
            label: 'Supplier',
            icon: CupertinoIcons.add,
            color: IOSColors.primary,
            onPressed: () => _showAddSupplierDialog(context),
          ),
        ],
      ),
      bottomNavigationBar:
          AppBottomNav(currentIndex: 0, onNavigate: _handleBottomNav),
    );
  }

  void _showAddSupplierDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _SupplierFormSheet(
        onSave: (supplier) async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to save supplier'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Generate local ID
            final localId = _uuid.v4();

            // Create local supplier first (offline-first)
            final localSupplier = LocalSupplier(
              id: localId,
              name: supplier.name,
              phone: supplier.phone,
              email: supplier.email,
              address: supplier.address,
              products: supplier.products.join(', '),
              totalPurchases: supplier.totalPurchases,
              notes: supplier.notes,
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: null,
            );

            // Save to local SQLite first
            await LocalDatabaseService.insertSupplier(localSupplier);
            debugPrint('Supplier saved to local database: $localId');

            // Try to sync with Firestore in background
            bool firebaseSynced = false;
            try {
              final docRef =
                  await FirebaseFirestore.instance.collection('suppliers').add({
                ...supplier.toFirestore(),
                'userId': userId,
              });

              // Update local record with Firebase ID using copyWith
              final syncedSupplier = localSupplier.copyWith(
                firebaseId: docRef.id,
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateSupplier(syncedSupplier);
              debugPrint('Supplier synced to Firestore: ${docRef.id}');
              firebaseSynced = true;
            } catch (e) {
              debugPrint(
                  'Firestore sync failed (supplier will sync later): $e');
            }

            _loadSuppliers();
            if (mounted) {
              Navigator.pop(context);
              // Show appropriate message based on sync status
              if (firebaseSynced) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Supplier added successfully and synced to cloud'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Supplier saved locally. Will sync when online.'),
                      backgroundColor: Colors.orange),
                );
              }
            }
          } catch (e) {
            debugPrint('Error adding supplier: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error saving supplier: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showSupplierDetails(BuildContext context, Supplier supplier) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _SupplierDetailsSheet(
        supplier: supplier,
        onEdit: () {
          Navigator.pop(context);
          _showEditSupplierDialog(context, supplier);
        },
        onDelete: () async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Please log in again'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Soft delete in local SQLite first (offline-first)
            await LocalDatabaseService.deleteSupplier(supplier.id);
            debugPrint('Supplier marked as deleted locally: ${supplier.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('suppliers')
                  .doc(supplier.id)
                  .update({
                'isActive': false,
                'updatedAt': DateTime.now(),
              });
              debugPrint('Supplier deleted in Firestore: ${supplier.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (delete will sync later): $e');
            }

            _loadSuppliers();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Supplier deleted (saved locally)'),
                    backgroundColor: Colors.orange),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error: $e'), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditSupplierDialog(BuildContext context, Supplier supplier) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _SupplierFormSheet(
        supplier: supplier,
        onSave: (updatedSupplier) async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to update supplier'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Update local SQLite first (offline-first)
            final localSupplier = LocalSupplier(
              id: supplier.id,
              name: updatedSupplier.name,
              phone: updatedSupplier.phone,
              email: updatedSupplier.email,
              address: updatedSupplier.address,
              products: updatedSupplier.products.join(', '),
              totalPurchases: updatedSupplier.totalPurchases,
              notes: updatedSupplier.notes,
              userId: userId,
              createdAt: supplier.createdAt,
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: supplier.id,
            );
            await LocalDatabaseService.updateSupplier(localSupplier);
            debugPrint('Supplier updated locally: ${supplier.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('suppliers')
                  .doc(supplier.id)
                  .update({
                ...updatedSupplier.toFirestore(),
                'updatedAt': DateTime.now(),
              });

              // Mark as synced using copyWith
              final syncedSupplier = localSupplier.copyWith(
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateSupplier(syncedSupplier);
              debugPrint('Supplier updated in Firestore: ${supplier.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (update will sync later): $e');
            }

            _loadSuppliers();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Supplier updated (saved locally)'),
                    backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            debugPrint('Error updating supplier: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error updating supplier: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }
}

class _SupplierCard extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onTap;

  const _SupplierCard({required this.supplier, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final purchaseColor =
        isDarkMode ? IOSDarkColors.purchaseColor : IOSColors.purchaseColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: IOSSpacing.sm),
        padding: const EdgeInsets.all(IOSSpacing.md),
        decoration: BoxDecoration(
          color: isDarkMode
              ? IOSDarkColors.cardBackground
              : IOSColors.systemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(
            color: (isDarkMode
                    ? IOSDarkColors.labelQuaternary
                    : IOSColors.labelQuaternary)
                .withOpacity(0.3),
          ),
          boxShadow: isDarkMode
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: purchaseColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Center(
                child: Text(
                  supplier.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: purchaseColor,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(width: IOSSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    supplier.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (supplier.products.isNotEmpty)
                    Text(
                      supplier.productsString,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? IOSDarkColors.labelSecondary
                            : IOSColors.labelSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Total
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  supplier.formattedTotalPurchases,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: purchaseColor,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 16,
                  color: isDarkMode
                      ? IOSDarkColors.labelTertiary
                      : IOSColors.labelTertiary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SupplierFormSheet extends StatefulWidget {
  final Supplier? supplier;
  final Function(Supplier) onSave;

  const _SupplierFormSheet({this.supplier, required this.onSave});

  @override
  State<_SupplierFormSheet> createState() => _SupplierFormSheetState();
}

class _SupplierFormSheetState extends State<_SupplierFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _productsController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.supplier?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.supplier?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.supplier?.email ?? '');
    _addressController =
        TextEditingController(text: widget.supplier?.address ?? '');
    _productsController =
        TextEditingController(text: widget.supplier?.products.join(', ') ?? '');
    _notesController =
        TextEditingController(text: widget.supplier?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _productsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.systemBackground
            : IOSColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? IOSDarkColors.labelQuaternary
                  : IOSColors.labelQuaternary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.all(IOSSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                Text(widget.supplier == null ? 'Add Supplier' : 'Edit Supplier',
                    style: IOSTextStyles.headline),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saveSupplier,
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
          const IOSDivider(),
          // Form
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(IOSSpacing.md),
              children: [
                _buildLabel('Supplier Name *'),
                IOSTextField(
                  controller: _nameController,
                  placeholder: 'Enter supplier name',
                ),
                const SizedBox(height: IOSSpacing.md),
                _buildLabel('Phone'),
                IOSTextField(
                  controller: _phoneController,
                  placeholder: 'Enter phone number',
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: IOSSpacing.md),
                _buildLabel('Email'),
                IOSTextField(
                  controller: _emailController,
                  placeholder: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: IOSSpacing.md),
                _buildLabel('Address'),
                IOSTextField(
                  controller: _addressController,
                  placeholder: 'Enter address',
                ),
                const SizedBox(height: IOSSpacing.md),
                _buildLabel('Products (comma-separated)'),
                IOSTextField(
                  controller: _productsController,
                  placeholder: 'e.g., Beef, Goat, Chicken',
                ),
                const SizedBox(height: IOSSpacing.md),
                _buildLabel('Notes'),
                IOSTextField(
                  controller: _notesController,
                  placeholder: 'Add any notes',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: IOSSpacing.xs),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: isDarkMode
              ? IOSDarkColors.labelSecondary
              : IOSColors.labelSecondary,
        ),
      ),
    );
  }

  void _saveSupplier() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter supplier name'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final products = _productsController.text
        .split(',')
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .toList();

    final supplier = Supplier(
      id: widget.supplier?.id ?? '',
      name: _nameController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      products: products,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      totalPurchases: widget.supplier?.totalPurchases ?? 0,
      userId: '',
      createdAt: widget.supplier?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(supplier);
  }
}

class _SupplierDetailsSheet extends StatelessWidget {
  final Supplier supplier;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _SupplierDetailsSheet({
    required this.supplier,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final purchaseColor =
        isDarkMode ? IOSDarkColors.purchaseColor : IOSColors.purchaseColor;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.systemBackground
            : IOSColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? IOSDarkColors.labelQuaternary
                  : IOSColors.labelQuaternary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header with gradient
          Container(
            margin: const EdgeInsets.all(IOSSpacing.md),
            padding: const EdgeInsets.all(IOSSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        purchaseColor.withOpacity(0.2),
                        IOSDarkColors.systemBackground
                      ]
                    : [
                        purchaseColor.withOpacity(0.1),
                        IOSColors.systemBackground
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(IOSBorderRadius.large),
            ),
            child: Row(
              children: [
                // Avatar with gradient
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [purchaseColor, purchaseColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(IOSBorderRadius.large),
                    boxShadow: [
                      BoxShadow(
                        color: purchaseColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      supplier.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 28,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: IOSSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(supplier.name, style: IOSTextStyles.title2),
                      if (supplier.phone != null)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.phone,
                              size: 14,
                              color: isDarkMode
                                  ? IOSDarkColors.labelSecondary
                                  : IOSColors.labelSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(supplier.phone!,
                                style: IOSTextStyles.subheadline),
                          ],
                        ),
                      if (supplier.email != null)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.mail,
                              size: 14,
                              color: isDarkMode
                                  ? IOSDarkColors.labelSecondary
                                  : IOSColors.labelSecondary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(supplier.email!,
                                  style: IOSTextStyles.subheadline,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats Card
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
            child: IOSCard(
              child: _buildDetailRow('Total Purchases',
                  supplier.formattedTotalPurchases, isDarkMode, purchaseColor),
            ),
          ),
          const SizedBox(height: IOSSpacing.sm),
          // Products
          if (supplier.products.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: IOSSpacing.md),
              child: IOSCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.cube_box,
                          size: 16,
                          color: isDarkMode
                              ? IOSDarkColors.labelSecondary
                              : IOSColors.labelSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text('Products',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isDarkMode
                                    ? IOSDarkColors.labelPrimary
                                    : IOSColors.labelPrimary)),
                      ],
                    ),
                    const SizedBox(height: IOSSpacing.sm),
                    Wrap(
                      spacing: IOSSpacing.xs,
                      runSpacing: IOSSpacing.xs,
                      children: supplier.products
                          .map((p) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: purchaseColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: purchaseColor.withOpacity(0.2)),
                                ),
                                child: Text(p,
                                    style: TextStyle(
                                        color: purchaseColor,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500)),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
          const Spacer(),
          // Actions
          Padding(
            padding: const EdgeInsets.all(IOSSpacing.md),
            child: Row(
              children: [
                Expanded(
                    child: IOSOutlineButton(title: 'Edit', onPressed: onEdit)),
                const SizedBox(width: IOSSpacing.md),
                Expanded(
                    child: IOSButton(
                        title: 'Delete',
                        isDestructive: true,
                        onPressed: onDelete)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, bool isDarkMode, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: IOSSpacing.xs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: isDarkMode
                      ? IOSDarkColors.labelSecondary
                      : IOSColors.labelSecondary)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 18, color: color)),
        ],
      ),
    );
  }
}
