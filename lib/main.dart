import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/agent_provider.dart';
import 'providers/chat_provider.dart';
import 'providers/review_provider.dart';
import 'screens/auth/login_screen.dart';
import 'screens/home/agent_catalogue_screen.dart';
import 'screens/auth/role_selection_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('🔵 [Main] Initializing Firebase...');
  await Firebase.initializeApp();
  print('✅ [Main] Firebase initialized');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => AgentProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(create: (_) => ReviewProvider()),
      ],
      child: MaterialApp(
        title: 'TravelConnect',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white,
          appBarTheme: const AppBarTheme(
            elevation: 0,
            centerTitle: true,
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({Key? key}) : super(key: key);

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Start listening to chats when authenticated
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      if (authProvider.currentUser != null) {
        chatProvider.listenToUserChats(authProvider.currentUser!.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        print('🔵 [AuthWrapper] Building...');
        print('🔵 [AuthWrapper] isAuth=${authProvider.isAuthenticated}');
        print('🔵 [AuthWrapper] hasUser=${authProvider.currentUser != null}');
        print('🔵 [AuthWrapper] role=${authProvider.currentUser?.role}');
        print('🔵 [AuthWrapper] isLoading=${authProvider.isLoading}');
        
        // Show loading spinner while checking auth state or during operations
        if (authProvider.isLoading) {
          print('🔵 [AuthWrapper] Showing loading screen');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // Check Firebase Auth state (not just currentUser)
        if (!authProvider.isAuthenticated) {
          print('🔵 [AuthWrapper] Not authenticated → LoginScreen');
          return const LoginScreen();
        }

        // User is authenticated but we don't have user data yet
        if (authProvider.currentUser == null) {
          print('🟡 [AuthWrapper] Authenticated but no user data → Loading...');
          return const Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading user data...',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }

        // User is authenticated and has data, check role
        final user = authProvider.currentUser!;
        
        if (user.role.isEmpty) {
          print('🔵 [AuthWrapper] No role → RoleSelectionScreen');
          return const RoleSelectionScreen();
        }

        print('🔵 [AuthWrapper] Has role: ${user.role} → AgentCatalogueScreen');
        
        // Start listening to chats if not already listening
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final chatProvider = Provider.of<ChatProvider>(context, listen: false);
          if (chatProvider.chats.isEmpty) {
            chatProvider.listenToUserChats(user.id);
          }
        });
        
        return const AgentCatalogueScreen();
      },
    );
  }
}