import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {

  // ── Infos du coach ──────────────────────────────────────
  static const String _coachName    = 'Thomas Dupont';
  static const String _coachInitials = 'TD';
  static const String _coachStatus  = 'En ligne • Disponible';

  // ── Message state ──────────────────────────────────────
  final _msgController   = TextEditingController();
  final _scrollController = ScrollController();
  bool _isMicActive  = false;
  bool _isTyping     = false; // true quand le coach est en train d'écrire
  int  _msgIdCounter = 0;

  String _nextId() => '${++_msgIdCounter}';

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: '0',
      text: "Bonjour ! 👋 Je suis Thomas, votre coach personnel. Prêt à commencer notre séance ?",
      isUser: false,
      time: '09:00',
      timestamp: DateTime(2025, 1, 1, 9, 0),
      status: MessageStatus.read,
    ),
  ];

  // ── Call overlay state ──────────────────────────────────
  bool _isVideoCallActive = false;
  bool _isVoiceCallActive = false;

  bool _videoMuted   = false;
  bool _videoCamera  = true;
  bool _videoSpeaker = true;

  bool _voiceMuted   = false;
  bool _voiceSpeaker = true;

  Timer? _callTimer;
  int   _callSeconds = 0;

  // ── Animations ──────────────────────────────────────────
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _waveController  = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _callTimer?.cancel();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────
  String get _callDuration {
    final m = (_callSeconds ~/ 60).toString().padLeft(2, '0');
    final s = (_callSeconds %  60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _startCallTimer() {
    _callSeconds = 0;
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _callSeconds++);
    });
  }

  void _stopCallTimer() { _callTimer?.cancel(); _callSeconds = 0; }

  void _sendMessage() {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    setState(() => _messages.add(ChatMessage.fromUser(id: _nextId(), text: text)));
    _msgController.clear();
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _startVideoCall() { setState(() => _isVideoCallActive = true);  _startCallTimer(); }
  void _endVideoCall()   { setState(() { _isVideoCallActive = false; _videoMuted = false; _videoCamera = true;  }); _stopCallTimer(); }
  void _startVoiceCall() { setState(() => _isVoiceCallActive = true);  _startCallTimer(); }
  void _endVoiceCall()   { setState(() { _isVoiceCallActive = false; _voiceMuted = false; _voiceSpeaker = true; }); _stopCallTimer(); }

  // ═══════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _glowBlob(200, 0.06)),
          Positioned(bottom: 80, left: -40, child: _glowBlob(150, 0.04)),
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(child: _buildMessageList()),
                if (_isTyping) _buildTypingIndicator(),
                _buildInputBar(),
              ],
            ),
          ),
          if (_isVideoCallActive) _buildVideoCallOverlay(),
          if (_isVoiceCallActive) _buildVoiceCallOverlay(),
        ],
      ),
    );
  }

  // ── App bar ──────────────────────────────────────────────
  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: kDarkCard,
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          // Avatar avec initiales du coach
          Stack(children: [
            Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonGreen.withOpacity(0.12),
                border: Border.all(color: kNeonGreen.withOpacity(0.4), width: 2),
              ),
              child: Center(
                child: Text(
                  _coachInitials,
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            // Indicateur en ligne
            Positioned(
              bottom: 1, right: 1,
              child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle, color: kNeonGreen,
                  border: Border.all(color: Colors.black, width: 1.5),
                  boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.7), blurRadius: 6)],
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  _coachName,
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                ),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Text(
                    _coachStatus,
                    style: TextStyle(
                      color: kNeonGreen.withOpacity(0.6 + _pulseController.value * 0.4),
                      fontSize: 11, fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _callIconBtn(icon: Icons.call_outlined,    onTap: _startVoiceCall, tooltip: 'Appel vocal'),
          const SizedBox(width: 8),
          _callIconBtn(icon: Icons.videocam_outlined, onTap: _startVideoCall, tooltip: 'Appel vidéo'),
        ],
      ),
    );
  }

  Widget _callIconBtn({required IconData icon, required VoidCallback onTap, required String tooltip}) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: tooltip,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: kNeonGreen.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: kNeonGreen.withOpacity(0.35)),
          ),
          child: Icon(icon, color: kNeonGreen, size: 18),
        ),
      ),
    );
  }

  // ── Typing indicator ─────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
      child: Row(
        children: [
          // Mini avatar coach
          Container(
            width: 24, height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kNeonGreen.withOpacity(0.12),
              border: Border.all(color: kNeonGreen.withOpacity(0.35)),
            ),
            child: Center(
              child: Text(
                _coachInitials,
                style: const TextStyle(color: kNeonGreen, fontSize: 8, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(18), topRight: Radius.circular(18),
                bottomLeft: Radius.circular(4), bottomRight: Radius.circular(18),
              ),
              border: Border.all(color: Colors.white.withOpacity(0.07)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) => AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) {
                  final opacity = 0.3 + math.sin(_waveController.value * 2 * math.pi + i * 0.8).abs() * 0.7;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 5, height: 5,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(opacity),
                    ),
                  );
                },
              )),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$_coachName écrit…',
            style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ── Message list ─────────────────────────────────────────
  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Avatar coach (initiales)
          if (!msg.isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonGreen.withOpacity(0.12),
                border: Border.all(color: kNeonGreen.withOpacity(0.35)),
              ),
              child: Center(
                child: Text(
                  _coachInitials,
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: msg.isUser ? kNeonGreen.withOpacity(0.15) : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.only(
                      topLeft:     const Radius.circular(18),
                      topRight:    const Radius.circular(18),
                      bottomLeft:  Radius.circular(msg.isUser ? 18 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4  : 18),
                    ),
                    border: Border.all(
                      color: msg.isUser ? kNeonGreen.withOpacity(0.4) : Colors.white.withOpacity(0.07),
                    ),
                    boxShadow: msg.isUser
                        ? [BoxShadow(color: kNeonGreen.withOpacity(0.08), blurRadius: 12)]
                        : [],
                  ),
                  child: Text(
                    msg.text,
                    style: TextStyle(
                      color: msg.isUser ? Colors.white : Colors.white.withOpacity(0.9),
                      fontSize: 13.5, fontWeight: FontWeight.w500, height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(msg.time, style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10)),
                    if (msg.isUser) ...[const SizedBox(width: 4), _statusIcon(msg.status)],
                  ],
                ),
              ],
            ),
          ),
          if (msg.isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:   return Icon(Icons.access_time, size: 11, color: Colors.white.withOpacity(0.3));
      case MessageStatus.sent:      return Icon(Icons.check,       size: 11, color: Colors.white.withOpacity(0.35));
      case MessageStatus.delivered: return Icon(Icons.done_all,    size: 11, color: Colors.white.withOpacity(0.35));
      case MessageStatus.read:      return const Icon(Icons.done_all, size: 11, color: kNeonGreen);
    }
  }

  // ── Input bar ────────────────────────────────────────────
  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: kDarkCard,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.07))),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTapDown:   (_) => setState(() => _isMicActive = true),
            onTapUp:     (_) => setState(() => _isMicActive = false),
            onTapCancel: ()  => setState(() => _isMicActive = false),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: _isMicActive ? kNeonGreen : kNeonGreen.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: kNeonGreen.withOpacity(_isMicActive ? 1 : 0.35)),
                boxShadow: _isMicActive
                    ? [BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 14)]
                    : [],
              ),
              child: Icon(Icons.mic_outlined, color: _isMicActive ? kDarkBg : kNeonGreen, size: 18),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.10)),
              ),
              child: TextField(
                controller: _msgController,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Envoyer un message…',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: kNeonGreen,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: kNeonGreen.withOpacity(0.4), blurRadius: 12)],
              ),
              child: const Icon(Icons.send_rounded, color: kDarkBg, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  VIDEO CALL OVERLAY
  // ═══════════════════════════════════════════════════════
  Widget _buildVideoCallOverlay() {
    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D0D0D), Color(0xFF050505)],
                ),
              ),
            ),
            CustomPaint(painter: _GridPainter(opacity: 0.04)),

            // Avatar du coach (initiales + nom)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _pulseController,
                    builder: (_, __) => Container(
                      width: 110, height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kNeonGreen.withOpacity(0.10),
                        border: Border.all(
                          color: kNeonGreen.withOpacity(0.3 + _pulseController.value * 0.4),
                          width: 2.5,
                        ),
                        boxShadow: [BoxShadow(
                          color: kNeonGreen.withOpacity(0.12 + _pulseController.value * 0.1),
                          blurRadius: 40,
                        )],
                      ),
                      child: Center(
                        child: Text(
                          _coachInitials,
                          style: const TextStyle(
                            color: kNeonGreen,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    _coachName,
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Coach personnel',
                    style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Text(_callDuration, style: TextStyle(color: kNeonGreen.withOpacity(0.8), fontSize: 14)),
                ],
              ),
            ),

            // Badge en haut
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: _callBadge(Icons.videocam, 'APPEL VIDÉO', Colors.red),
                ),
              ),
            ),

            // PiP : vue caméra de l'utilisateur
            Positioned(
              bottom: 150, right: 20,
              child: Container(
                width: 90, height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kNeonGreen.withOpacity(0.35), width: 1.5),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 12)],
                ),
                child: _videoCamera
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter, end: Alignment.bottomCenter,
                              colors: [const Color(0xFF1A1A1A), kNeonGreen.withOpacity(0.06)],
                            ),
                          ),
                          child: const Center(child: Icon(Icons.person_outline, color: Colors.white38, size: 36)),
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                        child: const Center(child: Icon(Icons.videocam_off, color: Colors.white24, size: 28)),
                      ),
              ),
            ),

            // Contrôles bas
            Positioned(
              bottom: 0, left: 0, right: 0,
              child: SafeArea(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter, end: Alignment.topCenter,
                      colors: [Colors.black, Colors.black.withOpacity(0)],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _videoCtrlBtn(
                        icon: _videoMuted ? Icons.mic_off : Icons.mic,
                        label: _videoMuted ? 'Activer' : 'Couper',
                        active: _videoMuted,
                        onTap: () => setState(() => _videoMuted = !_videoMuted),
                      ),
                      const SizedBox(width: 16),
                      _videoCtrlBtn(
                        icon: _videoCamera ? Icons.videocam : Icons.videocam_off,
                        label: _videoCamera ? 'Caméra' : 'Masqué',
                        active: !_videoCamera,
                        onTap: () => setState(() => _videoCamera = !_videoCamera),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: _endVideoCall,
                        child: Container(
                          width: 64, height: 64,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle, color: Colors.red,
                            boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 20)],
                          ),
                          child: const Icon(Icons.call_end, color: Colors.white, size: 26),
                        ),
                      ),
                      const SizedBox(width: 16),
                      _videoCtrlBtn(
                        icon: _videoSpeaker ? Icons.volume_up : Icons.volume_off,
                        label: 'Haut-p.',
                        active: !_videoSpeaker,
                        onTap: () => setState(() => _videoSpeaker = !_videoSpeaker),
                      ),
                      const SizedBox(width: 16),
                      _videoCtrlBtn(icon: Icons.flip_camera_ios_outlined, label: 'Retourner', active: false, onTap: () {}),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _videoCtrlBtn({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.08),
              border: Border.all(color: active ? Colors.white.withOpacity(0.4) : Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════
  //  VOICE CALL OVERLAY
  // ═══════════════════════════════════════════════════════
  Widget _buildVoiceCallOverlay() {
    return Material(
      color: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Color(0xFF050505), Colors.black],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Anneaux de propagation
            Center(
              child: AnimatedBuilder(
                animation: _waveController,
                builder: (_, __) => Stack(
                  alignment: Alignment.center,
                  children: List.generate(4, (i) {
                    final progress = (_waveController.value + i / 4) % 1.0;
                    final size = 120.0 + progress * 180;
                    return Container(
                      width: size, height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: kNeonGreen.withOpacity((1 - progress) * 0.25),
                          width: 1.5,
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                    child: Center(child: _callBadge(Icons.call, 'APPEL VOCAL', kNeonGreen)),
                  ),
                  const Spacer(),
                  Column(
                    children: [
                      // Grand avatar avec initiales du coach
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (_, __) => Container(
                          width: 120, height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: kNeonGreen.withOpacity(0.09),
                            border: Border.all(
                              color: kNeonGreen.withOpacity(0.3 + _pulseController.value * 0.45),
                              width: 2.5,
                            ),
                            boxShadow: [BoxShadow(
                              color: kNeonGreen.withOpacity(0.15 + _pulseController.value * 0.12),
                              blurRadius: 50,
                            )],
                          ),
                          child: Center(
                            child: Text(
                              _coachInitials,
                              style: const TextStyle(
                                color: kNeonGreen,
                                fontSize: 42,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        _coachName,
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: -0.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Coach personnel',
                        style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _callDuration,
                        style: const TextStyle(color: kNeonGreen, fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1),
                      ),
                      const SizedBox(height: 10),
                      // Barres audio animées
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ...List.generate(5, (i) => AnimatedBuilder(
                            animation: _waveController,
                            builder: (_, __) {
                              final h = 8.0 + math.sin(_waveController.value * 2 * math.pi + i * 0.7).abs() * 16;
                              return Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 3, height: h,
                                decoration: BoxDecoration(
                                  color: kNeonGreen.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            },
                          )),
                          const SizedBox(width: 8),
                          Text('En communication…', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _voiceCtrlBtn(
                          icon: _voiceMuted ? Icons.mic_off : Icons.mic,
                          label: _voiceMuted ? 'Activer' : 'Couper',
                          active: _voiceMuted,
                          onTap: () => setState(() => _voiceMuted = !_voiceMuted),
                        ),
                        GestureDetector(
                          onTap: _endVoiceCall,
                          child: Container(
                            width: 70, height: 70,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle, color: Colors.red,
                              boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.5), blurRadius: 24)],
                            ),
                            child: const Icon(Icons.call_end, color: Colors.white, size: 28),
                          ),
                        ),
                        _voiceCtrlBtn(
                          icon: _voiceSpeaker ? Icons.volume_up : Icons.volume_off,
                          label: 'Haut-p.',
                          active: !_voiceSpeaker,
                          onTap: () => setState(() => _voiceSpeaker = !_voiceSpeaker),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _voiceCtrlBtn({required IconData icon, required String label, required bool active, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: active ? Colors.white.withOpacity(0.15) : Colors.white.withOpacity(0.06),
              border: Border.all(color: active ? Colors.white.withOpacity(0.35) : Colors.white.withOpacity(0.1)),
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // ── Shared ────────────────────────────────────────────────
  Widget _callBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
        ],
      ),
    );
  }

  Widget _glowBlob(double size, double opacity) => Container(
    width: size, height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [kNeonGreen.withOpacity(opacity), Colors.transparent]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────
//  Grid painter (fond texture appel vidéo)
// ─────────────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  final double opacity;
  _GridPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = kNeonGreen.withOpacity(opacity)..strokeWidth = 0.5;
    const step = 40.0;
    for (double x = 0; x < size.width;  x += step) canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    for (double y = 0; y < size.height; y += step) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
  }

  @override
  bool shouldRepaint(covariant _GridPainter old) => old.opacity != opacity;
}