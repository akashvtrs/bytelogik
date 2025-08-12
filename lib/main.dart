 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

void main() {
  runApp(const ProviderScope(child: CounterApp()));
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Counter App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AuthWrapper(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// Models
class User {
  final int? id;
  final String email;
  final String password;
  final DateTime createdAt;

  User({
    this.id,
    required this.email,
    required this.password,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'created_at': createdAt.millisecondsSinceEpoch,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt(),
      email: map['email'] ?? '',
      password: map['password'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at']),
    );
  }
}

class CounterModel {
  final int? id;
  final int userId;
  final int value;
  final DateTime updatedAt;

  CounterModel({
    this.id,
    required this.userId,
    required this.value,
    DateTime? updatedAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'value': value,
      'updated_at': updatedAt.millisecondsSinceEpoch,
    };
  }

  factory CounterModel.fromMap(Map<String, dynamic> map) {
    return CounterModel(
      id: map['id']?.toInt(),
      userId: map['user_id']?.toInt() ?? 0,
      value: map['value']?.toInt() ?? 0,
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at']),
    );
  }
}

// Database Service
class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'counter_app.db';
  static const int _databaseVersion = 1;

  static const String _usersTable = 'users';
  static const String _countersTable = 'counters';

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }

  Future<void> _createTables(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE $_usersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Create counters table
    await db.execute('''
      CREATE TABLE $_countersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        value INTEGER DEFAULT 0,
        updated_at INTEGER NOT NULL,
        FOREIGN KEY (user_id) REFERENCES $_usersTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_users_email ON $_usersTable (email)');
    await db.execute('CREATE INDEX idx_counters_user_id ON $_countersTable (user_id)');
  }

  // User operations
  Future<int> insertUser(User user) async {
    final db = await database;
    return await db.insert(_usersTable, user.toMap());
  }

  Future<User?> getUserByEmail(String email) async {
    final db = await database;
    final maps = await db.query(
      _usersTable,
      where: 'email = ?',
      whereArgs: [email],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  Future<User?> getUserById(int id) async {
    final db = await database;
    final maps = await db.query(
      _usersTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return User.fromMap(maps.first);
    }
    return null;
  }

  // Counter operations
  Future<int> insertCounter(CounterModel counter) async {
    final db = await database;
    return await db.insert(_countersTable, counter.toMap());
  }

  Future<int> updateCounter(CounterModel counter) async {
    final db = await database;
    return await db.update(
      _countersTable,
      counter.toMap(),
      where: 'user_id = ?',
      whereArgs: [counter.userId],
    );
  }

  Future<CounterModel?> getCounterByUserId(int userId) async {
    final db = await database;
    final maps = await db.query(
      _countersTable,
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    if (maps.isNotEmpty) {
      return CounterModel.fromMap(maps.first);
    }
    return null;
  }

  Future<void> createCounterForUser(int userId) async {
    final counter = CounterModel(userId: userId, value: 0);
    await insertCounter(counter);
  }
}

// Auth Service
class AuthService {
  final DatabaseService _dbService;

  AuthService(this._dbService);

  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<User> signUp(String email, String password) async {
    // Check if user already exists
    final existingUser = await _dbService.getUserByEmail(email);
    if (existingUser != null) {
      throw Exception('User with this email already exists');
    }

    // Hash password and create user
    final hashedPassword = _hashPassword(password);
    final user = User(email: email, password: hashedPassword);
    
    final userId = await _dbService.insertUser(user);
    final createdUser = user.copyWith(id: userId);
    
    // Create initial counter for user
    await _dbService.createCounterForUser(userId);
    
    return createdUser;
  }

  Future<User> signIn(String email, String password) async {
    final user = await _dbService.getUserByEmail(email);
    if (user == null) {
      throw Exception('User not found');
    }

    final hashedPassword = _hashPassword(password);
    if (user.password != hashedPassword) {
      throw Exception('Invalid password');
    }

    return user;
  }
}

extension UserCopyWith on User {
  User copyWith({
    int? id,
    String? email,
    String? password,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Counter Service
class CounterService {
  final DatabaseService _dbService;

  CounterService(this._dbService);

  Future<int> getCounterValue(int userId) async {
    final counter = await _dbService.getCounterByUserId(userId);
    return counter?.value ?? 0;
  }

  Future<void> updateCounterValue(int userId, int value) async {
    final counter = CounterModel(userId: userId, value: value);
    final existingCounter = await _dbService.getCounterByUserId(userId);
    
    if (existingCounter != null) {
      await _dbService.updateCounter(counter);
    } else {
      await _dbService.insertCounter(counter);
    }
  }
}

// Providers
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService());

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.read(databaseServiceProvider));
});

final counterServiceProvider = Provider<CounterService>((ref) {
  return CounterService(ref.read(databaseServiceProvider));
});

// Auth State
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;

  AuthState({
    this.user,
    this.isLoading = false,
    this.error,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// State Notifiers
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthService _authService;

  AuthNotifier(this._authService) : super(AuthState());

  Future<void> signUp(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.signUp(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final user = await _authService.signIn(email, password);
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void signOut() {
    state = AuthState();
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

class CounterNotifier extends StateNotifier<int> {
  final CounterService _counterService;
  final int _userId;

  CounterNotifier(this._counterService, this._userId) : super(0) {
    _loadCounter();
  }

  Future<void> _loadCounter() async {
    final value = await _counterService.getCounterValue(_userId);
    state = value;
  }

  Future<void> increment() async {
    state = state + 1;
    await _counterService.updateCounterValue(_userId, state);
  }

  Future<void> decrement() async {
    state = state - 1;
    await _counterService.updateCounterValue(_userId, state);
  }

  Future<void> reset() async {
    state = 0;
    await _counterService.updateCounterValue(_userId, state);
  }
}

// State Providers
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref.read(authServiceProvider));
});

final counterProvider = StateNotifierProvider.family<CounterNotifier, int, int>(
  (ref, userId) {
    return CounterNotifier(ref.read(counterServiceProvider), userId);
  },
);

// Widgets
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    if (authState.isAuthenticated) {
      return CounterScreen(user: authState.user!);
    }

    return const AuthScreen();
  }
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                
                // App Title
                Text(
                  'Counter App',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isSignUp ? 'Create your account' : 'Welcome back',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                const SizedBox(height: 50),
                
                // Email Field
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email',
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Password Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 30),
                
                // Error Message
                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authState.error!,
                            style: TextStyle(color: Colors.red[700]),
                          ),
                        ),
                        IconButton(
                          onPressed: () => ref.read(authProvider.notifier).clearError(),
                          icon: const Icon(Icons.close, size: 20),
                          color: Colors.red[700],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                
                // Submit Button
                ElevatedButton(
                  onPressed: authState.isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isSignUp ? 'Sign Up' : 'Sign In',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                
                const SizedBox(height: 24),
                
                // Switch between Sign In/Sign Up
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isSignUp 
                          ? 'Already have an account? ' 
                          : "Don't have an account? ",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSignUp = !_isSignUp;
                        });
                        ref.read(authProvider.notifier).clearError();
                      },
                      child: Text(
                        _isSignUp ? 'Sign In' : 'Sign Up',
                        style: TextStyle(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      final email = _emailController.text.trim();
      final password = _passwordController.text;
      
      if (_isSignUp) {
        ref.read(authProvider.notifier).signUp(email, password);
      } else {
        ref.read(authProvider.notifier).signIn(email, password);
      }
    }
  }
}

class CounterScreen extends ConsumerWidget {
  final User user;
  
  const CounterScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counter = ref.watch(counterProvider(user.id!));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Counter App'),
        backgroundColor: Colors.blue[600],
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => ref.read(authProvider.notifier).signOut(),
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Welcome message
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      Text(
                        'Welcome back!',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.blue[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Counter display
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Counter',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '$counter',
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        color: Colors.blue[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 50),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Increment button
                  _CounterButton(
                    onPressed: () => ref.read(counterProvider(user.id!).notifier).increment(),
                    icon: Icons.add,
                    label: 'Increment',
                    color: Colors.green,
                  ),
                  
                  // Decrement button  
                  _CounterButton(
                    onPressed: () => ref.read(counterProvider(user.id!).notifier).decrement(),
                    icon: Icons.remove,
                    label: 'Decrement',
                    color: Colors.orange,
                  ),
                  
                  // Reset button
                  _CounterButton(
                    onPressed: () => ref.read(counterProvider(user.id!).notifier).reset(),
                    icon: Icons.refresh,
                    label: 'Reset',
                    color: Colors.red,
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

class _CounterButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final Color color;

  const _CounterButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: color,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(16),
            elevation: 4,
          ),
          child: Icon(icon, size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}