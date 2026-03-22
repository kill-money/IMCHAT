/// 移动端首页 — 图片轮播 + 功能宫格 + 动态列表
/// 数据来源：后端 client_config API（ChatApi :10008），管理员可通过配置中心设置内容。
library;

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/controllers/config_controller.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/ui/app_card.dart';
import '../../../shared/theme/typography.dart';
import '../../../shared/widgets/ui/app_text.dart';

class MobileHomePage extends StatefulWidget {
  const MobileHomePage({super.key});

  @override
  State<MobileHomePage> createState() => _MobileHomePageState();
}

class _MobileHomePageState extends State<MobileHomePage> {
  List<_BannerData> _banners = [];
  List<_NewsItem> _news = [];
  String _announcement = '';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    debugPrint('[PAGE_INIT] MobileHomePage');
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadHomeData());
  }

  Future<void> _loadHomeData() async {
    try {
      final cfg = context.read<ConfigController>();
      if (!cfg.loaded) await cfg.load();
      final config = cfg.config;
      _parseBanners(config['home_banners']);
      _parseNews(config['home_news']);
      _announcement = config['home_announcement'] ?? '';
    } catch (e) {
      debugPrint('加载首页配置失败: $e');
    }
    // 未配置或加载失败则使用默认数据
    if (_banners.isEmpty) _banners = _defaultBanners;
    if (_news.isEmpty) _news = _defaultNews;
    if (_announcement.isEmpty) _announcement = _defaultAnnouncement;
    if (mounted) setState(() => _loaded = true);
  }

  void _parseBanners(String? json) {
    if (json == null || json.isEmpty) return;
    try {
      final list = jsonDecode(json) as List;
      _banners = list.map((e) {
        final m = e as Map<String, dynamic>;
        return _BannerData(
          gradient: _parseGradient(m['gradient'] as String? ?? 'red'),
          imageUrl: m['imageUrl'] as String? ?? '',
          title: m['title'] as String? ?? '',
          subtitle: m['subtitle'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('解析Banner数据失败: $e');
    }
  }

  void _parseNews(String? json) {
    if (json == null || json.isEmpty) return;
    try {
      final list = jsonDecode(json) as List;
      _news = list.map((e) {
        final m = e as Map<String, dynamic>;
        return _NewsItem(
          tag: m['tag'] as String? ?? '',
          tagColor: _parseColor(m['tagColor'] as String? ?? 'primary'),
          title: m['title'] as String? ?? '',
          summary: m['summary'] as String? ?? '',
          date: m['date'] as String? ?? '',
        );
      }).toList();
    } catch (e) {
      debugPrint('解析资讯数据失败: $e');
    }
  }

  static List<Color> _parseGradient(String name) {
    switch (name) {
      case 'blue':
        return AppColors.bannerBlue;
      case 'green':
        return AppColors.bannerGreen;
      case 'orange':
        return AppColors.bannerOrange;
      default:
        return AppColors.bannerRed;
    }
  }

  static Color _parseColor(String name) {
    switch (name) {
      case 'success':
        return AppColors.success;
      case 'sky':
        return AppColors.sky;
      case 'activity':
        return AppColors.activity;
      default:
        return AppColors.primary;
    }
  }

  // ─── 默认数据（管理员未配置时使用） ──────────────────────────────

  static final _defaultBanners = [
    _BannerData(
      gradient: AppColors.bannerRed,
      imageUrl: 'assets/images/banners/banner1.jpg',
      title: '全国两会 · 乡村振兴',
      subtitle: '2026年乡村振兴重点任务部署',
    ),
    _BannerData(
      gradient: AppColors.bannerBlue,
      imageUrl: 'assets/images/banners/banner2.jpg',
      title: '财政帮扶 · 专项资金',
      subtitle: '中央财政衔接推进乡村振兴补助资金下达',
    ),
    _BannerData(
      gradient: AppColors.bannerGreen,
      imageUrl: 'assets/images/banners/banner3.jpg',
      title: '雨露计划 · 圆梦助学',
      subtitle: '2026年春季培训班全面启动',
    ),
    _BannerData(
      gradient: AppColors.bannerOrange,
      imageUrl: 'assets/images/banners/banner4.jpg',
      title: '就业援助 · 稳岗扩容',
      subtitle: '一季度脱贫人口务工规模再创新高',
    ),
  ];

  static const _defaultAnnouncement = '2026年春季脱贫攻坚成果专项督促检查工作已正式启动，各地抓紧...';

  static final _defaultNews = [
    _NewsItem(
      tag: '最新要闻',
      tagColor: AppColors.primary,
      title: '2026年全国巩固拓展脱贫攻坚成果工作推进会即将召开',
      summary: '会议强调，要将防止返贫摆在更突出位置，全面落实动态监测管理。',
      date: '2026-03-08',
    ),
    _NewsItem(
      tag: '就业帮扶',
      tagColor: AppColors.success,
      title: '甘肃省绿色农产品产销对接活动正式启动',
      summary: '省级帮扶协调机制统筹协调，预计带动农产品交易超20亿元。',
      date: '2026-03-05',
    ),
    _NewsItem(
      tag: '雨露计划',
      tagColor: AppColors.sky,
      title: '"雨露计划"2026年春季补助申请全面开放',
      summary: '对接受职业教育的脱贫家庭学生，每学年3000元助学金，已覆盖18所院校。',
      date: '2026-03-02',
    ),
    _NewsItem(
      tag: '就业援助',
      tagColor: AppColors.activity,
      title: '贫困人口务工规模同比增长，一季度转移就业再创新高',
      summary: '2026年一季度贫困人口务工规模达3278万人，同比增长4.3%。',
      date: '2026-02-28',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final extraPad = screenWidth > 500 ? (screenWidth - 500) / 2 : 0.0;

    if (!_loaded) {
      return const Scaffold(
        backgroundColor: AppColors.pageBackground,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            backgroundColor: AppColors.primary,
            title: const Text(
              '乡村振兴3.0',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: extraPad),
              child: _BannerCarousel(banners: _banners),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: extraPad),
              child: _AnnouncementBanner(text: _announcement),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg + extraPad, vertical: AppSpacing.sm),
            sliver: SliverToBoxAdapter(
              child: _ChineseGridSection(),
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(AppSpacing.lg + extraPad,
                AppSpacing.sm, AppSpacing.lg + extraPad, AppSpacing.xl),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const _SectionTitle(title: '最新动态'),
                const SizedBox(height: AppSpacing.sm),
                ..._buildNewsCards(context),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildNewsCards(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return _news
        .map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: EdgeInsets.zero,
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(e.title),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: e.tagColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(e.tag,
                              style: AppTypography.caption.copyWith(
                                  color: AppColors.contrastSafe(
                                      e.tagColor, brightness),
                                  fontWeight: FontWeight.w600)),
                        ),
                        const Spacer(),
                        Text(e.date,
                            style: AppTypography.caption
                                .copyWith(color: AppColors.textSecondary)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AppText(e.title,
                        style: AppTypography.body
                            .copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    AppText(e.summary,
                        isSmall: true,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.small
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ))
        .toList();
  }
}

// ─── 数据模型 ─────────────────────────────────────────────────────────────────

class _NewsItem {
  final String tag;
  final Color tagColor;
  final String title;
  final String summary;
  final String date;
  const _NewsItem({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.summary,
    required this.date,
  });
}

// ─── 图片轮播 ─────────────────────────────────────────────────────────────────

class _BannerCarousel extends StatefulWidget {
  final List<_BannerData> banners;
  const _BannerCarousel({required this.banners});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _current = 0;
  Timer? _timer;

  List<_BannerData> get _banners => widget.banners;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _banners.isEmpty) return;
      final next = (_current + 1) % _banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.md),
        LayoutBuilder(
          builder: (context, constraints) {
            // 按卡片实际宽度（扣除左右 margin）计算 16:9 高度，
            // 避免容器与图片比例不匹配导致 BoxFit.cover 裁切内容
            final cardWidth = constraints.maxWidth - 2 * AppSpacing.lg;
            final height = (cardWidth / (16 / 9)).clamp(120.0, 320.0);
            return SizedBox(
              height: height,
              child: PageView.builder(
                controller: _controller,
                itemCount: _banners.length,
                onPageChanged: (i) => setState(() => _current = i),
                itemBuilder: (_, i) => _buildBannerCard(_banners[i]),
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 20 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: i == _current
                    ? AppColors.primary
                    : AppColors.primary.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCard(_BannerData banner) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 底层：先渲染渐变兜底，再叠加网络图片
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: banner.gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (banner.imageUrl.isNotEmpty)
              banner.imageUrl.startsWith('http')
                  ? Image.network(
                      banner.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : Image.asset(
                      banner.imageUrl,
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            // 文字 overlay — 单行标题，紧贴底部
          ],
        ),
      ),
    );
  }
}

class _BannerData {
  final List<Color> gradient;
  final String imageUrl;
  final String title;
  final String subtitle;
  const _BannerData({
    required this.gradient,
    required this.imageUrl,
    required this.title,
    required this.subtitle,
  });
}

// ─── 分区标题 ─────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        AppText(title,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── 公告横幅（滚动提现成功消息） ─────────────────────────────────────────────

class _AnnouncementBanner extends StatefulWidget {
  final String text;
  const _AnnouncementBanner({required this.text});

  @override
  State<_AnnouncementBanner> createState() => _AnnouncementBannerState();
}

class _AnnouncementBannerState extends State<_AnnouncementBanner> {
  static final _messages = _generateMessages();
  int _index = 0;
  Timer? _timer;

  static List<String> _generateMessages() {
    // 用固定种子保证每次启动顺序一致，模拟提现成功动态
    const regions = [
      '山东省临沂市',
      '河北省石家庄市',
      '山西省大同市',
      '江苏省南京市',
      '浙江省杭州市',
      '广东省深圳市',
      '四川省成都市',
      '湖北省武汉市',
      '辽宁省沈阳市',
      '福建省福州市',
      '安徽省合肥市',
      '江西省南昌市',
      '河南省郑州市',
      '湖南省长沙市',
      '云南省昆明市',
      '贵州省贵阳市',
      '陕西省西安市',
      '甘肃省兰州市',
      '广西省南宁市',
      '吉林省长春市',
      '山东省青岛市',
      '广东省广州市',
      '浙江省宁波市',
      '江苏省苏州市',
      '河北省保定市',
      '湖南省岳阳市',
      '四川省绵阳市',
      '福建省厦门市',
      '安徽省芜湖市',
      '河南省洛阳市',
    ];
    const surnames2 = [
      '张*',
      '李*',
      '王*',
      '刘*',
      '陈*',
      '杨*',
      '赵*',
      '黄*',
      '周*',
      '吴*',
      '孙*',
      '马*',
      '朱*',
      '胡*',
      '林*',
    ];
    const surnames3 = [
      '李**',
      '王**',
      '张**',
      '刘**',
      '陈**',
      '杨**',
      '赵**',
      '黄**',
      '周**',
      '吴**',
      '孙**',
      '马**',
      '朱**',
      '胡**',
      '林**',
      '徐**',
      '何**',
      '郭**',
      '罗**',
      '宋**',
    ];
    const amounts = [
      47,
      53,
      62,
      68,
      75,
      81,
      89,
      96,
      103,
      112,
      118,
      127,
      135,
      143,
      156,
      163,
      171,
      185,
      197,
      208,
      216,
      225,
      238,
      247,
      256,
      268,
      275,
      289,
      305,
      312,
      318,
      326,
      330,
    ];
    final list = <String>[];
    for (int i = 0; i < 60; i++) {
      final region = regions[i % regions.length];
      final name = i % 3 == 0
          ? surnames2[i % surnames2.length]
          : surnames3[i % surnames3.length];
      final amount = amounts[i % amounts.length];
      list.add('$region$name已成功完成善款提现$amount万元');
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      setState(() => _index = (_index + 1) % _messages.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_outlined,
              color: AppColors.primary, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, anim) {
                return SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 1),
                    end: Offset.zero,
                  ).animate(anim),
                  child: FadeTransition(opacity: anim, child: child),
                );
              },
              child: Text(
                _messages[_index],
                key: ValueKey<int>(_index),
                style: AppTypography.small,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 国风宫格：印章+牌匾风格 ──────────────────────────────────────────────

class _ChineseGridSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        children: [
          // 第一行 "2026" — 印章风格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['2', '0', '2', '6']
                  .map((ch) => _SealStamp(char: ch))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // 第二行 "乡村振兴" — 牌匾风格
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: ['乡', '村', '振', '兴']
                  .map((ch) => _PlaqueCell(char: ch))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

/// 印章风格数字 — 圆形红底白字，仿篆刻印章
class _SealStamp extends StatelessWidget {
  final String char;
  const _SealStamp({required this.char});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      height: 60,
      child: CustomPaint(
        painter: _SealPainter(),
        child: Center(
          child: Text(
            char,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFFC62828),
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

/// 印章画笔 — 双圈红边，仿篆刻风
class _SealPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerR = size.width / 2 - 2;
    final innerR = outerR - 3;

    final paint = Paint()
      ..color = const Color(0xFFC62828)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    // 外圈
    canvas.drawCircle(center, outerR, paint);
    // 内圈（略细）
    paint.strokeWidth = 1.2;
    canvas.drawCircle(center, innerR, paint);

    // 四角装饰短横 — 仿印章边纹
    final dashPaint = Paint()
      ..color = const Color(0xFFC62828).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const d = 4.0;
    const dl = 6.0;
    canvas.drawLine(const Offset(d, d), const Offset(d + dl, d), dashPaint);
    canvas.drawLine(const Offset(d, d), const Offset(d, d + dl), dashPaint);
    canvas.drawLine(
        Offset(size.width - d, d), Offset(size.width - d - dl, d), dashPaint);
    canvas.drawLine(
        Offset(size.width - d, d), Offset(size.width - d, d + dl), dashPaint);
    canvas.drawLine(
        Offset(d, size.height - d), Offset(d + dl, size.height - d), dashPaint);
    canvas.drawLine(
        Offset(d, size.height - d), Offset(d, size.height - d - dl), dashPaint);
    canvas.drawLine(Offset(size.width - d, size.height - d),
        Offset(size.width - d - dl, size.height - d), dashPaint);
    canvas.drawLine(Offset(size.width - d, size.height - d),
        Offset(size.width - d, size.height - d - dl), dashPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 牌匾风格汉字 — 金色渐变底 + 深色字 + 回纹装饰框
class _PlaqueCell extends StatelessWidget {
  final String char;
  const _PlaqueCell({required this.char});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9A825), Color(0xFFFFD54F)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF9A825).withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        painter: _PlaqueBorderPainter(),
        child: Center(
          child: Text(
            char,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Color(0xFF5D1600),
              height: 1.0,
              shadows: [
                Shadow(
                  color: Color(0x40000000),
                  offset: Offset(0.5, 0.5),
                  blurRadius: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 回纹边框画笔 — 仿传统牌匾回形纹装饰
class _PlaqueBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF8D6E00).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const m = 4.0;
    final rect = Rect.fromLTRB(m, m, size.width - m, size.height - m);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(rrect, paint);

    const m2 = 7.0;
    final rect2 = Rect.fromLTRB(m2, m2, size.width - m2, size.height - m2);
    final rrect2 = RRect.fromRectAndRadius(rect2, const Radius.circular(2));
    paint.strokeWidth = 0.8;
    paint.color = const Color(0xFF8D6E00).withValues(alpha: 0.3);
    canvas.drawRRect(rrect2, paint);

    // 四角回纹装饰
    final cp = Paint()
      ..color = const Color(0xFF8D6E00).withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    _drawCornerMeander(canvas, cp, m + 1, m + 1, 1, 1);
    _drawCornerMeander(canvas, cp, size.width - m - 1, m + 1, -1, 1);
    _drawCornerMeander(canvas, cp, m + 1, size.height - m - 1, 1, -1);
    _drawCornerMeander(
        canvas, cp, size.width - m - 1, size.height - m - 1, -1, -1);
  }

  void _drawCornerMeander(
      Canvas canvas, Paint paint, double x, double y, int dx, int dy) {
    const s = 5.0;
    final path = Path()
      ..moveTo(x, y)
      ..lineTo(x + s * dx, y)
      ..lineTo(x + s * dx, y + s * dy)
      ..lineTo(x + s * 0.4 * dx, y + s * dy);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
