import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'cyber.dart';
import 'theme.dart';
import 'screens/threads_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: C.bg,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const RelayApp());
}

class RelayApp extends StatelessWidget {
  const RelayApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'RELAY',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(),
        home: const Gate(),
      );
}

class Gate extends StatefulWidget {
  const Gate({super.key});
  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool? ok;

  @override
  void initState() {
    super.initState();
    Permission.sms.isGranted.then((v) => setState(() => ok = v));
  }

  Future<void> _jackIn() async {
    final s = await Permission.sms.request();
    await Permission.contacts.request();
    await Permission.notification.request();
    if (s.isPermanentlyDenied) await openAppSettings();
    setState(() => ok = s.isGranted);
  }

  @override
  Widget build(BuildContext context) {
    if (ok == null) return const Scaffold();
    if (ok!) return const ThreadsScreen();
    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('RELAY', style: hud(54, color: C.yellow, w: FontWeight.w700, ls: 6)),
                const SizedBox(height: 6),
                Text('// SMS CLIENT v0.1', style: hud(16, color: C.cyan, ls: 3)),
                const SizedBox(height: 28),
                Text(
                    'need sms, contacts + notification access to jack in. '
                    'nothing leaves your phone.',
                    style: hud(18, color: C.dim, w: FontWeight.w500, ls: .4)),
                const SizedBox(height: 28),
                CyberButton(label: 'JACK IN', onTap: _jackIn),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
