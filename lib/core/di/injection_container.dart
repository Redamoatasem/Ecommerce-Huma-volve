import '../network/api_client.dart';
import '../storage/token_storage.dart';
import '../../features/auth/data/datasources/auth_local_data_source.dart';
import '../../features/auth/data/datasources/auth_remote_data_source.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/check_session_usecase.dart';
import '../../features/auth/domain/usecases/get_profile_usecase.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/home/data/datasources/home_remote_data_source.dart';
import '../../features/home/data/repositories/home_repository_impl.dart';
import '../../features/home/domain/repositories/home_repository.dart';
import '../../features/home/domain/usecases/get_categories_usecase.dart';
import '../../features/home/domain/usecases/get_product_by_id_usecase.dart';
import '../../features/home/domain/usecases/get_products_usecase.dart';
import '../../features/home/cubit/home_cubit.dart';
import '../../features/details/cubit/product_details_cubit.dart';

/// Lightweight dependency composition locator for the application.
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  // Core
  late final ApiClient apiClient = ApiClient();
  late final TokenStorage tokenStorage = SecureTokenStorage();

  // Auth - Data Sources
  late final AuthRemoteDataSource authRemoteDataSource =
      AuthRemoteDataSourceImpl(apiClient: apiClient);
  late final AuthLocalDataSource authLocalDataSource = AuthLocalDataSourceImpl(
    tokenStorage: tokenStorage,
  );

  // Auth - Repository
  late final AuthRepository authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemoteDataSource,
    localDataSource: authLocalDataSource,
  );

  // Auth - Use Cases
  late final LoginUseCase loginUseCase = LoginUseCase(authRepository);
  late final RegisterUseCase registerUseCase = RegisterUseCase(authRepository);
  late final GetProfileUseCase getProfileUseCase = GetProfileUseCase(
    authRepository,
  );
  late final CheckSessionUseCase checkSessionUseCase = CheckSessionUseCase(
    authRepository,
  );
  late final LogoutUseCase logoutUseCase = LogoutUseCase(authRepository);

  // Home - Data Source & Repository
  late final HomeRemoteDataSource homeRemoteDataSource =
      HomeRemoteDataSourceImpl(apiClient: apiClient);
  late final HomeRepository homeRepository = HomeRepositoryImpl(
    remoteDataSource: homeRemoteDataSource,
  );

  // Home - Use Cases
  late final GetCategoriesUseCase getCategoriesUseCase = GetCategoriesUseCase(
    homeRepository,
  );
  late final GetProductsUseCase getProductsUseCase = GetProductsUseCase(
    homeRepository,
  );
  late final GetProductByIdUseCase getProductByIdUseCase =
      GetProductByIdUseCase(homeRepository);

  // Home - Cubit factory
  HomeCubit createHomeCubit() => HomeCubit(
    getCategoriesUseCase: getCategoriesUseCase,
    getProductsUseCase: getProductsUseCase,
  );

  // Product Details - Cubit factory
  ProductDetailsCubit createProductDetailsCubit({dynamic initialProduct}) =>
      ProductDetailsCubit(
        getProductByIdUseCase: getProductByIdUseCase,
        initialProduct: initialProduct,
      );
}

final sl = ServiceLocator();
