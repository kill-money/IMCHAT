import md5 from "md5";
import { adminRequest, imRequest } from "./request";

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
  return adminRequest("/block/add", { userID, reason });
}

/** 解封用户 */
export async function unblockUser(userIDs: string[]) {
  return adminRequest("/block/del", { userIDs });
}

/** 搜索封禁列表 */
export async function searchBlockUsers(
  pagination: OPENIM.Pagination,
  keyword?: string
) {
  return adminRequest<OPENIM.BlockUserListResult>("/block/search", {
    pagination,
    keyword,
  });
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
    newPassword: md5(newPassword),
  });
}

// ==================== 二开：用户 IP / 角色 ====================

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

/** 设置用户端管理员角色（0=普通 1=用户端管理员） */
export async function setAppRole(targetUserID: string, appRole: number) {
  return adminRequest("/user/set_app_role", { targetUserID, appRole });
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

/** 获取群组列表 */
export async function getGroups(
  pagination: OPENIM.Pagination,
  keyword?: string
) {
  return imRequest<OPENIM.GroupListResult>("/group/get_groups", {
    pagination,
    keyword,
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
  return imRequest<OPENIM.MessageSearchResult>("/msg/search_msg", params);
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

/** 用户注册统计 */
export async function getUserRegisterStats(start: string, end: string) {
  return imRequest<OPENIM.StatisticsResult>("/statistics/user/register", {
    start,
    end,
  });
}

/** 用户活跃统计 */
export async function getUserActiveStats(start: string, end: string) {
  return imRequest<OPENIM.StatisticsResult>("/statistics/user/active", {
    start,
    end,
  });
}

/** 群组创建统计 */
export async function getGroupCreateStats(start: string, end: string) {
  return imRequest<OPENIM.StatisticsResult>("/statistics/group/create", {
    start,
    end,
  });
}

/** 新增用户数统计 */
export async function getNewUserCount(start: string, end: string) {
  return adminRequest<OPENIM.StatisticsResult>("/statistic/new_user_count", {
    start,
    end,
  });
}

/** 登录用户数统计 */
export async function getLoginUserCount(start: string, end: string) {
  return adminRequest<OPENIM.StatisticsResult>("/statistic/login_user_count", {
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

/** 删除管理员 */
export async function deleteAdmin(adminAccounts: string[]) {
  return adminRequest("/account/del_admin", { adminAccounts });
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
  return adminRequest("/forbidden/ip/add", { ip, limitLogin, limitRegister });
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

/** 二开：批量创建用户（动态用户名解析） */
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
