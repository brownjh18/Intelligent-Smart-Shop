import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:ismart_shop/models/product.dart';
import 'package:ismart_shop/models/category.dart';
import 'package:ismart_shop/providers/auth_provider.dart';
import 'package:ismart_shop/utils/ios_theme.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ismart_shop/models/transaction_item.dart';
import 'package:ismart_shop/services/local_database_service.dart';
import 'package:uuid/uuid.dart';
import 'package:ismart_shop/widgets/expandable_fab.dart';
import 'package:ismart_shop/screens/voice_recording_screen.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = true;
  List<Product> _products = [];
  List<Category> _categories = [];
  final _uuid = const Uuid();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      String? userId = authProvider.userModel?.id;

      debugPrint(
          'Loading inventory - userId: $userId, isAuthenticated: ${authProvider.isAuthenticated}');

      if (userId == null || userId.isEmpty) {
        setState(() {
          _products = [];
          _categories = [];
          _isLoading = false;
        });
        return;
      }

      // Load products from local SQLite first (offline-first)
      final localProducts = await LocalDatabaseService.getProducts(userId);

      // Load categories from local SQLite
      final localCategories = await LocalDatabaseService.getCategories(userId);

      setState(() {
        _products = localProducts
            .map((local) => Product(
                  id: local.firebaseId ?? local.id,
                  name: local.name,
                  description: local.description,
                  categoryId: local.categoryId,
                  categoryName: local.categoryName,
                  unit: local.unit,
                  sellingPrice: local.sellingPrice,
                  costPrice: local.costPrice,
                  stockQuantity: local.stockQuantity,
                  lowStockThreshold: local.lowStockThreshold,
                  imageUrl: local.imageUrl,
                  userId: local.userId,
                  createdAt: local.createdAt,
                  updatedAt: local.updatedAt,
                  isActive: local.isActive,
                ))
            .toList();
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

      debugPrint('Loaded ${_products.length} products from local database');

      // Try to sync with Firestore if online
      try {
        // Sync products
        final productsSnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        for (final doc in productsSnapshot.docs) {
          final product = Product.fromFirestore(doc);

          // Check if we already have this product locally (by firebaseId)
          final existingProduct =
              await LocalDatabaseService.getProductByFirebaseId(doc.id);

          if (existingProduct != null) {
            // Update existing record
            final updatedProduct = existingProduct.copyWith(
              name: product.name,
              description: product.description,
              categoryId: product.categoryId,
              categoryName: product.categoryName,
              unit: product.unit,
              sellingPrice: product.sellingPrice,
              costPrice: product.costPrice,
              stockQuantity: product.stockQuantity,
              lowStockThreshold: product.lowStockThreshold,
              imageUrl: product.imageUrl,
              syncStatus: SyncStatus.synced,
            );
            await LocalDatabaseService.updateProduct(updatedProduct);
          } else {
            // Insert new record
            final localProduct = LocalProduct(
              id: doc.id,
              name: product.name,
              description: product.description,
              categoryId: product.categoryId,
              categoryName: product.categoryName,
              unit: product.unit,
              sellingPrice: product.sellingPrice,
              costPrice: product.costPrice,
              stockQuantity: product.stockQuantity,
              lowStockThreshold: product.lowStockThreshold,
              imageUrl: product.imageUrl,
              userId: product.userId,
              createdAt: product.createdAt,
              updatedAt: product.updatedAt,
              isActive: product.isActive,
              syncStatus: SyncStatus.synced,
              firebaseId: doc.id,
            );
            await LocalDatabaseService.insertProduct(localProduct);
          }
        }

        // Sync categories
        final categoriesSnapshot = await FirebaseFirestore.instance
            .collection('categories')
            .where('userId', isEqualTo: userId)
            .where('isActive', isEqualTo: true)
            .orderBy('name')
            .get();

        for (final doc in categoriesSnapshot.docs) {
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
        final updatedProducts = await LocalDatabaseService.getProducts(userId);
        final updatedCategories =
            await LocalDatabaseService.getCategories(userId);

        setState(() {
          _products = updatedProducts
              .map((local) => Product(
                    id: local.firebaseId ?? local.id,
                    name: local.name,
                    description: local.description,
                    categoryId: local.categoryId,
                    categoryName: local.categoryName,
                    unit: local.unit,
                    sellingPrice: local.sellingPrice,
                    costPrice: local.costPrice,
                    stockQuantity: local.stockQuantity,
                    lowStockThreshold: local.lowStockThreshold,
                    imageUrl: local.imageUrl,
                    userId: local.userId,
                    createdAt: local.createdAt,
                    updatedAt: local.updatedAt,
                    isActive: local.isActive,
                  ))
              .toList();
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
      debugPrint('Error loading inventory: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error loading inventory: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  List<Product> get _filteredProducts {
    return _products.where((product) {
      final matchesSearch = _searchQuery.isEmpty ||
          product.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || product.categoryId == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<Product> get _lowStockProducts {
    return _products.where((p) => p.isLowStock).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode
          ? IOSDarkColors.secondarySystemBackground
          : IOSColors.secondarySystemBackground,
      body: CustomScrollView(
        slivers: [
          // Search and Filter
          SliverToBoxAdapter(
            child: Container(
              color: isDarkMode
                  ? IOSDarkColors.systemBackground
                  : IOSColors.systemBackground,
              padding: const EdgeInsets.all(IOSSpacing.md),
              child: Column(
                children: [
                  // Search bar
                  CupertinoSearchTextField(
                    placeholder: 'Search products...',
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  const SizedBox(height: IOSSpacing.sm),
                  // Category filter
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All', null),
                        ..._categories
                            .map((cat) => _buildFilterChip(cat.name, cat.id)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Low Stock Alert
          if (_lowStockProducts.isNotEmpty && _searchQuery.isEmpty)
            SliverToBoxAdapter(
              child: _buildLowStockAlert(isDarkMode),
            ),
          // Products Grid
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_filteredProducts.isEmpty)
            SliverFillRemaining(
              child: IOSEmptyState(
                icon: CupertinoIcons.cube_box,
                title: 'No Products Found',
                subtitle: _searchQuery.isEmpty
                    ? 'Add your first product to get started'
                    : 'Try a different search term',
                action: _searchQuery.isEmpty
                    ? IOSButton(
                        title: 'Add Product',
                        onPressed: () => _showAddProductDialog(context),
                      )
                    : null,
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(IOSSpacing.md),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: IOSSpacing.sm,
                  mainAxisSpacing: IOSSpacing.sm,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = _filteredProducts[index];
                    return _ProductCard(
                      product: product,
                      onTap: () => _showProductDetails(context, product),
                    );
                  },
                  childCount: _filteredProducts.length,
                ),
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
            label: 'Product',
            icon: CupertinoIcons.add,
            color: IOSColors.primary,
            onPressed: () => _showAddProductDialog(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? categoryId) {
    final isSelected = _selectedCategory == categoryId;

    return Padding(
      padding: const EdgeInsets.only(right: IOSSpacing.xs),
      child: IOSFilterChip(
        label: label,
        isSelected: isSelected,
        onTap: () {
          setState(() => _selectedCategory = categoryId);
        },
      ),
    );
  }

  Widget _buildLowStockAlert(bool isDarkMode) {
    final warningColor = isDarkMode ? IOSDarkColors.warning : IOSColors.warning;

    return Container(
      margin: const EdgeInsets.all(IOSSpacing.md),
      padding: const EdgeInsets.all(IOSSpacing.md),
      decoration: BoxDecoration(
        color: warningColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(IOSBorderRadius.large),
        border: Border.all(color: warningColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: warningColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(IOSBorderRadius.small),
            ),
            child: Icon(CupertinoIcons.exclamationmark_triangle,
                color: warningColor, size: 20),
          ),
          const SizedBox(width: IOSSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Low Stock Alert',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: warningColor,
                  ),
                ),
                Text(
                  '${_lowStockProducts.length} products need restocking',
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
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context) {
    final authProvider = context.read<AuthProvider>();

    // Check if categories are available
    if (_categories.isEmpty) {
      // Show dialog to create a category first
      showCupertinoDialog(
        context: context,
        builder: (dialogContext) => CupertinoAlertDialog(
          title: const Text('No Categories'),
          content: const Text(
              'You need to create at least one category before adding products. Would you like to create one now?'),
          actions: [
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                _showAddCategoryAndProductDialog(context, authProvider);
              },
              child: const Text('Add Category'),
            ),
          ],
        ),
      );
      return;
    }

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _ProductFormSheet(
        categories: _categories,
        onSave: (product) async {
          try {
            final userId = authProvider.userModel?.id;
            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Please log in again to save product'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Generate local ID
            final localId = _uuid.v4();

            // Create local product first (offline-first)
            final localProduct = LocalProduct(
              id: localId,
              name: product.name,
              description: product.description,
              categoryId: product.categoryId,
              categoryName: product.categoryName,
              unit: product.unit,
              sellingPrice: product.sellingPrice,
              costPrice: product.costPrice,
              stockQuantity: product.stockQuantity,
              lowStockThreshold: product.lowStockThreshold,
              imageUrl: product.imageUrl,
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: null,
            );

            // Save to local SQLite first
            await LocalDatabaseService.insertProduct(localProduct);
            debugPrint('Product saved to local database: $localId');

            // Try to sync with Firestore in background
            bool firebaseSynced = false;
            String? firebaseError;
            try {
              // Create a product with userId for Firestore
              final firestoreProduct = product.copyWith(
                userId: userId,
                createdAt: DateTime.now(),
              );

              final docRef = await FirebaseFirestore.instance
                  .collection('products')
                  .add(firestoreProduct.toFirestore());

              // Update local record with Firebase ID using copyWith
              final syncedProduct = localProduct.copyWith(
                firebaseId: docRef.id,
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateProduct(syncedProduct);
              debugPrint('Product synced to Firestore: ${docRef.id}');
              firebaseSynced = true;
            } catch (e) {
              firebaseError = e.toString();
              debugPrint('Firestore sync failed (product will sync later): $e');
            }

            await _loadData();
            if (mounted) {
              Navigator.pop(dialogContext);
              // Show appropriate message based on sync status
              if (firebaseSynced) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Product added successfully and synced to cloud'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Product saved locally. Will sync when online.'),
                      backgroundColor: Colors.orange),
                );
              }
            }
          } catch (e) {
            debugPrint('Error adding product: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error adding product: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  // Method to add category first, then product
  void _showAddCategoryAndProductDialog(
      BuildContext context, AuthProvider authProvider) {
    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _CategoryFormSheetForProduct(
        onSave: (category) async {
          try {
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

            // Generate local ID for category
            final localId = _uuid.v4();

            // Create local category
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

            // Save to local SQLite
            await LocalDatabaseService.insertCategory(localCategory);
            debugPrint('Category saved to local database: $localId');

            // Try to sync to Firestore
            try {
              final docRef = await FirebaseFirestore.instance
                  .collection('categories')
                  .add({
                ...category.toFirestore(),
                'userId': userId,
              });

              final syncedCategory = localCategory.copyWith(
                firebaseId: docRef.id,
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateCategory(syncedCategory);
              debugPrint('Category synced to Firestore: ${docRef.id}');
            } catch (e) {
              debugPrint('Firestore sync failed: $e');
            }

            // Reload categories
            await _loadData();

            if (mounted) {
              // Find the newly created category
              final newCategory = _categories.firstWhere(
                (c) => c.name == category.name,
                orElse: () => category,
              );

              // Show product form with the new category pre-selected
              Navigator.pop(dialogContext);
              _showAddProductDialogWithCategory(
                  context, authProvider, newCategory);
            }
          } catch (e) {
            debugPrint('Error adding category: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Error: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  // Method to show product dialog with pre-selected category
  void _showAddProductDialogWithCategory(BuildContext context,
      AuthProvider authProvider, Category selectedCategory) {
    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _ProductFormSheet(
        categories: _categories,
        preselectedCategoryId: selectedCategory.id,
        preselectedCategoryName: selectedCategory.name,
        onSave: (product) async {
          try {
            final userId = authProvider.userModel?.id;
            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Error: Please log in again to save product'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Generate local ID
            final localId = _uuid.v4();

            // Create local product first (offline-first)
            final localProduct = LocalProduct(
              id: localId,
              name: product.name,
              description: product.description,
              categoryId: product.categoryId,
              categoryName: product.categoryName,
              unit: product.unit,
              sellingPrice: product.sellingPrice,
              costPrice: product.costPrice,
              stockQuantity: product.stockQuantity,
              lowStockThreshold: product.lowStockThreshold,
              imageUrl: product.imageUrl,
              userId: userId,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: null,
            );

            // Save to local SQLite first
            await LocalDatabaseService.insertProduct(localProduct);
            debugPrint('Product saved to local database: $localId');

            // Try to sync with Firestore in background
            bool firebaseSynced = false;
            try {
              // Create a product with userId for Firestore
              final firestoreProduct = product.copyWith(
                userId: userId,
                createdAt: DateTime.now(),
              );

              final docRef = await FirebaseFirestore.instance
                  .collection('products')
                  .add(firestoreProduct.toFirestore());

              // Update local record with Firebase ID using copyWith
              final syncedProduct = localProduct.copyWith(
                firebaseId: docRef.id,
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateProduct(syncedProduct);
              debugPrint('Product synced to Firestore: ${docRef.id}');
              firebaseSynced = true;
            } catch (e) {
              debugPrint('Firestore sync failed (product will sync later): $e');
            }

            await _loadData();
            if (mounted) {
              Navigator.pop(dialogContext);
              // Show appropriate message based on sync status
              if (firebaseSynced) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'Product added successfully and synced to cloud'),
                      backgroundColor: Colors.green),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content:
                          Text('Product saved locally. Will sync when online.'),
                      backgroundColor: Colors.orange),
                );
              }
            }
          } catch (e) {
            debugPrint('Error adding product: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error adding product: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showProductDetails(BuildContext context, Product product) {
    final authProvider = context.read<AuthProvider>();

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _ProductDetailsSheet(
        product: product,
        onEdit: () {
          Navigator.pop(dialogContext);
          _showEditProductDialog(context, product);
        },
        onDelete: () async {
          try {
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
            await LocalDatabaseService.deleteProduct(product.id);
            debugPrint('Product marked as deleted locally: ${product.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(product.id)
                  .update({
                'isActive': false,
                'updatedAt': DateTime.now(),
              });
              debugPrint('Product deleted in Firestore: ${product.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (delete will sync later): $e');
            }

            await _loadData();
            if (mounted) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Product deleted successfully'),
                    backgroundColor: Colors.orange),
              );
            }
          } catch (e) {
            debugPrint('Error deleting product: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error deleting product: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }

  void _showEditProductDialog(BuildContext context, Product product) {
    final authProvider = context.read<AuthProvider>();

    showCupertinoModalPopup(
      context: context,
      builder: (dialogContext) => _ProductFormSheet(
        product: product,
        categories: _categories,
        onSave: (updatedProduct) async {
          try {
            final userId = authProvider.userModel?.id;

            if (userId == null || userId.isEmpty) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Error: Please log in again to update product'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
              return;
            }

            // Update local SQLite first (offline-first)
            final localProduct = LocalProduct(
              id: product.id,
              name: updatedProduct.name,
              description: updatedProduct.description,
              categoryId: updatedProduct.categoryId,
              categoryName: updatedProduct.categoryName,
              unit: updatedProduct.unit,
              sellingPrice: updatedProduct.sellingPrice,
              costPrice: updatedProduct.costPrice,
              stockQuantity: updatedProduct.stockQuantity,
              lowStockThreshold: updatedProduct.lowStockThreshold,
              imageUrl: updatedProduct.imageUrl,
              userId: userId,
              createdAt: product.createdAt,
              updatedAt: DateTime.now(),
              isActive: true,
              syncStatus: SyncStatus.pending,
              firebaseId: product.id,
            );
            await LocalDatabaseService.updateProduct(localProduct);
            debugPrint('Product updated locally: ${product.id}');

            // Try to sync with Firestore
            try {
              await FirebaseFirestore.instance
                  .collection('products')
                  .doc(product.id)
                  .update({
                ...updatedProduct.toFirestore(),
                'updatedAt': DateTime.now(),
              });

              // Mark as synced using copyWith
              final syncedProduct = localProduct.copyWith(
                syncStatus: SyncStatus.synced,
              );
              await LocalDatabaseService.updateProduct(syncedProduct);
              debugPrint('Product updated in Firestore: ${product.id}');
            } catch (e) {
              debugPrint('Firestore sync failed (update will sync later): $e');
            }

            await _loadData();
            if (mounted) {
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Product updated successfully'),
                    backgroundColor: Colors.green),
              );
            }
          } catch (e) {
            debugPrint('Error updating product: $e');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text('Error updating product: $e'),
                    backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = product.isLowStock;
    final warningColor = isDarkMode ? IOSDarkColors.warning : IOSColors.warning;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode
              ? IOSDarkColors.cardBackground
              : IOSColors.systemBackground,
          borderRadius: BorderRadius.circular(IOSBorderRadius.large),
          border: Border.all(
            color: isLowStock
                ? warningColor.withOpacity(0.5)
                : (isDarkMode
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
        child: Padding(
          padding: const EdgeInsets.all(IOSSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product icon/image placeholder
              Container(
                height: 80,
                decoration: BoxDecoration(
                  color: (isDarkMode
                          ? IOSDarkColors.secondarySystemBackground
                          : IOSColors.secondarySystemBackground)
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                ),
                child: Center(
                  child: Icon(
                    CupertinoIcons.cube_box_fill,
                    size: 40,
                    color:
                        isDarkMode ? IOSDarkColors.primary : IOSColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: IOSSpacing.sm),
              // Product name
              Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                  color: labelPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              // Category
              Text(
                product.categoryName,
                style: const TextStyle(
                  fontSize: 12,
                  color: IOSColors.labelSecondary,
                ),
              ),
              const Spacer(),
              // Price and stock
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product.formattedPrice,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDarkMode
                          ? IOSDarkColors.primary
                          : IOSColors.primary,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLowStock
                          ? warningColor.withOpacity(0.1)
                          : (isDarkMode
                              ? IOSDarkColors.secondarySystemBackground
                              : IOSColors.secondarySystemBackground),
                      borderRadius:
                          BorderRadius.circular(IOSBorderRadius.small),
                      border: Border.all(
                        color: isLowStock ? warningColor : Colors.transparent,
                      ),
                    ),
                    child: Text(
                      '${product.stockQuantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isLowStock
                            ? warningColor
                            : IOSColors.labelSecondary,
                      ),
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
}

class _ProductFormSheet extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final Function(Product) onSave;
  final String? preselectedCategoryId;
  final String? preselectedCategoryName;

  const _ProductFormSheet(
      {this.product,
      required this.categories,
      required this.onSave,
      this.preselectedCategoryId,
      this.preselectedCategoryName});

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _stockController;
  late TextEditingController _thresholdController;
  late FixedExtentScrollController _categoryScrollController;
  late FixedExtentScrollController _unitScrollController;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  QuantityUnit _selectedUnit = QuantityUnit.pcs;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _priceController = TextEditingController(
      text: widget.product?.sellingPrice.toStringAsFixed(0) ?? '',
    );
    _costController = TextEditingController(
      text: widget.product?.costPrice.toStringAsFixed(0) ?? '',
    );
    _stockController = TextEditingController(
      text: widget.product?.stockQuantity.toString() ?? '0',
    );
    _thresholdController = TextEditingController(
      text: widget.product?.lowStockThreshold.toString() ?? '10',
    );
    _selectedCategoryId =
        widget.product?.categoryId ?? widget.preselectedCategoryId;
    _selectedCategoryName =
        widget.product?.categoryName ?? widget.preselectedCategoryName;
    if (widget.product != null) {
      _selectedUnit = widget.product!.unit;
    }

    // Initialize scroll controllers for pickers
    _categoryScrollController = FixedExtentScrollController();
    _unitScrollController = FixedExtentScrollController();

    // Set initial scroll position for category picker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_selectedCategoryId != null) {
        final categoryIndex =
            widget.categories.indexWhere((c) => c.id == _selectedCategoryId);
        if (categoryIndex > 0) {
          _categoryScrollController.jumpTo(categoryIndex.toDouble());
        }
      }
      // Set initial scroll position for unit picker
      final unitIndex = QuantityUnit.values.indexOf(_selectedUnit);
      if (unitIndex > 0) {
        _unitScrollController.jumpTo(unitIndex.toDouble());
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _stockController.dispose();
    _thresholdController.dispose();
    _categoryScrollController.dispose();
    _unitScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
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
                Text(
                  widget.product == null ? 'Add Product' : 'Edit Product',
                  style: IOSTextStyles.headline,
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: _saveProduct,
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
                _buildLabel('Product Name'),
                IOSTextField(
                  controller: _nameController,
                  placeholder: 'Enter product name',
                ),
                const SizedBox(height: IOSSpacing.md),
                // Category
                _buildLabel('Category'),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? IOSDarkColors.secondarySystemBackground
                        : IOSColors.secondarySystemBackground,
                    borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                    border: Border.all(
                      color: isDarkMode
                          ? IOSDarkColors.labelQuaternary
                          : IOSColors.labelQuaternary,
                    ),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(IOSSpacing.md),
                    onPressed: () => _showCategoryPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedCategoryName ?? 'Select category',
                          style: TextStyle(
                            color: _selectedCategoryName != null
                                ? (isDarkMode
                                    ? IOSDarkColors.labelPrimary
                                    : IOSColors.labelPrimary)
                                : (isDarkMode
                                    ? IOSDarkColors.labelTertiary
                                    : IOSColors.labelTertiary),
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 16,
                          color: isDarkMode
                              ? IOSDarkColors.labelSecondary
                              : IOSColors.labelSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Unit
                _buildLabel('Unit'),
                Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? IOSDarkColors.secondarySystemBackground
                        : IOSColors.secondarySystemBackground,
                    borderRadius: BorderRadius.circular(IOSBorderRadius.medium),
                    border: Border.all(
                      color: isDarkMode
                          ? IOSDarkColors.labelQuaternary
                          : IOSColors.labelQuaternary,
                    ),
                  ),
                  child: CupertinoButton(
                    padding: const EdgeInsets.all(IOSSpacing.md),
                    onPressed: () => _showUnitPicker(context),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedUnit.name,
                          style: TextStyle(
                            color: isDarkMode
                                ? IOSDarkColors.labelPrimary
                                : IOSColors.labelPrimary,
                          ),
                        ),
                        Icon(
                          CupertinoIcons.chevron_down,
                          size: 16,
                          color: isDarkMode
                              ? IOSDarkColors.labelSecondary
                              : IOSColors.labelSecondary,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: IOSSpacing.md),
                // Prices
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Selling Price'),
                          IOSTextField(
                            controller: _priceController,
                            placeholder: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: IOSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Cost Price'),
                          IOSTextField(
                            controller: _costController,
                            placeholder: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: IOSSpacing.md),
                // Stock
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Initial Stock'),
                          IOSTextField(
                            controller: _stockController,
                            placeholder: '0',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: IOSSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildLabel('Low Stock Alert'),
                          IOSTextField(
                            controller: _thresholdController,
                            placeholder: '10',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                  ],
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

  void _showCategoryPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: _categoryScrollController,
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedCategoryId = widget.categories[index].id;
                    _selectedCategoryName = widget.categories[index].name;
                  });
                },
                children: widget.categories
                    .map((c) => Center(child: Text(c.name)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUnitPicker(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => Container(
        height: 250,
        color: CupertinoColors.systemBackground.resolveFrom(context),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CupertinoButton(
                    child: const Text('Cancel'),
                    onPressed: () => Navigator.pop(context)),
                CupertinoButton(
                    child: const Text('Done'),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            Expanded(
              child: CupertinoPicker(
                scrollController: _unitScrollController,
                itemExtent: 32,
                onSelectedItemChanged: (index) {
                  setState(() {
                    _selectedUnit = QuantityUnit.values[index];
                  });
                },
                children: QuantityUnit.values
                    .map((u) => Center(child: Text(u.name)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter product name'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: Colors.red),
      );
      return;
    }

    // Validate price fields
    final sellingPrice = double.tryParse(_priceController.text);
    final costPrice = double.tryParse(_costController.text);
    final stockQuantity = int.tryParse(_stockController.text);
    final lowStockThreshold = int.tryParse(_thresholdController.text);

    if (sellingPrice == null || sellingPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid selling price'),
            backgroundColor: Colors.red),
      );
      return;
    }

    if (costPrice == null || costPrice < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid cost price'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.userModel?.id ?? '';

    // Validate userId
    if (userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Error: Please log in to save products'),
            backgroundColor: Colors.red),
      );
      return;
    }

    final product = Product(
      id: widget.product?.id ?? '',
      name: _nameController.text,
      description:
          _nameController.text.isNotEmpty ? _nameController.text : null,
      categoryId: _selectedCategoryId!,
      categoryName: _selectedCategoryName ?? '',
      unit: _selectedUnit,
      sellingPrice: sellingPrice,
      costPrice: costPrice,
      stockQuantity: stockQuantity ?? 0,
      lowStockThreshold: lowStockThreshold ?? 10,
      imageUrl: null, // Image URL is optional
      userId: userId,
      createdAt: widget.product?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
    );

    widget.onSave(product);
  }
}

class _ProductDetailsSheet extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductDetailsSheet({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isLowStock = product.isLowStock;
    final warningColor = isDarkMode ? IOSDarkColors.warning : IOSColors.warning;
    final primaryColor = isDarkMode ? IOSDarkColors.primary : IOSColors.primary;
    final labelPrimary =
        isDarkMode ? IOSDarkColors.labelPrimary : IOSColors.labelPrimary;
    final labelSecondary =
        isDarkMode ? IOSDarkColors.labelSecondary : IOSColors.labelSecondary;
    final cardBg =
        isDarkMode ? IOSDarkColors.cardBackground : IOSColors.systemBackground;

    return Container(
      height: MediaQuery.of(context).size.height * 0.58,
      decoration: BoxDecoration(
        color: isDarkMode
            ? IOSDarkColors.systemBackground
            : IOSColors.systemBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Modern handle bar with gradient
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
          // Modern header with gradient background
          Container(
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [
                        IOSDarkColors.primary.withOpacity(0.15),
                        IOSDarkColors.systemBackground
                      ]
                    : [
                        IOSColors.primary.withOpacity(0.1),
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
                // Product icon with gradient background
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
                  child: const Icon(
                    CupertinoIcons.cube_box_fill,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: labelPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          product.categoryName,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Low stock warning
          if (isLowStock)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: warningColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: warningColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(CupertinoIcons.exclamationmark_triangle_fill,
                      color: warningColor, size: 20),
                  const SizedBox(width: 10),
                  Text(
                    'Low stock! Only ${product.stockQuantity} left',
                    style: TextStyle(
                      color: warningColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          // Details in modern cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Price and Stock Card
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Selling Price',
                              product.formattedPrice,
                              CupertinoIcons.tag_fill,
                              primaryColor,
                              labelPrimary,
                              labelSecondary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: isDarkMode
                                ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                                : IOSColors.labelQuaternary.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Cost Price',
                              product.formattedCost,
                              CupertinoIcons.cart_fill,
                              labelSecondary,
                              labelPrimary,
                              labelSecondary,
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
                      Row(
                        children: [
                          Expanded(
                            child: _buildDetailItem(
                              'Current Stock',
                              '${product.stockQuantity} ${product.unitDisplay}',
                              CupertinoIcons.cube_box,
                              isLowStock ? warningColor : primaryColor,
                              labelPrimary,
                              labelSecondary,
                            ),
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: isDarkMode
                                ? IOSDarkColors.labelQuaternary.withOpacity(0.2)
                                : IOSColors.labelQuaternary.withOpacity(0.2),
                          ),
                          Expanded(
                            child: _buildDetailItem(
                              'Profit Margin',
                              'UGX ${product.profitMargin.toStringAsFixed(0)}',
                              CupertinoIcons.graph_circle_fill,
                              Colors.green,
                              labelPrimary,
                              labelSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Low Stock Threshold
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            CupertinoIcons.bell_fill,
                            size: 18,
                            color: IOSColors.labelSecondary,
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Low Stock Alert Threshold',
                            style: TextStyle(
                              fontSize: 14,
                              color: IOSColors.labelSecondary,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${product.lowStockThreshold}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: labelPrimary,
                        ),
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

  Widget _buildDetailItem(
    String label,
    String value,
    IconData icon,
    Color iconColor,
    Color labelPrimary,
    Color labelSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: labelSecondary),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  color: IOSColors.labelSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: labelPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// Simple category form for creating a category from product screen
class _CategoryFormSheetForProduct extends StatefulWidget {
  final Function(Category) onSave;

  const _CategoryFormSheetForProduct({required this.onSave});

  @override
  State<_CategoryFormSheetForProduct> createState() =>
      _CategoryFormSheetForProductState();
}

class _CategoryFormSheetForProductState
    extends State<_CategoryFormSheetForProduct> {
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
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
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
                const Text('Add Category', style: IOSTextStyles.headline),
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
      id: '',
      name: _nameController.text,
      description: _descriptionController.text.isEmpty
          ? null
          : _descriptionController.text,
      colorValue: _colorOptions[_selectedColorIndex],
      userId: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    widget.onSave(category);
  }
}
