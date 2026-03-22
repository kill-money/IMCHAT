import 'package:flutter/material.dart';

/// 鍏ㄥ眬鎺掔増绯荤粺 鈥?鍥藉鍏泭鎵惰传涓婚
///
/// 瀛椾綋鍥為€€閾撅細PingFang SC 鈫?Noto Sans SC 鈫?Roboto锛堣鐩?iOS / Android / Web锛?
/// 琛岄珮缁熶竴 1.5锛屽瓧闂磋窛鎸夋斂鍔¤鑼冨垎灞傝瀹?
/// 鈿狅笍  鎵€鏈夋牱寮忓潎涓嶅唴缃鑹诧紝棰滆壊鐢变富棰?textTheme 鎴栬皟鐢ㄦ柟 copyWith 鎻愪緵
class AppTypography {
  static const List<String> _familyFallback = [
    'PingFang SC',
    'Noto Sans SC',
    'Roboto',
  ];

  // 鈹€鈹€ 鏄剧ず绾?鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
  /// 澶ф爣棰橈紙Banner 涓绘爣棰?24sp锛?
  static const TextStyle display = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.35,
    letterSpacing: 0.5,
    fontFamilyFallback: _familyFallback,
  );

  // 鈹€鈹€ 鏍囬绾?鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
  /// 椤甸潰涓绘爣棰?/ 寮圭獥鏍囬锛?0sp SemiBold锛?
  static const TextStyle title = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.3,
    fontFamilyFallback: _familyFallback,
  );

  /// 灏忚妭鏍囬 / 鍗＄墖鏍囬锛?8sp SemiBold锛?
  static const TextStyle subtitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.45,
    letterSpacing: 0.3,
    fontFamilyFallback: _familyFallback,
  );

  // 鈹€鈹€ 姝ｆ枃绾?鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
  /// 姝ｆ枃锛?6sp Regular锛?
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.55,
    letterSpacing: 0.1,
    fontFamilyFallback: _familyFallback,
  );

  /// 姝ｆ枃鍔犵矖锛?6sp Medium锛?
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.55,
    letterSpacing: 0.1,
    fontFamilyFallback: _familyFallback,
  );

  // 鈹€鈹€ 杈呭姪绾?鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
  /// 灏忓瓧 / 鍓爣棰橈紙14sp Regular锛?
  static const TextStyle small = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
    letterSpacing: 0.1,
    fontFamilyFallback: _familyFallback,
  );

  /// 鏍囩 / 瀹牸鏂囧瓧锛?2sp Regular锛?
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
    fontFamilyFallback: _familyFallback,
  );

  /// 璇存槑鏂囧瓧 / 鐗堟潈淇℃伅锛?1sp Regular锛?
  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    height: 1.4,
    letterSpacing: 0.2,
    fontFamilyFallback: _familyFallback,
  );

  // 鈹€鈹€ 鎸夐挳绾?鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
  /// 鎸夐挳鏂囧瓧锛?6sp Medium锛屽缁堢櫧鑹诧級
  static const TextStyle button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.0,
    letterSpacing: 1.0,
    color: Colors.white,
    fontFamilyFallback: _familyFallback,
  );

  // 鈹€鈹€ AppBar 涓撶敤 鈥斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€斺€?
  /// 椤堕儴鏍囬鏍忥紙18sp SemiBold锛屽缁堢櫧鑹诧級
  static const TextStyle appBar = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.0,
    letterSpacing: 0.5,
    color: Colors.white,
    fontFamilyFallback: _familyFallback,
  );
}

