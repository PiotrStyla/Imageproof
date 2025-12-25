import 'package:get_it/get_it.dart';
import '../viewmodels/image_proof_viewmodel.dart';
import '../crypto/crypto_service.dart';
import '../image_processing/image_processing_service.dart';
import '../storage/storage_service.dart';
import '../navigation/app_router.dart';
import '../error/error_reporting_service.dart';
import 'image_proof_service.dart';

/// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Service initializer for dependency injection
class ServiceInitializer {
  /// Initialize all services and register dependencies
  static Future<void> initialize() async {
    // Register singleton services
    _registerSingletons();
    
    // Register factory services
    _registerFactories();
    
    // Register ViewModels
    _registerViewModels();
    
    // Initialize services that require async setup
    await _initializeAsyncServices();
  }
  
  /// Register singleton services (shared state)
  static void _registerSingletons() {
    // Core services
    getIt.registerSingleton<StorageService>(StorageService());
    getIt.registerSingleton<CryptoService>(CryptoService());
    getIt.registerSingleton<ErrorReportingService>(ErrorReportingService());
    
    // Navigation
    getIt.registerSingleton<AppRouter>(AppRouter());
  }
  
  /// Register factory services (new instances each time)
  static void _registerFactories() {
    // Image processing service
    getIt.registerFactory<ImageProcessingService>(
      () => ImageProcessingService(
        storageService: getIt<StorageService>(),
      ),
    );
    
    // Image proof service
    getIt.registerFactory<ImageProofService>(
      () => ImageProofService(
        cryptoService: getIt<CryptoService>(),
        storageService: getIt<StorageService>(),
        imageProcessingService: getIt<ImageProcessingService>(),
      ),
    );
  }
  
  /// Register ViewModels
  static void _registerViewModels() {
    getIt.registerFactory<ImageProofViewModel>(
      () => ImageProofViewModel(
        proofService: getIt<ImageProofService>(),
        imageProcessingService: getIt<ImageProcessingService>(),
      ),
    );
  }
  
  /// Initialize async services
  static Future<void> _initializeAsyncServices() async {
    // Initialize storage
    await getIt<StorageService>().initialize();
    
    // Initialize crypto service
    await getIt<CryptoService>().initialize();
    
    // Initialize error reporting
    await getIt<ErrorReportingService>().initialize();
  }
  
  /// Cleanup services (call when app is closing)
  static Future<void> cleanup() async {
    await getIt<StorageService>().cleanup();
    await getIt<CryptoService>().cleanup();
    
    getIt.reset();
  }
}
