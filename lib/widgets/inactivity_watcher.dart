import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../state/auth_notifier.dart';
import '../core/router.dart';

class InactivityWatcher extends StatefulWidget {
  final Duration timeout;
  final Duration warningBefore;
  final Duration? maxSessionDuration;
  final VoidCallback onTimeout;
  final VoidCallback? onMaxSessionTimeout;
  final Widget child;

  const InactivityWatcher({
    super.key,
    required this.timeout,
    required this.warningBefore,
    this.maxSessionDuration,
    required this.onTimeout,
    this.onMaxSessionTimeout,
    required this.child,
  });

  static void showWarningPreview(BuildContext context, {VoidCallback? onContinue}) {
    showDialog(
      context: rootNavigatorKey.currentContext ?? context,
      barrierDismissible: false,
      builder: (c) => _WarningDialog(
        initialSeconds: 30,
        onContinue: () {
          Navigator.of(c, rootNavigator: true).pop();
          onContinue?.call();
        },
      ),
    );
  }

  @override
  State<InactivityWatcher> createState() => _InactivityWatcherState();
}

class _InactivityWatcherState extends State<InactivityWatcher> {
  Timer? _timer;
  Timer? _warningTimer;
  Timer? _maxSessionTimer;
  bool _warningShown = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onKey);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthNotifier>();
    if (auth.isAuthenticated) {
      if (_timer == null) {
        _restart();
        _startMaxSessionTimer();
      }
    } else {
      _cancelAll();
    }
  }

  bool _onKey(KeyEvent event) {
    if (!_warningShown) {
      _restart();
    }
    return false;
  }

  void _restart() {
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated) return;

    _timer?.cancel();
    _warningTimer?.cancel();
    _warningShown = false;

    final warningTime = widget.timeout.inMilliseconds - widget.warningBefore.inMilliseconds;
    _warningTimer = Timer(Duration(milliseconds: warningTime), _showWarning);
    _timer = Timer(widget.timeout, () {
      _closeWarningDialogIfOpen();
      _cancelAll();
      widget.onTimeout();
    });
  }

  void _startMaxSessionTimer() {
    _maxSessionTimer?.cancel();
    if (widget.maxSessionDuration != null) {
      _maxSessionTimer = Timer(widget.maxSessionDuration!, () {
        _closeWarningDialogIfOpen();
        _cancelAll();
        if (widget.onMaxSessionTimeout != null) {
          widget.onMaxSessionTimeout!();
        } else {
          widget.onTimeout();
        }
      });
    }
  }

  void _closeWarningDialogIfOpen() {
    if (_warningShown) {
      final navContext = rootNavigatorKey.currentContext;
      if (navContext != null) {
        try {
          Navigator.of(navContext, rootNavigator: true).pop();
        } catch (_) {}
      }
      _warningShown = false;
    }
  }

  void _cancelAll() {
    _timer?.cancel();
    _warningTimer?.cancel();
    _maxSessionTimer?.cancel();
    _timer = null;
    _warningTimer = null;
    _maxSessionTimer = null;
    _warningShown = false;
  }

  void _showWarning() {
    final auth = context.read<AuthNotifier>();
    if (!auth.isAuthenticated || !mounted || _warningShown) return;

    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null) return;

    _warningShown = true;

    showDialog(
      context: navContext,
      barrierDismissible: false,
      builder: (c) => _WarningDialog(
        initialSeconds: widget.warningBefore.inSeconds,
        onContinue: () {
          Navigator.of(c, rootNavigator: true).pop();
          _warningShown = false;
          _restart();
        },
      ),
    );
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    _cancelAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) {
        if (!_warningShown) _restart();
      },
      onPointerMove: (_) {
        if (!_warningShown) _restart();
      },
      onPointerSignal: (_) {
        if (!_warningShown) _restart();
      },
      child: widget.child,
    );
  }
}

class _WarningDialog extends StatefulWidget {
  final int initialSeconds;
  final VoidCallback onContinue;

  const _WarningDialog({
    required this.initialSeconds,
    required this.onContinue,
  });

  @override
  State<_WarningDialog> createState() => _WarningDialogState();
}

class _WarningDialogState extends State<_WarningDialog> {
  late int _remaining;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.initialSeconds;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_remaining > 1) {
          _remaining--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
          SizedBox(width: 10),
          Text('Сессия истекает'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Вы не совершали никаких действий. В целях безопасности сессия будет автоматически завершена.',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withAlpha(100)),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: Colors.orange),
                const SizedBox(width: 8),
                Text(
                  'До выхода осталось: $_remaining сек.',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        FilledButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Продолжить работу'),
          onPressed: widget.onContinue,
        ),
      ],
    );
  }
}
