import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'api/hamstock_api.dart';

void main() {
  runApp(const HamstockApp());
}

class HamstockApp extends StatelessWidget {
  const HamstockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'HamStock',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFB8860B)),
        scaffoldBackgroundColor: const Color(0xFFF7F7FA),
        useMaterial3: true,
      ),
      home: const AuthPage(),
    );
  }
}

String get _defaultBaseUrl {
  if (kIsWeb) return 'http://localhost:3000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:3000';
  }
  return 'http://localhost:3000';
}

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  late final HamstockApi _api = HamstockApi(_defaultBaseUrl);
  final _emailController = TextEditingController(text: 'test@hamstock.com');
  final _passwordController = TextEditingController(text: '123456');
  final _nicknameController = TextEditingController(text: '햄스터');
  bool _isLogin = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final nickname = _nicknameController.text.trim();
      final result = _isLogin
          ? await _api.login(
              email: email,
              password: password,
            )
          : await _api.signup(
              email: email,
              password: password,
              nickname: nickname,
            );
      final user = Map<String, dynamic>.from(result['user'] as Map);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => HomeSkeletonPage(api: _api, user: user),
        ),
      );
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF3A2818), Color(0xFF1C140D)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF6DF),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFC49A3A), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.22),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'HAMSTOCK',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF2E1E12),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isLogin ? '로그인' : '회원가입',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6F4E16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: '이메일',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: '비밀번호',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    if (!_isLogin) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _nicknameController,
                        decoration: const InputDecoration(
                          labelText: '닉네임',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: const TextStyle(
                          color: Color(0xFFC33E36),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton(
                      onPressed: _loading ? null : _submit,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF128B2F),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: Text(
                        _loading ? '처리 중...' : (_isLogin ? '로그인' : '가입하기'),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => setState(() {
                                _isLogin = !_isLogin;
                                _error = null;
                              }),
                      child: Text(_isLogin ? '계정이 없으면 회원가입' : '이미 계정이 있으면 로그인'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeSkeletonPage extends StatefulWidget {
  const HomeSkeletonPage({
    super.key,
    required this.api,
    required this.user,
  });

  final HamstockApi api;
  final Map<String, dynamic> user;

  @override
  State<HomeSkeletonPage> createState() => _HomeSkeletonPageState();
}

class _HomeSkeletonPageState extends State<HomeSkeletonPage> {
  Map<String, dynamic>? _dashboard;
  bool _loadingDashboard = false;

  int get _userId => ((widget.user['id'] as num?) ?? 1).toInt();

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (_loadingDashboard) return;
    setState(() => _loadingDashboard = true);
    try {
      final dashboard = await widget.api.getDashboard(_userId);
      if (mounted) setState(() => _dashboard = dashboard);
    } catch (_) {
      // 홈은 앱 진입 화면이므로 대시보드 실패 시 기본값으로 계속 렌더링한다.
    } finally {
      if (mounted) setState(() => _loadingDashboard = false);
    }
  }

  int _stageFor(num totalAsset) {
    if (totalAsset < 6000000) return 1;
    if (totalAsset < 9000000) return 2;
    if (totalAsset < 12000000) return 3;
    if (totalAsset < 16000000) return 4;
    return 5;
  }

  String _stageTitle(int stage) {
    return switch (stage) {
      1 => '위기',
      2 => '노력',
      3 => '보통',
      4 => '여유',
      _ => '재벌',
    };
  }

  String _stageStatus(int stage) {
    return switch (stage) {
      1 => '위기의 햄스터',
      2 => '노력하는 햄스터',
      3 => '보통 햄스터',
      4 => '여유로운 햄스터',
      _ => '재벌 햄스터',
    };
  }

  void _logout() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthPage()),
      (_) => false,
    );
  }

  Future<void> _exchangeSeeds() async {
    try {
      final result = await widget.api.exchangeSeeds(userId: _userId);
      final cashAdded = (result['cashAdded'] as num?) ?? 0;
      _showToast(context, '${_formatWon(cashAdded)} 전환 완료');
      await _loadDashboard();
    } catch (e) {
      final message = e.toString().replaceFirst('Exception: ', '');
      _showToast(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF3A2818);
    const bgBottom = Color(0xFF1C140D);
    const panel = Color(0xFFF0E1BE);
    const accent = Color(0xFFC49A3A);
    const positive = Color(0xFF127A3A);
    const negative = Color(0xFFC33E36);
    final dashboard = _dashboard ?? const <String, dynamic>{};
    final totalAsset = (dashboard['totalAsset'] as num?) ?? 10000000;
    final returnRate = (dashboard['returnRate'] as num?) ?? 0;
    final seed = (dashboard['seed'] as num?) ?? 0;
    final mdd = (dashboard['mdd'] as num?) ?? (returnRate < 0 ? returnRate : 0);
    final volatilityLabel =
        (dashboard['volatilityLabel'] ?? '낮음').toString();
    final stabilityLabel = (dashboard['stabilityLabel'] ?? '양호').toString();
    final hamsterMessage =
        (dashboard['hamsterMessage'] ?? '포트폴리오를 확인해보자.').toString();
    final stage = _stageFor(totalAsset);
    final stageTitle = _stageTitle(stage);
    final stageStatus = _stageStatus(stage);
    final mainImagePath = 'assets/images/main_$stage.webp';
    final returnColor = returnRate >= 0 ? positive : negative;

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
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final h = constraints.maxHeight;
                final bottomBtnH = (h * 0.095).clamp(68.0, 86.0);
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                      decoration: BoxDecoration(
                        color: panel.withOpacity(0.96),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '[$stageTitle] HAMSTOCK',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF2E1E12),
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '씨앗 $seed',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF2E1E12),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _exchangeSeeds,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFB98D23)
                                            .withOpacity(0.22),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                        border: Border.all(
                                          color: const Color(0xFFB98D23),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Text(
                                        '전환',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF6F4E16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  GestureDetector(
                                    onTap: _logout,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF2E1E12)
                                            .withOpacity(0.12),
                                        borderRadius:
                                            BorderRadius.circular(999),
                                      ),
                                      child: const Text(
                                        '로그아웃',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFF2E1E12),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              hamsterMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF6F4E16),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '총 자산',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4C3827),
                                ),
                              ),
                              Text(
                                _formatWon(totalAsset),
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF6F4E16),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                '총 수익',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF4C3827),
                                ),
                              ),
                              Text(
                                _formatSignedPercent(returnRate),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: returnColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
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
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.asset(
                                  mainImagePath,
                                  fit: BoxFit.cover,
                                  alignment: const Alignment(0, -0.55),
                                  width: double.infinity,
                                  filterQuality: FilterQuality.high,
                                  errorBuilder: (_, __, ___) => Container(
                                    color: const Color(0xFFFAEDCA),
                                    child: const Icon(
                                      Icons.pets,
                                      size: 100,
                                      color: Color(0xFF7B4D1E),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '상태: $stageStatus',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2E1E12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: _AspectImageButton(
                        imagePath: 'assets/images/btn_invest.png',
                        aspectRatio: 1194 / 265,
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => StockHomePage(
                                api: widget.api,
                                userId: _userId,
                              ),
                            ),
                          );
                          if (mounted) await _loadDashboard();
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricBadge(
                            title: 'MDD',
                            value: _formatSignedPercent(mdd),
                            background: negative,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricBadge(
                            title: '변동성',
                            value: volatilityLabel,
                            background: const Color(0xFF246DBA),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _MetricBadge(
                            title: '수익 안정',
                            value: stabilityLabel,
                            background: stabilityLabel == '주의'
                                ? negative
                                : const Color(0xFF1F8E42),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _BottomWideImageButton(
                            imagePath: 'assets/images/btn_quiz_mission.png',
                            height: bottomBtnH,
                            onTap: () async {
                              final changed =
                                  await Navigator.of(context).push<bool>(
                                MaterialPageRoute(
                                  builder: (_) => QuizMissionPage(
                                    api: widget.api,
                                    userId: _userId,
                                  ),
                                ),
                              );
                              if (changed == true && mounted) {
                                await _loadDashboard();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BottomWideImageButton(
                            imagePath: 'assets/images/btn_rank.png',
                            height: bottomBtnH,
                            onTap: () => _showToast(context, '랭킹/비교 탭 예정'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _BottomWideImageButton(
                            imagePath: 'assets/images/btn_investrep.png',
                            height: bottomBtnH,
                            onTap: () => _showToast(context, '투자 리포트 탭 예정'),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class QuizMissionPage extends StatefulWidget {
  const QuizMissionPage({
    super.key,
    required this.api,
    required this.userId,
  });

  final HamstockApi api;
  final int userId;

  @override
  State<QuizMissionPage> createState() => _QuizMissionPageState();
}

class _QuizMissionPageState extends State<QuizMissionPage> {
  Map<String, dynamic>? _quiz;
  Map<String, dynamic>? _result;
  bool _loading = true;
  bool _submitting = false;
  bool _changed = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadQuestion();
  }

  Future<void> _loadQuestion() async {
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final quiz = await widget.api.getQuiz(userId: widget.userId);
      if (mounted) setState(() => _quiz = quiz);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submitAnswer(String answer) async {
    final question = _quiz?['question'];
    final questionId = question is Map ? (question['id'] as num?)?.toInt() : null;
    if (questionId == null || _submitting || _result != null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.api.submitQuiz(
        userId: widget.userId,
        questionId: questionId,
        answer: answer,
      );
      final seedAwarded = (result['seedAwarded'] as num?) ?? 0;
      if (seedAwarded > 0) _changed = true;
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _close() {
    Navigator.of(context).pop(_changed);
  }

  @override
  Widget build(BuildContext context) {
    const bgTop = Color(0xFF3A2818);
    const bgBottom = Color(0xFF1C140D);
    const panel = Color(0xFFF3E3BB);
    const gold = Color(0xFFB98D23);
    const green = Color(0xFF15803D);
    const red = Color(0xFFD13D36);
    final quiz = _quiz ?? const <String, dynamic>{};
    final question = quiz['question'] is Map
        ? Map<String, dynamic>.from(quiz['question'] as Map)
        : const <String, dynamic>{};
    final seed = (quiz['seed'] as num?) ?? (_result?['seed'] as num?) ?? 0;
    final remaining =
        (_result?['remaining'] as num?) ?? (quiz['remaining'] as num?) ?? 0;
    final todayAwarded =
        (_result?['todayAwarded'] as num?) ?? (quiz['todayAwarded'] as num?) ?? 0;
    final dailyLimit =
        (_result?['dailyLimit'] as num?) ?? (quiz['dailyLimit'] as num?) ?? 5;
    final correct = _result?['correct'] == true;

    return WillPopScope(
      onWillPop: () async {
        _close();
        return false;
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [bgTop, bgBottom],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: _close,
                        icon: const Icon(Icons.arrow_back_ios_new),
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      const Expanded(
                        child: Text(
                          '퀴즈/미션',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: panel,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: gold, width: 1.5),
                        ),
                        child: Text(
                          '씨앗 $seed',
                          style: const TextStyle(
                            color: Color(0xFF2E1E12),
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: panel,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: gold, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF2E1E12),
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    child: Text(
                                      (question['category'] ?? '금융 퀴즈')
                                          .toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '오늘 $todayAwarded/$dailyLimit개 획득',
                                    style: const TextStyle(
                                      color: Color(0xFF6F4E16),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'OX 금융 퀴즈',
                                style: TextStyle(
                                  color: Color(0xFF2E1E12),
                                  fontSize: 25,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '정답 시 해바라기씨 1개 지급, 하루 최대 5개까지 받을 수 있습니다. 남은 획득 가능 씨앗은 $remaining개입니다.',
                                style: const TextStyle(
                                  color: Color(0xFF6F4E16),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),
                              if (_loading)
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(36),
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              else if (_error != null)
                                _QuizMessageCard(
                                  color: red,
                                  title: '불러오기 실패',
                                  message: _error!,
                                )
                              else
                                Text(
                                  question['text']?.toString() ?? '',
                                  style: const TextStyle(
                                    color: Color(0xFF1B160F),
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    height: 1.35,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        if (!_loading && _error == null) ...[
                          Row(
                            children: [
                              Expanded(
                                child: _OxButton(
                                  label: 'O',
                                  subtitle: '맞다',
                                  color: green,
                                  disabled: _submitting || _result != null,
                                  onTap: () => _submitAnswer('O'),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _OxButton(
                                  label: 'X',
                                  subtitle: '아니다',
                                  color: red,
                                  disabled: _submitting || _result != null,
                                  onTap: () => _submitAnswer('X'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                        ],
                        if (_submitting)
                          const Center(child: CircularProgressIndicator()),
                        if (_result != null)
                          _QuizResultCard(
                            correct: correct,
                            answer: (_result!['answer'] ?? '').toString(),
                            explanation:
                                (_result!['explanation'] ?? '').toString(),
                            seedAwarded:
                                ((_result!['seedAwarded'] as num?) ?? 0).toInt(),
                            onNext: _loadQuestion,
                          ),
                      ],
                    ),
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

class _OxButton extends StatelessWidget {
  const _OxButton({
    required this.label,
    required this.subtitle,
    required this.color,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final Color color;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: disabled ? null : onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 140),
        opacity: disabled ? 0.55 : 1,
        child: Container(
          height: 128,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withOpacity(0.96), color.withOpacity(0.72)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: Colors.white.withOpacity(0.45), width: 1),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.32),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 54,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuizMessageCard extends StatelessWidget {
  const _QuizMessageCard({
    required this.color,
    required this.title,
    required this.message,
  });

  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF2E1E12),
              fontSize: 14,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuizResultCard extends StatelessWidget {
  const _QuizResultCard({
    required this.correct,
    required this.answer,
    required this.explanation,
    required this.seedAwarded,
    required this.onNext,
  });

  final bool correct;
  final String answer;
  final String explanation;
  final int seedAwarded;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final color = correct ? const Color(0xFF15803D) : const Color(0xFFD13D36);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.96),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.38), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 8),
              Text(
                correct ? '맞았다!' : '틀렸다!',
                style: TextStyle(
                  color: color,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E3BB),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  seedAwarded > 0 ? '+씨앗 $seedAwarded' : '정답 $answer',
                  style: const TextStyle(
                    color: Color(0xFF6F4E16),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '정답: $answer',
            style: const TextStyle(
              color: Color(0xFF1B160F),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            explanation,
            style: const TextStyle(
              color: Color(0xFF4C3827),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E1E12),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                '다음 문제',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum StockCategory {
  holdings('내 보유 주식'),
  marketCap('시가총액순'),
  volume('거래량순'),
  rising('급상승순');

  const StockCategory(this.label);
  final String label;
}

class StockHomePage extends StatefulWidget {
  const StockHomePage({
    super.key,
    required this.api,
    required this.userId,
  });

  final HamstockApi api;
  final int userId;

  @override
  State<StockHomePage> createState() => _StockHomePageState();
}

class _StockHomePageState extends State<StockHomePage> {
  final TextEditingController _searchController = TextEditingController();
  StockCategory _category = StockCategory.marketCap;
  Map<String, dynamic> _dashboard = const {};
  List<Map<String, dynamic>> _stocks = const [];
  bool _loadingDashboard = true;
  bool _loadingStocks = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _refreshAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshAll() async {
    await Future.wait([_loadDashboard(), _loadStocks()]);
  }

  Future<void> _loadDashboard() async {
    setState(() => _loadingDashboard = true);
    try {
      final data = await widget.api.getDashboard(widget.userId);
      if (!mounted) return;
      setState(() {
        _dashboard = data.isEmpty ? _sampleDashboard : data;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _dashboard = _sampleDashboard;
      });
    } finally {
      if (mounted) {
        setState(() => _loadingDashboard = false);
      }
    }
  }

  Future<void> _loadStocks() async {
    setState(() {
      _loadingStocks = true;
      _error = null;
    });
    try {
      final query = _searchController.text.trim();
      late List<dynamic> raw;
      if (_category == StockCategory.holdings) {
        raw = await widget.api.getHoldings(userId: widget.userId);
      } else if (_category == StockCategory.marketCap) {
        raw = await widget.api.getStocks(
          q: query.isEmpty ? null : query,
          sort: 'marketCap',
          order: 'desc',
        );
      } else if (_category == StockCategory.volume) {
        raw = await widget.api.getStocks(
          q: query.isEmpty ? null : query,
          sort: 'volume',
          order: 'desc',
        );
      } else {
        raw = await widget.api.getStocks(
          q: query.isEmpty ? null : query,
          sort: 'changeRate',
          order: 'desc',
        );
      }

      final rows = raw
          .map((e) => _normalizeStockRow(Map<String, dynamic>.from(e as Map)))
          .where((map) {
            if (_category != StockCategory.holdings || query.isEmpty) {
              return true;
            }
            final name = (map['name'] ?? '').toString().toLowerCase();
            final code = (map['code'] ?? '').toString().toLowerCase();
            final q = query.toLowerCase();
            return name.contains(q) || code.contains(q);
          })
          .toList(growable: false);

      if (!mounted) return;
      setState(() {
        _stocks = rows;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _stocks = const [];
      });
    } finally {
      if (mounted) {
        setState(() => _loadingStocks = false);
      }
    }
  }

  Map<String, dynamic> _normalizeStockRow(Map<String, dynamic> row) {
    final nestedStock = row['stock'];
    final stock = nestedStock is Map
        ? Map<String, dynamic>.from(nestedStock)
        : <String, dynamic>{};
    final merged = <String, dynamic>{...stock, ...row};
    if (stock.isNotEmpty) {
      merged.remove('stock');
      merged['portfolioId'] = row['id'];
    }

    final quantity = _asNum(merged['quantity']);
    final avgPrice = _asNum(merged['avgPrice']);
    if (quantity != null && avgPrice != null) {
      final price = _asNum(merged['price']) ?? 0;
      final purchaseAmount =
          _asNum(merged['purchaseAmount']) ?? quantity * avgPrice;
      final evaluationAmount =
          _asNum(merged['evaluationAmount']) ?? quantity * price;
      final profitLoss =
          _asNum(merged['profitLoss']) ?? evaluationAmount - purchaseAmount;
      final returnRate = _asNum(merged['returnRate']) ??
          (purchaseAmount == 0 ? 0 : (profitLoss / purchaseAmount) * 100);

      return {
        ...merged,
        'purchaseAmount': purchaseAmount,
        'evaluationAmount': evaluationAmount,
        'profitLoss': profitLoss,
        'returnRate': returnRate,
      };
    }

    return merged;
  }

  num? _asNum(dynamic value) {
    if (value is num) return value;
    return num.tryParse(value?.toString() ?? '');
  }

  Future<void> _openHistorySheet() async {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      builder: (context) {
        return FutureBuilder<List<dynamic>>(
          future: widget.api.getOrderHistory(userId: widget.userId),
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snapshot.hasError) {
              return SizedBox(
                height: 240,
                child: Center(
                  child: Text(
                    '거래내역을 불러오지 못했습니다.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              );
            }

            final items = snapshot.data ?? const [];
            if (items.isEmpty) {
              return const SizedBox(
                height: 240,
                child: Center(child: Text('거래내역이 없습니다.')),
              );
            }

            return SafeArea(
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final order = Map<String, dynamic>.from(items[index] as Map);
                  final isBuy = (order['type'] ?? '') == 'BUY';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${order['stock']?['name'] ?? '종목'} ${isBuy ? '매수' : '매도'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      '${_formatDate(order['createdAt'])} · ${order['quantity'] ?? 0}주',
                    ),
                    trailing: Text(
                      _formatWon(order['totalPrice'] ?? 0),
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: isBuy ? const Color(0xFFE1525C) : const Color(0xFF2678D2),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalAsset = (_dashboard['totalAsset'] ?? _sampleDashboard['totalAsset']) as num;
    final profitLoss = (_dashboard['totalProfitLoss'] ??
        _dashboard['evaluationProfitLoss'] ??
        _sampleDashboard['totalProfitLoss'] ??
        _sampleDashboard['evaluationProfitLoss']) as num;
    final returnRate =
        (_dashboard['returnRate'] ?? _sampleDashboard['returnRate']) as num;
    final holdingsCount =
        (_dashboard['holdingsCount'] ?? _sampleDashboard['holdingsCount']) as num;
    final cashBalance =
        (_dashboard['cashBalance'] ?? _sampleDashboard['cashBalance']) as num;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        padding: EdgeInsets.zero,
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        '투자하기',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF121212),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: _refreshAll,
                        icon: const Icon(Icons.refresh_rounded),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
                  child: _loadingDashboard
                      ? const _DashboardSkeleton()
                      : _InvestmentDashboardCard(
                          totalAsset: totalAsset,
                          profitLoss: profitLoss,
                          returnRate: returnRate,
                          holdingsCount: holdingsCount.toInt(),
                          cashBalance: cashBalance,
                          onHistoryTap: _openHistorySheet,
                        ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                  child: _SearchBar(
                    controller: _searchController,
                    onSubmitted: (_) => _loadStocks(),
                    onSearchTap: _loadStocks,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                  child: _CategoryTabs(
                    value: _category,
                    onChanged: (next) {
                      if (_category == next) return;
                      setState(() => _category = next);
                      _loadStocks();
                    },
                  ),
                ),
              ),
              if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
                    child: Text(
                      _error!,
                      style: const TextStyle(
                        color: Color(0xFFD04747),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (_loadingStocks)
                const SliverPadding(
                  padding: EdgeInsets.fromLTRB(18, 18, 18, 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      _stockSkeletonBuilder,
                      childCount: 6,
                    ),
                  ),
                )
              else if (_stocks.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 24, 18, 30),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFE8EBF2)),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.inbox_outlined,
                            size: 42,
                            color: Color(0xFF9AA2B1),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _category == StockCategory.holdings
                                ? '보유 중인 종목이 없습니다.'
                                : '검색 결과가 없습니다.',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            '검색어를 바꾸거나 다른 카테고리를 선택해보세요.',
                            style: TextStyle(color: Color(0xFF7A8190)),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final stock = _stocks[index];
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom: index == _stocks.length - 1 ? 0 : 12,
                          ),
                          child: _StockListTile(
                            rank: index + 1,
                            stock: stock,
                            category: _category,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => StockDetailPage(
                                    stock: stock,
                                    api: widget.api,
                                    userId: widget.userId,
                                    onOrderCompleted: _refreshAll,
                                  ),
                                ),
                              );
                              if (context.mounted) {
                                await _refreshAll();
                              }
                            },
                          ),
                        );
                      },
                      childCount: _stocks.length,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class StockDetailPage extends StatefulWidget {
  const StockDetailPage({
    super.key,
    required this.stock,
    required this.api,
    required this.userId,
    this.onOrderCompleted,
  });

  final Map<String, dynamic> stock;
  final HamstockApi api;
  final int userId;
  final Future<void> Function()? onOrderCompleted;

  @override
  State<StockDetailPage> createState() => _StockDetailPageState();
}

enum StockDetailTab { chart, info, detail }

class _StockDetailPageState extends State<StockDetailPage> {
  static const _ranges = ['1D', '1W', '3M', '1Y'];

  String _selectedRange = '3M';
  StockDetailTab _selectedTab = StockDetailTab.chart;
  bool _loadingChart = true;
  bool _loadingDetail = true;
  String? _chartError;
  String? _detailError;
  Map<String, dynamic>? _chart;
  Map<String, dynamic>? _detail;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    await Future.wait([_loadChart(), _loadDetail()]);
  }

  Future<void> _loadChart([String? range]) async {
    final nextRange = range ?? _selectedRange;
    setState(() {
      _selectedRange = nextRange;
      _loadingChart = true;
      _chartError = null;
    });

    try {
      final data = await widget.api.getChart(
        code: (widget.stock['code'] ?? '').toString(),
        market: (widget.stock['market'] ?? '').toString(),
        range: nextRange,
      );
      if (!mounted) return;
      setState(() {
        _chart = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chartError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingChart = false;
        });
      }
    }
  }

  Future<void> _loadDetail() async {
    setState(() {
      _loadingDetail = true;
      _detailError = null;
    });

    try {
      final data = await widget.api.getStockDetail(
        code: (widget.stock['code'] ?? '').toString(),
        market: (widget.stock['market'] ?? '').toString(),
      );
      if (!mounted) return;
      setState(() {
        _detail = data;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _detailError = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingDetail = false;
        });
      }
    }
  }

  Future<void> _openOrderSheet(String side) async {
    final ordered = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _OrderSheet(
        api: widget.api,
        userId: widget.userId,
        stock: widget.stock,
        side: side,
        currency: _stockCurrency(widget.stock, chart: _chart),
      ),
    );

    if (ordered == true && mounted) {
      await Future.wait([
        _loadChart(),
        _loadDetail(),
        if (widget.onOrderCompleted != null) widget.onOrderCompleted!(),
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final company =
        Map<String, dynamic>.from((_detail?['company'] as Map?) ?? const {});
    final metrics =
        Map<String, dynamic>.from((_detail?['metrics'] as Map?) ?? const {});
    final detail =
        Map<String, dynamic>.from((_detail?['detail'] as Map?) ?? const {});
    final news = ((detail['news'] as List?) ?? const [])
        .map((item) => Map<String, dynamic>.from(item as Map))
        .toList(growable: false);

    final currency = _stockCurrency(stock, chart: _chart);
    final chartPrice =
        (_chart?['currentPrice'] as num?) ??
        (metrics['currentPrice'] as num?) ??
        ((stock['price'] ?? 0) as num);
    final previousClose =
        (_chart?['previousClose'] as num?) ??
        (metrics['previousClose'] as num?) ??
        0;
    final priceDiff = previousClose == 0 ? 0 : chartPrice - previousClose;
    final changeRate = previousClose == 0
        ? ((metrics['changeRate'] as num?) ??
            ((stock['changeRate'] ?? 0) as num))
        : (priceDiff / previousClose) * 100;
    final positive = changeRate >= 0;
    final color =
        positive ? const Color(0xFFE84E5C) : const Color(0xFF2871D7);
    final points = ((_chart?['points'] as List?) ?? const [])
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList(growable: false);
    final closes = points
        .map((point) => (point['close'] as num?)?.toDouble())
        .whereType<double>()
        .toList(growable: false);
    final minClose = (_chart?['minClose'] as num?)?.toDouble() ??
        (closes.isEmpty ? 0 : closes.reduce((a, b) => a < b ? a : b));
    final maxClose = (_chart?['maxClose'] as num?)?.toDouble() ??
        (closes.isEmpty ? 0 : closes.reduce((a, b) => a > b ? a : b));

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 34),
                    padding: EdgeInsets.zero,
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.search_rounded, size: 34),
                    padding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 0),
              child: Row(
                children: [
                  _StockAvatar(stock: stock, size: 74),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${stock['name'] ?? '종목'} ${stock['code'] ?? ''}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF6F7888),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatMoney(chartPrice, currency: currency),
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '전일 대비 ${_formatSignedMoney(priceDiff, currency: currency)} (${_formatSignedPercent(changeRate)})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.favorite_border_rounded,
                    color: Color(0xFFE0E0E0),
                    size: 36,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(
                children: [
                  _DetailTab(
                    label: '차트',
                    selected: _selectedTab == StockDetailTab.chart,
                    onTap: () => setState(() => _selectedTab = StockDetailTab.chart),
                  ),
                  _DetailTab(
                    label: '종목 정보',
                    selected: _selectedTab == StockDetailTab.info,
                    onTap: () => setState(() => _selectedTab = StockDetailTab.info),
                  ),
                  _DetailTab(
                    label: '상세 정보',
                    selected: _selectedTab == StockDetailTab.detail,
                    onTap: () => setState(() => _selectedTab = StockDetailTab.detail),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                child: switch (_selectedTab) {
                  StockDetailTab.chart => Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 360,
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(0, 14, 0, 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF7F8FC),
                            borderRadius: BorderRadius.circular(24),
                            border:
                                Border.all(color: const Color(0xFFE8EBF2)),
                          ),
                          child: _loadingChart
                              ? const Center(child: CircularProgressIndicator())
                              : _chartError != null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 20),
                                        child: Text(
                                          _chartError!,
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            color: Color(0xFFD04747),
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Stack(
                                      children: [
                                        Positioned.fill(
                                          child: Padding(
                                            padding: const EdgeInsets.fromLTRB(
                                                16, 16, 16, 22),
                                            child: CustomPaint(
                                              painter: _ChartPainter(
                                                values: closes,
                                                positive: positive,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 12,
                                          top: 10,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 6,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              _formatMoney(
                                                chartPrice,
                                                currency: currency,
                                              ),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: 18,
                                          bottom: 12,
                                          child: Text(
                                            '최저 ${_formatMoney(minClose, currency: currency)}',
                                            style: const TextStyle(
                                              color: Color(0xFF6F88E8),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          right: 18,
                                          top: 46,
                                          child: Text(
                                            '최고 ${_formatMoney(maxClose, currency: currency)}',
                                            style: const TextStyle(
                                              color: Color(0xFFE86767),
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _ranges
                              .map(
                                (label) => Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: label == _ranges.last ? 0 : 10,
                                    ),
                                    child: _RangeChip(
                                      label: label,
                                      selected: _selectedRange == label,
                                      onTap: () => _loadChart(label),
                                    ),
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                      ],
                    ),
                  StockDetailTab.info => _loadingDetail
                      ? const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _detailError != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Text(
                                  _detailError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFD04747),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoSectionCard(
                                  title: '종목 요약',
                                  child: Text(
                                    (detail['overview'] ??
                                            company['longBusinessSummary'] ??
                                            '기업 설명이 아직 없습니다.')
                                        .toString(),
                                    style: const TextStyle(
                                      height: 1.7,
                                      fontSize: 16,
                                      color: Color(0xFF333845),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _InfoSectionCard(
                                  title: '핵심 지표',
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '시가총액',
                                              value: _formatMoney(
                                                (metrics['marketCap'] ?? 0) as num,
                                                currency: currency,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: 'PER',
                                              value: _formatOptionalNumber(
                                                metrics['trailingPE'],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: 'PBR',
                                              value: _formatOptionalNumber(
                                                metrics['priceToBook'],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: 'EPS',
                                              value: _formatOptionalNumber(
                                                metrics['eps'],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '52주 최고',
                                              value: _formatOptionalMoney(
                                                metrics['fiftyTwoWeekHigh'],
                                                currency: currency,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '52주 최저',
                                              value: _formatOptionalMoney(
                                                metrics['fiftyTwoWeekLow'],
                                                currency: currency,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '업종',
                                              value:
                                                  (company['industry'] ?? '-')
                                                      .toString(),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '섹터',
                                              value: (company['sector'] ?? '-')
                                                  .toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '거래량',
                                              value: _formatPlainInteger(
                                                metrics['volume'],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: _InfoMetricTile(
                                              label: '거래소',
                                              value:
                                                  (company['exchange'] ?? '-')
                                                      .toString(),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                  StockDetailTab.detail => _loadingDetail
                      ? const Padding(
                          padding: EdgeInsets.only(top: 80),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : _detailError != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 80),
                              child: Center(
                                child: Text(
                                  _detailError!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: Color(0xFFD04747),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            )
                          : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoSectionCard(
                                  title: (detail['recentMoveTitle'] ??
                                          '최근 주가 변동 요약')
                                      .toString(),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: ((detail['recentMoveBullets']
                                                    as List?) ??
                                                const [])
                                            .map(
                                              (item) => Padding(
                                                padding: const EdgeInsets.only(
                                                    bottom: 10),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Padding(
                                                      padding:
                                                          EdgeInsets.only(
                                                              top: 8),
                                                      child: Icon(
                                                        Icons
                                                            .fiber_manual_record_rounded,
                                                        size: 10,
                                                        color:
                                                            Color(0xFFE84E5C),
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Expanded(
                                                      child: Text(
                                                        item.toString(),
                                                        style: const TextStyle(
                                                          height: 1.6,
                                                          fontSize: 16,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          color:
                                                              Color(0xFF333845),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(growable: false),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                _InfoSectionCard(
                                  title: '관련 뉴스',
                                  child: news.isEmpty
                                      ? const Text(
                                          '최근 뉴스가 없습니다.',
                                          style: TextStyle(
                                            color: Color(0xFF7A8190),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : Column(
                                          children: news
                                              .map(
                                                (item) => Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 14),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            14),
                                                    decoration: BoxDecoration(
                                                      color: const Color(
                                                          0xFFF7F8FC),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              18),
                                                    ),
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          (item['title'] ?? '')
                                                              .toString(),
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 15,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color: Color(
                                                                0xFF171A22),
                                                            height: 1.45,
                                                          ),
                                                        ),
                                                        const SizedBox(
                                                            height: 8),
                                                        Text(
                                                          '${item['publisher'] ?? 'Yahoo Finance'} · ${_formatDate(item['publishedAt'])}',
                                                          style:
                                                              const TextStyle(
                                                            color: Color(
                                                                0xFF8D95A3),
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(growable: false),
                                        ),
                                ),
                              ],
                            ),
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _openOrderSheet('SELL'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(58),
                          side: const BorderSide(
                            color: Color(0xFF2678D2),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          '매도하기',
                          style: TextStyle(
                            color: Color(0xFF2678D2),
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () => _openOrderSheet('BUY'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFF4258),
                          minimumSize: const Size.fromHeight(58),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: const Text(
                          '매수하기',
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderSheet extends StatefulWidget {
  const _OrderSheet({
    required this.api,
    required this.userId,
    required this.stock,
    required this.side,
    required this.currency,
  });

  final HamstockApi api;
  final int userId;
  final Map<String, dynamic> stock;
  final String side;
  final String currency;

  @override
  State<_OrderSheet> createState() => _OrderSheetState();
}

class _OrderSheetState extends State<_OrderSheet> {
  late String _side;
  String _priceType = 'MARKET';
  int _quantity = 1;
  bool _loadingPreview = false;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _preview;

  late final TextEditingController _limitPriceController;
  late final TextEditingController _quantityController;

  num get _marketPrice => (widget.stock['price'] as num?) ?? 0;
  int get _stockId => ((widget.stock['id'] as num?) ?? 0).toInt();
  bool get _isBuy => _side == 'BUY';

  @override
  void initState() {
    super.initState();
    _side = widget.side;
    _limitPriceController = TextEditingController(
      text: _marketPrice > 0 ? _marketPrice.toStringAsFixed(0) : '',
    );
    _quantityController = TextEditingController(text: '$_quantity');
    _refreshPreview();
  }

  @override
  void dispose() {
    _limitPriceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  double? get _limitPrice {
    final raw = _limitPriceController.text.replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  void _setQuantity(int next) {
    final normalized = next < 1 ? 1 : next;
    setState(() {
      _quantity = normalized;
      _quantityController.text = '$normalized';
      _quantityController.selection = TextSelection.fromPosition(
        TextPosition(offset: _quantityController.text.length),
      );
    });
    _refreshPreview();
  }

  Future<void> _applyQuickRatio(double ratio) async {
    if (!_isBuy) {
      _showToast(context, '매도 퀵 수량은 보유 수량 연동 후 정확해집니다.');
      return;
    }

    try {
      final dashboard = await widget.api.getDashboard(widget.userId);
      final cash = (dashboard['cashBalance'] as num?) ?? 0;
      final price = _priceType == 'LIMIT' ? (_limitPrice ?? 0) : _marketPrice;
      if (price <= 0) {
        setState(() => _error = '시장가가 0원이면 지정가를 입력해야 합니다.');
        return;
      }
      final qty = ((cash * ratio) / (price * 1.0035)).floor();
      _setQuantity(qty < 1 ? 1 : qty);
    } catch (e) {
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _refreshPreview() async {
    if (_stockId <= 0) {
      setState(() => _error = '종목 id가 없어 주문할 수 없습니다.');
      return;
    }

    setState(() {
      _loadingPreview = true;
      _error = null;
    });

    try {
      final data = await widget.api.preview(
        userId: widget.userId,
        stockId: _stockId,
        quantity: _quantity,
        side: _side,
        priceType: _priceType,
        limitPrice: _priceType == 'LIMIT' ? _limitPrice : null,
      );
      if (!mounted) return;
      setState(() => _preview = data);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _loadingPreview = false);
    }
  }

  Future<void> _submit() async {
    await _refreshPreview();
    if (!mounted) return;

    final preview = _preview;
    if (preview == null || preview['canExecute'] != true) {
      setState(() {
        _error = (preview?['reason'] ?? '주문 가능 조건을 확인하세요.').toString();
      });
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        final accent = _isBuy ? const Color(0xFFFF3F55) : const Color(0xFF2678D2);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(_isBuy ? '매수 확인' : '매도 확인'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${preview['stockName'] ?? widget.stock['name']} ${_quantity}주 ${_isBuy ? '매수' : '매도'}',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: accent,
                ),
              ),
              const SizedBox(height: 16),
              _OrderSummaryRow(
                label: '주문방식',
                value: _priceType == 'MARKET' ? '시장가' : '지정가',
              ),
              _OrderSummaryRow(
                label: '체결기준가',
                value: _formatMoney(
                  (preview['executionPrice'] as num?) ?? 0,
                  currency: widget.currency,
                ),
              ),
              _OrderSummaryRow(
                label: '예상 수수료',
                value: _formatMoney(
                  (preview['fee'] as num?) ?? 0,
                  currency: widget.currency,
                ),
              ),
              _OrderSummaryRow(
                label: _isBuy ? '총 주문금액' : '예상 입금액',
                value: _formatMoney(
                  (_isBuy
                          ? preview['totalOrderAmount']
                          : preview['estimatedReceiveAmount']) as num? ??
                      0,
                  currency: widget.currency,
                ),
              ),
            ],
          ),
          actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: Text(_isBuy ? '매수 확정' : '매도 확정'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() => _submitting = true);
    try {
      if (_isBuy) {
        await widget.api.buy(
          userId: widget.userId,
          stockId: _stockId,
          quantity: _quantity,
          priceType: _priceType,
          limitPrice: _priceType == 'LIMIT' ? _limitPrice : null,
        );
      } else {
        await widget.api.sell(
          userId: widget.userId,
          stockId: _stockId,
          quantity: _quantity,
          priceType: _priceType,
          limitPrice: _priceType == 'LIMIT' ? _limitPrice : null,
        );
      }
      if (!mounted) return;
      _showToast(context, _isBuy ? '매수 주문이 체결됐습니다.' : '매도 주문이 체결됐습니다.');
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sideColor = _isBuy ? const Color(0xFFFF3F55) : const Color(0xFF2678D2);
    final preview = _preview;
    final executionPrice = (preview?['executionPrice'] as num?) ?? _marketPrice;
    final fee = (preview?['fee'] as num?) ?? 0;
    final total = (preview?[_isBuy ? 'totalOrderAmount' : 'estimatedReceiveAmount']
            as num?) ??
        0;

    return DraggableScrollableSheet(
      initialChildSize: 0.86,
      minChildSize: 0.55,
      maxChildSize: 0.96,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD6D9DF),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _StockAvatar(stock: widget.stock, size: 52),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.stock['name'] ?? '종목'}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '현재가 ${_formatMoney(_marketPrice, currency: widget.currency)}',
                            style: const TextStyle(
                              color: Color(0xFF7A8190),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _OrderModeButton(
                        label: '구매',
                        selected: _side == 'BUY',
                        color: const Color(0xFFFF3F55),
                        onTap: () {
                          setState(() => _side = 'BUY');
                          _refreshPreview();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _OrderModeButton(
                        label: '판매',
                        selected: _side == 'SELL',
                        color: const Color(0xFF2678D2),
                        onTap: () {
                          setState(() => _side = 'SELL');
                          _refreshPreview();
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '가격 설정',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'MARKET', label: Text('시장가')),
                          ButtonSegment(value: 'LIMIT', label: Text('지정가')),
                        ],
                        selected: {_priceType},
                        onSelectionChanged: (next) {
                          setState(() => _priceType = next.first);
                          _refreshPreview();
                        },
                      ),
                      if (_priceType == 'LIMIT') ...[
                        const SizedBox(height: 12),
                        TextField(
                          controller: _limitPriceController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            labelText: '지정가',
                            suffixText: widget.currency == 'USD' ? 'USD' : '원',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onChanged: (_) => _refreshPreview(),
                        ),
                      ] else ...[
                        const SizedBox(height: 12),
                        Text(
                          '최대한 빠른 가격으로 체결합니다.',
                          style: TextStyle(
                            color: sideColor,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F7FA),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '수량 설정',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          IconButton.outlined(
                            onPressed: () => _setQuantity(_quantity - 1),
                            icon: const Icon(Icons.remove_rounded),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _quantityController,
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                              ),
                              decoration: InputDecoration(
                                suffixText: '주',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              onChanged: (value) {
                                final parsed = int.tryParse(value);
                                if (parsed == null) return;
                                _quantity = parsed < 1 ? 1 : parsed;
                                _refreshPreview();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          IconButton.filled(
                            onPressed: () => _setQuantity(_quantity + 1),
                            icon: const Icon(Icons.add_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _QuickRatioButton(label: '10%', onTap: () => _applyQuickRatio(0.10)),
                          _QuickRatioButton(label: '25%', onTap: () => _applyQuickRatio(0.25)),
                          _QuickRatioButton(label: '50%', onTap: () => _applyQuickRatio(0.50)),
                          _QuickRatioButton(label: '최대', onTap: () => _applyQuickRatio(1.0)),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _OrderSummaryRow(
                  label: '체결기준가',
                  value: _formatMoney(executionPrice, currency: widget.currency),
                ),
                _OrderSummaryRow(
                  label: '예상 수수료',
                  value: _formatMoney(fee, currency: widget.currency),
                ),
                _OrderSummaryRow(
                  label: _isBuy ? '총 주문금액' : '예상 입금액',
                  value: _loadingPreview
                      ? '계산 중'
                      : _formatMoney(total, currency: widget.currency),
                  strong: true,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFFD04747),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _submitting ? null : _submit,
                  style: FilledButton.styleFrom(
                    backgroundColor: sideColor,
                    minimumSize: const Size.fromHeight(58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: Text(
                    _submitting ? '처리 중...' : (_isBuy ? '사기' : '팔기'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _OrderModeButton extends StatelessWidget {
  const _OrderModeButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 50,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.12) : const Color(0xFFF3F4F7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? color : const Color(0xFF535966),
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
      ),
    );
  }
}

class _QuickRatioButton extends StatelessWidget {
  const _QuickRatioButton({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          height: 44,
          child: OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF00796B),
              side: const BorderSide(color: Color(0xFFD9DEE8)),
              minimumSize: const Size(0, 44),
              padding: const EdgeInsets.symmetric(horizontal: 2),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.noScaling,
                  ),
                  child: Text(
                    label,
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.fade,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrderSummaryRow extends StatelessWidget {
  const _OrderSummaryRow({
    required this.label,
    required this.value,
    this.strong = false,
  });

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: strong ? 17 : 15,
              color: const Color(0xFF555B66),
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: strong ? 22 : 16,
              color: const Color(0xFF111111),
              fontWeight: strong ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _InvestmentDashboardCard extends StatelessWidget {
  const _InvestmentDashboardCard({
    required this.totalAsset,
    required this.profitLoss,
    required this.returnRate,
    required this.holdingsCount,
    required this.cashBalance,
    required this.onHistoryTap,
  });

  final num totalAsset;
  final num profitLoss;
  final num returnRate;
  final int holdingsCount;
  final num cashBalance;
  final VoidCallback onHistoryTap;

  @override
  Widget build(BuildContext context) {
    final positive = profitLoss >= 0;
    final accent = positive ? const Color(0xFFE84E5C) : const Color(0xFF2B76DD);

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  '내 투자',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                ),
              ),
              TextButton.icon(
                onPressed: onHistoryTap,
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text('거래내역'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DashboardRow(
            label: '총 평가 자산',
            value: _formatWon(totalAsset),
            subValue: '${_formatSignedWon(totalAsset - 10000000)} / 기준 1,000만 원',
            valueColor: const Color(0xFF111111),
          ),
          const Divider(height: 28),
          Row(
            children: [
              Expanded(
                child: _MiniStatCard(
                  title: '전체 수익률',
                  value: _formatSignedPercent(returnRate),
                  description: _formatSignedWon(profitLoss),
                  valueColor: accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MiniStatCard(
                  title: '보유 종목 수',
                  value: '$holdingsCount개',
                  description: '현재 투자 중',
                  valueColor: const Color(0xFF111111),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _MiniStatCard(
            title: '예수금',
            value: _formatWon(cashBalance),
            description: '주문 가능 현금',
            valueColor: const Color(0xFF111111),
          ),
        ],
      ),
    );
  }
}

class _DashboardRow extends StatelessWidget {
  const _DashboardRow({
    required this.label,
    required this.value,
    required this.subValue,
    required this.valueColor,
  });

  final String label;
  final String value;
  final String subValue;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF7A8190),
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: valueColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          subValue,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF9AA2B1),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.description,
    required this.valueColor,
  });

  final String title;
  final String value;
  final String description;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF7A8190),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: valueColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: const TextStyle(
              color: Color(0xFF9AA2B1),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.onSubmitted,
    required this.onSearchTap,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '종목명 또는 종목코드 검색',
          prefixIcon: const Icon(Icons.search_rounded),
          suffixIcon: IconButton(
            onPressed: onSearchTap,
            icon: const Icon(Icons.arrow_forward_rounded),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(22),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.value,
    required this.onChanged,
  });

  final StockCategory value;
  final ValueChanged<StockCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: StockCategory.values.map((category) {
          final selected = category == value;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => onChanged(category),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: selected ? const Color(0xFF111111) : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: selected ? const Color(0xFF111111) : const Color(0xFFE4E8F0),
                  ),
                ),
                child: Text(
                  category.label,
                  style: TextStyle(
                    color: selected ? Colors.white : const Color(0xFF7A8190),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          );
        }).toList(growable: false),
      ),
    );
  }
}

class _StockListTile extends StatelessWidget {
  const _StockListTile({
    required this.rank,
    required this.stock,
    required this.category,
    required this.onTap,
  });

  final int rank;
  final Map<String, dynamic> stock;
  final StockCategory category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final price = (stock['price'] ?? 0) as num;
    final currency = _stockCurrency(stock);
    final displayRate = category == StockCategory.holdings
        ? ((stock['returnRate'] as num?) ?? 0)
        : ((stock['changeRate'] as num?) ?? 0);
    final positive = displayRate >= 0;
    final color = positive ? const Color(0xFFE84E5C) : const Color(0xFF2678D2);
    final quantity = stock['quantity'];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFE8EBF2)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24,
                child: Text(
                  '$rank',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4C9AF6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _StockAvatar(stock: stock),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stock['name']?.toString() ?? '종목',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF141414),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stock['code']?.toString() ?? '',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF9AA2B1),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (category == StockCategory.holdings && quantity != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '보유 수량 ${quantity.toString()}주',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F7888),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatMoney(price, currency: currency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatSignedPercent(displayRate),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: color,
                    ),
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

class _StockAvatar extends StatelessWidget {
  const _StockAvatar({
    required this.stock,
    this.size = 58,
  });

  final Map<String, dynamic> stock;
  final double size;

  @override
  Widget build(BuildContext context) {
    final label = _stockLogoLabel(stock);
    final bg = _stockLogoColor(stock);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      clipBehavior: Clip.antiAlias,
      child: _StockAvatarFallback(label: label, bg: bg, size: size),
    );
  }
}

class _StockAvatarFallback extends StatelessWidget {
  const _StockAvatarFallback({
    required this.label,
    required this.bg,
    required this.size,
  });

  final String label;
  final Color bg;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.all(size * 0.08),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.26,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 210,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(child: CircularProgressIndicator()),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomWideImageButton extends StatelessWidget {
  const _BottomWideImageButton({
    required this.imagePath,
    required this.onTap,
    required this.height,
  });

  final String imagePath;
  final VoidCallback onTap;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF333333),
                child: Center(
                  child: Text(
                    imagePath.split('/').last,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AspectImageButton extends StatelessWidget {
  const _AspectImageButton({
    required this.imagePath,
    required this.aspectRatio,
    required this.onTap,
  });

  final String imagePath;
  final double aspectRatio;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AspectRatio(
            aspectRatio: aspectRatio,
            child: Image.asset(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(
                color: const Color(0xFF333333),
                child: Center(
                  child: Text(
                    imagePath.split('/').last,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoSectionCard extends StatelessWidget {
  const _InfoSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE8EBF2)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Color(0xFF151515),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoMetricTile extends StatelessWidget {
  const _InfoMetricTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F8FC),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF7A8190),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Color(0xFF171A22),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTab extends StatelessWidget {
  const _DetailTab({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    color:
                        selected ? const Color(0xFF151515) : const Color(0xFFA0A6B2),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 56,
                  height: 3,
                  color: selected ? const Color(0xFF151515) : Colors.transparent,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF0F1F5) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected
                  ? const Color(0xFFE1E4EB)
                  : const Color(0xFFE8EBF2),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: selected
                  ? const Color(0xFF151515)
                  : const Color(0xFF7A8190),
            ),
          ),
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.values,
    required this.positive,
  });

  final List<double> values;
  final bool positive;

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFE4E8F0)
      ..strokeWidth = 1;
    for (var i = 1; i < 6; i++) {
      final y = size.height * i / 6;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..color = positive ? const Color(0xFFE84E5C) : const Color(0xFF2B76DD)
      ..strokeCap = StrokeCap.round;

    if (values.length < 2) {
      return;
    }

    final minValue = values.reduce((a, b) => a < b ? a : b);
    final maxValue = values.reduce((a, b) => a > b ? a : b);
    final spread = (maxValue - minValue).abs() < 0.0001 ? 1.0 : (maxValue - minValue);

    final points = <Offset>[];
    for (var i = 0; i < values.length; i++) {
      final x = i / (values.length - 1) * size.width;
      final normalized = (values[i] - minValue) / spread;
      final y = size.height - (normalized * (size.height - 10)) - 5;
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final current = points[i];
      path.lineTo(current.dx, current.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          (positive ? const Color(0xFFE84E5C) : const Color(0xFF2B76DD))
              .withOpacity(0.18),
          (positive ? const Color(0xFFE84E5C) : const Color(0xFF2B76DD))
              .withOpacity(0.02),
        ],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Offset.zero & size);

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final lastPoint = points.last;
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = linePaint.color;
    final dotBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = Colors.white;
    canvas.drawCircle(lastPoint, 6.5, dotPaint);
    canvas.drawCircle(lastPoint, 6.5, dotBorderPaint);
  }

  @override
  bool shouldRepaint(covariant _ChartPainter oldDelegate) {
    return oldDelegate.positive != positive ||
        oldDelegate.values.length != values.length ||
        !listEquals(oldDelegate.values, values);
  }
}

Widget _stockSkeletonBuilder(BuildContext context, int index) {
  return Container(
    height: 96,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
    ),
  );
}

String _stockTicker(Map<String, dynamic> stock) {
  final code = (stock['code'] ?? '').toString();
  if (code.isNotEmpty) return code.length > 5 ? code.substring(0, 5) : code;
  final name = (stock['name'] ?? '').toString();
  if (name.isEmpty) return 'STK';
  return name.substring(0, name.length < 3 ? name.length : 3).toUpperCase();
}

String _stockLogoLabel(Map<String, dynamic> stock) {
  final market = (stock['market'] ?? '').toString().toUpperCase();
  final code = (stock['code'] ?? '').toString().toUpperCase();
  final key = '$market:$code';
  const labelsByCode = <String, String>{
    '005930': 'SAMSUNG',
    '000660': 'SK',
    '373220': 'LG',
    '005380': 'HYUNDAI',
    '000270': 'KIA',
    '105560': 'KB',
    '035420': 'NAVER',
    '207940': 'S BIO',
    '005490': 'POSCO',
    '068270': 'CT',
    'AAPL': 'AAPL',
    'NVDA': 'NVDA',
    'MSFT': 'MSFT',
    'AMZN': 'AMZN',
    'GOOGL': 'GOOGL',
    'META': 'META',
    'TSLA': 'TSLA',
    'AVGO': 'AVGO',
    'NFLX': 'NFLX',
    'AMD': 'AMD',
  };
  const labels = <String, String>{
    'KOSPI:005930': 'SAMSUNG',
    'KOSPI:000660': 'SK',
    'KOSPI:373220': 'LG',
    'KOSPI:005380': 'HYUNDAI',
    'KOSPI:000270': 'KIA',
    'KOSPI:105560': 'KB',
    'KOSPI:035420': 'NAVER',
    'KOSPI:207940': 'S BIO',
    'KOSPI:005490': 'POSCO',
    'KOSPI:068270': 'CT',
    'US:AAPL': 'AAPL',
    'US:NVDA': 'NVDA',
    'US:MSFT': 'MSFT',
    'US:AMZN': 'AMZN',
    'US:GOOGL': 'G',
    'US:META': 'META',
    'US:TSLA': 'TSLA',
    'US:AVGO': 'AVGO',
    'US:NFLX': 'NFLX',
    'US:AMD': 'AMD',
  };
  return labelsByCode[code] ?? labels[key] ?? _stockTicker(stock);
}

Color _stockLogoColor(Map<String, dynamic> stock) {
  final market = (stock['market'] ?? '').toString().toUpperCase();
  final code = (stock['code'] ?? '').toString().toUpperCase();
  final key = '$market:$code';
  const colorsByCode = <String, Color>{
    '005930': Color(0xFF1399F6),
    '000660': Color(0xFFD8243C),
    '373220': Color(0xFFB51F47),
    '005380': Color(0xFF174A86),
    '000270': Color(0xFF111111),
    '105560': Color(0xFFF4B400),
    '035420': Color(0xFF03C75A),
    '207940': Color(0xFF2339B9),
    '005490': Color(0xFF2D5D8B),
    '068270': Color(0xFF00A38D),
    'AAPL': Color(0xFF111111),
    'NVDA': Color(0xFF56A900),
    'MSFT': Color(0xFF737373),
    'AMZN': Color(0xFFFF9900),
    'GOOGL': Color(0xFF4285F4),
    'META': Color(0xFF0866FF),
    'TSLA': Color(0xFFCC0000),
    'AVGO': Color(0xFFC41230),
    'NFLX': Color(0xFFE50914),
    'AMD': Color(0xFF111111),
  };
  const colors = <String, Color>{
    'KOSPI:005930': Color(0xFF1399F6),
    'KOSPI:000660': Color(0xFFD8243C),
    'KOSPI:373220': Color(0xFFB51F47),
    'KOSPI:005380': Color(0xFF174A86),
    'KOSPI:000270': Color(0xFF111111),
    'KOSPI:105560': Color(0xFFF4B400),
    'KOSPI:035420': Color(0xFF03C75A),
    'KOSPI:207940': Color(0xFF2339B9),
    'KOSPI:005490': Color(0xFF2D5D8B),
    'KOSPI:068270': Color(0xFF00A38D),
    'US:AAPL': Color(0xFF111111),
    'US:NVDA': Color(0xFF56A900),
    'US:MSFT': Color(0xFF737373),
    'US:AMZN': Color(0xFFFF9900),
    'US:GOOGL': Color(0xFF4285F4),
    'US:META': Color(0xFF0866FF),
    'US:TSLA': Color(0xFFCC0000),
    'US:AVGO': Color(0xFFC41230),
    'US:NFLX': Color(0xFFE50914),
    'US:AMD': Color(0xFF111111),
  };
  return colorsByCode[code] ??
      colors[key] ??
      (market == 'US' ? const Color(0xFFAF2238) : const Color(0xFF2339B9));
}

String _stockCurrency(
  Map<String, dynamic> stock, {
  Map<String, dynamic>? chart,
}) {
  final chartCurrency = chart?['currency']?.toString().toUpperCase();
  if (chartCurrency == 'USD' || chartCurrency == 'KRW') {
    return chartCurrency!;
  }
  final market = (stock['market'] ?? '').toString().toUpperCase();
  return market == 'US' || market == 'NASDAQ' || market == 'NYSE'
      ? 'USD'
      : 'KRW';
}

String _formatMoney(num value, {required String currency}) {
  final rounded = currency == 'USD' ? value.toDouble() : value.round();
  final sign = rounded < 0 ? '-' : '';
  final absValue = rounded.abs();

  if (currency == 'USD') {
    final fixed = absValue.toStringAsFixed(absValue >= 100 ? 0 : 2);
    final parts = fixed.split('.');
    final digits = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final indexFromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    final decimals = parts.length > 1 && parts[1] != '00' ? '.${parts[1]}' : '';
    return '\$$sign$buffer$decimals';
  }

  final digits = absValue.toStringAsFixed(0);
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final indexFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '₩$sign$buffer';
}

String _formatSignedMoney(num value, {required String currency}) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${_formatMoney(value, currency: currency)}';
}

String _formatOptionalNumber(dynamic value) {
  final number = value is num ? value.toDouble() : double.tryParse('$value');
  if (number == null) return '-';
  if (number.abs() >= 100) return number.toStringAsFixed(0);
  if (number.abs() >= 10) return number.toStringAsFixed(1);
  return number.toStringAsFixed(2);
}

String _formatOptionalMoney(dynamic value, {required String currency}) {
  final number = value is num ? value : num.tryParse('$value');
  if (number == null) return '-';
  return _formatMoney(number, currency: currency);
}

String _formatPlainInteger(dynamic value) {
  final number = value is num ? value : num.tryParse('$value');
  if (number == null) return '-';
  final intValue = number.round().abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < intValue.length; i++) {
    final indexFromEnd = intValue.length - i;
    buffer.write(intValue[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  final sign = number < 0 ? '-' : '';
  return '$sign$buffer';
}

String _formatWon(num value) {
  final rounded = value.round();
  final sign = rounded < 0 ? '-' : '';
  final digits = rounded.abs().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final indexFromEnd = digits.length - i;
    buffer.write(digits[i]);
    if (indexFromEnd > 1 && indexFromEnd % 3 == 1) {
      buffer.write(',');
    }
  }
  return '₩$sign$buffer';
}

String _formatSignedWon(num value) {
  final rounded = value.round();
  final prefix = rounded > 0 ? '+' : '';
  return '$prefix${_formatWon(rounded)}';
}

String _formatSignedPercent(num value) {
  final prefix = value > 0 ? '+' : '';
  return '$prefix${value.toStringAsFixed(2)}%';
}

String _formatDate(dynamic raw) {
  final value = raw?.toString();
  if (value == null || value.isEmpty) return '-';
  if (value.length >= 10) return value.substring(0, 10);
  return value;
}

void _showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(milliseconds: 900),
    ),
  );
}

const Map<String, dynamic> _sampleDashboard = {
  'totalAsset': 12350000,
  'evaluationProfitLoss': 2350000,
  'totalProfitLoss': 2350000,
  'returnRate': 23.5,
  'holdingsCount': 4,
  'cashBalance': 3180000,
};
