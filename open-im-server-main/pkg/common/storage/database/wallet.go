package database

import (
	"context"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/pagination"
)

type WalletAccount interface {
	Create(ctx context.Context, account *model.WalletAccount) error
	Take(ctx context.Context, userID string) (*model.WalletAccount, error)
	UpdateBalanceWithVersion(ctx context.Context, userID string, version int64, balanceDelta int64, frozenDelta int64) error
	UpdateStatus(ctx context.Context, userID string, status int32) error
	Page(ctx context.Context, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletAccount, error)
	CountByStatus(ctx context.Context) (total int64, frozen int64, err error)
	SumBalance(ctx context.Context) (totalBalance int64, totalFrozen int64, err error)
}

type WalletTransaction interface {
	Create(ctx context.Context, tx *model.WalletTransaction) error
	Take(ctx context.Context, transactionID string) (*model.WalletTransaction, error)
	TakeByIdempotencyKey(ctx context.Context, key string) (*model.WalletTransaction, error)
	UpdateStatus(ctx context.Context, transactionID string, status int32) error
	PageByUser(ctx context.Context, userID string, txTypes []int32, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletTransaction, error)
	SumByTypeAndRange(ctx context.Context, txType int32, start, end time.Time) (int64, error)
}

type WalletFreezeRecord interface {
	Create(ctx context.Context, record *model.WalletFreezeRecord) error
	UpdateStatus(ctx context.Context, freezeID string, status int32) error
	PageByUser(ctx context.Context, userID string, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletFreezeRecord, error)
	GetActiveFreezes(ctx context.Context, userID string) ([]*model.WalletFreezeRecord, error)
}

type WalletAuditLog interface {
	Create(ctx context.Context, log *model.WalletAuditLog) error
	PageByUser(ctx context.Context, userID string, action string, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error)
	PageByOperator(ctx context.Context, operatorUserID string, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error)
	PageAll(ctx context.Context, userID, action, operatorUserID string, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error)
}
