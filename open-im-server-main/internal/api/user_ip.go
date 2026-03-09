package api

import (
	"net"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/openimsdk/open-im-server/v3/pkg/apistruct"
	"github.com/openimsdk/open-im-server/v3/pkg/authverify"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/controller"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/apiresp"
	"github.com/openimsdk/tools/errs"
	"github.com/openimsdk/tools/log"
	"github.com/openimsdk/tools/mcontext"
)

type UserIPApi struct {
	ipDB controller.UserIPDatabase
}

func NewUserIPApi(ipDB controller.UserIPDatabase) *UserIPApi {
	return &UserIPApi{ipDB: ipDB}
}

// GetClientIP 从请求中提取真实客户端 IP
func GetClientIP(c *gin.Context) string {
	// 优先从 X-Forwarded-For 取第一个 IP
	if xff := c.GetHeader("X-Forwarded-For"); xff != "" {
		parts := strings.Split(xff, ",")
		ip := strings.TrimSpace(parts[0])
		if parsedIP := net.ParseIP(ip); parsedIP != nil {
			return ip
		}
	}
	// 其次从 X-Real-IP
	if xri := c.GetHeader("X-Real-IP"); xri != "" {
		ip := strings.TrimSpace(xri)
		if parsedIP := net.ParseIP(ip); parsedIP != nil {
			return ip
		}
	}
	// 最后用 RemoteAddr
	ip, _, err := net.SplitHostPort(c.Request.RemoteAddr)
	if err != nil {
		return c.Request.RemoteAddr
	}
	return ip
}

// checkIPViewPermission 检查 IP 查看权限：超级管理员或用户端管理员
func (a *UserIPApi) checkIPViewPermission(c *gin.Context) bool {
	// 后台超级管理员（share.yml 配置的 IMAdminUser）
	if authverify.IsAdmin(c) {
		return true
	}
	// 用户端管理员（app_role >= 1）
	userID := mcontext.GetOpUserID(c)
	role, err := a.ipDB.GetAppRole(c, userID)
	if err != nil {
		log.ZWarn(c, "checkIPViewPermission get role", err, "userID", userID)
		return false
	}
	return role >= model.AppRoleAppAdmin
}

// GetUserIPInfo 查看用户最后登录 IP
func (a *UserIPApi) GetUserIPInfo(c *gin.Context) {
	var req apistruct.GetUserIPInfoReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !a.checkIPViewPermission(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("no permission to view IP"))
		return
	}
	lastIP, lastTime, err := a.ipDB.GetUserIPInfo(c, req.UserID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	var loginTimeMilli int64
	if !lastTime.IsZero() {
		loginTimeMilli = lastTime.UnixMilli()
	}
	apiresp.GinSuccess(c, &apistruct.GetUserIPInfoResp{
		UserID:        req.UserID,
		LastIP:        lastIP,
		LastLoginTime: loginTimeMilli,
	})
}

// GetUserIPLogs 查看用户 IP 历史
func (a *UserIPApi) GetUserIPLogs(c *gin.Context) {
	var req apistruct.GetUserIPLogsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !a.checkIPViewPermission(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("no permission to view IP logs"))
		return
	}
	total, logs, err := a.ipDB.GetUserIPLogs(c, req.UserID, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	items := make([]*apistruct.UserIPLogItem, 0, len(logs))
	for _, l := range logs {
		items = append(items, &apistruct.UserIPLogItem{
			IP:        l.IP,
			Platform:  l.Platform,
			LoginTime: l.LoginTime.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, &apistruct.GetUserIPLogsResp{
		Total: total,
		Logs:  items,
	})
}

// SearchByIP 按 IP 搜索用户登录记录
func (a *UserIPApi) SearchByIP(c *gin.Context) {
	var req apistruct.SearchByIPReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !a.checkIPViewPermission(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("no permission to search by IP"))
		return
	}
	total, logs, err := a.ipDB.SearchByIP(c, req.IP, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	items := make([]*apistruct.UserIPLogItem, 0, len(logs))
	for _, l := range logs {
		items = append(items, &apistruct.UserIPLogItem{
			UserID:    l.UserID,
			IP:        l.IP,
			Platform:  l.Platform,
			LoginTime: l.LoginTime.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, &apistruct.SearchByIPResp{
		Total: total,
		Logs:  items,
	})
}

// SetAppRole 设置用户端管理员角色
func (a *UserIPApi) SetAppRole(c *gin.Context) {
	var req apistruct.SetAppRoleReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	// 仅超级管理员（后台配置的 IMAdmin）可调用
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("only super admin can set app role"))
		return
	}
	// 不允许设置自己
	opUserID := mcontext.GetOpUserID(c)
	if opUserID == req.UserID {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("cannot change own role"))
		return
	}
	// app_role 只能设为 0 或 1
	if req.AppRole != model.AppRoleNormal && req.AppRole != model.AppRoleAppAdmin {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("appRole must be 0 or 1"))
		return
	}
	if err := a.ipDB.SetAppRole(c, req.UserID, req.AppRole); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.SetAppRoleResp{})
}

// GetAppRole 查询用户角色
func (a *UserIPApi) GetAppRole(c *gin.Context) {
	var req apistruct.GetAppRoleReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	role, err := a.ipDB.GetAppRole(c, req.UserID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GetAppRoleResp{
		UserID:  req.UserID,
		AppRole: role,
	})
}

// RecordLoginIP 记录用户登录 IP（供内部调用）
func (a *UserIPApi) RecordLoginIP(c *gin.Context) {
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinSuccess(c, nil)
		return
	}
	ip := GetClientIP(c)
	platform, _ := c.Get("opUserPlatform")
	platformStr, _ := platform.(string)
	if err := a.ipDB.RecordLogin(c, userID, ip, platformStr); err != nil {
		log.ZWarn(c, "record login IP failed", err, "userID", userID, "ip", ip)
	}
	apiresp.GinSuccess(c, nil)
}
