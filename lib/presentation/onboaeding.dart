import 'package:flutter/material.dart';
import 'package:medora/main.dart';
import 'package:medora/presentation/login_screen.dart';
import '../services/art_painter.dart';

class _Info {
  final ArtKind art;
  final String title, body;

  const _Info(this.art, this.title, this.body);
}

const _pages = [
  _Info(ArtKind.shelf, 'Every medicine, one clear shelf',
      'Add medicines, group them by category and keep supplier and batch details in one place.'),
  _Info(ArtKind.scan, 'Stock in and out in seconds',
      'Record deliveries and sales as they happen so your counts always match the shelf.'),
  _Info(ArtKind.alert, 'Know before it runs out or expires',
      'Get alerts for low stock and nearing expiry dates so nothing goes to waste.'),
];

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _ctrl = PageController();
  int _page = 0;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _finish() => Navigator.of(context).pushReplacement(PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder: (_, __, ___) => const AuthGate(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
      ));

  void _next() => _page == _pages.length - 1
      ? _finish()
      : _ctrl.nextPage(
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kSurface2, kBg])),
        child: SafeArea(
          child: Column(children: [
            Align(
              alignment: Alignment.centerRight,
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 250),
                child: TextButton(
                    onPressed: last ? null : _finish,
                    child: const Text('Skip')),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _ctrl,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _page = i),
                itemBuilder: (_, i) {
                  final p = _pages[i];
                  final on = i == _page;
                  return AnimatedOpacity(
                    opacity: on ? 1 : .3,
                    duration: const Duration(milliseconds: 350),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedScale(
                              scale: on ? 1 : .8,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeOutBack,
                              child: SizedBox(
                                  width: 290,
                                  height: 290,
                                  child: FloatingArt(p.art)),
                            ),
                            const SizedBox(height: 32),
                            Text(
                              p.title,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 14),
                            Text(p.body,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: kMuted, fontSize: 16, height: 1.5)),
                          ]),
                    ),
                  );
                },
              ),
            ),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              for (var i = 0; i < _pages.length; i++)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.all(4),
                  height: 8,
                  width: i == _page ? 28 : 8,
                  decoration: BoxDecoration(
                      color: i == _page ? kAccent : kSurface2,
                      borderRadius: BorderRadius.circular(8)),
                ),
            ]),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                      backgroundColor: kAccent,
                      foregroundColor: kBg,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18))),
                  onPressed: _next,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(last ? 'Get started' : 'Next',
                        key: ValueKey(last),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// TextStyle display(double size) => GoogleFonts.fraunces(
//     fontSize: size, fontWeight: FontWeight.w600, color: kText, height: 1.15);
