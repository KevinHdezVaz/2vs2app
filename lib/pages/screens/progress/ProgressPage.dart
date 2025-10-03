import 'dart:async';
import 'dart:ui';

import 'package:Frutia/services/RachaProgreso.dart';
import 'package:Frutia/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

class DynamicTheme {
  final String imagePath;
  final Color accentTextColor;
  DynamicTheme({
    required this.imagePath,
    required this.accentTextColor,
  });
}

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({Key? key}) : super(key: key);

  @override
  _ProgressScreenState createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  int _currentStreak = 0;
  DateTime? _lastStreakUpdateDate;
  bool _isLoading = true;
  bool _isButtonLoading = false;
  String? _errorMessage;
  bool _hasActivePlan = false;
  // CAMBIO: Se añade estado para los días de inactividad
  int _daysSinceLastStreak = 0;
  String _userGoal = 'No definido';

  final double _startWeight = 85.0;
  final double _currentWeight = 78.5;

  late ScrollController _scrollController;
  late DynamicTheme _currentTheme;
  final double _stepHeight = 100.0;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('es_ES', null);
    _scrollController = ScrollController();
    _setCurrentTheme();
    _fetchProfileData();
  }

  Future<void> _fetchProfileData() async {
    try {
      final response = await RachaProgresoService.getProgresoWithUser();
      final profile = response['profile'];

      if (profile != null) {
        setState(() {
          _currentStreak = profile['racha_actual'] ?? 0;
          _userGoal = profile['goal'] ?? 'No definido'; // <--- AÑADE ESTA LÍNEA

          if (profile['ultima_fecha_racha'] != null) {
            _lastStreakUpdateDate =
                DateTime.parse(profile['ultima_fecha_racha']);
            final todayUTC = DateTime.now().toUtc();
            _daysSinceLastStreak =
                todayUTC.difference(_lastStreakUpdateDate!).inDays;
            print('--- DEBUG Racha ---');
            print('Racha actual: $_currentStreak');
            print(
                'Última fecha racha: $_lastStreakUpdateDate (UTC: ${_lastStreakUpdateDate?.toUtc()})');
            print('Hoy UTC: $todayUTC');
            print('Días sin racha: $_daysSinceLastStreak');
            print('-------------------');
          } else {
            _daysSinceLastStreak = 0;
          }

          _hasActivePlan = (profile['plan_setup_complete'] == true ||
              profile['plan_setup_complete'] == 1);
        });
      }

      setState(() {
        _isLoading = false;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _animateToCurrentStreak();
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error al cargar tu progreso: ${e.toString()}";
      });
    }
  }

  Future<void> _completeDay() async {
    if (!mounted) return;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    setState(() => _isButtonLoading = true);

    try {
      await RachaProgresoService.marcarDiaCompleto();
      if (!mounted) return;
      await _fetchProfileData(); // Recargamos para actualizar todo
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content:
              Text('¡Felicidades! Tu racha ahora es de $_currentStreak días.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isButtonLoading = false);
    }
  }

  bool _canCompleteToday() {
    if (_lastStreakUpdateDate == null) return true;
    final todayUTC = DateTime.now().toUtc();
    final lastUpdateUTC = _lastStreakUpdateDate!;
    return lastUpdateUTC.year != todayUTC.year ||
        lastUpdateUTC.month != todayUTC.month ||
        lastUpdateUTC.day != todayUTC.day;
  }

  void _setCurrentTheme() {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) {
      _currentTheme = DynamicTheme(
          imagePath: 'assets/images/dia.png',
          accentTextColor: const Color(0xFFF9A825));
    } else if (hour >= 12 && hour < 19) {
      _currentTheme = DynamicTheme(
          imagePath: 'assets/images/mediatarde.png',
          accentTextColor: const Color(0xFFD35400));
    } else {
      _currentTheme = DynamicTheme(
          imagePath: 'assets/images/noche.png',
          accentTextColor: const Color(0xFFF1C40F));
    }
  }

  void _animateToCurrentStreak() {
    if (!mounted || !_scrollController.hasClients) return;
    final targetOffset =
        (_currentStreak * _stepHeight) - (context.size!.height * 0.4);
    _scrollController.animateTo(
      targetOffset > 0 ? targetOffset : 0,
      duration: const Duration(milliseconds: 1500),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Tu Progreso',
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: const [Shadow(color: Colors.black26, blurRadius: 4)])),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          _AnimatedParallaxBackground(imagePath: _currentTheme.imagePath),
          SafeArea(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                    ? Center(
                        child: Text(_errorMessage!,
                            style: const TextStyle(color: Colors.white)))
                    : Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildHeaderInfo(),
                          const SizedBox(height: 16),
                          Expanded(child: _buildProgressTimeline()),
                          const SizedBox(height: 130),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    double weightChange = _currentWeight - _startWeight;
    bool canComplete = _canCompleteToday();
    // CAMBIO: La racha que se muestra visualmente se reinicia si hay 4 o más días de inactividad
    int displayedStreak = (_daysSinceLastStreak >= 4) ? 0 : _currentStreak;

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5)
              ]),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // CAMBIO: Se pasa la racha visual
              _buildStreakIndicator(displayedStreak),
              const SizedBox(width: 24),
              Container(width: 1, height: 60, color: Colors.grey.shade300),
              const SizedBox(width: 24),
              _buildGoalIndicator(_userGoal), // <--- REEMPLAZA CON ESTO
            ],
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.5, curve: Curves.easeOut),
        const SizedBox(height: 20),
        if (_hasActivePlan)
          _isButtonLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : ElevatedButton.icon(
                  icon: Icon(
                      canComplete
                          ? Icons.check_circle_outline_rounded
                          : Icons.check_circle_rounded,
                      color:
                          canComplete ? Colors.white : Colors.green.shade200),
                  label: Text(
                      canComplete ? "¡Cumplí mi día!" : "¡Ya cumpliste hoy!",
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: canComplete
                        ? _currentTheme.accentTextColor
                        : Colors.grey.shade600,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 15),
                    elevation: 8,
                    shadowColor: Colors.black.withOpacity(0.5),
                  ),
                  onPressed: canComplete ? _completeDay : null,
                ).animate().scale(delay: 500.ms),
      ],
    );
  }

  Widget _buildStreakIndicator(int displayedStreak) {
    return Column(
      children: [
        Text("Racha Actual",
            style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🔥', style: const TextStyle(fontSize: 28))
                .animate(onComplete: (c) => c.repeat(reverse: true))
                .scaleXY(end: 1.3, duration: 280.ms, curve: Curves.easeInOut),
            const SizedBox(width: 4),
            Text('$displayedStreak',
                style: GoogleFonts.poppins(
                    fontSize: 42,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primaryText,
                    height: 1.1)),
          ],
        ),
        Text("Días",
            style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText, fontSize: 14)),
      ],
    );
  }

// En ProgressScreen.dart

  Widget _buildGoalIndicator(String goal) {
    return Expanded(
      // Usamos Expanded para que el texto no se desborde
      child: Column(
        children: [
          Text("Tu Objetivo",
              style: GoogleFonts.lato(
                  color: FrutiaColors.secondaryText, fontSize: 14)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag_rounded, color: Colors.blue, size: 28),
              const SizedBox(width: 8),
              // Expanded aquí también para manejar textos largos de objetivos
              Expanded(
                child: Text(
                  goal,
                  style: GoogleFonts.poppins(
                      fontSize: 22, // Un poco más pequeño para que quepa mejor
                      fontWeight: FontWeight.bold,
                      color: FrutiaColors.primaryText),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis, // Evita que se desborde
                  maxLines: 2,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWeightIndicator(double weightChange) {
    return Column(
      children: [
        Text("Balance",
            style: GoogleFonts.lato(
                color: FrutiaColors.secondaryText, fontSize: 14)),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(
                weightChange <= 0
                    ? Icons.trending_down_rounded
                    : Icons.trending_up_rounded,
                color: Colors.green,
                size: 28),
            const SizedBox(width: 8),
            Text('${weightChange.abs().toStringAsFixed(1)} kg',
                style: GoogleFonts.poppins(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: FrutiaColors.primaryText)),
          ],
        )
      ],
    );
  }

  Widget _buildProgressTimeline() {
    // CAMBIO: La racha que se usa para dibujar la línea de tiempo también respeta la regla de los 4 días.
    final displayedStreak = (_daysSinceLastStreak >= 4) ? 0 : _currentStreak;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
            width: 4,
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.4),
                  Colors.white.withOpacity(0.1)
                ], begin: Alignment.topCenter, end: Alignment.bottomCenter))),
        ListView.builder(
          reverse: true,
          controller: _scrollController,
          padding: const EdgeInsets.symmetric(vertical: 20),
          // CAMBIO: El tamaño de la lista se basa en la racha visual.
          itemCount: displayedStreak + 10,
          itemBuilder: (context, index) {
            final stepNumber = index + 1;
            return _TimelineStepWidget(
              stepNumber: stepNumber,
              // CAMBIO: Se pasan ambos valores de racha y los días de inactividad.
              currentStreak: displayedStreak,
              daysSinceLastStreak: _daysSinceLastStreak,
              isMilestone: stepNumber % 7 == 0,
              isCurrent: stepNumber == displayedStreak,
              isLeftAligned: index.isEven,
              stepHeight: _stepHeight,
              accentColor: _currentTheme.accentTextColor,
            );
          },
        ),
      ],
    );
  }
}

class _TimelineStepWidget extends StatefulWidget {
  final int stepNumber;
  final int currentStreak;
  final bool isMilestone;
  final bool isCurrent;
  final bool isLeftAligned;
  final double stepHeight;
  final Color accentColor;
  // CAMBIO: Se añade para la lógica de la imagen triste.
  final int daysSinceLastStreak;

  const _TimelineStepWidget({
    required this.stepNumber,
    required this.currentStreak,
    required this.isMilestone,
    required this.isCurrent,
    required this.isLeftAligned,
    required this.stepHeight,
    required this.accentColor,
    required this.daysSinceLastStreak,
  });

  @override
  State<_TimelineStepWidget> createState() => _TimelineStepWidgetState();
}

class _TimelineStepWidgetState extends State<_TimelineStepWidget> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final bool isPast = widget.stepNumber < widget.currentStreak;
    final bool isFuture = widget.stepNumber > widget.currentStreak;

    return InkWell(
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      onTap: () {
        if (!isFuture) setState(() => _isExpanded = !_isExpanded);
      },
      child: SizedBox(
        height: widget.stepHeight,
        child: Row(
          children: [
            Expanded(
                child: widget.isLeftAligned
                    ? _buildStepCard(isPast, isFuture)
                    : const SizedBox()),
            _buildNode(),
            Expanded(
                child: !widget.isLeftAligned
                    ? _buildStepCard(isPast, isFuture)
                    : const SizedBox()),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * (widget.stepNumber % 10)).ms);
  }

  Widget _buildNode() {
    // CAMBIO: Lógica de imagen actualizada para mostrar la versión "triste".
    String imagePath;
    bool isSad =
        (widget.daysSinceLastStreak == 2 || widget.daysSinceLastStreak == 3);

    if (widget.currentStreak >= 30) {
      imagePath = isSad
          ? 'assets/images/frutaProgresoSad3.png'
          : 'assets/images/frutaProgreso3.png';
    } else if (widget.currentStreak >= 7) {
      imagePath = isSad
          ? 'assets/images/frutaProgresoSad2.png'
          : 'assets/images/frutaProgreso2.png';
    } else if (widget.currentStreak >= 2) {
      imagePath = isSad
          ? 'assets/images/frutaProgresoSad4.png'
          : 'assets/images/frutaProgreso4.png';
    } else {
      imagePath = isSad
          ? 'assets/images/frutaProgresoSad1.png'
          : 'assets/images/frutaProgreso1.png';
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
                color:
                    widget.isMilestone ? Colors.yellow.shade600 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white.withOpacity(0.5), width: 1))),
        if (widget.isCurrent)
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.accentColor.withOpacity(0.3)),
            child: Image.asset(imagePath, width: 150, height: 150)
                .animate()
                .scale(
                    delay: 300.ms, duration: 600.ms, curve: Curves.elasticOut),
          ),
      ],
    );
  }

  Widget _buildStepCard(bool isPast, bool isFuture) {
    final DateFormat formatter = DateFormat('EEEE d', 'es_ES');
    final date = DateTime.now()
        .subtract(Duration(days: widget.currentStreak - widget.stepNumber));
    return Align(
      alignment:
          widget.isLeftAligned ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeInOut,
          constraints: const BoxConstraints(maxWidth: 150),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFuture
                ? Colors.black.withOpacity(0.1)
                : Colors.black.withOpacity(0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: widget.isCurrent
                    ? widget.accentColor
                    : (widget.isMilestone
                        ? Colors.yellow.shade700
                        : Colors.white.withOpacity(0.2)),
                width: widget.isCurrent ? 2.0 : 1.0),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (widget.isMilestone)
                    Icon(Icons.military_tech_rounded,
                        color: Colors.yellow.shade700, size: 18)
                  else
                    Text('Día ${widget.stepNumber}',
                        style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: const [
                              Shadow(color: Colors.black26, blurRadius: 2)
                            ])),
                  if (widget.isMilestone) const SizedBox(width: 4),
                  if (widget.isMilestone)
                    Text('Hito',
                        style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [
                              const Shadow(color: Colors.black26, blurRadius: 2)
                            ])),
                  const Spacer(),
                  if (isPast)
                    const Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 18),
                ],
              ),
              AnimatedSize(
                duration: 300.ms,
                curve: Curves.easeInOut,
                child: SizedBox(
                  height: _isExpanded ? null : 0,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(formatter.format(date),
                        style: GoogleFonts.lato(
                            fontSize: 12, color: Colors.white70)),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedParallaxBackground extends StatefulWidget {
  final String imagePath;
  const _AnimatedParallaxBackground({Key? key, required this.imagePath})
      : super(key: key);

  @override
  State<_AnimatedParallaxBackground> createState() =>
      _AnimatedParallaxBackgroundState();
}

class _AnimatedParallaxBackgroundState
    extends State<_AnimatedParallaxBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Alignment> _animation;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(vsync: this, duration: const Duration(seconds: 90));
    _animation = TweenSequence<Alignment>([
      TweenSequenceItem(
          tween: AlignmentTween(
              begin: Alignment.center, end: Alignment.centerLeft),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(
              begin: Alignment.centerLeft, end: Alignment.centerRight),
          weight: 1),
      TweenSequenceItem(
          tween: AlignmentTween(
              begin: Alignment.centerRight, end: Alignment.center),
          weight: 1),
    ]).animate(_controller);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(widget.imagePath),
              fit: BoxFit.cover,
              alignment: _animation.value,
            ),
          ),
        );
      },
    );
  }
}
