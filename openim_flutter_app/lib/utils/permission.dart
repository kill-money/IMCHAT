/// 用户 IP 查看等权限判断
/// 普通用户不渲染任何 IP 相关组件（不是隐藏，是不渲染）
library;

/// 根据当前用户的 [appRole] 判断是否为「用户端管理员」。
/// - 0 = 普通用户（无 IP 查看权限）
/// - 1 = 用户端管理员（可在 App 内查看他人 IP）
/// 超级管理员为后台登录，不通过此字段。
bool isAppAdmin(int appRole) {
  return appRole >= 1;
}
