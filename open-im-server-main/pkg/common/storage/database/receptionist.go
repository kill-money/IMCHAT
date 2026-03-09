package database

import (
	"context"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/pagination"
)

// ReceptionistInviteCode 邀请码数据库接口
type ReceptionistInviteCode interface {
	Create(ctx context.Context, code *model.ReceptionistInviteCode) error
	GetByUserID(ctx context.Context, userID string) (*model.ReceptionistInviteCode, error)
	GetByCode(ctx context.Context, inviteCode string) (*model.ReceptionistInviteCode, error)
	UpdateStatus(ctx context.Context, inviteCode string, status int32) error
	Delete(ctx context.Context, inviteCode string) error
	Search(ctx context.Context, keyword string, pagination pagination.Pagination) (int64, []*model.ReceptionistInviteCode, error)
	CountByUserID(ctx context.Context, userID string) (int64, error)
}

// CustomerReceptionistBinding 客户绑定关系数据库接口
type CustomerReceptionistBinding interface {
	Create(ctx context.Context, binding *model.CustomerReceptionistBinding) error
	GetByCustomerID(ctx context.Context, customerID string) (*model.CustomerReceptionistBinding, error)
	PageByReceptionist(ctx context.Context, receptionistID string, keyword string, pagination pagination.Pagination) (int64, []*model.CustomerReceptionistBinding, error)
	CountByInviteCode(ctx context.Context, inviteCode string) (int64, error)
	CountByReceptionist(ctx context.Context, receptionistID string) (int64, error)
}

// ReceptionistGreeting 问候语数据库接口
type ReceptionistGreeting interface {
	Upsert(ctx context.Context, greeting *model.ReceptionistGreeting) error
	GetByReceptionistID(ctx context.Context, receptionistID string) (*model.ReceptionistGreeting, error)
	Search(ctx context.Context, keyword string, pagination pagination.Pagination) (int64, []*model.ReceptionistGreeting, error)
}

// GreetingSendLog 问候语发送日志数据库接口
type GreetingSendLog interface {
	Create(ctx context.Context, log *model.GreetingSendLog) error
	Search(ctx context.Context, receptionistID string, startTime, endTime int64, pagination pagination.Pagination) (int64, []*model.GreetingSendLog, error)
}
