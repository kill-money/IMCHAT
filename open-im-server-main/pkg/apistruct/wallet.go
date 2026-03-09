package apistruct

import "time"

// ===== User-side Wallet Requests & Responses =====

type CreateWalletAccountReq struct {
	Currency string `json:"currency"`
}

type CreateWalletAccountResp struct {
	UserID   string `json:"userID"`
	Currency string `json:"currency"`
}

type GetWalletAccountReq struct {
}

type GetWalletAccountResp struct {
	UserID       string `json:"userID"`
	Balance      int64  `json:"balance"`
	FrozenAmount int64  `json:"frozenAmount"`
	Currency     string `json:"currency"`
	Status       int32  `json:"status"`
}

type WalletRechargeReq struct {
	Amount         int64  `json:"amount" binding:"required,gt=0"`
	IdempotencyKey string `json:"idempotencyKey" binding:"required"`
	Remark         string `json:"remark"`
}

type WalletWithdrawReq struct {
	Amount         int64  `json:"amount" binding:"required,gt=0"`
	IdempotencyKey string `json:"idempotencyKey" binding:"required"`
	Remark         string `json:"remark"`
}

type WalletTransferReq struct {
	ToUserID       string `json:"toUserID" binding:"required"`
	Amount         int64  `json:"amount" binding:"required,gt=0"`
	IdempotencyKey string `json:"idempotencyKey" binding:"required"`
	Remark         string `json:"remark"`
}

type WalletTransactionResp struct {
	TransactionID  string `json:"transactionID"`
	UserID         string `json:"userID"`
	OppositeUserID string `json:"oppositeUserID,omitempty"`
	Type           int32  `json:"type"`
	Amount         int64  `json:"amount"`
	BalanceBefore  int64  `json:"balanceBefore"`
	BalanceAfter   int64  `json:"balanceAfter"`
	Status         int32  `json:"status"`
	Remark         string `json:"remark"`
	CreateTime     int64  `json:"createTime"`
}

type WalletTransferResp struct {
	TransactionOut *WalletTransactionResp `json:"transactionOut"`
	TransactionIn  *WalletTransactionResp `json:"transactionIn"`
}

type GetWalletTransactionsReq struct {
	Types     []int32    `json:"types"`
	StartTime *time.Time `json:"startTime"`
	EndTime   *time.Time `json:"endTime"`
	Pagination
}

type GetWalletTransactionsResp struct {
	Total        int64                    `json:"total"`
	Transactions []*WalletTransactionResp `json:"transactions"`
}

// ===== Admin-side Wallet Requests & Responses =====

type AdminGetWalletOverviewReq struct {
}

type AdminGetWalletOverviewResp struct {
	TotalAccounts  int64 `json:"totalAccounts"`
	FrozenAccounts int64 `json:"frozenAccounts"`
	TotalBalance   int64 `json:"totalBalance"`
	TotalFrozen    int64 `json:"totalFrozen"`
}

type AdminGetAccountListReq struct {
	StatusFilter []int32 `json:"statusFilter"`
	Pagination
}

type AdminGetAccountListResp struct {
	Total    int64               `json:"total"`
	Accounts []*AdminAccountItem `json:"accounts"`
}

type AdminAccountItem struct {
	UserID       string `json:"userID"`
	Balance      int64  `json:"balance"`
	FrozenAmount int64  `json:"frozenAmount"`
	Currency     string `json:"currency"`
	Status       int32  `json:"status"`
	CreateTime   int64  `json:"createTime"`
}

type AdminAdjustBalanceReq struct {
	UserID string `json:"userID" binding:"required"`
	Amount int64  `json:"amount" binding:"required,gt=0"`
	IsAdd  bool   `json:"isAdd"`
	Remark string `json:"remark" binding:"required"`
}

type AdminFreezeAccountReq struct {
	UserID string `json:"userID" binding:"required"`
	Reason string `json:"reason" binding:"required"`
}

type AdminUnfreezeAccountReq struct {
	UserID string `json:"userID" binding:"required"`
	Reason string `json:"reason"`
}

type AdminFreezeAmountReq struct {
	UserID string `json:"userID" binding:"required"`
	Amount int64  `json:"amount" binding:"required,gt=0"`
	Reason string `json:"reason" binding:"required"`
}

type AdminFreezeAmountResp struct {
	FreezeID string `json:"freezeID"`
	UserID   string `json:"userID"`
	Amount   int64  `json:"amount"`
}

type AdminUnfreezeAmountReq struct {
	FreezeID string `json:"freezeID" binding:"required"`
	UserID   string `json:"userID" binding:"required"`
}

type AdminGetAuditLogsReq struct {
	UserID         string     `json:"userID"`
	Action         string     `json:"action"`
	OperatorUserID string     `json:"operatorUserID"`
	StartTime      *time.Time `json:"startTime"`
	EndTime        *time.Time `json:"endTime"`
	Pagination
}

type AdminGetAuditLogsResp struct {
	Total int64           `json:"total"`
	Logs  []*AuditLogItem `json:"logs"`
}

type AuditLogItem struct {
	AuditID        string `json:"auditID"`
	UserID         string `json:"userID"`
	Action         string `json:"action"`
	Detail         string `json:"detail"`
	OperatorUserID string `json:"operatorUserID"`
	IP             string `json:"ip"`
	CreateTime     int64  `json:"createTime"`
}

type AdminGetFreezeRecordsReq struct {
	UserID       string  `json:"userID" binding:"required"`
	StatusFilter []int32 `json:"statusFilter"`
	Pagination
}

type AdminGetFreezeRecordsResp struct {
	Total   int64              `json:"total"`
	Records []*FreezeRecordItem `json:"records"`
}

type FreezeRecordItem struct {
	FreezeID       string `json:"freezeID"`
	UserID         string `json:"userID"`
	Amount         int64  `json:"amount"`
	Type           int32  `json:"type"`
	Reason         string `json:"reason"`
	OperatorUserID string `json:"operatorUserID"`
	Status         int32  `json:"status"`
	CreateTime     int64  `json:"createTime"`
}

// Pagination is a common pagination struct for wallet APIs.
type Pagination struct {
	PageNumber int32 `json:"pageNumber" binding:"required,gt=0"`
	ShowNumber int32 `json:"showNumber" binding:"required,gt=0,lte=100"`
}
