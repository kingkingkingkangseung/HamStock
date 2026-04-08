import 'package:flutter/material.dart';

void main() {
  runApp(const HamstockApp());
}

class HamstockApp extends StatelessWidget {
  const HamstockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamStock',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8860B)),
        useMaterial3: true,
      ),
      home: const HomeSkeletonPage(),
    );
  }
}

class HomeSkeletonPage extends StatelessWidget {
  const HomeSkeletonPage({super.key});

  void _toast(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(milliseconds: 900),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF3A2818);
    const bgBottom = Color(0xFF1C140D);
    const panel = Color(0xFFEAD9B5);
    const accent = Color(0xFFC49A3A);
    const positive = Color(0xFF127A3A);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [bgTop, bgBottom],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: panel.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: Column(
                    children: const [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '[재벌] HAMSTOCK',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF2E1E12),
                            ),
                          ),
                          Text(
                            '씨앗 120',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2E1E12),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '총 자산',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4C3827),
                            ),
                          ),
                          Text(
                            '₩12,350,000',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF6F4E16),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '총 수익',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4C3827),
                            ),
                          ),
                          Text(
                            '+85.4%',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: positive,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE6C47A), Color(0xFF8D6131)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    border: Border.all(color: accent, width: 2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 185,
                        height: 185,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFAEDCA),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.pets,
                          size: 100,
                          color: Color(0xFF7B4D1E),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          '상태: 재벌 햄스터',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF2E1E12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton(
                    onPressed: () => _toast(context, '투자 화면으로 이동 예정'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1D7F2B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      elevation: 8,
                    ),
                    child: const Text(
                      '투자하기',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: const [
                    Expanded(
                      child: _MetricBadge(
                        title: 'MDD',
                        value: '-12%',
                        background: Color(0xFFC33E36),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _MetricBadge(
                        title: '변동성',
                        value: '낮음',
                        background: Color(0xFF246DBA),
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: _MetricBadge(
                        title: '수익 안정',
                        value: '양호',
                        background: Color(0xFF1F8E42),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _BottomActionButton(
                        icon: Icons.quiz,
                        label: '퀴즈/미션',
                        colors: [Color(0xFF176D8B), Color(0xFF0A455E)],
                        onTap: () => _toast(context, '퀴즈/미션 탭 예정'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BottomActionButton(
                        icon: Icons.emoji_events,
                        label: '랭킹/비교',
                        colors: [Color(0xFF7D2A7C), Color(0xFF4B1849)],
                        onTap: () => _toast(context, '랭킹/비교 탭 예정'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _BottomActionButton(
                        icon: Icons.analytics,
                        label: '투자리포트',
                        colors: [Color(0xFF48611A), Color(0xFF2E3F10)],
                        onTap: () => _toast(context, '투자 리포트 탭 예정'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MetricBadge extends StatelessWidget {
  const _MetricBadge({
    required this.title,
    required this.value,
    required this.background,
  });

  final String title;
  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionButton extends StatelessWidget {
  const _BottomActionButton({
    required this.icon,
    required this.label,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 94,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(colors: colors),
            border: Border.all(color: const Color(0xFFD7AF5A), width: 1.5),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(height: 6),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
