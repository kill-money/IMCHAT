package apistruct

// ===== IP 查看功能请求/响应 =====

// GetUserIPInfoReq 查看用户 IP 信息
type GetUserIPInfoReq struct {
	UserID string `json:"userID" binding:"required"`
}

type GetUserIPInfoResp struct {
	UserID        string `json:"userID"`
	LastIP        string `json:"lastIP"`
	LastLoginTime int64  `json:"lastLoginTime"` // 毫秒时间戳
}

// GetUserIPLogsReq 查看用户 IP 历史
type GetUserIPLogsReq struct {
	UserID     string     `json:"userID" binding:"required"`
	Pagination Pagination `json:"pagination" binding:"required"`
}

type UserIPLogItem struct {
	UserID    string `json:"userID,omitempty"`
	IP        string `json:"ip"`
	Platform  string `json:"platform"`
	LoginTime int64  `json:"loginTime"` // 毫秒时间戳
}

type GetUserIPLogsResp struct {
	Total int64            `json:"total"`
	Logs  []*UserIPLogItem `json:"logs"`
}

// SearchByIPReq 按 IP 搜索用户
type SearchByIPReq struct {
	IP         string     `json:"ip" binding:"required"`
	Pagination Pagination `json:"pagination" binding:"required"`
}

type SearchByIPResp struct {
	Total int64            `json:"total"`
	Logs  []*UserIPLogItem `json:"logs"`
}

// SetAppRoleReq 设置用户端管理员
type SetAppRoleReq struct {
	UserID  string `json:"userID" binding:"required"`
	AppRole int32  `json:"appRole" binding:"oneof=0 1"`
}

type SetAppRoleResp struct{}

// GetAppRoleReq 查询用户角色
type GetAppRoleReq struct {
	UserID string `json:"userID" binding:"required"`
}

type GetAppRoleResp struct {
	UserID  string `json:"userID"`
	AppRole int32  `json:"appRole"`
}
