import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mime_flutter/app.dart';

const dirPath = "Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Stickers";

void main() {
  runApp(const ProviderScope(child: MimeApp()));
}

extension on BuildContext {
  void showSnackBar(String message) {
    ScaffoldMessenger.of(this).showSnackBar(SnackBar(
      content: Text(message),
    ));
  }
}

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Flutter Demo',
//       theme: ThemeData(
//         colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
//         useMaterial3: true,
//       ),
//       home: const MyHomePage(title: 'Flutter Demo Home Page'),
//     );
//   }
// }

// class MyHomePage extends StatefulWidget {
//   const MyHomePage({super.key, required this.title});

//   final String title;

//   @override
//   State<MyHomePage> createState() => _MyHomePageState();
// }

// class _MyHomePageState extends State<MyHomePage> {
//   final _counter = 0;

//   @override
//   void initState() {
//     super.initState();
//   }

//   void saf() async {
//     Saf saf =
//         Saf("Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Stickers");

//     bool? isGranted = await saf.getDirectoryPermission(isDynamic: false);

//     if (!mounted) return;

//     if (isGranted != null && isGranted) {
//       // Perform some file operations
//       context.showSnackBar("Yo");

//       final directoriesPath = await Saf.getPersistedPermissionDirectories();
//       print(directoriesPath);

//       List<String>? paths = await saf.getFilesPath();
//       print(paths);

//       // Try to read the first file and its modification date
//       // using dart:io
//       if (paths != null && paths.isNotEmpty) {
//         final file = File(paths[1]);
//         final lastModified = await file.lastModified();
//         print(lastModified);
//       }

//       print("Bye Bye Bye");
//     } else {
//       // failed to get the permission
//       context.showSnackBar("No");
//     }
//   }

//   void fp() async {
//     String? selectedDirectory = await FilePicker.platform.getDirectoryPath(
//         initialDirectory:
//             "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/WhatsApp Images");

//     if (selectedDirectory == null) {
//       // User canceled the picker
//     }
//   }

//   void raw() async {
//     Directory dir = Directory("/storage/emulated/0/$dirPath");
//     print(dir);
//     if (!await dir.exists()) return;

//     List<FileSystemEntity> files = dir.listSync();
//     print(files);

//     print(files[0]);
//     print(files[0].stat());
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//         title: Text(widget.title),
//       ),
//       body: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: <Widget>[
//             const Text(
//               'You have pushed the button this many times:',
//             ),
//             Text(
//               '$_counter',
//               style: Theme.of(context).textTheme.headlineMedium,
//             ),
//           ],
//         ),
//       ),
//       floatingActionButton: FloatingActionButton(
//         onPressed: saf,
//         tooltip: 'Increment',
//         child: const Icon(Icons.add),
//       ),
//     );
//   }
// }
