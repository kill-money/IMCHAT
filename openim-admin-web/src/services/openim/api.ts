import md5 from "md5";
import { request } from "@umijs/max";
import { adminRequest, imRequest, sensitiveAdminRequest } from "./request";

// ==================== 认证 ====================

/** 管理员登录 */
export async function adminLogin(account: string, password: string) {
  return adminRequest<OPENIM.LoginResult>("/account/login", {
    account,
    password: md5(password),
  });
}

/** 获取管理员信息 */
export async function getAdminInfo() {
  return adminRequest<OPENIM.AdminInfo>("/account/info", {});
}

/** 无感续期：用 refreshToken 换取新 accessToken（由 request.ts 内部自动调用，一般无需手动调用） */
export async function refreshAdminToken(refreshToken: string) {
  return adminRequest<OPENIM.RefreshTokenResult>("/account/token/refresh", {
    refreshToken,
  });
}

/** 获取当前管理员自己的权限列表 */
export async function getMyPermissions() {
  return adminRequest<OPENIM.PermissionSet>("/account/permissions", {});
}

/** 设置指定管理员的权限列表（仅超级管理员可操作） */
export async function setAdminPermissions(adminUserID: string, permissions: string[]) {
  return adminRequest("/account/admin_permissions/set", { adminUserID, permissions });
}

/** 获取指定管理员的权限列表（仅超级管理员可查询） */
export async function getAdminPermissions(adminUserID: string) {
  return adminRequest<OPENIM.PermissionSet>("/account/admin_permissions/get", { adminUserID });
}

/** 修改密码 */
export async function changeAdminPassword(
  currentPassword: string,
  newPassword: string
) {
  return adminRequest("/account/change_password", {
    currentPassword: md5(currentPassword),
    newPassword: md5(newPassword),
  });
}

/** 更新管理员自身资料（昵称/头像/账号/等级） */
export async function updateAdminInfo(params: {
  account?: string;
  faceURL?: string;
  nickname?: string;
  level?: number;
}) {
  return adminRequest<OPENIM.AdminInfo>("/account/update", params);
}

// ==================== 用户管理 ====================

/** 搜索用户 */
export async function searchUsers(params: {
  keyword?: string;
  pagination: OPENIM.Pagination;
  genders?: number[];
  userIDs?: string[];
}) {
  return imRequest<OPENIM.UserListResult>("/user/get_users", {
    pagination: params.pagination,
    keyword: params.keyword,
    userIDs: params.userIDs,
    genders: params.genders,
  });
}

/** 获取用户详情 */
export async function getUsersInfo(userIDs: string[]) {
  return imRequest<{ users: OPENIM.UserInfo[] }>("/user/get_users_info", {
    userIDs,
  });
}

/** 获取在线用户 */
export async function getUsersOnlineStatus(userIDs: string[]) {
  return imRequest<{ statusList: OPENIM.OnlineUser[] }>(
    "/user/get_users_online_status",
    {
      userIDs,
    }
  );
}

/** 封禁用户 */
export async function blockUser(userID: string, reason: string) {
  return adminRequest("/user/forbidden/add", { userID, reason });
}

/** 解封用户 */
export async function unblockUser(userIDs: string[]) {
  return adminRequest("/user/forbidden/remove", { userIDs });
}

/** 搜索封禁列表 */
export async function searchBlockUsers(
  pagination: OPENIM.Pagination,
  keyword?: string
) {
  return adminRequest<OPENIM.BlockUserListResult>("/user/forbidden/search", {
    pagination,
    keyword,
  });
}

/** 批量查询用户封禁状态 */
export async function getUserBlockStatus(userIDs: string[]) {
  return adminRequest<{ userID: string; isBlocked: boolean }[]>(
    "/user/status/get",
    { userIDs }
  );
}

/** 批量注册用户 */
export async function batchRegisterUsers(
  users: { userID: string; nickname: string; password: string }[]
) {
  return adminRequest("/user/batch_register", { users });
}

/** 重置用户密码 */
export async function resetUserPassword(userID: string, newPassword: string) {
  return adminRequest("/user/password/reset", {
    userID,
    newPassword, // 后端 ResetUserPassword() 统一做 SHA-256 哈希，此处发送明文
  });
}

// ==================== 用户 IP / 角色 ====================

/** 管理员新建单个用户账号 */
export async function addSingleUser(user: {
  account: string;
  nickname: string;
  password: string;
  phoneNumber?: string;
  email?: string;
  gender?: number;
  faceURL?: string;
}) {
  return adminRequest("/account/add_user", { user });
}

/** 修改用户基本资料（im-server 管理员接口） */
export async function updateUserBasicInfo(
  userID: string,
  info: { nickname?: string; faceURL?: string; gender?: number; birth?: number; ex?: string }
) {
  return imRequest("/user/update_user_info", { userInfo: { userID, ...info } });
}

/** 删除用户（通过 admin API 调用 CancellationUser 注销账号，需二次密码确认） */
export async function deleteUsers(userIDs: string[], password: string) {
  return sensitiveAdminRequest("/user/delete_users", { userIDs }, password, "user_delete");
}

/** 获取用户加入的群列表（管理员查看） */
export async function getUserJoinedGroups(
  userID: string,
  pagination: OPENIM.Pagination
) {
  return imRequest<{ total: number; groups: OPENIM.GroupInfo[] }>(
    "/group/get_joined_group_list",
    { fromUserID: userID, pagination }
  );
}

/** 搜索用户（含最后登录 IP/时间/角色，仅后台管理员） */
export async function searchUsersWithIP(params: {
  keyword?: string;
  pagination: OPENIM.Pagination;
  userIDs?: string[];
  genders?: number[];
}) {
  return adminRequest<OPENIM.UserListResult>("/user/search", {
    keyword: params.keyword,
    pagination: params.pagination,
    userIDs: params.userIDs,
    genders: params.genders,
  });
}

/** 设置用户端管理员角色（0=普通 1=用户端管理员）— 需二次密码验证 */
export async function setAppRole(targetUserID: string, appRole: number, password: string) {
  return sensitiveAdminRequest("/user/set_app_role", { targetUserID, appRole }, password, "set_app_role");
}

/** 设置官方账号标识（0=普通 1=官方金 V）*/
export async function setOfficialStatus(targetUserID: string, isOfficial: number) {
  return adminRequest("/user/set_official", { targetUserID, isOfficial });
}

/** 查询用户 IP 登录历史（分页） */
export async function getUserIPLogs(
  userID: string,
  pagination: OPENIM.Pagination
) {
  return adminRequest<OPENIM.UserIPLogsResult>("/user/ip_logs", {
    userID,
    pagination,
  });
}

// ==================== 群组管理 ====================

/** 获取群组列表（groupName/groupID 对应 GetGroupsReq proto 字段，keyword 已弃用）*/
export async function getGroups(
  pagination: OPENIM.Pagination,
  groupName?: string,
  groupID?: string,
) {
  return imRequest<OPENIM.GroupListResult>("/group/get_groups", {
    pagination,
    groupName,
    groupID,
  });
}

/** 获取群组详情 */
export async function getGroupsInfo(groupIDs: string[]) {
  return imRequest<{ groups: OPENIM.GroupInfo[] }>("/group/get_groups_info", {
    groupIDs,
  });
}

/** 获取群成员 */
export async function getGroupMembers(
  groupID: string,
  pagination: OPENIM.Pagination
) {
  return imRequest<{ total: number; members: OPENIM.GroupMember[] }>(
    "/group/get_group_member_list",
    {
      groupID,
      pagination,
    }
  );
}

/** 解散群组 */
export async function dismissGroup(groupID: string) {
  return imRequest("/group/dismiss_group", { groupID });
}

/** 禁言群组 */
export async function muteGroup(groupID: string) {
  return imRequest("/group/mute_group", { groupID });
}

/** 取消禁言群组 */
export async function cancelMuteGroup(groupID: string) {
  return imRequest("/group/cancel_mute_group", { groupID });
}

/** 踢出群成员 */
export async function kickGroupMember(
  groupID: string,
  userIDs: string[],
  reason?: string
) {
  return imRequest("/group/kick_group", {
    groupID,
    kickedUserIDs: userIDs,
    reason,
  });
}

/** 转让群主 */
export async function transferGroup(groupID: string, newOwnerUserID: string) {
  return imRequest("/group/transfer_group", { groupID, newOwnerUserID });
}

// ==================== 消息管理 ====================

/** 搜索消息 */
export async function searchMessages(params: {
  sendID?: string;
  recvID?: string;
  groupID?: string;
  keyword?: string;
  contentType?: number;
  sessionType?: number;
  sendTime?: string;
  pagination: OPENIM.Pagination;
}) {
  // groupID 仅在群聊场景(sessionType=3)传递，避免后端 proto 冲突
  const { groupID, sessionType, ...rest } = params;
  const body: Record<string, unknown> = { ...rest };
  if (sessionType) body.sessionType = sessionType;
  if (groupID && sessionType === 3) body.groupID = groupID;
  return imRequest<OPENIM.MessageSearchResult>("/msg/search_msg", body);
}

/** 发送消息 */
export async function sendMessage(params: {
  sendID: string;
  recvID?: string;
  groupID?: string;
  senderNickname?: string;
  senderFaceURL?: string;
  senderPlatformID?: number;
  content: Record<string, any>;
  contentType: number;
  sessionType: number;
}) {
  return imRequest("/msg/send_msg", {
    ...params,
    sendTime: Date.now(),
  });
}

/** 撤回消息 */
export async function revokeMessage(
  conversationID: string,
  seq: number,
  userID: string
) {
  return imRequest("/msg/revoke_msg", { conversationID, seq, userID });
}

// ==================== 统计 ====================

/** 用户注册统计（im-server）→ IMCountResult */
export async function getUserRegisterStats(start: string, end: string) {
  return imRequest<OPENIM.IMCountResult>("/statistics/user/register", {
    start,
    end,
  });
}

/** 用户活跃统计（im-server）*/
export async function getUserActiveStats(start: string, end: string) {
  return imRequest<Record<string, unknown>>("/statistics/user/active", {
    start,
    end,
  });
}

/** 群组创建统计（im-server）→ IMCountResult */
export async function getGroupCreateStats(start: string, end: string) {
  return imRequest<OPENIM.IMCountResult>("/statistics/group/create", {
    start,
    end,
  });
}

/** 新增用户数统计（admin chat API）→ NewUserCountResult */
export async function getNewUserCount(start: number, end: number) {
  return adminRequest<OPENIM.NewUserCountResult>("/statistic/new_user_count", {
    start,
    end,
  });
}

/** 登录用户数统计（admin chat API）→ LoginCountResult */
export async function getLoginUserCount(start: number, end: number) {
  return adminRequest<OPENIM.LoginCountResult>("/statistic/login_user_count", {
    start,
    end,
  });
}

// ==================== 管理员管理 ====================

/** 搜索管理员 */
export async function searchAdmins(pagination: OPENIM.Pagination) {
  return adminRequest<OPENIM.AdminListResult>("/account/search", {
    pagination,
  });
}

/** 添加管理员 */
export async function addAdmin(
  account: string,
  password: string,
  nickname: string,
  faceURL?: string
) {
  return adminRequest("/account/add_admin", {
    account,
    password: md5(password),
    nickname,
    faceURL,
  });
}

/** 删除管理员（传入 userID 数组） */
export async function deleteAdmin(userIDs: string[]) {
  return adminRequest("/account/del_admin", { userIDs });
}

// ==================== 邀请码 ====================

/** 搜索邀请码 */
export async function searchInvitationCodes(
  pagination: OPENIM.Pagination,
  keyword?: string
) {
  return adminRequest<OPENIM.InvitationCodeListResult>(
    "/invitation_code/search",
    {
      pagination,
      keyword,
    }
  );
}

/** 生成邀请码 */
export async function genInvitationCodes(num: number) {
  return adminRequest("/invitation_code/gen", { num });
}

/** 删除邀请码 */
export async function deleteInvitationCodes(codes: string[]) {
  return adminRequest("/invitation_code/del", { codes });
}

// ==================== IP 封禁 ====================

/** 搜索 IP 封禁 */
export async function searchForbiddenIPs(
  pagination: OPENIM.Pagination,
  keyword?: string
) {
  return adminRequest<OPENIM.ForbiddenIPListResult>("/forbidden/ip/search", {
    pagination,
    keyword,
  });
}

/** 添加 IP 封禁 */
export async function addForbiddenIP(
  ip: string,
  limitLogin: boolean,
  limitRegister: boolean
) {
  return adminRequest("/forbidden/ip/add", { forbiddens: [{ ip, limitLogin, limitRegister }] });
}

/** 删除 IP 封禁 */
export async function deleteForbiddenIP(ips: string[]) {
  return adminRequest("/forbidden/ip/del", { ips });
}

// ==================== 默认好友/群 ====================

/** 搜索默认好友 */
export async function searchDefaultFriends(pagination: OPENIM.Pagination) {
  return adminRequest<OPENIM.DefaultListResult>("/default/user/search", {
    pagination,
  });
}

/** 添加默认好友 */
export async function addDefaultFriends(userIDs: string[]) {
  return adminRequest("/default/user/add", { userIDs });
}

/** 删除默认好友 */
export async function deleteDefaultFriends(userIDs: string[]) {
  return adminRequest("/default/user/del", { userIDs });
}

/** 搜索默认群组 */
export async function searchDefaultGroups(pagination: OPENIM.Pagination) {
  return adminRequest<OPENIM.DefaultListResult>("/default/group/search", {
    pagination,
  });
}

/** 添加默认群组 */
export async function addDefaultGroups(groupIDs: string[]) {
  return adminRequest("/default/group/add", { groupIDs });
}

/** 删除默认群组 */
export async function deleteDefaultGroups(groupIDs: string[]) {
  return adminRequest("/default/group/del", { groupIDs });
}

// ==================== 日志 ====================

/** 搜索客户端日志 */
export async function searchClientLogs(
  pagination: OPENIM.Pagination,
  keyword?: string
) {
  return imRequest<OPENIM.ClientLogResult>("/third/logs/search", {
    pagination,
    keyword,
  });
}

/** 删除客户端日志 */
export async function deleteClientLogs(logIDs: string[]) {
  return imRequest("/third/logs/delete", { logIDs });
}

// ==================== 强制下线 ====================

/** 强制用户下线 */
export async function forceLogout(userID: string, platformID?: number) {
  return imRequest("/auth/force_logout", { userID, platformID });
}

// ==================== 白名单管理（二开）====================

/** 搜索白名单 */
export async function searchWhitelist(params: {
  keyword?: string;
  status?: number; // -1=全部 0=禁用 1=启用
  pageNum?: number;
  showNum?: number;
}) {
  return adminRequest<{ total: number; list: OPENIM.WhitelistUser[] }>("/whitelist/search", {
    keyword: params.keyword ?? "",
    status: params.status ?? -1,
    pageNum: params.pageNum ?? 1,
    showNum: params.showNum ?? 20,
  });
}

/** 添加白名单 */
export async function addWhitelistUser(data: {
  identifier: string;
  type: number; // 1=phone 2=email
  role?: string;
  permissions?: string[];
  remark?: string;
}) {
  return adminRequest<OPENIM.WhitelistUser>("/whitelist/add", data);
}

/** 修改白名单 */
export async function updateWhitelistUser(data: {
  id: string;
  role?: string;
  permissions?: string[];
  status?: number;
  remark?: string;
}) {
  return adminRequest("/whitelist/update", data);
}

/** 删除白名单 */
export async function deleteWhitelistUsers(ids: string[]) {
  return adminRequest("/whitelist/del", { ids });
}

/** 批量创建用户（动态用户名解析） */
export async function batchCreateUsers(data: {
  start_username: string;
  count: number;
  password: string;
  role?: string;
}) {
  return adminRequest<OPENIM.BatchCreateResult>("/user/batch_create", data);
}

// ==================== 接待员管理（二开）====================

/** 搜索接待员邀请码 */
export async function searchReceptionistInviteCodes(params: {
  keyword?: string;
  pagination: { pageNumber: number; showNumber: number };
}) {
  return adminRequest<{ total: number; list: OPENIM.ReceptionistInviteCode[] }>(
    "/receptionist/invite_codes/search",
    params,
  );
}

/** 更新邀请码状态（启用/禁用） */
export async function updateReceptionistInviteCodeStatus(id: string, status: number) {
  return adminRequest("/receptionist/invite_codes/update_status", { id, status });
}

/** 删除邀请码 */
export async function deleteReceptionistInviteCode(id: string) {
  return adminRequest("/receptionist/invite_codes/delete", { id });
}

/** 查询接待员的客户列表 */
export async function listReceptionistBindings(receptionistID: string) {
  return adminRequest<{ total: number; list: OPENIM.CustomerBinding[] }>(
    "/receptionist/bindings/list",
    { receptionistID },
  );
}

/** 删除绑定关系 */
export async function deleteReceptionistBinding(customerID: string) {
  return adminRequest("/receptionist/bindings/delete", { customerID });
}

// ==================== 用户端管理员 + 推荐系统（二开）====================

/** 搜索用户端管理员 */
export async function searchUserAdmins(params: {
  keyword?: string;
  pagination: { pageNumber: number; showNumber: number };
}) {
  return adminRequest<{ total: number; list: OPENIM.UserAdmin[] }>(
    "/user_admin/search",
    params,
  );
}

/** 添加用户端管理员 */
export async function addUserAdmin(userID: string) {
  return adminRequest("/user_admin/add", { userID });
}

/** 移除用户端管理员 */
export async function removeUserAdmin(userID: string) {
  return adminRequest("/user_admin/remove", { userID });
}

/** 获取推荐用户列表 */
export async function getReferralUsers(adminID: string) {
  return adminRequest<{ total: number; list: OPENIM.ReferralBinding[] }>(
    "/user_admin/referral/users",
    { adminID },
  );
}

// ==================== 钱包管理（二开）====================

/** 查询用户钱包信息 */
export async function getUserWallet(userID: string) {
  return adminRequest<OPENIM.WalletAccount>("/wallet/user", { userID });
}

/** 调整用户余额（amount 单位：分，正=入账，负=扣款，需二次密码确认） */
export async function adjustWalletBalance(
  params: { userID: string; amount: number; note?: string },
  password: string
) {
  return sensitiveAdminRequest<{ balance: number; transaction: OPENIM.WalletTransaction }>(
    "/wallet/adjust",
    params,
    password,
    "wallet_adjust",
  );
}

/** 查询用户钱包流水 */
export async function getWalletTransactions(params: {
  userID: string;
  pagination: { pageNumber: number; showNumber: number };
}) {
  return adminRequest<{ total: number; list: OPENIM.WalletTransaction[] }>(
    "/wallet/transactions",
    params,
  );
}

// ==================== 安全审计日志（二开）====================

/** 搜索安全审计日志 */
export async function searchSecurityLogs(params: {
  keyword?: string;
  action?: string;
  start_time?: string; // ISO-8601
  end_time?: string;
  pageNum?: number;
  showNum?: number;
}) {
  return adminRequest<OPENIM.SecurityLogResult>("/security_log/search", {
    keyword: params.keyword ?? "",
    action: params.action ?? "",
    start_time: params.start_time ?? "",
    end_time: params.end_time ?? "",
    pageNum: params.pageNum ?? 1,
    showNum: params.showNum ?? 20,
  });
}

// ==================== 客户端配置（白名单功能开关）====================

/** 获取客户端配置 key 列表 */
export async function getClientConfig() {
  return adminRequest<{ config: Record<string, string> }>("/client_config/get", {});
}

/** 设置客户端配置 */
export async function setClientConfig(config: Record<string, string>) {
  return adminRequest("/client_config/set", { config });
}

/** 删除客户端配置 key */
export async function delClientConfig(keys: string[]) {
  return adminRequest("/client_config/del", { keys });
}

// ==================== 注册开关 ====================

/** 查询当前注册是否开放 */
export async function getAllowRegister() {
  return adminRequest<{ allowRegister: boolean }>("/user/allow_register/get", {});
}

/** 设置注册开关 */
export async function setAllowRegister(allowRegister: boolean) {
  return adminRequest("/user/allow_register/set", { allowRegister });
}

// ==================== 批量导入用户 ====================

/** 批量导入用户（JSON 格式） */
export async function importUsersByJson(users: OPENIM.RegisterUserImportInfo[]) {
  return adminRequest("/user/import/json", { users });
}

/**
 * 批量导入用户（Excel 文件）
 * @param file 符合模板格式的 .xlsx 文件
 */
export async function importUsersByXlsx(file: File) {
  const formData = new FormData();
  formData.append("data", file);
  return request<OPENIM.BaseResponse<Record<string, never>>>("/admin_api/user/import/xlsx", {
    method: "POST",
    data: formData,
    headers: {
      operationID: String(Date.now()),
    },
    credentials: "include",
    requestType: "form",
    skipErrorHandler: true,
  });
}

/**
 * 下载批量导入用户的 Excel 模板
 * 直接在新标签页中触发浏览器下载。
 */
export function downloadImportTemplate() {
  const link = document.createElement("a");
  link.href = `/admin_api/user/import/xlsx`;
  link.download = "template.xlsx";
  link.click();
}

// ==================== 应用版本管理 ====================

/** 分页查询应用版本列表 */
export async function pageApplicationVersions(params: {
  platform?: string[];
  pagination: { pageNumber: number; showNumber: number };
}) {
  return adminRequest<{ total: number; versions: OPENIM.ApplicationVersion[] }>(
    "/application/page_versions",
    params,
  );
}

/** 新增应用版本 */
export async function addApplicationVersion(params: {
  platform: string;
  version: string;
  url: string;
  text: string;
  force: boolean;
  latest: boolean;
  hot: boolean;
}) {
  return adminRequest("/application/add_version", params);
}

/** 更新应用版本 */
export async function updateApplicationVersion(params: {
  id: string;
  platform?: string;
  version?: string;
  url?: string;
  text?: string;
  force?: boolean;
  latest?: boolean;
  hot?: boolean;
}) {
  return adminRequest("/application/update_version", params);
}

/** 删除应用版本 */
export async function deleteApplicationVersion(ids: string[]) {
  return adminRequest("/application/delete_version", { id: ids });
}

// ==================== 用户 IP 登录限制（二开）====================

/** 查询用户 IP 登录限制列表（keyword = userID / IP 关键字） */
export async function searchUserIPLimitLogin(params: {
  keyword?: string;
  pagination: { pageNumber: number; showNumber: number };
}) {
  return adminRequest<{ total: number; list: OPENIM.UserIPLimitLoginItem[] }>(
    "/forbidden/user/search",
    params,
  );
}

/** 添加用户 IP 登录限制（每条限制: userID + 允许登录的 IP） */
export async function addUserIPLimitLogin(
  limits: Array<{ userID: string; ip: string }>
) {
  return adminRequest("/forbidden/user/add", { limits });
}

/** 删除用户 IP 登录限制 */
export async function deleteUserIPLimitLogin(
  limits: Array<{ userID: string; ip: string }>
) {
  return adminRequest("/forbidden/user/del", { limits });
}

// ==================== 配置中心（管理端）====================

/** 获取所有配置文件名列表 */
export async function getConfigList() {
  return adminRequest<{ configNames: string[]; environment: string; version: string }>(
    "/config/get_config_list",
    {},
  );
}

/** 获取指定配置文件的 JSON 内容 */
export async function getConfig(configName: string) {
  return adminRequest<string>("/config/get_config", { configName });
}

/** 保存指定配置文件（仅 etcd 模式支持） */
export async function setConfig(configName: string, configBody: string) {
  return adminRequest("/config/set_config", { configName, configBody });
}

/** 重置指定配置文件到默认值（仅 etcd 模式支持） */
export async function resetConfig(configName: string) {
  return adminRequest("/config/reset_config", { configName });
}

/** 查询配置管理功能是否启用 */
export async function getEnableConfigManager() {
  return adminRequest<{ enable: boolean }>("/config/get_enable_config_manager", {});
}

/** 设置配置管理功能开关 */
export async function setEnableConfigManager(enable: boolean) {
  return adminRequest("/config/set_enable_config_manager", { enable });
}

/** 重启服务（慎用，仅 etcd 模式支持热重启） */
export async function restartService() {
  return adminRequest("/restart", {});
}

// ==================== 2FA/TOTP 多因子认证 ====================

/** 生成 TOTP 密钥（首次启用 2FA） */
export async function setup2FA() {
  return adminRequest<{
    secret: string;
    otpauthURI: string;
    issuer: string;
    digits: number;
    period: number;
  }>("/account/2fa/setup", {});
}

/** 验证 TOTP 码并激活 2FA */
export async function verify2FA(code: string) {
  return adminRequest<{ enabled: boolean }>("/account/2fa/verify", { code });
}

/** 查询当前管理员 2FA 状态 */
export async function get2FAStatus() {
  return adminRequest<{ enabled: boolean }>("/account/2fa/status", {});
}

/** 禁用 2FA（需当前 TOTP 码验证） */
export async function disable2FA(code: string) {
  return adminRequest<{ enabled: boolean }>("/account/2fa/disable", { code });
}

/** 登录二步验证（2FA 临时令牌 + TOTP 码），成功后返回完整双 Token */
export async function login2FA(tempToken: string, code: string) {
  return adminRequest<OPENIM.LoginResult>(
    "/account/login/2fa",
    { tempToken, code },
  );
}

// ==================== 风控系统 ====================

/** 查询 IP + 管理员的风险评分 */
export async function getRiskScore(params: { ip?: string; adminID?: string }) {
  return adminRequest<{
    score: number;
    level: string;
    factors: string[];
    ip: string;
    admin_id: string;
  }>("/security/risk/score", params);
}

// ==================== WebSocket 鉴权 ====================

/** 获取 WebSocket 鉴权 ticket（30s 有效） */
export async function getWSTicket() {
  return adminRequest<{ ticket: string; expiresIn: number }>("/ws/auth", {});
}

// ==================== 内容过滤规则 ====================

export interface ContentFilterRule {
  ruleID: string;
  pattern: string;
  ruleType: string; // phone | wechat | qq | email | custom
  action: string;   // block | warn | mask
  enabled: boolean;
  description?: string;
}

/** 获取全部过滤规则 */
export async function getFilterRules() {
  return adminRequest<{ rules: ContentFilterRule[] }>("/content_filter/list", {});
}

// ==================== Dashboard 统计 ====================

/** 获取 Dashboard 聚合统计（实时在线数 + 注册总数 + 24h 新增） */
export async function getDashboardStats() {
  return adminRequest<{
    onlineUserCount: number;
    totalUsers: number;
    newUsers24h: number;
  }>("/statistic/dashboard", {});
}

// ==================== 消息广播管理 ====================

export interface BroadcastMessage {
  broadcastID: string;
  title: string;
  content: string;
  contentType: number; // 1=text 2=markdown
  status: number;      // 0=pending 1=sent 2=failed 3=sending
  sendTo: string;      // "all" or comma-separated userIDs
  sentAt?: string;
  sentBy?: string;
  successCount?: number;
  failCount?: number;
  createdBy: string;
  createdAt: string;
  updatedAt: string;
}

/** 创建广播 */
export async function createBroadcast(params: {
  title: string;
  content: string;
  contentType?: number;
  sendTo?: string;
}) {
  return adminRequest<BroadcastMessage>("/broadcast/create", params);
}

/** 搜索广播列表 */
export async function searchBroadcasts(params: {
  keyword?: string;
  status?: number;
  pagination: { pageNumber: number; showNumber: number };
}) {
  return adminRequest<{ broadcasts: BroadcastMessage[]; total: number }>(
    "/broadcast/search",
    params,
  );
}

/** 更新广播 */
export async function updateBroadcast(params: {
  broadcastID: string;
  title?: string;
  content?: string;
  contentType?: number;
  sendTo?: string;
}) {
  return adminRequest<void>("/broadcast/update", params);
}

/** 删除广播 */
export async function deleteBroadcasts(broadcastIDs: string[]) {
  return adminRequest<void>("/broadcast/delete", { broadcastIDs });
}

/** 获取广播详情 */
export async function getBroadcastDetail(broadcastID: string) {
  return adminRequest<BroadcastMessage>("/broadcast/detail", { broadcastID });
}

/** 发送广播（需二次密码确认） */
export async function sendBroadcast(broadcastID: string, password: string) {
  return sensitiveAdminRequest<{ broadcastID: string; status: string }>(
    "/broadcast/send",
    { broadcastID },
    password,
    "broadcast_send",
  );
}

/** 新增/更新过滤规则 */
export async function upsertFilterRule(rule: Partial<ContentFilterRule>) {
  return adminRequest<{}>("/content_filter/upsert", rule);
}

/** 删除过滤规则 */
export async function deleteFilterRule(ruleID: string) {
  return adminRequest<{}>("/content_filter/delete", { ruleID });
}

// ==================== 功能开关 ====================

export interface FeatureToggle {
  featureKey: string;
  enabled: boolean;
  description: string;
  updatedAt?: string;
  updatedBy?: string;
}

/** 获取全部功能开关 */
export async function getFeatureToggles() {
  return adminRequest<{ toggles: FeatureToggle[] }>("/feature_toggle/list", {});
}

/** 设置功能开关 */
export async function setFeatureToggle(featureKey: string, enabled: boolean) {
  return adminRequest<{}>("/feature_toggle/set", { featureKey, enabled });
}

// ==================== 官方群管理 ====================

/** 设置/取消官方群 */
export async function setOfficialGroup(groupID: string, isOfficial: boolean) {
  return adminRequest<{}>("/official_group/set", { groupID, isOfficial });
}

/** 批量查询群官方状态 */
export async function getOfficialGroupStatus(groupIDs: string[]) {
  return adminRequest<{ statuses: Record<string, boolean> }>("/official_group/status", { groupIDs });
}

// ==================== 消息管理（管理端操作） ====================

/** 管理员撤回消息 */
export async function adminRecallMessage(params: {
  conversationID: string;
  seq: number;
  senderID: string;
  sendTime: number;
}) {
  return adminRequest<{}>("/chat_msg/recall", params);
}

/** 管理员删除群消息 */
export async function adminDeleteGroupMessage(params: {
  conversationID: string;
  groupID: string;
  seqs: number[];
  operatorID: string;
}) {
  return adminRequest<{}>("/chat_msg/delete_group", params);
}

// ==================== 提现审批 ====================

export interface WithdrawRequest {
  ID: string;
  UserID: string;
  Amount: number;
  CardID: string;
  Note: string;
  Status: string;
  Reason: string;
  OpAdminID: string;
  CreatedAt: string;
  UpdatedAt: string;
}

/** 查询提现申请列表 */
export async function listWithdrawRequests(status?: string, pagination?: { pageNumber: number; showNumber: number }) {
  return adminRequest<{ total: number; list: WithdrawRequest[] }>("/wallet/withdraw/list", {
    status: status ?? "",
    pagination: pagination ?? { pageNumber: 1, showNumber: 50 },
  });
}

/** 审批提现申请 */
export async function reviewWithdraw(requestID: string, action: "approved" | "rejected", reasonOrPassword?: string, reason?: string) {
  // 兼容旧调用 (id, action, reason) 和新调用 (id, action, password, reason)
  // 如果只有3个参数，视为 reason（无密码时退化为普通请求）
  if (reason === undefined) {
    return adminRequest<{ status: string }>("/wallet/withdraw/review", {
      requestID,
      action,
      reason: reasonOrPassword ?? "",
    });
  }
  return sensitiveAdminRequest<{ status: string }>("/wallet/withdraw/review", {
    requestID,
    action,
    reason,
  }, reasonOrPassword!, "withdraw_review");
}

// ==================== 限流管理 ====================

/** 获取限流统计 */
export async function getRateLimitStats() {
  return adminRequest<{
    totalAllowed: number;
    totalDenied: number;
    rules: Array<{ level: string; identity: string; allowed: number; denied: number }>;
  }>("/ratelimit/stats", {});
}

/** 检查限流状态 */
export async function checkRateLimit(level: string, identity: string) {
  return adminRequest<{ allowed: boolean; remaining?: number; resetAt?: number }>(
    "/ratelimit/check", { level, identity }
  );
}

/** 获取分布式限流统计 */
export async function getDistRateLimitStats() {
  return adminRequest<Record<string, unknown>>("/dist_ratelimit/stats", {});
}

/** 检查分布式限流状态 */
export async function checkDistRateLimit(level: string, identity: string) {
  return adminRequest<{ allowed: boolean }>("/dist_ratelimit/check", { level, identity });
}

// ==================== 策略引擎 ====================

/** 获取策略规则列表 */
export async function getPolicyRules() {
  return adminRequest<{ rules: Array<Record<string, unknown>>; version: number }>(
    "/policy/rules", {}
  );
}

/** 评估策略 */
export async function evalPolicy(variables: Record<string, unknown>) {
  return adminRequest<{ matched: boolean; actions?: unknown[] }>(
    "/policy/eval", { variables }
  );
}

/** 验证策略表达式 */
export async function validatePolicy(expression: string) {
  return adminRequest<{ valid: boolean; error?: string }>(
    "/policy/validate", { expression }
  );
}

/** 获取策略版本历史 */
export async function getPolicyHistory() {
  return adminRequest<{ currentVersion: number; history?: unknown[] }>(
    "/policy/history", {}
  );
}

/** 获取规则引擎版本 */
export async function getRuleVersion() {
  return adminRequest<{ version: number }>("/rule/version", {});
}

/** 获取分片列表 */
export async function getShardList() {
  return adminRequest<{ shards: Array<{ key: string; description?: string }> }>(
    "/shard/list", {}
  );
}
