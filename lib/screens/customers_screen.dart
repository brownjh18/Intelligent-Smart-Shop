import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/models/customer.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:ismart_shop/widgets/ios_app_bar.dart';
import 'package:ismart_shop/widgets/app_sidebar.dart';
import 'package:ismart_shop/widgets/app_bottom_nav.dart';
import 'package:ismart_shop/widgets/expandable_fab.dart';
import 'package:ismart_shop/screens/suppliers_screen.dart';
import 'package:ismart_shop/screens/voice_recording_screen.dart';
import 'package:ismart_shop/screens/categories_screen.dart';
import 'package:ismart_shop/screens/receipts_screen.dart';
import 'package:ismart_shop/screens/expenses_screen.dart';

class CustomersScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const CustomersScreen({super.key, this.onNavigate});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  String _searchQuery = '';
  bool _isLoading = true;
  List<Customer> _customers = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String? userId = authProvider.userModel?.id;

      debugPrint(
          'Loading customers - userId: $userId, isAuthenticated: ${authProvider.isAuthenticated}');

      if (userId == null || userId.isEmpty) {
        // Show empty state if not authenticated
        setState(() {
          _customers = [];
          _isLoading = false;
        });
        return;
      }

      // Load from local SQLite first (offline-first)
      final localCustomers = await LocalDatabaseService.getCustomers(userId);

      setState(() {
        _customers = localCustomers
            .map((local) => Customer(
                  id: local.firebaseId ?? local.id,
                  name: local.name,
                  phone: local.phone,
                  email: local.email,
                  address: local.address,
                  totalPurchases: local.totalPurchases,
                  creditBalance: local.creditBalance,
                  notes: local.notes,
                  userId: local.userId,
                  createdAt: local.createdAt,
                  updatedAt: local.updatedAt,
                  isActive: local.isActive,
                ))
            .toList();
        _isLoading = false;
      });

      debugPrint('Loaded ${_customers.length} customers from local database');

      // Try to sync with Firestore if online
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('customers')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        // Update local database with Firebase data (avoid duplicates)
        for (final doc in snapshot.docs) {
          final customer = Customer.fromFirestore(doc);

          // Check if we already have this customer locally (by firebaseId)
          final existingCustomer =
              await LocalDatabaseService.getCustomerByFirebaseId(doc.id);

          if (existingCustomer != null) {
            // Update existing record
            final updatedCustomer = existingCustomer.copyWith(
              name: customer.name,
              phone: customer.phone,
              email: customer.email,
              address: customer.address,
              totalPurchases: customer.totalPurchases,
              creditBalance: customer.creditBalance,
              notes: customer.notes,
              syncStatus: SyncStatus.synced,
            );
            await LocalDatabaseService.updateCustomer(updatedCustomer);
          } else {
            // Insert new record
            final localCustomer = LocalCustomer(
              id: doc.id,
              name: customer.name,
              phone: customer.phone,
              email: customer.email,
              address: customer.address,
              totalPurchases: customer.totalPurchases,
              creditBalance: customer.creditBalance,
              notes: customer.notes,
              userId: customer.userId,
              createdAt: customer.createdAt,
              updatedAt: customer.updatedAt,
              isActive: customer.isActive,
              syncStatus: SyncStatus.synced,
              firebaseId: doc.id,
            );
            await LocalDatabaseService.insertCustomer(localCustomer);
          }
        }

        // Reload from local database
        final updatedCustomers =
            await LocalDatabaseService.getCustomers(userId);
        setState(() {
          _customers = updatedCustomers
              .map((local) => Customer(
                    id: local.firebaseId ?? local.id,
                    name: local.name,
                    phone: local.phone,
                    email: local.email,
                    address: local.address,
                    totalPurchases: local.totalPurchases,
                    creditBalance: local.creditBalance,
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
      debugPrint('Error loading customers: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading customers: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Customer> get _filteredCustomers {
    return _customers.where((customer) {
      return _searchQuery.isEmpty ||
          customer.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (customer.phone?.contains(_searchQuery) ?? false);
    }).toList();
  }

  void _handleBottomNav(int index) {
    Navigator.popUntil(context, (route) => route.isFirst);
    widget.onNavigate?.call(index);
  }

  void _handleSidebarNavigation(int index) {
    if (index < 0) {
      // Handle secondary screens
      switch (index) {
        case -1:
          // Already on Customers
          break;
        case -2:
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const SuppliersScreen()),
          );
          break;
        case -3:
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const CategoriesScreen()),
          );
          break;
        case -4:
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ReceiptsScreen()),
          );
          break;
        case -5:
          Navigator.push(
            context,
            CupertinoPageRoute(builder: (_) => const ExpensesScreen()),
          );
          break;
      }
    } else {
      // Main navigation - go to home and switch tab
      Navigator.popUntil(context, (route) => route.isFirst);
      widget.onNavigate?.call(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode
        ? IOSDarkColors.systemBackground
        : IOSColors.systemBackground;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

    return Scaffold(
      key: _scaffoldKey,
      drawer: AppSidebar(
        currentIndex: -1, // Customers is a secondary screen
        onNavigate: (index) => _handleSidebarNavigation(index),
      ),
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      appBar: IOSNavigationBar(
        title: 'Customers',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: Icon(
            CupertinoIcons.line_horizontal_3,
            color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
          ),
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
              placeholder: 'Search customers...',
              onChanged: (value) => setState(() => _searchQuery = value),
            ),
          ),
          // Customer list
          Expanded(
            child: _isLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _filteredCustomers.isEmpty
                    ? IOSEmptyState(
                        icon: CupertinoIcons.person_2,
                        title: 'No Customers',
                        subtitle: _searchQuery.isEmpty
                            ? 'Add your first customer to track sales'
                            : 'Try a different search term',
                        action: _searchQuery.isEmpty
                            ? IOSButton(
                                title: 'Add Customer',
                                onPressed: () =>
                                    _showAddCustomerDialog(context),
                              )
                            : null,
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(IOSSpacing.md),
                        itemCount: _filteredCustomers.length,
                        itemBuilder: (context, index) {
                          final customer = _filteredCustomers[index];
                          return _CustomerCard(
                            customer: customer,
                            onTap: () =>
                                _showCustomerDetails(context, customer),
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
            label: 'Customer',
            icon: CupertinoIcons.add,
            color: IOSColors.primary,
            onPressed: () => _showAddCustomerDialog(context),
          ),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: 0,
        onNavigate: (index) => _handleBottomNav(index),
      ),
    );
  }

  void _showAddCustomerDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CustomerFormSheet(
        onSave: (customer) async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to save customer'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Generate local ID
            final localId = _uuid.v4();

            // Create local customer first (offline-first)
            final localCustomer = LocalCustomer(
              id: localId,
              name: customer.name,
              phone: customer.phone,
              email: customer.email,
              address: customer.address,
              totalPurchases: customer.totalPurchases,
              creditBalance: customer.creditBalance,
              notes: customer.notes,
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: null,
            );

            // Save to local SQLite first
            await LocalDatabaseService.insertCustomer(localCustomer);
            debugPrint('Customer saved to local database: $localId');

            // Try to sync with Firestore in background
            bool firebaseSynced = false;
            try {
              final docRef =
                  await FirebaseFirestore.instance.collection('customers').add({
                ...customer.toFirestore(),
                'userId': userId,
              });

              // Update local record with Firebase ID using copyWith
              final syncedCustomer = localCustomer.copyWith(
                firebaseId: docRef.id,
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateCustomer(syncedCustomer);
              debugPrint('Customer synced to Firestore: ${docRef.id}');
              firebaseSynced = true;
            } catch (e) {
              debugPrint(
                  'Firestore sync failed (customer will sync later): $e');
            }

            _loadCustomers();
            if (mounted) {
              Navigator.pop(context);
              // Show appropriate message based on sync status
              if (firebaseSynced) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Customer added successfully and synced to cloud'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Customer saved locally. Will sync when online.'),
                      backgroundColor: Colors.orange),
                );
              }
            }
          } catch (e) {
            debugPrint('Error adding customer: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error saving customer: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showCustomerDetails(BuildContext context, Customer customer) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CustomerDetailsSheet(
        customer: customer,
        onEdit: () {
          Navigator.pop(context);
          _showEditCustomerDialog(context, customer);
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
            await LocalDatabaseService.deleteCustomer(customer.id);
            debugPrint('Customer marked as deleted locally: ${customer.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(customer.id)
                  .update({
                'isActive': false,
                'updatedAt': DateTime.now(),
              });
              debugPrint('Customer deleted in Firestore: ${customer.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (delete will sync later): $e');
            }

            _loadCustomers();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Customer deleted (saved locally)'),
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

  void _showEditCustomerDialog(BuildContext context, Customer customer) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CustomerFormSheet(
        customer: customer,
        onSave: (updatedCustomer) async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to update customer'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Update local SQLite first (offline-first)
            final localCustomer = LocalCustomer(
              id: customer.id,
              name: updatedCustomer.name,
              phone: updatedCustomer.phone,
              email: updatedCustomer.email,
              address: updatedCustomer.address,
              totalPurchases: updatedCustomer.totalPurchases,
              creditBalance: updatedCustomer.creditBalance,
              notes: updatedCustomer.notes,
              userId: userId,
              createdAt: customer.createdAt,
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: customer.id,
            );
            await LocalDatabaseService.updateCustomer(localCustomer);
            debugPrint('Customer updated locally: ${customer.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('customers')
                  .doc(customer.id)
                  .update({
                ...updatedCustomer.toFirestore(),
                'updatedAt': DateTime.now(),
              });

              // Mark as synced using copyWith
              final syncedCustomer = localCustomer.copyWith(
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateCustomer(syncedCustomer);
              debugPrint('Customer updated in Firestore: ${customer.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (update will sync later): $e');
            }

            _loadCustomers();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Customer updated (saved locally)'),
                    backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            debugPrint('Error updating customer: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error updating customer: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  final Customer customer;
  final VoidCallback onTap;

  const _CustomerCard({required this.customer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;

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
                color: primaryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Center(
                child: Text(
                  customer.initials,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: primaryColor,
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
                    customer.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (customer.phone != null)
                    Text(
                      customer.phone!,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode
                            ? IOSDarkColors.labelSecondary
                            : IOSColors.labelSecondary,
                      ),
                    ),
                ],
              ),
            ),
            // Total purchases
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  customer.formattedTotalPurchases,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: primaryColor,
                  ),
                ),
                if (customer.hasCredit)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Credit: ${customer.formattedCreditBalance}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomerFormSheet extends StatefulWidget {
  final Customer? customer;
  final Function(Customer) onSave;

  const _CustomerFormSheet({this.customer, required this.onSave});

  @override
  State<_CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<_CustomerFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _addressController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.customer?.name ?? '');
    _phoneController =
        TextEditingController(text: widget.customer?.phone ?? '');
    _emailController =
        TextEditingController(text: widget.customer?.email ?? '');
    _addressController =
        TextEditingController(text: widget.customer?.address ?? '');
    _notesController =
        TextEditingController(text: widget.customer?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
                Text(widget.customer == null ? 'Add Customer' : 'Edit Customer',
                    style: IOSTextStyles.headline),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saveCustomer,
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
                _buildLabel('Name *'),
                IOSTextField(
                  controller: _nameController,
                  placeholder: 'Enter customer name',
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

  void _saveCustomer() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter customer name'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final customer = Customer(
      id: widget.customer?.id ?? '',
      name: _nameController.text,
      phone: _phoneController.text.isEmpty ? null : _phoneController.text,
      email: _emailController.text.isEmpty ? null : _emailController.text,
      address: _addressController.text.isEmpty ? null : _addressController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      totalPurchases: widget.customer?.totalPurchases ?? 0,
      creditBalance: widget.customer?.creditBalance ?? 0,
      userId: '',
      createdAt: widget.customer?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(customer);
  }
}

class _CustomerDetailsSheet extends StatelessWidget {
  final Customer customer;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CustomerDetailsSheet({
    required this.customer,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final cardBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;

    return Container(
      height: MediaQuery.of(context).size.height * 0.68,
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.systemBackground
            : IOSColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Modern handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 36,
            height: 5,
            decoration: BoxDecoration(
              color: isDarkMode
                  ? IOSDarkColors.labelQuaternary
                  : IOSColors.labelQuaternary,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          // Header with gradient
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        primaryColor.withOpacity(0.15),
                        IOSDarkColors.systemBackground
                      ]
                    : [
                        primaryColor.withOpacity(0.1),
                        IOSColors.systemBackground
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: primaryColor.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                // Avatar with gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, primaryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      customer.initials,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        customer.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: labelPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (customer.phone != null)
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.phone_fill,
                              size: 14,
                              color: labelSecondary,
                            ),
                            const SizedBox(width: 6),
                            Text(customer.phone!,
                                style: TextStyle(
                                    fontSize: 13, color: labelSecondary)),
                          ],
                        ),
                      if (customer.email != null) ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              CupertinoIcons.mail_solid,
                              size: 14,
                              color: labelSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(customer.email!,
                                  style: TextStyle(
                                      fontSize: 13, color: labelSecondary),
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Stats Cards
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _StatCard(
                    title: 'Total Purchases',
                    value: customer.formattedTotalPurchases,
                    icon: CupertinoIcons.cart_fill,
                    color: primaryColor,
                    isDarkMode: isDarkMode,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    title: 'Credit Balance',
                    value: customer.formattedCreditBalance,
                    icon: CupertinoIcons.creditcard_fill,
                    color: customer.hasCredit ? Colors.red : Colors.green,
                    isDarkMode: isDarkMode,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Notes if available
          if (customer.notes != null && customer.notes!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDarkMode
                        ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                        : IOSColors.labelQuaternary.withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          CupertinoIcons.doc_text_fill,
                          size: 16,
                          color: labelSecondary,
                        ),
                        const SizedBox(width: 8),
                        Text('Notes',
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: labelPrimary)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(customer.notes!,
                        style: TextStyle(fontSize: 14, color: labelSecondary)),
                  ],
                ),
              ),
            ),
          const Spacer(),
          // Action buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDarkMode
                  ? IOSDarkColors.systemBackground
                  : IOSColors.systemBackground,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: onEdit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.pencil,
                                size: 18, color: primaryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: primaryColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                        ),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: onDelete,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.trash,
                                size: 18, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDarkMode;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? IOSDarkColors.labelSecondary
                          : IOSColors.labelSecondary)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}
