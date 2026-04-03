import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/models/category.dart';
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
import 'package:ismart_shop/screens/suppliers_screen.dart';
import 'package:ismart_shop/screens/receipts_screen.dart';
import 'package:ismart_shop/screens/expenses_screen.dart';

class CategoriesScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const CategoriesScreen({super.key, this.onNavigate});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  bool _isLoading = true;
  List<Category> _categories = [];
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String? userId = authProvider.userModel?.id;

      debugPrint(
          'Loading categories - userId: $userId, isAuthenticated: ${authProvider.isAuthenticated}');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _categories = [];
          _isLoading = false;
        });
        return;
      }

      // Load from local SQLite first (offline-first)
      final localCategories = await LocalDatabaseService.getCategories(userId);

      setState(() {
        _categories = localCategories
            .map((local) => Category(
                  id: local.firebaseId ?? local.id,
                  name: local.name,
                  description: local.description,
                  iconName: local.iconName,
                  colorValue: local.colorValue,
                  userId: local.userId,
                  createdAt: local.createdAt,
                  updatedAt: local.updatedAt,
                  isActive: local.isActive,
                ))
            .toList();
        _isLoading = false;
      });

      debugPrint('Loaded ${_categories.length} categories from local database');

      // Try to sync with Firestore if online
      try {
        final snapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        // Update local database with Firebase data (avoid duplicates)
        for (final doc in snapshot.docs) {
          final category = Category.fromFirestore(doc);

          // Check if we already have this category locally (by firebaseId)
          final existingCategory =
              await LocalDatabaseService.getCategoryByFirebaseId(doc.id);

          if (existingCategory != null) {
            // Update existing record
            final updatedCategory = existingCategory.copyWith(
              name: category.name,
              description: category.description,
              iconName: category.iconName,
              colorValue: category.colorValue,
              syncStatus: SyncStatus.synced,
            );
            await LocalDatabaseService.updateCategory(updatedCategory);
          } else {
            // Insert new record
            final localCategory = LocalCategory(
              id: doc.id,
              name: category.name,
              description: category.description,
              iconName: category.iconName,
              colorValue: category.colorValue,
              userId: category.userId,
              createdAt: category.createdAt,
              updatedAt: category.updatedAt,
              isActive: category.isActive,
              syncStatus: SyncStatus.synced,
              firebaseId: doc.id,
            );
            await LocalDatabaseService.insertCategory(localCategory);
          }
        }

        // Reload from local database
        final updatedCategories =
            await LocalDatabaseService.getCategories(userId);
        setState(() {
          _categories = updatedCategories
              .map((local) => Category(
                    id: local.firebaseId ?? local.id,
                    name: local.name,
                    description: local.description,
                    iconName: local.iconName,
                    colorValue: local.colorValue,
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
      debugPrint('Error loading categories: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading categories: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleSidebarNavigation(int index) {
    if (index < 0) {
      switch (index) {
        case -1:
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const CustomersScreen()));
          break;
        case -2:
          Navigator.push(context,
              CupertinoPageRoute(builder: (_) => const SuppliersScreen()));
          break;
        case -3:
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
          AppSidebar(currentIndex: -3, onNavigate: _handleSidebarNavigation),
      appBar: IOSNavigationBar(
        title: 'Categories',
        automaticallyImplyLeading: false,
        leading: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          child: Icon(CupertinoIcons.line_horizontal_3,
              color: isDarkMode ? IOSDarkColors.primary : IOSColors.primary),
        ),
      ),
      body: _isLoading
          ? const Center(child: CupertinoActivityIndicator())
          : _categories.isEmpty
              ? IOSEmptyState(
                  icon: CupertinoIcons.tag,
                  title: 'No Categories',
                  subtitle: 'Add categories to organize your products',
                  action: IOSButton(
                    title: 'Add Category',
                    onPressed: () => _showAddCategoryDialog(context),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(IOSSpacing.md),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    return _CategoryCard(
                      category: category,
                      onTap: () => _showCategoryDetails(context, category),
                    );
                  },
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
            label: 'Category',
            icon: CupertinoIcons.add,
            color: IOSColors.primary,
            onPressed: () => _showAddCategoryDialog(context),
          ),
        ],
      ),
      bottomNavigationBar:
          AppBottomNav(currentIndex: 0, onNavigate: _handleBottomNav),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CategoryFormSheet(
        onSave: (category) async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to save category'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Generate local ID
            final localId = _uuid.v4();

            // Create local category first (offline-first)
            final localCategory = LocalCategory(
              id: localId,
              name: category.name,
              description: category.description,
              iconName: category.iconName,
              colorValue: category.colorValue,
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: null,
            );

            // Save to local SQLite first
            await LocalDatabaseService.insertCategory(localCategory);
            debugPrint('Category saved to local database: $localId');

            // Try to sync with Firestore in background
            bool firebaseSynced = false;
            try {
              final docRef = await FirebaseFirestore.instance
                  .collection('categories')
                  .add({
                ...category.toFirestore(),
                'userId': userId,
              });

              // Update local record with Firebase ID using copyWith
              final syncedCategory = localCategory.copyWith(
                firebaseId: docRef.id,
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateCategory(syncedCategory);
              debugPrint('Category synced to Firestore: ${docRef.id}');
              firebaseSynced = true;
            } catch (e) {
              debugPrint(
                  'Firestore sync failed (category will sync later): $e');
            }

            _loadCategories();
            if (mounted) {
              Navigator.pop(context);
              // Show appropriate message based on sync status
              if (firebaseSynced) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Category added successfully and synced to cloud'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Category saved locally. Will sync when online.'),
                      backgroundColor: Colors.orange),
                );
              }
            }
          } catch (e) {
            debugPrint('Error adding category: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error saving category: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showCategoryDetails(BuildContext context, Category category) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CategoryDetailsSheet(
        category: category,
        onEdit: () {
          Navigator.pop(context);
          _showEditCategoryDialog(context, category);
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
            await LocalDatabaseService.deleteCategory(category.id);
            debugPrint('Category marked as deleted locally: ${category.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('categories')
                  .doc(category.id)
                  .update({
                'isActive': false,
                'updatedAt': DateTime.now(),
              });
              debugPrint('Category deleted in Firestore: ${category.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (delete will sync later): $e');
            }

            _loadCategories();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Category deleted (saved locally)'),
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

  void _showEditCategoryDialog(BuildContext context, Category category) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => _CategoryFormSheet(
        category: category,
        onSave: (updatedCategory) async {
          try {
            final authProvider = context.read<AuthProvider>();
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to update category'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Update local SQLite first (offline-first)
            final localCategory = LocalCategory(
              id: category.id,
              name: updatedCategory.name,
              description: updatedCategory.description,
              iconName: updatedCategory.iconName,
              colorValue: updatedCategory.colorValue,
              userId: userId,
              createdAt: category.createdAt,
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: category.id,
            );
            await LocalDatabaseService.updateCategory(localCategory);
            debugPrint('Category updated locally: ${category.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('categories')
                  .doc(category.id)
                  .update({
                ...updatedCategory.toFirestore(),
                'updatedAt': DateTime.now(),
              });

              // Mark as synced using copyWith
              final syncedCategory = localCategory.copyWith(
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateCategory(syncedCategory);
              debugPrint('Category updated in Firestore: ${category.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (update will sync later): $e');
            }

            _loadCategories();
            if (mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Category updated (saved locally)'),
                    backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            debugPrint('Error updating category: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error updating category: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;

  const _CategoryCard({required this.category, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = Color(category.colorValue);

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
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: categoryColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
              ),
              child: Icon(
                CupertinoIcons.tag_fill,
                color: categoryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: IOSSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: isDarkMode
                          ? IOSDarkColors.labelPrimary
                          : IOSColors.labelPrimary,
                    ),
                  ),
                  if (category.description != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      category.description!,
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
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 18,
              color: isDarkMode
                  ? IOSDarkColors.labelTertiary
                  : IOSColors.labelTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryFormSheet extends StatefulWidget {
  final Category? category;
  final Function(Category) onSave;

  const _CategoryFormSheet({this.category, required this.onSave});

  @override
  State<_CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<_CategoryFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  int _selectedColorIndex = 0;

  final List<int> _colorOptions = [
    0xFF34C759, // Green
    0xFFFF9500, // Orange
    0xFFFF3B30, // Red
    0xFF007AFF, // Blue
    0xFFAF52DE, // Purple
    0xFFFFCC00, // Yellow
    0xFF5AC8FA, // Cyan
    0xFFFF2D55, // Pink
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _descriptionController =
        TextEditingController(text: widget.category?.description ?? '');
    if (widget.category != null) {
      _selectedColorIndex = _colorOptions.indexOf(widget.category!.colorValue);
      if (_selectedColorIndex < 0) _selectedColorIndex = 0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
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
                Text(widget.category == null ? 'Add Category' : 'Edit Category',
                    style: IOSTextStyles.headline),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saveCategory,
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
                // Name
                _buildLabel('Category Name'),
                IOSTextField(
                  controller: _nameController,
                  placeholder: 'Enter category name',
                ),
                const SizedBox(height: IOSSpacing.md),
                // Description
                _buildLabel('Description (Optional)'),
                IOSTextField(
                  controller: _descriptionController,
                  placeholder: 'Enter description',
                ),
                const SizedBox(height: IOSSpacing.md),
                // Color
                _buildLabel('Color'),
                Wrap(
                  spacing: IOSSpacing.sm,
                  runSpacing: IOSSpacing.sm,
                  children: List.generate(_colorOptions.length, (index) {
                    final color = Color(_colorOptions[index]);
                    final isSelected = _selectedColorIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedColorIndex = index),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius:
                              BorderRadius.circular(IOSBorderRadius.medium),
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 3)
                              : null,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(CupertinoIcons.checkmark,
                                color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  }),
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

  void _saveCategory() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter category name'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final category = Category(
      id: widget.category?.id ?? '',
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      colorValue: _colorOptions[_selectedColorIndex],
      userId: '',
      createdAt: widget.category?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(category);
  }
}

class _CategoryDetailsSheet extends StatelessWidget {
  final Category category;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoryDetailsSheet({
    required this.category,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final categoryColor = Color(category.colorValue);
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final cardBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;

    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
                        categoryColor.withOpacity(0.2),
                        IOSDarkColors.systemBackground
                      ]
                    : [
                        categoryColor.withOpacity(0.15),
                        IOSColors.systemBackground
                      ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: categoryColor.withOpacity(0.2),
              ),
            ),
            child: Row(
              children: [
                // Icon with gradient
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [categoryColor, categoryColor.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: categoryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(CupertinoIcons.tag_fill,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: labelPrimary,
                        ),
                      ),
                      if (category.description != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 14,
                            color: labelSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Details Card
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Color Info Card
                Container(
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
                    children: [
                      _buildDetailRow(
                        'Name',
                        category.name,
                        CupertinoIcons.tag_fill,
                        categoryColor,
                        isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: isDarkMode
                            ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                            : IOSColors.labelQuaternary.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Description',
                        category.description ?? 'No description',
                        CupertinoIcons.doc_text_fill,
                        labelSecondary,
                        isDarkMode,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: isDarkMode
                            ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                            : IOSColors.labelQuaternary.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                CupertinoIcons.paintbrush_fill,
                                size: 18,
                                color: labelSecondary,
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Color',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: labelSecondary,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: categoryColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: categoryColor.withOpacity(0.5)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 16,
                                  height: 16,
                                  decoration: BoxDecoration(
                                    color: categoryColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '#${category.colorValue.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
                                  style: TextStyle(
                                      color: categoryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        height: 1,
                        color: isDarkMode
                            ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                            : IOSColors.labelQuaternary.withOpacity(0.2),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailRow(
                        'Created',
                        _formatDate(category.createdAt),
                        CupertinoIcons.calendar,
                        labelSecondary,
                        isDarkMode,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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
                          color: categoryColor.withOpacity(0.3),
                        ),
                      ),
                      child: CupertinoButton(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        onPressed: onEdit,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(CupertinoIcons.pencil,
                                size: 18, color: categoryColor),
                            const SizedBox(width: 8),
                            Text(
                              'Edit',
                              style: TextStyle(
                                color: categoryColor,
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

  Widget _buildDetailRow(String label, String value, IconData icon,
      Color iconColor, bool isDarkMode) {
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: labelSecondary),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: labelSecondary,
              ),
            ),
          ],
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: labelPrimary,
              fontSize: 14,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
