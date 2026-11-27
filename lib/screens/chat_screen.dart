import 'dart:async';
import 'package:flutter/material.dart';
import '../cyber.dart';
import '../sms_bridge.dart';
import '../theme.dart';

class ChatScreen extends StatefulWidget {
  final String address;
  final String? name;
  final int? threadId;
  const ChatScreen({super.key, required this.address, this.name, this.threadId});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<SmsMsg> msgs = [];
  int tid = -1;
  final ctl = TextEditingController();
  StreamSubscription? sub;

  String get title => (widget.name != null && widget.name!.isNotEmpty) ? widget.name! : widget.address;

  @override
  void initState() {
    super.initState();
    tid = widget.threadId ?? -1;
    sub = SmsBridge.events.listen((e) {
      if (e['type'] == 'incoming') _load();
    });
    _init();
  }

  @override
  void dispose() {
    sub?.cancel();
    ctl.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    if (tid <= 0) tid = await SmsBridge.threadIdFor(widget.address);
    await _load();
  }

  Future<void> _load() async {
    if (tid <= 0) return;
    final m = await SmsBridge.messages(tid);
    if (!mounted) return;
    setState(() => msgs = m);
    SmsBridge.markRead(tid);
  }

  Future<void> _send() async {
    final text = ctl.text.trim();
    if (text.isEmpty) return;
    ctl.clear();
    try {
      await SmsBridge.send(widget.address, text);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            backgroundColor: C.red,
            content: Text('SEND FAILED // $e',
                style: hud(14, color: C.bg, w: FontWeight.w700))));
      }
    }
    await Future.delayed(const Duration(milliseconds: 200));
    if (tid <= 0) tid = await SmsBridge.threadIdFor(widget.address);
    _load();
  }

  Widget _top() => Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 14, 8),
        child: Row(children: [
          IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.chevron_left, color: C.text, size: 30)),
          Avatar(label: title, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: hud(20, color: C.text, ls: 2)),
              if (title != widget.address) Text(widget.address, style: hud(13, color: C.dim)),
            ]),
          ),
          const HudTag('SMS', color: C.red),
        ]),
      );

  Widget _bubble(SmsMsg m) {
    final mine = m.mine;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * .78),
          child: Column(crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
            CyberPanel(
              fill: mine ? C.text : C.panel2,
              border: mine ? null : C.dim.withValues(alpha: .45),
              cut: 10,
              tl: !mine,
              br: mine,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text(m.body,
                  style: hud(17, color: mine ? C.bg : C.text, w: FontWeight.w500, ls: .3)),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 3, left: 4, right: 4),
              child: Text(m.failed ? 'FAILED // ${fmtStamp(m.date)}' : fmtStamp(m.date),
                  style: hud(11, color: m.failed ? C.red : C.dim)),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _compose() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: CyberPanel(
              fill: C.panel,
              border: C.dim.withValues(alpha: .45),
              cut: 10,
              tl: true,
              br: false,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: ctl,
                minLines: 1,
                maxLines: 5,
                cursorColor: C.red,
                style: hud(17, w: FontWeight.w500, ls: .3),
                decoration: InputDecoration(
                  hintText: 'TYPE MESSAGE…',
                  hintStyle: hud(15, color: C.dim),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          CyberButton(label: 'SEND', onTap: _send),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    final rev = msgs.reversed.toList();
    return Scaffold(
      body: CyberBackground(
        child: SafeArea(
          child: Column(children: [
            _top(),
            Container(height: 1, color: C.line),
            Expanded(
              child: rev.isEmpty
                  ? Center(child: Text('CHANNEL OPEN // SAY SOMETHING', style: hud(14, color: C.dim, ls: 3)))
                  : ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                      itemCount: rev.length,
                      itemBuilder: (_, i) => _bubble(rev[i]),
                    ),
            ),
            _compose(),
          ]),
        ),
      ),
    );
  }
}
