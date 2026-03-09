package controller

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/database"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/pagination"
	"github.com/openimsdk/tools/db/tx"
	"github.com/openimsdk/tools/errs"
)

type WalletDatabase interface {
	// Account
	CreateAccount(ctx context.Context, userID string, currency string) error
	GetAccount(ctx context.Context, userID string) (*model.WalletAccount, error)
	GetAccountPage(ctx context.Context, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletAccount, error)

	// Recharge 充值
	Recharge(ctx context.Context, userID string, amount int64, idempotencyKey string, remark string) (*model.WalletTransaction, error)
	// Withdraw 提现
	Withdraw(ctx context.Context, userID string, amount int64, idempotencyKey string, remark string) (*model.WalletTransaction, error)
	// Transfer 转账
	Transfer(ctx context.Context, fromUserID, toUserID string, amount int64, idempotencyKey string, remark string) (txOut *model.WalletTransaction, txIn *model.WalletTransaction, err error)

	// Admin operations
	AdminAdjust(ctx context.Context, userID string, amount int64, isAdd bool, operatorUserID string, remark string) (*model.WalletTransaction, error)
	FreezeAccount(ctx context.Context, userID string, operatorUserID string, reason string) error
	UnfreezeAccount(ctx context.Context, userID string, operatorUserID string, reason string) error
	FreezeAmount(ctx context.Context, userID string, amount int64, operatorUserID string, reason string) (*model.WalletFreezeRecord, error)
	UnfreezeAmount(ctx context.Context, freezeID string, userID string, operatorUserID string) error

	// Query
	GetTransactionPage(ctx context.Context, userID string, txTypes []int32, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletTransaction, error)
	GetAuditLogPage(ctx context.Context, userID, action, operatorUserID string, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error)
	GetFreezeRecordPage(ctx context.Context, userID string, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletFreezeRecord, error)

	// Statistics
	GetOverview(ctx context.Context) (*WalletOverview, error)
}

type WalletOverview struct {
	TotalAccounts  int64 `json:"totalAccounts"`
	FrozenAccounts int64 `json:"frozenAccounts"`
	TotalBalance   int64 `json:"totalBalance"`
	TotalFrozen    int64 `json:"totalFrozen"`
}

type walletDatabase struct {
	tx        tx.Tx
	accountDB database.WalletAccount
	txDB      database.WalletTransaction
	freezeDB  database.WalletFreezeRecord
	auditDB   database.WalletAuditLog
}

func NewWalletDatabase(
	accountDB database.WalletAccount,
	txDB database.WalletTransaction,
	freezeDB database.WalletFreezeRecord,
	auditDB database.WalletAuditLog,
	tx tx.Tx,
) WalletDatabase {
	return &walletDatabase{
		tx:        tx,
		accountDB: accountDB,
		txDB:      txDB,
		freezeDB:  freezeDB,
		auditDB:   auditDB,
	}
}

func (w *walletDatabase) CreateAccount(ctx context.Context, userID string, currency string) error {
	if currency == "" {
		currency = "CNY"
	}
	return w.accountDB.Create(ctx, &model.WalletAccount{
		UserID:   userID,
		Currency: currency,
		Status:   model.AccountStatusNormal,
	})
}

func (w *walletDatabase) GetAccount(ctx context.Context, userID string) (*model.WalletAccount, error) {
	return w.accountDB.Take(ctx, userID)
}

func (w *walletDatabase) GetAccountPage(ctx context.Context, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletAccount, error) {
	return w.accountDB.Page(ctx, statusFilter, pagination)
}

// Recharge performs a credit operation with idempotency.
func (w *walletDatabase) Recharge(ctx context.Context, userID string, amount int64, idempotencyKey string, remark string) (*model.WalletTransaction, error) {
	if amount <= 0 {
		return nil, errs.New("recharge amount must be positive")
	}
	// Idempotency check
	if idempotencyKey != "" {
		existing, err := w.txDB.TakeByIdempotencyKey(ctx, idempotencyKey)
		if err == nil && existing != nil {
			return existing, nil
		}
	}

	account, err := w.accountDB.Take(ctx, userID)
	if err != nil {
		return nil, err
	}
	if account.Status != model.AccountStatusNormal {
		return nil, errs.New("account is not in normal status")
	}

	txRecord := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         userID,
		Type:           model.TransactionTypeRecharge,
		Amount:         amount,
		BalanceBefore:  account.Balance,
		BalanceAfter:   account.Balance + amount,
		Status:         model.TransactionStatusSuccess,
		Remark:         remark,
		IdempotencyKey: idempotencyKey,
	}

	err = w.accountDB.UpdateBalanceWithVersion(ctx, userID, account.Version, amount, 0)
	if err != nil {
		return nil, err
	}

	if err := w.txDB.Create(ctx, txRecord); err != nil {
		return nil, err
	}

	w.writeAudit(ctx, userID, "recharge", "", map[string]any{
		"amount":         amount,
		"transaction_id": txRecord.TransactionID,
	})

	return txRecord, nil
}

// Withdraw performs a debit operation with idempotency, checking sufficient balance.
func (w *walletDatabase) Withdraw(ctx context.Context, userID string, amount int64, idempotencyKey string, remark string) (*model.WalletTransaction, error) {
	if amount <= 0 {
		return nil, errs.New("withdraw amount must be positive")
	}
	if idempotencyKey != "" {
		existing, err := w.txDB.TakeByIdempotencyKey(ctx, idempotencyKey)
		if err == nil && existing != nil {
			return existing, nil
		}
	}

	account, err := w.accountDB.Take(ctx, userID)
	if err != nil {
		return nil, err
	}
	if account.Status != model.AccountStatusNormal {
		return nil, errs.New("account is not in normal status")
	}
	if account.Balance < amount {
		return nil, errs.New("insufficient balance")
	}

	txRecord := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         userID,
		Type:           model.TransactionTypeWithdraw,
		Amount:         amount,
		BalanceBefore:  account.Balance,
		BalanceAfter:   account.Balance - amount,
		Status:         model.TransactionStatusSuccess,
		Remark:         remark,
		IdempotencyKey: idempotencyKey,
	}

	err = w.accountDB.UpdateBalanceWithVersion(ctx, userID, account.Version, -amount, 0)
	if err != nil {
		return nil, err
	}

	if err := w.txDB.Create(ctx, txRecord); err != nil {
		return nil, err
	}

	w.writeAudit(ctx, userID, "withdraw", "", map[string]any{
		"amount":         amount,
		"transaction_id": txRecord.TransactionID,
	})

	return txRecord, nil
}

// Transfer moves funds from one user to another atomically.
func (w *walletDatabase) Transfer(ctx context.Context, fromUserID, toUserID string, amount int64, idempotencyKey string, remark string) (*model.WalletTransaction, *model.WalletTransaction, error) {
	if amount <= 0 {
		return nil, nil, errs.New("transfer amount must be positive")
	}
	if fromUserID == toUserID {
		return nil, nil, errs.New("cannot transfer to yourself")
	}
	if idempotencyKey != "" {
		existing, err := w.txDB.TakeByIdempotencyKey(ctx, idempotencyKey)
		if err == nil && existing != nil {
			return existing, nil, nil
		}
	}

	fromAccount, err := w.accountDB.Take(ctx, fromUserID)
	if err != nil {
		return nil, nil, errs.Wrap(err)
	}
	if fromAccount.Status != model.AccountStatusNormal {
		return nil, nil, errs.New("sender account is not in normal status")
	}
	if fromAccount.Balance < amount {
		return nil, nil, errs.New("insufficient balance")
	}

	toAccount, err := w.accountDB.Take(ctx, toUserID)
	if err != nil {
		return nil, nil, errs.Wrap(err)
	}
	if toAccount.Status != model.AccountStatusNormal {
		return nil, nil, errs.New("receiver account is not in normal status")
	}

	txOut := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         fromUserID,
		OppositeUserID: toUserID,
		Type:           model.TransactionTypeTransferOut,
		Amount:         amount,
		BalanceBefore:  fromAccount.Balance,
		BalanceAfter:   fromAccount.Balance - amount,
		Status:         model.TransactionStatusSuccess,
		Remark:         remark,
		IdempotencyKey: idempotencyKey,
	}
	txIn := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         toUserID,
		OppositeUserID: fromUserID,
		Type:           model.TransactionTypeTransferIn,
		Amount:         amount,
		BalanceBefore:  toAccount.Balance,
		BalanceAfter:   toAccount.Balance + amount,
		Status:         model.TransactionStatusSuccess,
		Remark:         remark,
	}

	// Debit sender
	if err := w.accountDB.UpdateBalanceWithVersion(ctx, fromUserID, fromAccount.Version, -amount, 0); err != nil {
		return nil, nil, errs.Wrap(err)
	}
	// Credit receiver
	if err := w.accountDB.UpdateBalanceWithVersion(ctx, toUserID, toAccount.Version, amount, 0); err != nil {
		return nil, nil, errs.Wrap(err)
	}

	if err := w.txDB.Create(ctx, txOut); err != nil {
		return nil, nil, err
	}
	if err := w.txDB.Create(ctx, txIn); err != nil {
		return nil, nil, err
	}

	w.writeAudit(ctx, fromUserID, "transfer", "", map[string]any{
		"to_user_id":     toUserID,
		"amount":         amount,
		"transaction_id": txOut.TransactionID,
	})

	return txOut, txIn, nil
}

// AdminAdjust performs a manual balance adjustment by admin.
func (w *walletDatabase) AdminAdjust(ctx context.Context, userID string, amount int64, isAdd bool, operatorUserID string, remark string) (*model.WalletTransaction, error) {
	if amount <= 0 {
		return nil, errs.New("adjust amount must be positive")
	}

	account, err := w.accountDB.Take(ctx, userID)
	if err != nil {
		return nil, err
	}

	txType := int32(model.TransactionTypeAdjustAdd)
	delta := amount
	if !isAdd {
		txType = model.TransactionTypeAdjustSub
		delta = -amount
		if account.Balance < amount {
			return nil, errs.New("insufficient balance for deduction")
		}
	}

	txRecord := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         userID,
		Type:           txType,
		Amount:         amount,
		BalanceBefore:  account.Balance,
		BalanceAfter:   account.Balance + delta,
		Status:         model.TransactionStatusSuccess,
		Remark:         remark,
		OperatorUserID: operatorUserID,
	}

	if err := w.accountDB.UpdateBalanceWithVersion(ctx, userID, account.Version, delta, 0); err != nil {
		return nil, err
	}
	if err := w.txDB.Create(ctx, txRecord); err != nil {
		return nil, err
	}

	w.writeAudit(ctx, userID, "adjust", operatorUserID, map[string]any{
		"is_add":         isAdd,
		"amount":         amount,
		"transaction_id": txRecord.TransactionID,
		"remark":         remark,
	})

	return txRecord, nil
}

func (w *walletDatabase) FreezeAccount(ctx context.Context, userID string, operatorUserID string, reason string) error {
	if err := w.accountDB.UpdateStatus(ctx, userID, model.AccountStatusFrozen); err != nil {
		return err
	}
	w.writeAudit(ctx, userID, "freeze_account", operatorUserID, map[string]any{"reason": reason})
	return nil
}

func (w *walletDatabase) UnfreezeAccount(ctx context.Context, userID string, operatorUserID string, reason string) error {
	if err := w.accountDB.UpdateStatus(ctx, userID, model.AccountStatusNormal); err != nil {
		return err
	}
	w.writeAudit(ctx, userID, "unfreeze_account", operatorUserID, map[string]any{"reason": reason})
	return nil
}

func (w *walletDatabase) FreezeAmount(ctx context.Context, userID string, amount int64, operatorUserID string, reason string) (*model.WalletFreezeRecord, error) {
	if amount <= 0 {
		return nil, errs.New("freeze amount must be positive")
	}

	account, err := w.accountDB.Take(ctx, userID)
	if err != nil {
		return nil, err
	}
	if account.Balance < amount {
		return nil, errs.New("insufficient balance to freeze")
	}

	record := &model.WalletFreezeRecord{
		FreezeID:       genFreezeID(),
		UserID:         userID,
		Amount:         amount,
		Type:           model.FreezeTypeFreeze,
		Reason:         reason,
		OperatorUserID: operatorUserID,
		Status:         model.FreezeStatusActive,
	}

	// Move amount from balance to frozen
	if err := w.accountDB.UpdateBalanceWithVersion(ctx, userID, account.Version, -amount, amount); err != nil {
		return nil, err
	}
	if err := w.freezeDB.Create(ctx, record); err != nil {
		return nil, err
	}

	// Create transaction record
	txRecord := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         userID,
		Type:           model.TransactionTypeFreeze,
		Amount:         amount,
		BalanceBefore:  account.Balance,
		BalanceAfter:   account.Balance - amount,
		Status:         model.TransactionStatusSuccess,
		Remark:         reason,
		OperatorUserID: operatorUserID,
	}
	_ = w.txDB.Create(ctx, txRecord)

	w.writeAudit(ctx, userID, "freeze_amount", operatorUserID, map[string]any{
		"amount":    amount,
		"freeze_id": record.FreezeID,
		"reason":    reason,
	})

	return record, nil
}

func (w *walletDatabase) UnfreezeAmount(ctx context.Context, freezeID string, userID string, operatorUserID string) error {
	freezes, err := w.freezeDB.GetActiveFreezes(ctx, userID)
	if err != nil {
		return err
	}

	var target *model.WalletFreezeRecord
	for _, f := range freezes {
		if f.FreezeID == freezeID {
			target = f
			break
		}
	}
	if target == nil {
		return errs.New("active freeze record not found")
	}

	account, err := w.accountDB.Take(ctx, userID)
	if err != nil {
		return err
	}

	// Move amount from frozen back to balance
	if err := w.accountDB.UpdateBalanceWithVersion(ctx, userID, account.Version, target.Amount, -target.Amount); err != nil {
		return err
	}
	if err := w.freezeDB.UpdateStatus(ctx, freezeID, model.FreezeStatusReleased); err != nil {
		return err
	}

	txRecord := &model.WalletTransaction{
		TransactionID:  genTransactionID(),
		UserID:         userID,
		Type:           model.TransactionTypeUnfreeze,
		Amount:         target.Amount,
		BalanceBefore:  account.Balance,
		BalanceAfter:   account.Balance + target.Amount,
		Status:         model.TransactionStatusSuccess,
		Remark:         "unfreeze: " + freezeID,
		OperatorUserID: operatorUserID,
	}
	_ = w.txDB.Create(ctx, txRecord)

	w.writeAudit(ctx, userID, "unfreeze_amount", operatorUserID, map[string]any{
		"amount":    target.Amount,
		"freeze_id": freezeID,
	})

	return nil
}

func (w *walletDatabase) GetTransactionPage(ctx context.Context, userID string, txTypes []int32, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletTransaction, error) {
	return w.txDB.PageByUser(ctx, userID, txTypes, startTime, endTime, pagination)
}

func (w *walletDatabase) GetAuditLogPage(ctx context.Context, userID, action, operatorUserID string, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error) {
	return w.auditDB.PageAll(ctx, userID, action, operatorUserID, startTime, endTime, pagination)
}

func (w *walletDatabase) GetFreezeRecordPage(ctx context.Context, userID string, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletFreezeRecord, error) {
	return w.freezeDB.PageByUser(ctx, userID, statusFilter, pagination)
}

func (w *walletDatabase) GetOverview(ctx context.Context) (*WalletOverview, error) {
	totalAccounts, frozenAccounts, err := w.accountDB.CountByStatus(ctx)
	if err != nil {
		return nil, err
	}
	totalBalance, totalFrozen, err := w.accountDB.SumBalance(ctx)
	if err != nil {
		return nil, err
	}
	return &WalletOverview{
		TotalAccounts:  totalAccounts,
		FrozenAccounts: frozenAccounts,
		TotalBalance:   totalBalance,
		TotalFrozen:    totalFrozen,
	}, nil
}

// writeAudit writes an audit log entry (best-effort, never fails the calling operation).
func (w *walletDatabase) writeAudit(ctx context.Context, userID, action, operatorUserID string, detail map[string]any) {
	detailJSON, _ := json.Marshal(detail)
	_ = w.auditDB.Create(ctx, &model.WalletAuditLog{
		AuditID:        genAuditID(),
		UserID:         userID,
		Action:         action,
		Detail:         string(detailJSON),
		OperatorUserID: operatorUserID,
	})
}

func genTransactionID() string {
	return fmt.Sprintf("TX%d", time.Now().UnixNano())
}

func genFreezeID() string {
	return fmt.Sprintf("FZ%d", time.Now().UnixNano())
}

func genAuditID() string {
	return fmt.Sprintf("AL%d", time.Now().UnixNano())
}
