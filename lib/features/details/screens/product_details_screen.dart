import 'package:flutter/material.dart';

import '../../../core/dummy_data.dart';
import '../../../core/theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../widgets/color_selector.dart';
import '../widgets/size_selector.dart';

class ProductDetailsScreen extends StatefulWidget {
  final dynamic product;

  const ProductDetailsScreen({super.key, required this.product});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  Color? _selectedColor;
  String? _selectedSize;

  @override
  void initState() {
    super.initState();
    final dynamic p = widget.product;
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
  Widget build(BuildContext context) {
    final dynamic product = widget.product;
    final String productId = product.id.toString();
    final String productName = product.name;
    final double productPrice = product.price is num
        ? (product.price as num).toDouble()
        : 0.0;
    final String productDescription = product.description.toString();
    final String productImageUrl = product.imageUrl.toString();
    final bool hasSizes = product.sizes != null && product.sizes.isNotEmpty;

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
              onPressed: () => Navigator.pop(context),
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
                borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                      selectedColor: _selectedColor ?? product.colors.first,
                      onColorSelected: (color) {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                    )
                  else
                    Text(
                      'Standard color / Not specified',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
  }
}
