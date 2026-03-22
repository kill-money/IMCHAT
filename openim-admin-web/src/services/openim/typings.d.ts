// OpenIM Admin API 类型定义

declare namespace OPENIM {
  // 通用分页
  interface Pagination {
    pageNumber: number;
    showNumber: number;
  }

  // 通用响应
  interface BaseResponse<T = any> {
    errCode: number;
    errMsg: string;
    errDlt?: string;
    data: T;
  }

  // ========== 认证 ==========
  interface LoginParams {
    account: string;
    password: string; // MD5 hashed
  }

  interface LoginResult {
    adminToken: string;
    imToken: string;
    adminAccount: string;
    nickname: string;
    faceURL: string;
    level: number;
    /** 双 Token：7天刷新令牌（UUID） */
    refreshToken?: string;
    /** access token 有效期（秒），固定 900 */
    expiresIn?: number;
  }

  interface RefreshTokenResult {
    adminToken: string;
    refreshToken: string;
    expiresIn: number;
  }

  interface PermissionSet {
    permissions: string[];
  }

  interface AdminInfo {
    account: string;
    userID: string;
    nickname: string;
    faceURL: string;
    level: number;
    createTime: number;
  }

  // ========== 用户 ==========
  interface UserInfo {
    userID: string;
    nickname: string;
    faceURL: string;
    createTime: number;
    phoneNumber?: string;
    email?: string;
    gender?: number;
    birth?: number;
    account?: string;
    appMangerLevel?: number;
    globalRecvMsgOpt?: number;
    ex?: string;
    /** 最后登录 IP */
    lastIP?: string;
    /** 最后登录时间（毫秒） */
    lastIPTime?: number;
    /** 0=普通用户 1=用户端管理员 */
    appRole?: number;
    /** 0=普通账号 1=官方账号（金 V 标识）*/
    isOfficial?: number;
  }

  interface UserListResult {
    total: number;
    users: UserInfo[];
  }

  interface OnlineUser {
    userID: string;
    platformIDs: number[];
    status: number;
  }

  interface BlockUser {
    userID: string;
    nickname: string;
    faceURL: string;
    reason: string;
    opUserID: string;
    createTime: number;
  }

  interface BlockUserListResult {
    total: number;
    users: BlockUser[];
  }

  // ========== 群组 ==========
  interface GroupInfo {
    groupID: string;
    groupName: string;
    faceURL: string;
    ownerUserID: string;
    memberCount: number;
    status: number;
    creatorUserID: string;
    groupType: number;
    createTime: number;
    notification?: string;
    introduction?: string;
    ex?: string;
  }

  interface GroupListResult {
    total: number;
    groups: GroupInfo[];
  }

  interface GroupMember {
    groupID: string;
    userID: string;
    nickname: string;
    faceURL: string;
    roleLevel: number;
    joinTime: number;
    muteEndTime: number;
  }

  // ========== 消息 ==========
  interface MessageInfo {
    serverMsgID: string;
    clientMsgID: string;
    sendID: string;
    recvID: string;
    conversationID?: string;
    senderNickname: string;
    senderFaceURL: string;
    groupID?: string;
    contentType: number;
    content: string;
    sendTime: number;
    sessionType: number;
    status: number;
    seq: number;
  }

  interface MessageSearchResult {
    chatLogsNum: number;
    chatLogs: MessageInfo[];
  }

  // ========== 统计 ==========

  /**
   * im-server /statistics/user/register 和 /statistics/group/create 响应
   * total  = 全量历史总数（不受时间范围影响）
   * before = 时间范围起点之前的累计数
   * count  = 时间范围内每日增量 map（key=YYYY-MM-DD, value=数量）
   */
  interface IMCountResult {
    total: number;
    before: number;
    count: Record<string, number>;
  }

  /**
   * admin /statistic/new_user_count 响应（openim-chat 二开接口）
   * total      = 全量历史注册总数
   * date_count = 时间范围内每日新增 map（key=YYYY-MM-DD, value=数量）
   */
  interface NewUserCountResult {
    total: number;
    date_count: Record<string, number>;
  }

  /**
   * admin /statistic/login_user_count 响应（openim-chat 二开接口）
   * loginCount   = 时间范围内登录用户数
   * unloginCount = 时间范围内未登录用户数
   * count        = 时间范围内每日登录 map
   */
  interface LoginCountResult {
    loginCount: number;
    unloginCount: number;
    count: Record<string, number>;
  }

  // ========== 管理员 ==========
  interface AdminAccount {
    account: string;
    userID: string;
    nickname: string;
    faceURL: string;
    level: number;
    createTime: number;
  }

  interface AdminListResult {
    total: number;
    adminAccounts: AdminAccount[];
  }

  // ========== 邀请码 ==========
  interface InvitationCode {
    invitationCode: string;
    createTime: number;
    usedUserID?: string;
  }

  interface InvitationCodeListResult {
    total: number;
    list: InvitationCode[];
  }

  // ========== IP 封禁 ==========
  interface ForbiddenIP {
    ip: string;
    limitLogin: boolean;
    limitRegister: boolean;
    createTime: number;
  }

  interface ForbiddenIPListResult {
    total: number;
    forbiddens: ForbiddenIP[];
  }

  // ========== 默认好友/群 ==========
  interface DefaultItem {
    userID?: string;
    groupID?: string;
  }

  interface DefaultListResult {
    total: number;
    users?: UserInfo[];
    groups?: GroupInfo[];
  }

  // ========== 日志 ==========
  interface ClientLog {
    logID: string;
    userID: string;
    platform: number;
    createTime: number;
    url: string;
    filename: string;
    systemType: string;
    version: string;
    ex: string;
  }

  interface ClientLogResult {
    total: number;
    logs: ClientLog[];
  }

  /** 用户 IP 登录历史单条 */
  interface UserIPLogEntry {
    ip: string;
    loginTime: number;
    device?: string;
    platform?: string;
  }

  interface UserIPLogsResult {
    total: number;
    logs: UserIPLogEntry[];
  }

  /** 白名单用户 */
  interface WhitelistUser {
    id: string;
    identifier: string;       // +8613800138000 or email
    type: number;             // 1=phone 2=email
    role: string;             // admin/operator/user
    permissions: string[];    // view_ip/ban_user/view_chat_log/broadcast
    status: number;           // 1=active 0=disabled
    remark: string;
    createTime: string;
    updateTime: string;
  }

  /** 批量创建用户结果 */
  interface BatchCreateResult {
    created: number;
    skipped: number;
    usernames: string[];
  }

  // ========== 接待员管理（二开）==========
  interface ReceptionistInviteCode {
    id: string;
    userId: string;
    inviteCode: string;
    createdAt: string;
    status: number; // 1=enabled 0=disabled
    customerCount?: number;
  }

  interface CustomerBinding {
    id: string;
    customerId: string;
    receptionistId: string;
    inviteCode: string;
    boundAt: string;
  }

  // ========== 用户端管理员 + 推荐系统（二开）==========
  interface UserAdmin {
    id: string;
    userId: string;
    enabled: boolean;
    createdAt: string;
  }

  // ========== 批量导入用户（二开）==========
  /** 通过 JSON 批量导入时每条用户记录的结构（与后端 RegisterUserInfo 对齐） */
  interface RegisterUserImportInfo {
    userID?: string;
    nickname: string;
    faceURL?: string;
    birth?: number;       // Unix ms
    gender?: number;      // 1=男 2=女
    areaCode: string;     // 如 +86
    phoneNumber: string;
    email?: string;
    account?: string;
    password: string;     // 明文，后端统一 SHA-256
  }

  // ========== 应用版本管理 ==========
  interface ApplicationVersion {
    id: string;
    platform: string;     // android / ios / windows / ...
    version: string;
    url: string;
    text: string;
    force: boolean;
    latest: boolean;
    hot: boolean;
    createTime: number;   // Unix ms
  }

  interface ReferralBinding {
    id: string;
    adminId: string;
    userId: string;
    nickname: string;
    registerIp: string;
    registerTime: string;
  }

  // ========== 钱包系统（二开）==========
  interface WalletAccount {
    id: string;
    userID: string;
    balance: number;   // 分（cents）
    currency: string;  // "CNY"
    createdAt: string;
    updatedAt: string;
  }

  interface WalletTransaction {
    id: string;
    userID: string;
    amount: number;       // 分，正=入账 负=扣款
    balanceAfter: number; // 分
    note: string;
    opAdminID: string;
    createdAt: string;
  }

  // ========== 安全审计日志（二开）==========
  interface SecurityLog {
    _id: string;
    operator_id: string;
    operator_name: string;
    action: string;       // login / ban_user / reset_pass 等
    target_id: string;
    target_type: string;  // user / group / ip / system
    detail: string;
    ip: string;
    success: boolean;
    created_at: string;   // ISO-8601
  }

  interface SecurityLogResult {
    total: number;
    list: SecurityLog[];
  }

  // ========== 用户 IP 登录限制（二开）==========
  interface UserIPLimitLoginItem {
    userID: string;
    ip: string;
    createTime: number;   // Unix ms
    user?: {
      userID: string;
      nickname: string;
      faceURL: string;
    };
  }
}
