import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:test_hh/constants/colors.dart';
import 'package:test_hh/models/message.dart';
import 'package:test_hh/services/chatapi_service.dart';

/// Données de session passées à l'écran.
class ChatSession {
  final int coachId;
  final String coachName;
  final String coachInitials;
  final int clientId;
  final String clientName;
  final String clientInitials;
  final String role; // 'client' | 'coach'

  const ChatSession({
    required this.coachId,
    required this.coachName,
    required this.coachInitials,
    required this.clientId,
    required this.role,
    this.clientName = 'Client',
    this.clientInitials = 'C',
  });
}

class ChatScreen extends StatefulWidget {
  final ChatSession session;
  const ChatScreen({super.key, required this.session});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  ChatSession get _s => widget.session;

  final _msgController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isLoading = true;
  bool _isSending = false;
  String? _errorMsg;

  // Audio
  bool _isRecording = false;
  String? _recordingPath;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _currentPlayingUrl;
  bool _isPlaying = false;

  Timer? _pollTimer;
  final List<ChatMessage> _messages = [];

  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _initAudio();
    _loadMessages();
    _pollTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _pollNewMessages(),
    );
  }

  Future<void> _initAudio() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      _showSnack('Permission microphone requise pour enregistrer des audios.');
    }
  }

  @override
  void dispose() {
    _msgController.dispose();
    _scrollController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
    _pollTimer?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // MESSAGES
  // ─────────────────────────────────────────────

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });
    try {
      final raw = await ChatApiService.getMessages(
        coachId: _s.coachId,
        clientId: _s.clientId,
      );
      final msgs = raw.map(_fromJson).toList();
      setState(() {
        _messages.clear();
        _messages.addAll(msgs);
        _isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMsg = e.toString();
      });
    }
  }

  Future<void> _pollNewMessages() async {
    if (!mounted) return;
    try {
      final raw = await ChatApiService.getMessages(
        coachId: _s.coachId,
        clientId: _s.clientId,
        limit: 20,
      );
      final incoming = raw.map(_fromJson).toList();
      if (incoming.isEmpty) return;

      final knownIds = _messages.map((m) => m.id).toSet();
      final newMsgs = incoming.where((m) => !knownIds.contains(m.id)).toList();

      if (newMsgs.isNotEmpty && mounted) {
        setState(() => _messages.addAll(newMsgs));
        _scrollToBottom();
      }
    } catch (_) {}
  }

  Future<void> _sendMessage() async {
    final text = _msgController.text.trim();
    if (text.isEmpty || _isSending) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final tempMsg = ChatMessage(
      id: tempId,
      text: text,
      isUser: true,
      time: _formatTime(DateTime.now()),
      timestamp: DateTime.now(),
      status: MessageStatus.sending,
    );
    setState(() {
      _messages.add(tempMsg);
      _isSending = true;
    });
    _msgController.clear();
    _scrollToBottom();

    try {
      final saved = await ChatApiService.sendMessage(
        coachId: _s.coachId,
        clientId: _s.clientId,
        text: text,
      );
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && mounted) {
        setState(() => _messages[idx] = _fromJson(saved));
      }
    } catch (e) {
      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && mounted) {
        setState(() => _messages[idx] = tempMsg.copyWith(status: MessageStatus.sent));
      }
      _showSnack('Erreur lors de l\'envoi : $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─────────────────────────────────────────────
  // AUDIO RECORD
  // ─────────────────────────────────────────────

  Future<void> _startRecording() async {
    try {
      final hasPermission = await _audioRecorder.hasPermission();
      if (!hasPermission) {
        _showSnack('Permission microphone requise.');
        return;
      }

      Directory? dir;
      try {
        dir = await getTemporaryDirectory();
      } catch (_) {
        try {
          dir = await getApplicationDocumentsDirectory();
        } catch (_) {
          try {
            dir = await getExternalStorageDirectory();
          } catch (_) {}
        }
      }

      if (dir == null) {
        _showSnack('Impossible d\'accéder au stockage.');
        return;
      }

      _recordingPath =
          '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _recordingPath!,
      );
      setState(() => _isRecording = true);
    } catch (e) {
      _showSnack('Erreur microphone : $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _stopRecordingAndSend() async {
    if (!_isRecording) return;
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);
      if (path != null) {
        await _uploadAndSendAudio(path);
      } else {
        _showSnack('Enregistrement vide.');
      }
    } catch (e) {
      _showSnack('Erreur envoi audio : $e');
      setState(() => _isRecording = false);
    }
  }

  Future<void> _cancelRecording() async {
    if (!_isRecording) return;
    try {
      await _audioRecorder.stop();
      if (_recordingPath != null) {
        final f = File(_recordingPath!);
        if (await f.exists()) await f.delete();
      }
    } catch (_) {}
    setState(() => _isRecording = false);
    _showSnack('Enregistrement annulé.');
  }

  Future<void> _uploadAndSendAudio(String audioPath) async {
    try {
      final audioFile = File(audioPath);
      final audioUrl = await ChatApiService.uploadAudio(audioFile);

      final tempId = 'temp_audio_${DateTime.now().millisecondsSinceEpoch}';
      final tempMsg = ChatMessage(
        id: tempId,
        text: '[Message audio]',
        isUser: true,
        time: _formatTime(DateTime.now()),
        timestamp: DateTime.now(),
        type: MessageType.audio,
        status: MessageStatus.sending,
        mediaUrl: audioUrl,
      );
      setState(() {
        _messages.add(tempMsg);
        _isSending = true;
      });
      _scrollToBottom();

      final saved = await ChatApiService.sendMessage(
        coachId: _s.coachId,
        clientId: _s.clientId,
        type: 'audio',
        mediaUrl: audioUrl,
      );

      final idx = _messages.indexWhere((m) => m.id == tempId);
      if (idx != -1 && mounted) {
        setState(() => _messages[idx] = _fromJson(saved));
      }
    } catch (e) {
      _showSnack('Erreur lors de l\'envoi du message audio: $e');
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────

  ChatMessage _fromJson(Map<String, dynamic> json) {
    final isUser = json['isUser'] == 1;
    final rawTime = json['time'] ?? json['timestamp'];
    DateTime dt;
    try {
      dt = DateTime.parse(rawTime.toString());
    } catch (_) {
      dt = DateTime.now();
    }
    return ChatMessage(
      id: json['id'].toString(),
      text: json['text'] ?? '',
      isUser: isUser,
      time: _formatTime(dt),
      timestamp: dt,
      type: _parseType(json['type'] ?? 'text'),
      status: _parseStatus(json['status'] ?? 'sent'),
      mediaUrl: json['mediaUrl'] as String?,
    );
  }

  MessageType _parseType(String t) {
    switch (t) {
      case 'image': return MessageType.image;
      case 'audio': return MessageType.audio;
      case 'video': return MessageType.video;
      default:      return MessageType.text;
    }
  }

  MessageStatus _parseStatus(String s) {
    switch (s) {
      case 'sending':   return MessageStatus.sending;
      case 'delivered': return MessageStatus.delivered;
      case 'read':      return MessageStatus.read;
      default:          return MessageStatus.sent;
    }
  }

  static String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

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

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade800,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonGreen.withOpacity(0.12),
                border: Border.all(
                  color: kNeonGreen.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Center(
                child: Text(
                  _s.role == 'coach' ? _s.clientInitials : _s.coachInitials,
                  style: const TextStyle(
                    color: kNeonGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              _s.role == 'coach' ? _s.clientName : _s.coachName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(top: -80, right: -60, child: _glowBlob(200, 0.06)),
          Positioned(bottom: 80, left: -40, child: _glowBlob(150, 0.04)),
          SafeArea(
            child: Column(
              children: [
                Expanded(child: _buildBody()),
                _buildInputBar(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: kNeonGreen),
      );
    }
    if (_errorMsg != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMsg!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadMessages,
              style: ElevatedButton.styleFrom(backgroundColor: kNeonGreen),
              child: const Text(
                'Réessayer',
                style: TextStyle(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }
    return _buildMessageList();
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Text(
          'Aucun message. Envoyez le premier ! 👋',
          style: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 13,
          ),
        ),
      );
    }
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _messages.length,
      itemBuilder: (_, i) => _buildBubble(_messages[i]),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isCurrentUser = _s.role == 'coach' ? !msg.isUser : msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isCurrentUser) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kNeonGreen.withOpacity(0.12),
                border: Border.all(color: kNeonGreen.withOpacity(0.35)),
              ),
              child: Center(
                child: Text(
                  _s.role == 'coach' ? _s.clientInitials : _s.coachInitials,
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
              crossAxisAlignment: isCurrentUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                msg.type == MessageType.audio
                    ? _buildAudioMessage(msg, isCurrentUser)
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: isCurrentUser
                              ? kNeonGreen.withOpacity(0.15)
                              : const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft:
                                Radius.circular(isCurrentUser ? 18 : 4),
                            bottomRight:
                                Radius.circular(isCurrentUser ? 4 : 18),
                          ),
                          border: Border.all(
                            color: isCurrentUser
                                ? kNeonGreen.withOpacity(0.4)
                                : Colors.white.withOpacity(0.07),
                          ),
                        ),
                        child: Text(
                          msg.text,
                          style: TextStyle(
                            color: isCurrentUser
                                ? Colors.white
                                : Colors.white.withOpacity(0.9),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            height: 1.45,
                          ),
                        ),
                      ),
                const SizedBox(height: 3),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      msg.time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.3),
                        fontSize: 10,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 4),
                      _statusIcon(msg.status),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (isCurrentUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // AUDIO MESSAGE BUBBLE
  // ─────────────────────────────────────────────

  Widget _buildAudioMessage(ChatMessage msg, bool isCurrentUser) {
    if (msg.mediaUrl == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? kNeonGreen.withOpacity(0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
            bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
          ),
          border: Border.all(
            color: isCurrentUser
                ? kNeonGreen.withOpacity(0.4)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Text(
          'Audio indisponible',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
        ),
      );
    }

    final isThisPlaying = _currentPlayingUrl == msg.mediaUrl && _isPlaying;

    return GestureDetector(
      onTap: () async {
        if (isThisPlaying) {
          await _audioPlayer.pause();
          setState(() => _isPlaying = false);
        } else {
          if (_currentPlayingUrl != null &&
              _currentPlayingUrl != msg.mediaUrl) {
            await _audioPlayer.stop();
          }
          await _audioPlayer.play(UrlSource(msg.mediaUrl!));
          setState(() {
            _isPlaying = true;
            _currentPlayingUrl = msg.mediaUrl;
          });
          _audioPlayer.onPlayerComplete.listen((_) {
            if (mounted) {
              setState(() {
                _isPlaying = false;
                _currentPlayingUrl = null;
              });
            }
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? kNeonGreen.withOpacity(0.15)
              : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isCurrentUser ? 18 : 4),
            bottomRight: Radius.circular(isCurrentUser ? 4 : 18),
          ),
          border: Border.all(
            color: isCurrentUser
                ? kNeonGreen.withOpacity(0.4)
                : Colors.white.withOpacity(0.07),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isThisPlaying
                    ? Icons.pause_circle_filled
                    : Icons.play_circle_filled,
                key: ValueKey(isThisPlaying),
                color: isCurrentUser ? Colors.white : kNeonGreen,
                size: 28,
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Message audio',
                  style: TextStyle(
                    color: isCurrentUser
                        ? Colors.white
                        : Colors.white.withOpacity(0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                isThisPlaying
                    ? AnimatedBuilder(
                        animation: _waveController,
                        builder: (_, __) => Row(
                          children: List.generate(5, (i) {
                            final h = 4.0 +
                                (math
                                        .sin(_waveController.value *
                                            2 *
                                            math.pi +
                                            i * 0.7)
                                        .abs() *
                                    10);
                            return Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 1.5),
                              width: 3,
                              height: h,
                              decoration: BoxDecoration(
                                color: isCurrentUser
                                    ? Colors.white.withOpacity(0.8)
                                    : kNeonGreen.withOpacity(0.8),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        ),
                      )
                    : Row(
                        children: List.generate(
                          5,
                          (i) => Container(
                            margin:
                                const EdgeInsets.symmetric(horizontal: 1.5),
                            width: 3,
                            height: 4,
                            decoration: BoxDecoration(
                              color: isCurrentUser
                                  ? Colors.white.withOpacity(0.3)
                                  : Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // INPUT BAR
  // ─────────────────────────────────────────────

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: BoxDecoration(
        color: kDarkCard,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.07)),
        ),
      ),
      child: _isRecording ? _buildRecordingBar() : _buildNormalBar(),
    );
  }

  Widget _buildNormalBar() {
    return Row(
      children: [
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
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 13,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Bouton envoyer texte
        GestureDetector(
          onTap: _isSending ? null : _sendMessage,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _isSending ? kNeonGreen.withOpacity(0.5) : kNeonGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: kNeonGreen.withOpacity(0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child: _isSending
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(
                      color: Colors.black,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.send_rounded, color: kDarkBg, size: 18),
          ),
        ),
        const SizedBox(width: 8),
        // Bouton micro — appui long pour enregistrer
        GestureDetector(
          onLongPressStart: (_) => _startRecording(),
          onLongPressEnd: (_) => _stopRecordingAndSend(),
          onLongPressCancel: () => _cancelRecording(),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kNeonGreen.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: kNeonGreen.withOpacity(0.4)),
            ),
            child: const Icon(Icons.mic, color: kNeonGreen, size: 20),
          ),
        ),
      ],
    );
  }

  Widget _buildRecordingBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _cancelRecording,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.4)),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.red.withOpacity(0.25)),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) => Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.red.withOpacity(
                        0.4 + _pulseController.value * 0.6,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (_, __) => Row(
                    children: List.generate(12, (i) {
                      final h = 6.0 +
                          (math
                                  .sin(_waveController.value *
                                      2 *
                                      math.pi +
                                      i * 0.5)
                                  .abs() *
                              14);
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        width: 2.5,
                        height: h,
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Enregistrement…',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _stopRecordingAndSend,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: kNeonGreen,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: kNeonGreen.withOpacity(0.5), blurRadius: 14),
              ],
            ),
            child: const Icon(Icons.send_rounded, color: kDarkBg, size: 18),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // STATUS ICON
  // ─────────────────────────────────────────────

  Widget _statusIcon(MessageStatus status) {
    switch (status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 11, color: Colors.white.withOpacity(0.3));
      case MessageStatus.sent:
        return Icon(Icons.check, size: 11, color: Colors.white.withOpacity(0.35));
      case MessageStatus.delivered:
        return Icon(Icons.done_all, size: 11, color: Colors.white.withOpacity(0.35));
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 11, color: kNeonGreen);
    }
  }

  Widget _glowBlob(double size, double opacity) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [kNeonGreen.withOpacity(opacity), Colors.transparent],
          ),
        ),
      );
}