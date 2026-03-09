package database

import (
	"context"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/pagination"
)

type UserIPLog interface {
	Create(ctx context.Context, log *model.UserIPLog) error
	PageByUser(ctx context.Context, userID string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error)
	GetLastLog(ctx context.Context, userID string) (*model.UserIPLog, error)
	SearchByIP(ctx context.Context, ip string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error)
	DeleteBefore(ctx context.Context, before time.Time) error
}
