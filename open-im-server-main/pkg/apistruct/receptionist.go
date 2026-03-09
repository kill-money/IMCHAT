package apistruct

// ===== 邀请码相关 =====

type GenInviteCodeReq struct {
	UserID string `json:"userID" binding:"required"`
}

type GenInviteCodeResp struct {
	UserID     string `json:"userID"`
	InviteCode string `json:"inviteCode"`
	Status     int32  `json:"status"`
	CreatedAt  int64  `json:"createdAt"`
}

type GetInviteCodeReq struct {
	UserID string `json:"userID" binding:"required"`
}

type GetInviteCodeResp struct {
	UserID     string `json:"userID"`
	InviteCode string `json:"inviteCode"`
	Status     int32  `json:"status"`
	CreatedAt  int64  `json:"createdAt"`
}

type UpdateInviteCodeStatusReq struct {
	InviteCode string `json:"inviteCode" binding:"required"`
	Status     int32  `json:"status" binding:"oneof=0 1"`
}

type UpdateInviteCodeStatusResp struct{}

type DeleteInviteCodeReq struct {
	InviteCode string `json:"inviteCode" binding:"required"`
}

type DeleteInviteCodeResp struct{}

type SearchInviteCodesReq struct {
	Keyword    string     `json:"keyword"`
	Pagination Pagination `json:"pagination" binding:"required"`
}

type InviteCodeItem struct {
	UserID     string `json:"userID"`
	InviteCode string `json:"inviteCode"`
	Status     int32  `json:"status"`
	CreatedAt  int64  `json:"createdAt"`
}

type SearchInviteCodesResp struct {
	Total int64             `json:"total"`
	Codes []*InviteCodeItem `json:"codes"`
}

// ===== 客户绑定相关 =====

type BindCustomerReq struct {
	CustomerID string `json:"customerID" binding:"required"`
	InviteCode string `json:"inviteCode" binding:"required"`
}

type BindCustomerResp struct{}

type GetBindingReq struct {
	CustomerID string `json:"customerID" binding:"required"`
}

type BindingItem struct {
	CustomerID     string `json:"customerID"`
	ReceptionistID string `json:"receptionistID"`
	InviteCode     string `json:"inviteCode"`
	BoundAt        int64  `json:"boundAt"`
}

type GetBindingResp struct {
	Binding *BindingItem `json:"binding"`
}

type PageBindingsReq struct {
	ReceptionistID string     `json:"receptionistID" binding:"required"`
	Keyword        string     `json:"keyword"`
	Pagination     Pagination `json:"pagination" binding:"required"`
}

type PageBindingsResp struct {
	Total    int64          `json:"total"`
	Bindings []*BindingItem `json:"bindings"`
}

type GetBindingStatsReq struct {
	InviteCode     string `json:"inviteCode"`
	ReceptionistID string `json:"receptionistID"`
}

type GetBindingStatsResp struct {
	CodeCount  int64 `json:"codeCount"`
	TotalCount int64 `json:"totalCount"`
}

// ===== 问候语相关 =====

type SetGreetingReq struct {
	ReceptionistID string `json:"receptionistID" binding:"required"`
	GreetingText   string `json:"greetingText" binding:"required"`
}

type SetGreetingResp struct{}

type GetGreetingReq struct {
	ReceptionistID string `json:"receptionistID" binding:"required"`
}

type GetGreetingResp struct {
	ReceptionistID string `json:"receptionistID"`
	GreetingText   string `json:"greetingText"`
}

type SearchGreetingsReq struct {
	Keyword    string     `json:"keyword"`
	Pagination Pagination `json:"pagination" binding:"required"`
}

type GreetingItem struct {
	ReceptionistID string `json:"receptionistID"`
	GreetingText   string `json:"greetingText"`
	UpdatedAt      int64  `json:"updatedAt"`
}

type SearchGreetingsResp struct {
	Total     int64           `json:"total"`
	Greetings []*GreetingItem `json:"greetings"`
}

// ===== 注册时自动处理 =====

type OnCustomerRegisterReq struct {
	CustomerID string `json:"customerID" binding:"required"`
	InviteCode string `json:"inviteCode" binding:"required"`
}

type OnCustomerRegisterResp struct{}

// ===== 发送日志 =====

type SearchSendLogsReq struct {
	ReceptionistID string     `json:"receptionistID"`
	StartTime      int64      `json:"startTime"`
	EndTime        int64      `json:"endTime"`
	Pagination     Pagination `json:"pagination" binding:"required"`
}

type SendLogItem struct {
	ReceptionistID string `json:"receptionistID"`
	CustomerID     string `json:"customerID"`
	GreetingText   string `json:"greetingText"`
	SentAt         int64  `json:"sentAt"`
	Status         int32  `json:"status"`
}

type SearchSendLogsResp struct {
	Total int64          `json:"total"`
	Logs  []*SendLogItem `json:"logs"`
}
