package api

import (
	"github.com/gin-gonic/gin"
	"github.com/openimsdk/open-im-server/v3/pkg/apistruct"
	"github.com/openimsdk/open-im-server/v3/pkg/authverify"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/controller"
	"github.com/openimsdk/tools/apiresp"
	"github.com/openimsdk/tools/errs"
)

type ReceptionistApi struct {
	db controller.ReceptionistDatabase
}

func NewReceptionistApi(db controller.ReceptionistDatabase) *ReceptionistApi {
	return &ReceptionistApi{db: db}
}

// ===== 邀请码管理 =====

// GenInviteCode 为接待员生成邀请码
func (a *ReceptionistApi) GenInviteCode(c *gin.Context) {
	var req apistruct.GenInviteCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return
	}
	code, err := a.db.GenInviteCode(c, req.UserID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GenInviteCodeResp{
		UserID:     code.UserID,
		InviteCode: code.InviteCode,
		Status:     code.Status,
		CreatedAt:  code.CreatedAt.UnixMilli(),
	})
}

// GetInviteCode 获取接待员的邀请码
func (a *ReceptionistApi) GetInviteCode(c *gin.Context) {
	var req apistruct.GetInviteCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	code, err := a.db.GetInviteCode(c, req.UserID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GetInviteCodeResp{
		UserID:     code.UserID,
		InviteCode: code.InviteCode,
		Status:     code.Status,
		CreatedAt:  code.CreatedAt.UnixMilli(),
	})
}

// UpdateInviteCodeStatus 启用/禁用邀请码
func (a *ReceptionistApi) UpdateInviteCodeStatus(c *gin.Context) {
	var req apistruct.UpdateInviteCodeStatusReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return
	}
	if err := a.db.UpdateInviteCodeStatus(c, req.InviteCode, req.Status); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.UpdateInviteCodeStatusResp{})
}

// DeleteInviteCode 删除邀请码
func (a *ReceptionistApi) DeleteInviteCode(c *gin.Context) {
	var req apistruct.DeleteInviteCodeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return
	}
	if err := a.db.DeleteInviteCode(c, req.InviteCode); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.DeleteInviteCodeResp{})
}

// SearchInviteCodes 搜索邀请码列表
func (a *ReceptionistApi) SearchInviteCodes(c *gin.Context) {
	var req apistruct.SearchInviteCodesReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return
	}
	total, codes, err := a.db.SearchInviteCodes(c, req.Keyword, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	items := make([]*apistruct.InviteCodeItem, 0, len(codes))
	for _, code := range codes {
		items = append(items, &apistruct.InviteCodeItem{
			UserID:     code.UserID,
			InviteCode: code.InviteCode,
			Status:     code.Status,
			CreatedAt:  code.CreatedAt.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, &apistruct.SearchInviteCodesResp{
		Total: total,
		Codes: items,
	})
}

// ===== 客户绑定 =====

// BindCustomer 手动绑定客户到接待员
func (a *ReceptionistApi) BindCustomer(c *gin.Context) {
	var req apistruct.BindCustomerReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if err := a.db.BindCustomer(c, req.CustomerID, req.InviteCode); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.BindCustomerResp{})
}

// GetBinding 查看客户绑定关系
func (a *ReceptionistApi) GetBinding(c *gin.Context) {
	var req apistruct.GetBindingReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	binding, err := a.db.GetBinding(c, req.CustomerID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GetBindingResp{
		Binding: &apistruct.BindingItem{
			CustomerID:     binding.CustomerID,
			ReceptionistID: binding.ReceptionistID,
			InviteCode:     binding.InviteCode,
			BoundAt:        binding.BoundAt.UnixMilli(),
		},
	})
}

// PageBindings 分页查看接待员的客户列表
func (a *ReceptionistApi) PageBindings(c *gin.Context) {
	var req apistruct.PageBindingsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	total, bindings, err := a.db.PageBindings(c, req.ReceptionistID, req.Keyword, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	items := make([]*apistruct.BindingItem, 0, len(bindings))
	for _, b := range bindings {
		items = append(items, &apistruct.BindingItem{
			CustomerID:     b.CustomerID,
			ReceptionistID: b.ReceptionistID,
			InviteCode:     b.InviteCode,
			BoundAt:        b.BoundAt.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, &apistruct.PageBindingsResp{
		Total:    total,
		Bindings: items,
	})
}

// GetBindingStats 获取绑定统计
func (a *ReceptionistApi) GetBindingStats(c *gin.Context) {
	var req apistruct.GetBindingStatsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	codeCount, totalCount, err := a.db.GetBindingStats(c, req.InviteCode, req.ReceptionistID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GetBindingStatsResp{
		CodeCount:  codeCount,
		TotalCount: totalCount,
	})
}

// ===== 问候语管理 =====

// SetGreeting 设置问候语
func (a *ReceptionistApi) SetGreeting(c *gin.Context) {
	var req apistruct.SetGreetingReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if err := a.db.SetGreeting(c, req.ReceptionistID, req.GreetingText); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.SetGreetingResp{})
}

// GetGreeting 获取问候语
func (a *ReceptionistApi) GetGreeting(c *gin.Context) {
	var req apistruct.GetGreetingReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	text, err := a.db.GetGreeting(c, req.ReceptionistID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GetGreetingResp{
		ReceptionistID: req.ReceptionistID,
		GreetingText:   text,
	})
}

// SearchGreetings 搜索问候语列表
func (a *ReceptionistApi) SearchGreetings(c *gin.Context) {
	var req apistruct.SearchGreetingsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return
	}
	total, greetings, err := a.db.SearchGreetings(c, req.Keyword, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	items := make([]*apistruct.GreetingItem, 0, len(greetings))
	for _, g := range greetings {
		items = append(items, &apistruct.GreetingItem{
			ReceptionistID: g.ReceptionistID,
			GreetingText:   g.GreetingText,
			UpdatedAt:      g.UpdatedAt.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, &apistruct.SearchGreetingsResp{
		Total:     total,
		Greetings: items,
	})
}

// ===== 注册时自动处理 =====

// OnCustomerRegister 客户注册时: 绑定+加好友+发问候语
func (a *ReceptionistApi) OnCustomerRegister(c *gin.Context) {
	var req apistruct.OnCustomerRegisterReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if err := a.db.OnCustomerRegister(c, req.CustomerID, req.InviteCode); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.OnCustomerRegisterResp{})
}

// ===== 发送日志 =====

// SearchSendLogs 搜索问候语发送日志
func (a *ReceptionistApi) SearchSendLogs(c *gin.Context) {
	var req apistruct.SearchSendLogsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return
	}
	total, logs, err := a.db.SearchSendLogs(c, req.ReceptionistID, req.StartTime, req.EndTime, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	items := make([]*apistruct.SendLogItem, 0, len(logs))
	for _, l := range logs {
		items = append(items, &apistruct.SendLogItem{
			ReceptionistID: l.ReceptionistID,
			CustomerID:     l.CustomerID,
			GreetingText:   l.GreetingText,
			SentAt:         l.SentAt.UnixMilli(),
			Status:         l.Status,
		})
	}
	apiresp.GinSuccess(c, &apistruct.SearchSendLogsResp{
		Total: total,
		Logs:  items,
	})
}
