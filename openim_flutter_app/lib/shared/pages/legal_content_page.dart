import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';
import '../widgets/ui/app_header.dart';
import '../../core/controllers/config_controller.dart';

/// 通用法律文本展示页（用户协议 / 隐私政策）
///
/// 从 `client_config` 接口拉取对应 key 的内容并渲染。
/// [configKey] 对应后端 client_config 的键名，如 `terms_of_service` / `privacy_policy`。
class LegalContentPage extends StatefulWidget {
  final String title;
  final String configKey;

  const LegalContentPage({
    super.key,
    required this.title,
    required this.configKey,
  });

  @override
  State<LegalContentPage> createState() => _LegalContentPageState();
}

class _LegalContentPageState extends State<LegalContentPage> {
  String? _content;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFromConfig());
  }

  void _loadFromConfig() {
    final cfg = context.read<ConfigController>();
    if (cfg.loaded) {
      setState(() {
        _content = cfg.getString(widget.configKey);
        _loading = false;
      });
    } else {
      // 配置尚未加载（异常路径），主动拉取
      cfg.load().then((_) {
        if (mounted) {
          setState(() {
            _content = cfg.getString(widget.configKey);
            _loading = false;
          });
        }
      }).catchError((e) {
        if (mounted) {
          setState(() {
            _error = '加载失败，请检查网络后重试';
            _loading = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppHeader(title: widget.title),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, size: 48, color: AppColors.textSecondary),
            const SizedBox(height: AppSpacing.md),
            Text(_error!, style: TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _loadFromConfig();
                },
                child: const Text('重试')),
          ],
        ),
      );
    }
    if (_content == null || _content!.isEmpty) {
      return const Center(
        child: Text('暂无内容', style: TextStyle(color: AppColors.textSecondary)),
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SelectableText(
        _content!,
        style: const TextStyle(
          fontSize: 15,
          height: 1.8,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}
