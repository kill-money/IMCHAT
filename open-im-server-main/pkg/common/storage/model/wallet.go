package model

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

// WalletAccount 用户钱包账户 — 每个用户一条记录
type WalletAccount struct {
	ID             primitive.ObjectID `bson:"_id"`
	UserID         string             `bson:"user_id"`
	Balance        int64              `bson:"balance"`         // 可用余额，单位：分
	FrozenAmount   int64              `bson:"frozen_amount"`   // 冻结金额，单位：分
	Currency       string             `bson:"currency"`        // 币种代码 CNY/USD
	Status         int32              `bson:"status"`          // 1-正常 2-冻结 3-注销
	Version        int64              `bson:"version"`         // 乐观锁版本号
	CreateTime     time.Time          `bson:"create_time"`
	UpdateTime     time.Time          `bson:"update_time"`
}

// WalletTransaction 交易流水 — 每笔资金变动一条不可变记录
type WalletTransaction struct {
	ID              primitive.ObjectID `bson:"_id"`
	TransactionID   string             `bson:"transaction_id"`   // 全局唯一交易号
	UserID          string             `bson:"user_id"`
	OppositeUserID  string             `bson:"opposite_user_id"` // 对方用户(转账场景)
	Type            int32              `bson:"type"`             // 1-充值 2-提现 3-转出 4-转入 5-管理员调增 6-管理员调减 7-冻结 8-解冻
	Amount          int64              `bson:"amount"`           // 变动金额（正数），单位：分
	BalanceBefore   int64              `bson:"balance_before"`   // 变动前余额
	BalanceAfter    int64              `bson:"balance_after"`    // 变动后余额
	Status          int32              `bson:"status"`           // 1-处理中 2-成功 3-失败 4-已撤销
	Remark          string             `bson:"remark"`
	IdempotencyKey  string             `bson:"idempotency_key"`  // 幂等键，防重复提交
	OperatorUserID  string             `bson:"operator_user_id"` // 操作人(管理员调账时有值)
	CreateTime      time.Time          `bson:"create_time"`
	UpdateTime      time.Time          `bson:"update_time"`
}

// WalletFreezeRecord 冻结/解冻记录
type WalletFreezeRecord struct {
	ID             primitive.ObjectID `bson:"_id"`
	FreezeID       string             `bson:"freeze_id"`
	UserID         string             `bson:"user_id"`
	Amount         int64              `bson:"amount"`           // 冻结金额，单位：分
	Type           int32              `bson:"type"`             // 1-冻结 2-解冻
	Reason         string             `bson:"reason"`
	OperatorUserID string             `bson:"operator_user_id"` // 操作人
	Status         int32              `bson:"status"`           // 1-生效中 2-已解冻 3-已过期
	CreateTime     time.Time          `bson:"create_time"`
	UpdateTime     time.Time          `bson:"update_time"`
}

// WalletAuditLog 审计日志 — 只追加不可变
type WalletAuditLog struct {
	ID             primitive.ObjectID `bson:"_id"`
	AuditID        string             `bson:"audit_id"`
	UserID         string             `bson:"user_id"`
	Action         string             `bson:"action"`           // 操作类型: recharge/withdraw/transfer/freeze/unfreeze/adjust
	Detail         string             `bson:"detail"`           // JSON格式操作详情
	OperatorUserID string             `bson:"operator_user_id"`
	IP             string             `bson:"ip"`
	UserAgent      string             `bson:"user_agent"`
	CreateTime     time.Time          `bson:"create_time"`
}

// 交易类型常量
const (
	TransactionTypeRecharge    = 1 // 充值
	TransactionTypeWithdraw    = 2 // 提现
	TransactionTypeTransferOut = 3 // 转出
	TransactionTypeTransferIn  = 4 // 转入
	TransactionTypeAdjustAdd   = 5 // 管理员调增
	TransactionTypeAdjustSub   = 6 // 管理员调减
	TransactionTypeFreeze      = 7 // 冻结
	TransactionTypeUnfreeze    = 8 // 解冻
)

// 交易状态常量
const (
	TransactionStatusPending   = 1 // 处理中
	TransactionStatusSuccess   = 2 // 成功
	TransactionStatusFailed    = 3 // 失败
	TransactionStatusCancelled = 4 // 已撤销
)

// 账户状态常量
const (
	AccountStatusNormal = 1 // 正常
	AccountStatusFrozen = 2 // 冻结
	AccountStatusClosed = 3 // 注销
)

// 冻结记录类型
const (
	FreezeTypeFreeze   = 1 // 冻结
	FreezeTypeUnfreeze = 2 // 解冻
)

// 冻结记录状态
const (
	FreezeStatusActive   = 1 // 生效中
	FreezeStatusReleased = 2 // 已解冻
	FreezeStatusExpired  = 3 // 已过期
)
