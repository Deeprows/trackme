import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../services/settings_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onDone;
  const OnboardingScreen({super.key, required this.onDone});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final controller = PageController();
  int page = 0;
  static const icons = [
    Icons.touch_app_rounded,
    Icons.link_rounded,
    Icons.phone_android_rounded,
    Icons.health_and_safety_rounded,
  ];

  Future<void> _finish() async {
    await SettingsService.setOnboarded();
    widget.onDone();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = S.of(context).t;
    final primary = Theme.of(context).colorScheme.primary;
    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: TextButton(onPressed: _finish, child: Text(t('skip'))),
          ),
          Expanded(
            child: PageView.builder(
              controller: controller,
              itemCount: icons.length,
              onPageChanged: (i) => setState(() => page = i),
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.all(32),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(icons[i], size: 96, color: primary),
                  const SizedBox(height: 32),
                  Text(t('ob${i + 1}_t'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 16),
                  Text(t('ob${i + 1}_b'),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, height: 1.4, color: Colors.grey.shade700)),
                ]),
              ),
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < icons.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                width: i == page ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == page ? primary : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => page == icons.length - 1
                    ? _finish()
                    : controller.nextPage(
                        duration: const Duration(milliseconds: 250), curve: Curves.easeOut),
                child: Text(page == icons.length - 1 ? t('start') : t('next')),
              ),
            ),
          ),
        ]),
      ),
    );
  }
}
