package model

import "time"

// ReceptionistInviteCode 接待员邀请码表
type ReceptionistInviteCode struct {
	UserID     string    `bson:"user_id"`
	InviteCode string    `bson:"invite_code"`
	Status     int32     `bson:"status"` // 1启用 0禁用
	CreatedAt  time.Time `bson:"created_at"`
}

const (
	InviteCodeStatusEnabled  int32 = 1
	InviteCodeStatusDisabled int32 = 0
)

// CustomerReceptionistBinding 客户-接待员绑定关系表
type CustomerReceptionistBinding struct {
	CustomerID     string    `bson:"customer_id"`
	ReceptionistID string    `bson:"receptionist_id"`
	InviteCode     string    `bson:"invite_code"`
	BoundAt        time.Time `bson:"bound_at"`
}

// ReceptionistGreeting 接待员问候语
type ReceptionistGreeting struct {
	ReceptionistID string    `bson:"receptionist_id"`
	GreetingText   string    `bson:"greeting_text"`
	UpdatedAt      time.Time `bson:"updated_at"`
}

const DefaultGreetingText = "您好，欢迎使用本平台，我是您的专属接待员，有任何问题请随时联系我。"

// GreetingSendLog 问候语发送日志
type GreetingSendLog struct {
	ReceptionistID string    `bson:"receptionist_id"`
	CustomerID     string    `bson:"customer_id"`
	GreetingText   string    `bson:"greeting_text"`
	SentAt         time.Time `bson:"sent_at"`
	Status         int32     `bson:"status"` // 1成功 0失败
}

const (
	GreetingSendSuccess int32 = 1
	GreetingSendFailed  int32 = 0
)
