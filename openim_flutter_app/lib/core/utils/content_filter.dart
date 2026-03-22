/// 联系方式内容过滤器 — 检测并屏蔽群聊中的隐私联系方式
///
/// 过滤的内容类型：
/// - 手机号码（11位中国大陆手机号）
/// - 微信号（含常见关键词如 "加微信"、"vx"、"wx" 等）
/// - QQ号（含关键词如 "加QQ"、"扣扣" 等）
/// - 邮箱地址
class ContentFilter {
  /// 中国大陆手机号正则（1开头 + 10位数字，允许中间含空格/横线）
  static final _phoneRegex =
      RegExp(r'(?<!\d)1[3-9]\d[\s\-]?\d{4}[\s\-]?\d{4}(?!\d)');

  /// 微信号相关关键词
  static final _wechatKeywords = RegExp(
      r'(加|我|的)?(微信|vx|wx|weixin|wechat)\s*[:：]?\s*\S+',
      caseSensitive: false);

  /// QQ相关关键词
  static final _qqKeywords =
      RegExp(r'(加|我|的)?(qq|扣扣|企鹅)\s*[:：]?\s*\d{5,12}', caseSensitive: false);

  /// 邮箱正则
  static final _emailRegex = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

  /// 检查文本中是否含有联系方式
  static bool containsContactInfo(String text) {
    return _phoneRegex.hasMatch(text) ||
        _wechatKeywords.hasMatch(text) ||
        _qqKeywords.hasMatch(text) ||
        _emailRegex.hasMatch(text);
  }

  /// 将联系方式替换为 ***（用于展示层）
  static String mask(String text) {
    var result = text;
    result = result.replaceAll(_phoneRegex, '***');
    result = result.replaceAllMapped(_wechatKeywords, (m) {
      // 保留关键词前缀，屏蔽号码部分
      return '${m.group(0)?.split(RegExp(r'[:：\s]')).first ?? ''}:***';
    });
    result = result.replaceAllMapped(_qqKeywords, (m) {
      return '${m.group(0)?.split(RegExp(r'[:：\s]')).first ?? ''}:***';
    });
    result = result.replaceAll(_emailRegex, '***');
    return result;
  }

  /// 生成用户提示消息
  static const String warningMessage = '检测到联系方式信息，群聊中禁止分享个人联系方式';
}
