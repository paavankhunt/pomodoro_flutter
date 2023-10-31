import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/painting.dart';

void main() => runApp(PomodoroApp());

class PomodoroApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pomodoro App',
      theme: ThemeData(primarySwatch: Colors.red),
      home: PomodoroScreen(),
    );
  }
}

class CircleArrowPainter extends CustomPainter {
  final Color arrowColor;
  final Color remainingColor;
  final Color dotColor;
  final int totalTimeInSeconds;

  CircleArrowPainter({
    required this.arrowColor,
    required this.remainingColor,
    required this.dotColor,
    required this.totalTimeInSeconds,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final circlePaint = Paint()..color = remainingColor;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    canvas.drawCircle(center, radius, circlePaint);

    final arrowPaint = Paint()..color = arrowColor;
    final path = Path();
    path.moveTo(center.dx, center.dy - radius * 1);
    path.lineTo(center.dx + radius * 0.05, center.dy);
    path.lineTo(center.dx, center.dy);
    path.close();
    canvas.drawPath(path, arrowPaint);

    final dotPaint = Paint()..color = dotColor;
    final dotRadius = 4.0;
    final dotSpacing = 2.0 * pi / (totalTimeInSeconds / 60);
    final startAngle = -pi / 2;

    for (int i = 0; i < (totalTimeInSeconds / 60); i++) {
      final angle = startAngle + dotSpacing * i;
      final dotCenterX = center.dx + radius * cos(angle);
      final dotCenterY = center.dy + radius * sin(angle);
      final dotCenter = Offset(dotCenterX, dotCenterY);
      canvas.drawCircle(dotCenter, dotRadius, dotPaint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}

class PomodoroScreen extends StatefulWidget {
  @override
  _PomodoroScreenState createState() => _PomodoroScreenState();
}

class _PomodoroScreenState extends State<PomodoroScreen>
    with TickerProviderStateMixin {
  Timer? _timer;
  int _workTime = 25 * 60; // 25 minutes in seconds
  int _breakTime = 5 * 60; // 5 minutes in seconds
  int _longBreakTime = 15 * 60; // 15 minutes in seconds
  int _sessionsCompleted = 0;
  bool _isWorking = true;
  bool _isPaused = false;
  int _timeRemaining = 0;
  int _totalTimeInSeconds = 0;
  late AnimationController _animationController;
  late Animation<double> _animation;

  late AudioPlayer audioPlayer;

  @override
  void initState() {
    super.initState();
    audioPlayer = AudioPlayer();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _workTime),
    );
    _animation = Tween(begin: 0.0, end: 1.0).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ))
      ..addListener(() {
        setState(
            () {}); // Trigger a rebuild whenever the animation value changes
      });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!_isPaused) {
      _timeRemaining = _workTime;
      _isWorking = true;
      _sessionsCompleted = 0;
    }

    _animationController.duration = Duration(seconds: _timeRemaining);
    _animationController.reset();
    _animationController.forward();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeRemaining > 0) {
          _timeRemaining--;
        } else {
          _timer?.cancel();
          _playSound();
          if (_isWorking) {
            _sessionsCompleted++;
            if (_sessionsCompleted % 4 == 0) {
              setState(() {
                _timeRemaining = _longBreakTime;
              });
              _totalTimeInSeconds = _longBreakTime;
              if (_timeRemaining == 0) {
                _animationController.stop();
              }
            } else {
              setState(() {
                _totalTimeInSeconds = _breakTime;
              });
              _timeRemaining = _breakTime;
              if (_timeRemaining == 0) {
                _animationController.stop();
              }
            }
            _isWorking = false;
          } else {
            _totalTimeInSeconds = _workTime;
            setState(() {
              _timeRemaining = _workTime;
            });
            if (_timeRemaining == 0) {
              _animationController.stop();
            }
            _isWorking = true;
          }
        }
      });
    });
    setState(() {
      _isPaused = false;
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _animationController.stop();
    setState(() {
      _isPaused = true;
    });
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeRemaining = _workTime;
      _totalTimeInSeconds = _workTime;
      _isWorking = true;
      _sessionsCompleted = 0;
    });
  }

  String _formatTime(int seconds) {
    int minutes = (seconds / 60).floor();
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void _playSound() async {
    audioPlayer.stop();
    await audioPlayer
        .play(UrlSource('https://bigsoundbank.com/UPLOAD/wav/0022.wav'));
    // Timer(Duration(seconds: 4), () {
    //   audioPlayer.stop();
    // });
    // UrlSource('https://www.pachd.com/sfx/group-laughing-2.wav'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pomodoro Timer')),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/nature_background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _isWorking ? 'Work' : 'Break',
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
              SizedBox(height: 80),
              // RotationTransition(
              //   turns: _animation,
              //   child: Container(
              //     width: 200,
              //     height: 200,
              //     decoration: BoxDecoration(
              //       shape: BoxShape.circle,
              //       color: Colors.blue,
              //     ),
              //     child: Center(
              //       child: Icon(
              //         _isWorking ? Icons.arrow_upward : Icons.arrow_downward,
              //         size: 60,
              //         color: Colors.white,
              //       ),
              //     ),
              //   ),
              // ),
              CustomPaint(
                painter: CircleArrowPainter(
                  arrowColor: _isWorking ? Colors.green : Colors.blue,
                  remainingColor: Colors.red,
                  dotColor: Colors.green,
                  totalTimeInSeconds: _totalTimeInSeconds,
                ),
                child: Container(
                  width: 200,
                  height: 200,
                  child: RotationTransition(
                    turns: _animation,
                    child: const Icon(
                      Icons.arrow_upward,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                _formatTime(_timeRemaining),
                style: TextStyle(
                  fontSize: 60,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    child: Text(_isPaused ? 'Start' : 'Stop'),
                    onPressed: _isPaused ? _startTimer : _pauseTimer,
                  ),
                  SizedBox(width: 20),
                  ElevatedButton(
                    child: Text('Reset'),
                    onPressed: _resetTimer,
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
