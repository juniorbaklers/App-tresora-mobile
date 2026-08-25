import 'package:flutter/material.dart';
import '../main.dart';
import '../theme/app_theme.dart';

/// Écran d'entrée affiché au lancement de l'app : le losange de marque
/// entre en scène (fondu + zoom) puis respire doucement le temps que
/// l'app bascule vers AuthGate.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _entree = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );
  late final AnimationController _respiration = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  late final Animation<double> _echelle = CurvedAnimation(parent: _entree, curve: Curves.easeOutBack);
  late final Animation<double> _opacite = CurvedAnimation(parent: _entree, curve: Curves.easeOut);
  late final Animation<double> _pouls = Tween(begin: 0.97, end: 1.04).animate(
    CurvedAnimation(parent: _respiration, curve: Curves.easeInOut),
  );

  @override
  void initState() {
    super.initState();
    _entree.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
  void dispose() {
    _entree.dispose();
    _respiration.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.indigoProfond,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entree, _respiration]),
          builder: (context, _) {
            return Opacity(
              opacity: _opacite.value,
              child: Transform.scale(
                scale: _echelle.value * _pouls.value,
                child: const _LosangeLogo(),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LosangeLogo extends StatelessWidget {
  const _LosangeLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: 0.7853981633974483, // 45°
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.or, width: 3),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.7853981633974483,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.or,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
