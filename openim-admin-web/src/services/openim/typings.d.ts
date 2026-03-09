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
  }

  interface AdminInfo {
    adminAccount: string;
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
    /** 二开：最后登录 IP */
    lastIP?: string;
    /** 二开：最后登录时间（毫秒） */
    lastIPTime?: number;
    /** 二开：0=普通用户 1=用户端管理员 */
    appRole?: number;
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
    opAdminAccount: string;
    createTime: number;
  }

  interface BlockUserListResult {
    total: number;
    blocks: BlockUser[];
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
    total: number;
    chatLogs: MessageInfo[];
  }

  // ========== 统计 ==========
  interface DateCount {
    date: string;
    count: number;
  }

  interface StatisticsResult {
    total: number;
    before: number;
    dateCount: DateCount[];
  }

  // ========== 管理员 ==========
  interface AdminAccount {
    adminAccount: string;
    nickname: string;
    faceURL: string;
    level: number;
    createTime: number;
  }

  interface AdminListResult {
    total: number;
    admins: AdminAccount[];
  }

  // ========== 邀请码 ==========
  interface InvitationCode {
    invitationCode: string;
    createTime: number;
    usedTimes: number;
    lastUsedTime: number;
  }

  interface InvitationCodeListResult {
    total: number;
    invitationCodes: InvitationCode[];
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

  /** 二开：用户 IP 登录历史单条 */
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

  /** 二开：白名单用户 */
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

  /** 二开：批量创建用户结果 */
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

  interface ReferralBinding {
    id: string;
    adminId: string;
    userId: string;
    nickname: string;
    registerIp: string;
    registerTime: string;
  }
}
