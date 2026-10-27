import 'package:flutter_bloc/flutter_bloc.dart';

import '../../home/domain/usecases/get_product_by_id_usecase.dart';
import 'product_details_state.dart';

class ProductDetailsCubit extends Cubit<ProductDetailsState> {
  final GetProductByIdUseCase? getProductByIdUseCase;

  ProductDetailsCubit({this.getProductByIdUseCase, dynamic initialProduct})
    : super(
        initialProduct != null
            ? ProductDetailsState.success(initialProduct)
            : ProductDetailsState.initial(),
      );

  void setProduct(dynamic product) {
    emit(ProductDetailsState.success(product));
  }

  void setError(String message) {
    emit(ProductDetailsState.failure(message));
  }

  Future<void> loadProduct(int id) async {
    if (id <= 0) {
      emit(ProductDetailsState.failure('Invalid product ID: $id'));
      return;
    }

    emit(ProductDetailsState.loading());

    try {
      if (getProductByIdUseCase == null) {
        throw Exception('GetProductByIdUseCase is not provided.');
      }
      final product = await getProductByIdUseCase!(id);
      emit(ProductDetailsState.success(product));
    } catch (e) {
      final message = e.toString().replaceFirst(RegExp(r'^Exception:\s*'), '');
      emit(ProductDetailsState.failure(message));
    }
  }
}
