package api

import (
	"github.com/gin-gonic/gin"
	"github.com/openimsdk/open-im-server/v3/pkg/apistruct"
	"github.com/openimsdk/open-im-server/v3/pkg/authverify"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/controller"
	model "github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/apiresp"
	"github.com/openimsdk/tools/errs"
	"github.com/openimsdk/tools/mcontext"
)

type WalletApi struct {
	walletDB controller.WalletDatabase
}

func NewWalletApi(walletDB controller.WalletDatabase) *WalletApi {
	return &WalletApi{walletDB: walletDB}
}

// walletPagination implements pagination.Pagination interface.
type walletPagination struct {
	pageNumber int32
	showNumber int32
}

func (p *walletPagination) GetPageNumber() int32 { return p.pageNumber }
func (p *walletPagination) GetShowNumber() int32 { return p.showNumber }

func toPagination(p apistruct.Pagination) *walletPagination {
	return &walletPagination{pageNumber: p.PageNumber, showNumber: p.ShowNumber}
}

// ===== User-side endpoints =====

func (w *WalletApi) CreateAccount(c *gin.Context) {
	var req apistruct.CreateWalletAccountReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("missing user identity"))
		return
	}
	if err := w.walletDB.CreateAccount(c, userID, req.Currency); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.CreateWalletAccountResp{
		UserID:   userID,
		Currency: req.Currency,
	})
}

func (w *WalletApi) GetBalance(c *gin.Context) {
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("missing user identity"))
		return
	}
	account, err := w.walletDB.GetAccount(c, userID)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.GetWalletAccountResp{
		UserID:       account.UserID,
		Balance:      account.Balance,
		FrozenAmount: account.FrozenAmount,
		Currency:     account.Currency,
		Status:       account.Status,
	})
}

func (w *WalletApi) Recharge(c *gin.Context) {
	var req apistruct.WalletRechargeReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("missing user identity"))
		return
	}
	tx, err := w.walletDB.Recharge(c, userID, req.Amount, req.IdempotencyKey, req.Remark)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, toTransactionResp(tx))
}

func (w *WalletApi) Withdraw(c *gin.Context) {
	var req apistruct.WalletWithdrawReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("missing user identity"))
		return
	}
	tx, err := w.walletDB.Withdraw(c, userID, req.Amount, req.IdempotencyKey, req.Remark)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, toTransactionResp(tx))
}

func (w *WalletApi) Transfer(c *gin.Context) {
	var req apistruct.WalletTransferReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("missing user identity"))
		return
	}
	txOut, txIn, err := w.walletDB.Transfer(c, userID, req.ToUserID, req.Amount, req.IdempotencyKey, req.Remark)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.WalletTransferResp{
		TransactionOut: toTransactionResp(txOut),
		TransactionIn:  toTransactionResp(txIn),
	})
}

func (w *WalletApi) GetTransactions(c *gin.Context) {
	var req apistruct.GetWalletTransactionsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	userID := mcontext.GetOpUserID(c)
	if userID == "" {
		apiresp.GinError(c, errs.ErrArgs.WrapMsg("missing user identity"))
		return
	}
	total, txs, err := w.walletDB.GetTransactionPage(c, userID, req.Types, req.StartTime, req.EndTime, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	resp := &apistruct.GetWalletTransactionsResp{
		Total:        total,
		Transactions: make([]*apistruct.WalletTransactionResp, 0, len(txs)),
	}
	for _, t := range txs {
		resp.Transactions = append(resp.Transactions, toTransactionResp(t))
	}
	apiresp.GinSuccess(c, resp)
}

// ===== Admin-side endpoints =====

func (w *WalletApi) checkAdmin(c *gin.Context) bool {
	if !authverify.IsAdmin(c) {
		apiresp.GinError(c, errs.ErrNoPermission.WrapMsg("admin only"))
		return false
	}
	return true
}

func (w *WalletApi) AdminGetOverview(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	overview, err := w.walletDB.GetOverview(c)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.AdminGetWalletOverviewResp{
		TotalAccounts:  overview.TotalAccounts,
		FrozenAccounts: overview.FrozenAccounts,
		TotalBalance:   overview.TotalBalance,
		TotalFrozen:    overview.TotalFrozen,
	})
}

func (w *WalletApi) AdminGetAccountList(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminGetAccountListReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	total, accounts, err := w.walletDB.GetAccountPage(c, req.StatusFilter, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	resp := &apistruct.AdminGetAccountListResp{
		Total:    total,
		Accounts: make([]*apistruct.AdminAccountItem, 0, len(accounts)),
	}
	for _, a := range accounts {
		resp.Accounts = append(resp.Accounts, &apistruct.AdminAccountItem{
			UserID:       a.UserID,
			Balance:      a.Balance,
			FrozenAmount: a.FrozenAmount,
			Currency:     a.Currency,
			Status:       a.Status,
			CreateTime:   a.CreateTime.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, resp)
}

func (w *WalletApi) AdminAdjustBalance(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminAdjustBalanceReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	operatorUserID := mcontext.GetOpUserID(c)
	tx, err := w.walletDB.AdminAdjust(c, req.UserID, req.Amount, req.IsAdd, operatorUserID, req.Remark)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, toTransactionResp(tx))
}

func (w *WalletApi) AdminFreezeAccount(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminFreezeAccountReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	operatorUserID := mcontext.GetOpUserID(c)
	if err := w.walletDB.FreezeAccount(c, req.UserID, operatorUserID, req.Reason); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, nil)
}

func (w *WalletApi) AdminUnfreezeAccount(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminUnfreezeAccountReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	operatorUserID := mcontext.GetOpUserID(c)
	if err := w.walletDB.UnfreezeAccount(c, req.UserID, operatorUserID, req.Reason); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, nil)
}

func (w *WalletApi) AdminFreezeAmount(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminFreezeAmountReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	operatorUserID := mcontext.GetOpUserID(c)
	record, err := w.walletDB.FreezeAmount(c, req.UserID, req.Amount, operatorUserID, req.Reason)
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, &apistruct.AdminFreezeAmountResp{
		FreezeID: record.FreezeID,
		UserID:   record.UserID,
		Amount:   record.Amount,
	})
}

func (w *WalletApi) AdminUnfreezeAmount(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminUnfreezeAmountReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	operatorUserID := mcontext.GetOpUserID(c)
	if err := w.walletDB.UnfreezeAmount(c, req.FreezeID, req.UserID, operatorUserID); err != nil {
		apiresp.GinError(c, err)
		return
	}
	apiresp.GinSuccess(c, nil)
}

func (w *WalletApi) AdminGetAuditLogs(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminGetAuditLogsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	total, logs, err := w.walletDB.GetAuditLogPage(c, req.UserID, req.Action, req.OperatorUserID, req.StartTime, req.EndTime, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	resp := &apistruct.AdminGetAuditLogsResp{
		Total: total,
		Logs:  make([]*apistruct.AuditLogItem, 0, len(logs)),
	}
	for _, l := range logs {
		resp.Logs = append(resp.Logs, &apistruct.AuditLogItem{
			AuditID:        l.AuditID,
			UserID:         l.UserID,
			Action:         l.Action,
			Detail:         l.Detail,
			OperatorUserID: l.OperatorUserID,
			IP:             l.IP,
			CreateTime:     l.CreateTime.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, resp)
}

func (w *WalletApi) AdminGetFreezeRecords(c *gin.Context) {
	if !w.checkAdmin(c) {
		return
	}
	var req apistruct.AdminGetFreezeRecordsReq
	if err := c.ShouldBindJSON(&req); err != nil {
		apiresp.GinError(c, errs.ErrArgs.WithDetail(err.Error()).Wrap())
		return
	}
	total, records, err := w.walletDB.GetFreezeRecordPage(c, req.UserID, req.StatusFilter, toPagination(req.Pagination))
	if err != nil {
		apiresp.GinError(c, err)
		return
	}
	resp := &apistruct.AdminGetFreezeRecordsResp{
		Total:   total,
		Records: make([]*apistruct.FreezeRecordItem, 0, len(records)),
	}
	for _, r := range records {
		resp.Records = append(resp.Records, &apistruct.FreezeRecordItem{
			FreezeID:       r.FreezeID,
			UserID:         r.UserID,
			Amount:         r.Amount,
			Type:           r.Type,
			Reason:         r.Reason,
			OperatorUserID: r.OperatorUserID,
			Status:         r.Status,
			CreateTime:     r.CreateTime.UnixMilli(),
		})
	}
	apiresp.GinSuccess(c, resp)
}

// ===== Helpers =====

func toTransactionResp(t *model.WalletTransaction) *apistruct.WalletTransactionResp {
	if t == nil {
		return nil
	}
	return &apistruct.WalletTransactionResp{
		TransactionID:  t.TransactionID,
		UserID:         t.UserID,
		OppositeUserID: t.OppositeUserID,
		Type:           t.Type,
		Amount:         t.Amount,
		BalanceBefore:  t.BalanceBefore,
		BalanceAfter:   t.BalanceAfter,
		Status:         t.Status,
		Remark:         t.Remark,
		CreateTime:     t.CreateTime.UnixMilli(),
	}
}
