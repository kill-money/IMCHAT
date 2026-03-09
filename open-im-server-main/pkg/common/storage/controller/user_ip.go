package controller

import (
	"context"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/database"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/pagination"
)

type UserIPDatabase interface {
	// RecordLogin 记录用户登录 IP
	RecordLogin(ctx context.Context, userID, ip, platform string) error
	// GetUserIPInfo 获取用户最后登录 IP
	GetUserIPInfo(ctx context.Context, userID string) (lastIP string, lastTime time.Time, err error)
	// GetUserIPLogs 获取用户 IP 历史
	GetUserIPLogs(ctx context.Context, userID string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error)
	// SearchByIP 按 IP 搜索
	SearchByIP(ctx context.Context, ip string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error)
	// SetAppRole 设置用户角色
	SetAppRole(ctx context.Context, userID string, appRole int32) error
	// GetAppRole 获取用户角色
	GetAppRole(ctx context.Context, userID string) (int32, error)
}

type userIPDatabase struct {
	ipLog  database.UserIPLog
	userDB database.User
}

func NewUserIPDatabase(ipLog database.UserIPLog, userDB database.User) UserIPDatabase {
	return &userIPDatabase{ipLog: ipLog, userDB: userDB}
}

func (d *userIPDatabase) RecordLogin(ctx context.Context, userID, ip, platform string) error {
	log := &model.UserIPLog{
		UserID:    userID,
		IP:        ip,
		Platform:  platform,
		LoginTime: time.Now(),
	}
	if err := d.ipLog.Create(ctx, log); err != nil {
		return err
	}
	return d.userDB.UpdateByMap(ctx, userID, map[string]any{
		"last_login_ip":   ip,
		"last_login_time": time.Now(),
	})
}

func (d *userIPDatabase) GetUserIPInfo(ctx context.Context, userID string) (string, time.Time, error) {
	user, err := d.userDB.Take(ctx, userID)
	if err != nil {
		return "", time.Time{}, err
	}
	return user.LastLoginIP, user.LastLoginTime, nil
}

func (d *userIPDatabase) GetUserIPLogs(ctx context.Context, userID string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error) {
	return d.ipLog.PageByUser(ctx, userID, pagination)
}

func (d *userIPDatabase) SearchByIP(ctx context.Context, ip string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error) {
	return d.ipLog.SearchByIP(ctx, ip, pagination)
}

func (d *userIPDatabase) SetAppRole(ctx context.Context, userID string, appRole int32) error {
	return d.userDB.UpdateByMap(ctx, userID, map[string]any{
		"app_role": appRole,
	})
}

func (d *userIPDatabase) GetAppRole(ctx context.Context, userID string) (int32, error) {
	user, err := d.userDB.Take(ctx, userID)
	if err != nil {
		return 0, err
	}
	return user.AppRole, nil
}
