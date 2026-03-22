import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/api/api_client.dart';
import '../../../shared/theme/colors.dart';
import '../../../shared/theme/spacing.dart';
import '../../../shared/widgets/ui/app_header.dart';

/// 已登录设备管理页 — 显示当前账户在各平台的登录状态，支持踢出其他设备
class DeviceManagePage extends StatefulWidget {
  const DeviceManagePage({super.key});

  @override
  State<DeviceManagePage> createState() => _DeviceManagePageState();
}

const _platformNames = <int, String>{
  1: 'iOS',
  2: 'Android',
  3: 'Windows',
  4: 'macOS',
  5: 'Web',
  6: 'MiniWeb',
  7: 'Linux',
};

const _platformIcons = <int, IconData>{
  1: Icons.phone_iphone,
  2: Icons.phone_android,
  3: Icons.desktop_windows,
  4: Icons.laptop_mac,
  5: Icons.language,
  6: Icons.web,
  7: Icons.computer,
};

int _currentPlatformID() {
  if (kIsWeb) return 5;
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 2;
    case TargetPlatform.iOS:
      return 1;
    case TargetPlatform.windows:
      return 3;
    case TargetPlatform.macOS:
      return 4;
    case TargetPlatform.linux:
      return 7;
    default:
      return 0;
  }
}

class _DeviceManagePageState extends State<DeviceManagePage> {
  List<int> _platforms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchDevices();
  }

  Future<void> _fetchDevices() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ImApi.post('/user/get_users_online_status', {
        'userIDs': [ApiConfig.userID],
      });
      final data = resp['data'] as Map<String, dynamic>?;
      final statusList = data?['statusList'] as List<dynamic>? ?? [];
      final List<int> pids = [];
      for (final st in statusList) {
        if (st is Map<String, dynamic> && st['userID'] == ApiConfig.userID) {
          final ids = st['platformIDs'] as List<dynamic>? ?? [];
          pids.addAll(ids.cast<int>());
        }
      }
      if (mounted) {
        setState(() {
          _platforms = pids;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '获取失败，请检查网络';
          _loading = false;
        });
      }
    }
  }

  Future<void> _kickDevice(int platformID) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认下线'),
        content: Text('确定要将 ${_platformNames[platformID] ?? '未知设备'} 强制下线吗？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('确认')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final resp = await ImApi.post('/auth/force_logout', {
      'userID': ApiConfig.userID,
      'platformID': platformID,
    });
    if (!mounted) return;
    final errCode = resp['errCode'] as int?;
    if (errCode == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_platformNames[platformID]} 已下线')),
      );
      _fetchDevices();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('操作失败，请稍后重试')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPID = _currentPlatformID();
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: const AppHeader(title: '已登录设备'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_error!,
                          style: TextStyle(color: AppColors.textSecondary)),
                      TextButton(
                          onPressed: _fetchDevices, child: const Text('重试')),
                    ],
                  ),
                )
              : _platforms.isEmpty
                  ? const Center(child: Text('暂无在线设备信息'))
                  : RefreshIndicator(
                      onRefresh: _fetchDevices,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        itemCount: _platforms.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (context, index) {
                          final pid = _platforms[index];
                          final isCurrent = pid == currentPID;
                          return Card(
                            child: ListTile(
                              leading: Icon(
                                _platformIcons[pid] ?? Icons.devices_other,
                                color: isCurrent
                                    ? AppColors.primary
                                    : AppColors.textSecondary,
                                size: 32,
                              ),
                              title: Text(
                                _platformNames[pid] ?? '未知设备 ($pid)',
                                style: TextStyle(
                                  fontWeight: isCurrent
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                              subtitle: Text(isCurrent ? '当前设备' : '在线'),
                              trailing: isCurrent
                                  ? const Chip(
                                      label: Text('当前',
                                          style: TextStyle(fontSize: 12)))
                                  : TextButton(
                                      onPressed: () => _kickDevice(pid),
                                      child: const Text('下线',
                                          style: TextStyle(color: Colors.red)),
                                    ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
