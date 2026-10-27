import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/di/injection_container.dart';
import '../../../core/dummy_data.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../main_navigation/screens/main_navigation_screen.dart';
import '../cubit/product_details_cubit.dart';
import '../cubit/product_details_state.dart';
import '../widgets/color_selector.dart';
import '../widgets/size_selector.dart';

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;
  final int? productId;
  final ProductDetailsCubit? cubit;
  final String? initialErrorMessage;

  const ProductDetailsScreen({
    super.key,
    this.product,
    this.productId,
    this.cubit,
    this.initialErrorMessage,
  });

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  late final ProductDetailsCubit _cubit;
  Color? _selectedColor;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    _cubit = widget.cubit ?? sl.createProductDetailsCubit();

    if (widget.initialErrorMessage != null) {
      _cubit.setError(widget.initialErrorMessage!);
    } else if (widget.product != null) {
      _cubit.setProduct(widget.product);
      _initOptions(widget.product);
    } else if (widget.productId != null) {
      _cubit.loadProduct(widget.productId!);
    } else {
      _cubit.setError('No product or product ID provided.');
    }
  }

  void _initOptions(dynamic p) {
    if (p is Product && p.colors.isNotEmpty) {
      _selectedColor = p.colors.first;
    } else {
      _selectedColor = null;
    }

    if (p.sizes != null && p.sizes.isNotEmpty) {
      _selectedSize = p.sizes.first;
    } else {
      _selectedSize = null;
    }
  }

  @override
  void dispose() {
    if (widget.cubit == null) {
      _cubit.close();
    }
    super.dispose();
  }

  void _handleBack(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocConsumer<ProductDetailsCubit, ProductDetailsState>(
        listener: (context, state) {
          if (state.isSuccess &&
              _selectedColor == null &&
              _selectedSize == null) {
            _initOptions(state.product);
          }
        },
        builder: (context, state) {
          if (state.isLoading) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  onPressed: () => _handleBack(context),
                ),
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primary),
                    SizedBox(height: 16),
                    Text(
                      'Loading product details...',
                      style: TextStyle(color: Colors.grey, fontSize: 16),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state.isFailure) {
            return Scaffold(
              backgroundColor: AppTheme.background,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new,
                      size: 16,
                      color: AppTheme.primary,
                    ),
                  ),
                  onPressed: () => _handleBack(context),
                ),
              ),
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.error_outline,
                          size: 56,
                          color: AppTheme.error,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Unable to load product',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(fontSize: 22),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        state.errorMessage ??
                            'The requested product could not be found.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (widget.productId != null) ...[
                        PrimaryButton(
                          text: 'Retry',
                          onPressed: () =>
                              _cubit.loadProduct(widget.productId!),
                        ),
                        const SizedBox(height: 12),
                      ],
                      OutlinedButton(
                        onPressed: () => _handleBack(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Back to Home',
                          style: TextStyle(
                            color: AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          final dynamic product = state.product ?? widget.product;
          if (product == null) {
            return const SizedBox.shrink();
          }

          final String productId = product.id.toString();
          final String productName = product.name;
          final double productPrice = product.price is num
              ? (product.price as num).toDouble()
              : 0.0;
          final String productDescription = product.description.toString();
          final String productImageUrl = product.imageUrl.toString();
          final bool hasSizes =
              product.sizes != null && product.sizes.isNotEmpty;

          return Scaffold(
            backgroundColor: AppTheme.background,
            body: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 400,
                  pinned: true,
                  backgroundColor: AppTheme.background,
                  leading: IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new, size: 16),
                    ),
                    onPressed: () => _handleBack(context),
                  ),
                  actions: [
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: Hero(
                      tag: 'product-$productId',
                      child: Image.network(
                        productImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.image_not_supported_outlined,
                              color: Colors.grey,
                              size: 64,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                productName,
                                style: Theme.of(context).textTheme.displayLarge
                                    ?.copyWith(fontSize: 24),
                              ),
                            ),
                            Text(
                              '\$${productPrice.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Description',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          productDescription,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(height: 1.6, fontSize: 16),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Select Color',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (product is Product && product.colors.isNotEmpty)
                          ColorSelector(
                            colors: product.colors,
                            selectedColor:
                                _selectedColor ?? product.colors.first,
                            onColorSelected: (color) {
                              setState(() {
                                _selectedColor = color;
                              });
                            },
                          )
                        else
                          Text(
                            'Standard color / Not specified',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        const SizedBox(height: 24),
                        Text(
                          'Select Size',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        if (hasSizes)
                          SizeSelector(
                            sizes: List<String>.from(product.sizes),
                            selectedSize: _selectedSize ?? product.sizes.first,
                            onSizeSelected: (size) {
                              setState(() {
                                _selectedSize = size;
                              });
                            },
                          )
                        else
                          Text(
                            'One size fits all',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        const SizedBox(height: 48),
                        PrimaryButton(
                          text: 'Add to Cart',
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('$productName added to cart'),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
