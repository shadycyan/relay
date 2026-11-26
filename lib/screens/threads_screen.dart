import 'dart:async';
import 'package:flutter/material.dart';
import '../cyber.dart';
import '../sms_bridge.dart';
import '../theme.dart';
import 'chat_screen.dart';

class ThreadsScreen extends StatefulWidget {
  const ThreadsScreen({super.key});
  @override
  State<ThreadsScreen> createState() => _ThreadsScreenState();
}

class _ThreadsScreenState extends State<ThreadsScreen> with WidgetsBindingObserver {
  List<SmsThread> threads = [];
  bool loading = true, isDef = true;
  StreamSubscription? sub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    sub = SmsBridge.events.listen((e) {
      if (e['type'] == 'incoming') _load();
      if (e['type'] == 'open') _open(e['address'] as String);
    });
    _load();
    SmsBridge.initialAddress().then((a) {
      if (a != null && a.isNotEmpty) _open(a);
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    sub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    try {
      final d = await SmsBridge.isDefault();
      final t = await SmsBridge.threads();
      if (!mounted) return;
      setState(() {
        isDef = d;
        threads = t;
        loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> _open(String address) async {
    SmsThread? t;
    for (final x in threads) {
      if (sameAddr(x.address, address)) t = x;
    }
    await Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 150),
        pageBuilder: (_, __, ___) =>
            ChatScreen(address: t?.address ?? address, name: t?.name, threadId: t?.id),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
    _load();
  }

  Future<void> _new() async {
    final c = TextEditingController();
    final n = await showDialog<String>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: CyberPanel(
          fill: C.panel,
          border: C.yellow,
          cut: 14,
          tl: true,
          br: true,
          padding: const EdgeInsets.all(18),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('NEW TRANSMISSION', style: hud(18, color: C.yellow, ls: 2)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.phone,
              style: hud(20),
              decoration: InputDecoration(
                hintText: '+49 …',
                hintStyle: hud(20, color: C.dim),
                enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: C.cyan)),
                focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: C.yellow)),
              ),
            ),
            const SizedBox(height: 16),
            Align(
                alignment: Alignment.centerRight,
                child: CyberButton(label: 'OPEN', onTap: () => Navigator.pop(ctx, c.text.trim()))),
          ]),
        ),
      ),
    );
    if (n != null && n.isNotEmpty) _open(n);
  }

  Widget _header() => Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('MESSAGES', style: hud(34, color: C.yellow, w: FontWeight.w700, ls: 4)),
          const Spacer(),
          HudTag('${threads.length} THREADS'),
        ]),
      );

  Widget _banner() => Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: CyberPanel(
          fill: C.red.withValues(alpha: .1),
          border: C.red,
          cut: 10,
          tl: true,
          br: true,
          child: Row(children: [
            Expanded(
                child: Text('NOT DEFAULT SMS APP // incoming msgs wont be stored',
                    style: hud(14, color: C.red, ls: .8))),
            const SizedBox(width: 10),
            CyberButton(
                label: 'SET',
                color: C.red,
                onTap: () async {
                  await SmsBridge.requestDefault();
                  _load();
                }),
          ]),
        ),
      );

  Widget _row(SmsThread t) {
    final unread = t.unread > 0;
    return InkWell(
      onTap: () => _open(t.address),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        child: CyberPanel(
          fill: C.panel,
          border: unread ? C.yellow.withValues(alpha: .7) : C.line,
          glow: unread,
          cut: 10,
          tr: true,
          br: false,
          bl: true,
          padding: const EdgeInsets.all(10),
          child: Row(children: [
            Avatar(label: t.title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(
                      child: Text(t.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: hud(17, color: unread ? C.yellow : C.text, ls: 1.5))),
                  Text(fmtThreadTime(t.date), style: hud(13, color: C.dim)),
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(
                      child: Text('${t.lastMine ? "> " : ""}${t.snippet.replaceAll("\n", " ")}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: hud(15, color: C.dim, w: FontWeight.w500, ls: .3))),
                  if (unread)
                    Container(
                      margin: const EdgeInsets.only(left: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      color: C.yellow,
                      child: Text('${t.unread}', style: hud(13, color: Colors.black, w: FontWeight.w700)),
                    ),
                ]),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        floatingActionButton: GestureDetector(
            onTap: _new, child: CyberPanel(fill: C.yellow, cut: 12, tl: true, br: true,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Text('+ NEW', style: hud(17, color: Colors.black, w: FontWeight.w700, ls: 2)))),
        body: CyberBackground(
          child: SafeArea(
            child: Column(children: [
              _header(),
              if (!isDef) _banner(),
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator(color: C.yellow))
                    : RefreshIndicator(
                        color: C.yellow,
                        backgroundColor: C.panel,
                        onRefresh: _load,
                        child: threads.isEmpty
                            ? ListView(children: [
                                const SizedBox(height: 120),
                                Center(child: Text('NO SIGNAL // NO THREADS', style: hud(16, color: C.dim, ls: 3))),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.only(bottom: 90),
                                itemCount: threads.length,
                                itemBuilder: (_, i) => _row(threads[i]),
                              ),
                      ),
              ),
            ]),
          ),
        ),
      );
}
