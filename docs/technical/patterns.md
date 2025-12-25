# VIMz Architecture Patterns

## MVVM Architecture Pattern

### Overview
VIMz follows a strict Model-View-ViewModel (MVVM) architecture to ensure separation of concerns, testability, and maintainability.

### Layer Structure

#### Models Layer (`/lib/models/`)
- **Data Models**: Represent business entities and data structures
- **JSON Serialization**: Using `json_serializable` for API communication
- **Validation**: Input validation and business rules
- **Immutable Objects**: All models are immutable for predictability

```dart
// Example Model
@JsonSerializable()
class ImageProof {
  final String id;
  final String imageHash;
  final String proof;
  final DateTime createdAt;
  
  const ImageProof({
    required this.id,
    required this.imageHash,
    required this.proof,
    required this.createdAt,
  });
  
  factory ImageProof.fromJson(Map<String, dynamic> json) =>
      _$ImageProofFromJson(json);
  
  Map<String, dynamic> toJson() => _$ImageProofToJson(this);
}
```

#### ViewModels Layer (`/lib/viewmodels/`)
- **Business Logic**: All business logic resides in ViewModels
- **State Management**: Using `ChangeNotifier` for reactive state
- **Service Coordination**: Coordinate between multiple services
- **Data Transformation**: Convert models to view-friendly formats

```dart
// Example ViewModel
class ImageProofViewModel extends ChangeNotifier {
  final ImageProofService _proofService;
  final ImageProcessingService _processingService;
  
  List<ImageProof> _proofs = [];
  bool _isLoading = false;
  String? _error;
  
  List<ImageProof> get proofs => _proofs;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  Future<void> generateProof(Uint8List imageData) async {
    _setLoading(true);
    try {
      final proof = await _proofService.generateProof(imageData);
      _proofs.add(proof);
      notifyListeners();
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
```

#### Views Layer (`/lib/views/`)
- **UI Components**: Pure UI logic, no business logic
- **State Consumption**: Consume ViewModels via Provider
- **User Interactions**: Handle user input and delegate to ViewModels
- **Responsive Design**: Adaptive layouts for different screen sizes

```dart
// Example View
class ImageProofView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => getIt<ImageProofViewModel>(),
      child: Consumer<ImageProofViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const CircularProgressIndicator();
          }
          
          return ListView.builder(
            itemCount: viewModel.proofs.length,
            itemBuilder: (context, index) {
              final proof = viewModel.proofs[index];
              return ProofCard(proof: proof);
            },
          );
        },
      ),
    );
  }
}
```

## Dependency Injection Pattern

### Service Locator Setup
Using `GetIt` for dependency injection with clear separation and lifetime management.

```dart
// /lib/core/services/service_initializer.dart
class ServiceInitializer {
  static Future<void> initialize() async {
    // Singletons
    getIt.registerSingleton<DatabaseService>(DatabaseService());
    getIt.registerSingleton<CryptoService>(CryptoService());
    getIt.registerSingleton<StorageService>(StorageService());
    
    // Factory services
    getIt.registerFactory<ImageProofService>(
      () => ImageProofService(
        cryptoService: getIt<CryptoService>(),
        storageService: getIt<StorageService>(),
      ),
    );
    
    // ViewModels
    getIt.registerFactory<ImageProofViewModel>(
      () => ImageProofViewModel(
        proofService: getIt<ImageProofService>(),
        processingService: getIt<ImageProcessingService>(),
      ),
    );
  }
}
```

### Service Registration Rules
- **Singleton Services**: Database, crypto, storage (shared state)
- **Factory Services**: ViewModels, business logic (per instance)
- **Lazy Registration**: Heavy services registered lazily
- **Interface Segregation**: Services depend on abstractions

## State Management Pattern

### Provider + ChangeNotifier
Using Provider pattern with ChangeNotifier for reactive state management.

```dart
// Base ViewModel Pattern
abstract class BaseViewModel extends ChangeNotifier {
  bool _isLoading = false;
  String? _error;
  
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }
  
  void _setError(String? error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }
  
  void clearError() {
    _setError(null);
  }
}
```

### State Flow Pattern
- **Unidirectional Data Flow**: View → ViewModel → Service → Model
- **Reactive Updates**: UI automatically updates on state changes
- **Error Handling**: Centralized error state management
- **Loading States**: Consistent loading indicators

## Error Handling Pattern

### Result Type Pattern
Using Result type for error handling instead of exceptions.

```dart
// Result Type
sealed class Result<T> {
  const Result();
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String error;
  const Failure(this.error);
}

// Usage in Services
Future<Result<ImageProof>> generateProof(Uint8List imageData) async {
  try {
    final proof = await _createProof(imageData);
    return Success(proof);
  } catch (e) {
    return Failure('Proof generation failed: ${e.toString()}');
  }
}
```

### Error Reporting Pattern
Centralized error reporting with context and user-friendly messages.

```dart
// Error Reporting Service
class ErrorReportingService {
  static void reportError(
    Exception error,
    StackTrace stackTrace, {
    Map<String, dynamic>? context,
  }) {
    // Log to console in debug
    debugPrint('Error: $error');
    debugPrint('Stack: $stackTrace');
    
    // Send to crash reporting in production
    if (!kDebugMode) {
      // Firebase Crashlytics or similar
    }
  }
}
```

## Repository Pattern

### Data Access Abstraction
Repository pattern abstracts data sources and provides clean API.

```dart
// Abstract Repository
abstract class ImageProofRepository {
  Future<List<ImageProof>> getAllProofs();
  Future<ImageProof?> getProofById(String id);
  Future<void> saveProof(ImageProof proof);
  Future<void> deleteProof(String id);
}

// Concrete Implementation
class ImageProofRepositoryImpl implements ImageProofRepository {
  final DatabaseService _database;
  final NetworkService _network;
  
  ImageProofRepositoryImpl(this._database, this._network);
  
  @override
  Future<List<ImageProof>> getAllProofs() async {
    try {
      return await _database.getAllProofs();
    } catch (e) {
      // Fallback to network if database fails
      return await _network.getAllProofs();
    }
  }
}
```

## Service Pattern

### Business Logic Encapsulation
Services encapsulate business logic and coordinate between repositories.

```dart
// Service Interface
abstract class ImageProofService {
  Future<Result<ImageProof>> generateProof(Uint8List imageData);
  Future<Result<bool>> verifyProof(ImageProof proof);
  Future<Result<List<ImageProof>>> getProofHistory();
}

// Service Implementation
class ImageProofServiceImpl implements ImageProofService {
  final ImageProofRepository _repository;
  final CryptoService _crypto;
  final ImageProcessingService _processing;
  
  ImageProofServiceImpl(
    this._repository,
    this._crypto,
    this._processing,
  );
  
  @override
  Future<Result<ImageProof>> generateProof(Uint8List imageData) async {
    try {
      // Process image
      final processedImage = await _processing.processImage(imageData);
      
      // Generate cryptographic proof
      final proofData = await _crypto.generateProof(processedImage);
      
      // Create proof object
      final proof = ImageProof(
        id: const Uuid().v4(),
        imageHash: _crypto.hashImage(imageData),
        proof: proofData,
        createdAt: DateTime.now(),
      );
      
      // Save to repository
      await _repository.saveProof(proof);
      
      return Success(proof);
    } catch (e) {
      return Failure('Failed to generate proof: ${e.toString()}');
    }
  }
}
```

## Navigation Pattern

### Go Router Configuration
Using Go Router for declarative navigation with deep linking support.

```dart
// /lib/core/navigation/app_router.dart
final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeView(),
    ),
    GoRoute(
      path: '/proof/:id',
      builder: (context, state) {
        final proofId = state.pathParameters['id']!;
        return ProofDetailView(proofId: proofId);
      },
    ),
  ],
  errorBuilder: (context, state) => const ErrorView(),
);
```

## Testing Patterns

### Unit Testing
Test ViewModels and services with mocked dependencies.

```dart
// ViewModel Test Example
void main() {
  group('ImageProofViewModel', () {
    late ImageProofViewModel viewModel;
    late MockImageProofService mockService;
    
    setUp(() {
      mockService = MockImageProofService();
      viewModel = ImageProofViewModel(mockService);
    });
    
    test('should generate proof successfully', () async {
      // Arrange
      final mockProof = createMockProof();
      when(mockService.generateProof(any))
          .thenAnswer((_) async => Success(mockProof));
      
      // Act
      await viewModel.generateProof(mockImageData);
      
      // Assert
      expect(viewModel.proofs, contains(mockProof));
      expect(viewModel.error, isNull);
    });
  });
}
```

### Widget Testing
Test UI components with test utilities.

```dart
// Widget Test Example
void main() {
  testWidgets('ProofCard displays proof information', (tester) async {
    // Arrange
    final proof = createMockProof();
    
    // Act
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProofCard(proof: proof),
        ),
      ),
    );
    
    // Assert
    expect(find.text(proof.id), findsOneWidget);
    expect(find.byIcon(Icons.verified), findsOneWidget);
  });
}
```

## Performance Patterns

### Lazy Loading
Load resources only when needed to improve startup performance.

```dart
// Lazy Service Initialization
class LazyService<T> {
  T? _instance;
  final T Function() _factory;
  
  LazyService(this._factory);
  
  T get instance {
    return _instance ??= _factory();
  }
}
```

### Memory Management
Proper disposal of resources and memory optimization.

```dart
// Resource Management
class ImageProcessor {
  Uint8List? _cachedData;
  
  Future<void> processImage(Uint8List data) async {
    try {
      _cachedData = data;
      // Processing logic
    } finally {
      _cachedData = null;
    }
  }
  
  void dispose() {
    _cachedData = null;
  }
}
```

## Security Patterns

### Secure Storage
Sensitive data stored securely using platform-specific secure storage.

```dart
// Secure Storage Service
class SecureStorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  
  Future<void> storePrivateKey(String key, String value) async {
    await _storage.write(key: key, value: value);
  }
  
  Future<String?> getPrivateKey(String key) async {
    return await _storage.read(key: key);
  }
}
```

### Cryptographic Operations
Centralized cryptographic service with secure implementations.

```dart
// Crypto Service
class CryptoService {
  Future<String> generateProof(Uint8List data) async {
    // Implement secure proof generation
    // Use platform-specific secure implementations
  }
  
  Future<bool> verifyProof(String proof, Uint8List data) async {
    // Implement secure verification
  }
}
```
