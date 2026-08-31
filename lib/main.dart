import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/storage_service.dart';
import 'services/note_service.dart';
import 'services/sync_service.dart';
import 'screens/auth_screen.dart';
import 'screens/home_screen_notes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final storageService = StorageService();
  await storageService.init();

  final authService = AuthService();
  final noteService = NoteService(storageService, authService);
  final syncService = SyncService(noteService);

  runApp(SuperNoteApp(
    authService: authService,
    noteService: noteService,
    syncService: syncService,
  ));
}

class SuperNoteApp extends StatelessWidget {
  final AuthService authService;
  final NoteService noteService;
  final SyncService syncService;

  const SuperNoteApp({
    super.key,
    required this.authService,
    required this.noteService,
    required this.syncService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SuperNote',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: StreamBuilder(
        stream: authService.authStateChanges,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasData) {
            return HomeScreen(
              noteService: noteService,
              syncService: syncService,
              authService: authService,
            );
          }

          return AuthScreen(authService: authService);
        },
      ),
    );
  }
}
