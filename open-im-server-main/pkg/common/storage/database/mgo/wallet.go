package mgo

import (
	"context"
	"fmt"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/mongoutil"
	"github.com/openimsdk/tools/db/pagination"
	"github.com/openimsdk/tools/errs"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// NewWalletAccountMongo initializes the wallet_account collection with indexes.
func NewWalletAccountMongo(db *mongo.Database) (*WalletAccountMgo, error) {
	coll := db.Collection("wallet_account")
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "user_id", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
		},
	})
	if err != nil {
		return nil, errs.Wrap(err)
	}
	return &WalletAccountMgo{coll: coll}, nil
}

type WalletAccountMgo struct {
	coll *mongo.Collection
}

func (w *WalletAccountMgo) Create(ctx context.Context, account *model.WalletAccount) error {
	account.ID = primitive.NewObjectID()
	account.CreateTime = time.Now()
	account.UpdateTime = time.Now()
	account.Version = 1
	return mongoutil.InsertMany(ctx, w.coll, []*model.WalletAccount{account})
}

func (w *WalletAccountMgo) Take(ctx context.Context, userID string) (*model.WalletAccount, error) {
	return mongoutil.FindOne[*model.WalletAccount](ctx, w.coll, bson.M{"user_id": userID})
}

// UpdateBalanceWithVersion performs optimistic locking update on balance.
func (w *WalletAccountMgo) UpdateBalanceWithVersion(ctx context.Context, userID string, version int64, balanceDelta int64, frozenDelta int64) error {
	filter := bson.M{
		"user_id": userID,
		"version": version,
		"status":  model.AccountStatusNormal,
	}
	// Use $inc for atomic balance change and version bump
	update := bson.M{
		"$inc": bson.M{
			"balance":       balanceDelta,
			"frozen_amount": frozenDelta,
			"version":       int64(1),
		},
		"$set": bson.M{
			"update_time": time.Now(),
		},
	}
	result, err := w.coll.UpdateOne(ctx, filter, update)
	if err != nil {
		return errs.Wrap(err)
	}
	if result.ModifiedCount == 0 {
		return errs.New("optimistic lock conflict or account not in normal status")
	}
	return nil
}

func (w *WalletAccountMgo) UpdateStatus(ctx context.Context, userID string, status int32) error {
	filter := bson.M{"user_id": userID}
	update := bson.M{
		"$set": bson.M{
			"status":      status,
			"update_time": time.Now(),
		},
	}
	_, err := w.coll.UpdateOne(ctx, filter, update)
	return errs.Wrap(err)
}

func (w *WalletAccountMgo) Page(ctx context.Context, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletAccount, error) {
	filter := bson.M{}
	if len(statusFilter) > 0 {
		filter["status"] = bson.M{"$in": statusFilter}
	}
	return mongoutil.FindPage[*model.WalletAccount](ctx, w.coll, filter, pagination)
}

func (w *WalletAccountMgo) CountByStatus(ctx context.Context) (total int64, frozen int64, err error) {
	total, err = w.coll.CountDocuments(ctx, bson.M{})
	if err != nil {
		return 0, 0, errs.Wrap(err)
	}
	frozen, err = w.coll.CountDocuments(ctx, bson.M{"status": model.AccountStatusFrozen})
	if err != nil {
		return 0, 0, errs.Wrap(err)
	}
	return total, frozen, nil
}

func (w *WalletAccountMgo) SumBalance(ctx context.Context) (totalBalance int64, totalFrozen int64, err error) {
	pipeline := mongo.Pipeline{
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: nil},
			{Key: "total_balance", Value: bson.M{"$sum": "$balance"}},
			{Key: "total_frozen", Value: bson.M{"$sum": "$frozen_amount"}},
		}}},
	}
	cursor, err := w.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, 0, errs.Wrap(err)
	}
	defer cursor.Close(ctx)
	var results []struct {
		TotalBalance int64 `bson:"total_balance"`
		TotalFrozen  int64 `bson:"total_frozen"`
	}
	if err := cursor.All(ctx, &results); err != nil {
		return 0, 0, errs.Wrap(err)
	}
	if len(results) > 0 {
		return results[0].TotalBalance, results[0].TotalFrozen, nil
	}
	return 0, 0, nil
}

// NewWalletTransactionMongo initializes the wallet_transaction collection.
func NewWalletTransactionMongo(db *mongo.Database) (*WalletTransactionMgo, error) {
	coll := db.Collection("wallet_transaction")
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "transaction_id", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys:    bson.D{{Key: "idempotency_key", Value: 1}},
			Options: options.Index().SetUnique(true).SetSparse(true),
		},
		{
			Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "create_time", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "type", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "status", Value: 1}},
		},
	})
	if err != nil {
		return nil, errs.Wrap(err)
	}
	return &WalletTransactionMgo{coll: coll}, nil
}

type WalletTransactionMgo struct {
	coll *mongo.Collection
}

func (w *WalletTransactionMgo) Create(ctx context.Context, tx *model.WalletTransaction) error {
	tx.ID = primitive.NewObjectID()
	tx.CreateTime = time.Now()
	tx.UpdateTime = time.Now()
	return mongoutil.InsertMany(ctx, w.coll, []*model.WalletTransaction{tx})
}

func (w *WalletTransactionMgo) Take(ctx context.Context, transactionID string) (*model.WalletTransaction, error) {
	return mongoutil.FindOne[*model.WalletTransaction](ctx, w.coll, bson.M{"transaction_id": transactionID})
}

func (w *WalletTransactionMgo) TakeByIdempotencyKey(ctx context.Context, key string) (*model.WalletTransaction, error) {
	return mongoutil.FindOne[*model.WalletTransaction](ctx, w.coll, bson.M{"idempotency_key": key})
}

func (w *WalletTransactionMgo) UpdateStatus(ctx context.Context, transactionID string, status int32) error {
	filter := bson.M{"transaction_id": transactionID}
	update := bson.M{"$set": bson.M{"status": status, "update_time": time.Now()}}
	_, err := w.coll.UpdateOne(ctx, filter, update)
	return errs.Wrap(err)
}

func (w *WalletTransactionMgo) PageByUser(ctx context.Context, userID string, txTypes []int32, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletTransaction, error) {
	filter := bson.M{"user_id": userID}
	if len(txTypes) > 0 {
		filter["type"] = bson.M{"$in": txTypes}
	}
	if startTime != nil || endTime != nil {
		timeFilter := bson.M{}
		if startTime != nil {
			timeFilter["$gte"] = *startTime
		}
		if endTime != nil {
			timeFilter["$lte"] = *endTime
		}
		filter["create_time"] = timeFilter
	}
	return mongoutil.FindPage[*model.WalletTransaction](ctx, w.coll, filter, pagination)
}

func (w *WalletTransactionMgo) SumByTypeAndRange(ctx context.Context, txType int32, start, end time.Time) (int64, error) {
	pipeline := mongo.Pipeline{
		{{Key: "$match", Value: bson.M{
			"type":   txType,
			"status": model.TransactionStatusSuccess,
			"create_time": bson.M{
				"$gte": start,
				"$lte": end,
			},
		}}},
		{{Key: "$group", Value: bson.D{
			{Key: "_id", Value: nil},
			{Key: "total", Value: bson.M{"$sum": "$amount"}},
		}}},
	}
	cursor, err := w.coll.Aggregate(ctx, pipeline)
	if err != nil {
		return 0, errs.Wrap(err)
	}
	defer cursor.Close(ctx)
	var results []struct {
		Total int64 `bson:"total"`
	}
	if err := cursor.All(ctx, &results); err != nil {
		return 0, errs.Wrap(err)
	}
	if len(results) > 0 {
		return results[0].Total, nil
	}
	return 0, nil
}

// NewWalletFreezeRecordMongo initializes the wallet_freeze_record collection.
func NewWalletFreezeRecordMongo(db *mongo.Database) (*WalletFreezeRecordMgo, error) {
	coll := db.Collection("wallet_freeze_record")
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "freeze_id", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "status", Value: 1}},
		},
	})
	if err != nil {
		return nil, errs.Wrap(err)
	}
	return &WalletFreezeRecordMgo{coll: coll}, nil
}

type WalletFreezeRecordMgo struct {
	coll *mongo.Collection
}

func (w *WalletFreezeRecordMgo) Create(ctx context.Context, record *model.WalletFreezeRecord) error {
	record.ID = primitive.NewObjectID()
	record.CreateTime = time.Now()
	record.UpdateTime = time.Now()
	return mongoutil.InsertMany(ctx, w.coll, []*model.WalletFreezeRecord{record})
}

func (w *WalletFreezeRecordMgo) UpdateStatus(ctx context.Context, freezeID string, status int32) error {
	filter := bson.M{"freeze_id": freezeID}
	update := bson.M{"$set": bson.M{"status": status, "update_time": time.Now()}}
	_, err := w.coll.UpdateOne(ctx, filter, update)
	return errs.Wrap(err)
}

func (w *WalletFreezeRecordMgo) PageByUser(ctx context.Context, userID string, statusFilter []int32, pagination pagination.Pagination) (int64, []*model.WalletFreezeRecord, error) {
	filter := bson.M{"user_id": userID}
	if len(statusFilter) > 0 {
		filter["status"] = bson.M{"$in": statusFilter}
	}
	return mongoutil.FindPage[*model.WalletFreezeRecord](ctx, w.coll, filter, pagination)
}

func (w *WalletFreezeRecordMgo) GetActiveFreezes(ctx context.Context, userID string) ([]*model.WalletFreezeRecord, error) {
	filter := bson.M{
		"user_id": userID,
		"status":  model.FreezeStatusActive,
	}
	cursor, err := w.coll.Find(ctx, filter)
	if err != nil {
		return nil, errs.Wrap(err)
	}
	var records []*model.WalletFreezeRecord
	if err := cursor.All(ctx, &records); err != nil {
		return nil, errs.Wrap(err)
	}
	return records, nil
}

// NewWalletAuditLogMongo initializes the wallet_audit_log collection.
func NewWalletAuditLogMongo(db *mongo.Database) (*WalletAuditLogMgo, error) {
	coll := db.Collection("wallet_audit_log")
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{
			Keys:    bson.D{{Key: "audit_id", Value: 1}},
			Options: options.Index().SetUnique(true),
		},
		{
			Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "create_time", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "operator_user_id", Value: 1}},
		},
		{
			Keys: bson.D{{Key: "action", Value: 1}},
		},
	})
	if err != nil {
		return nil, errs.Wrap(err)
	}
	return &WalletAuditLogMgo{coll: coll}, nil
}

type WalletAuditLogMgo struct {
	coll *mongo.Collection
}

func (w *WalletAuditLogMgo) Create(ctx context.Context, log *model.WalletAuditLog) error {
	log.ID = primitive.NewObjectID()
	log.CreateTime = time.Now()
	return mongoutil.InsertMany(ctx, w.coll, []*model.WalletAuditLog{log})
}

func (w *WalletAuditLogMgo) PageByUser(ctx context.Context, userID string, action string, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error) {
	filter := bson.M{}
	if userID != "" {
		filter["user_id"] = userID
	}
	if action != "" {
		filter["action"] = action
	}
	return mongoutil.FindPage[*model.WalletAuditLog](ctx, w.coll, filter, pagination)
}

func (w *WalletAuditLogMgo) PageByOperator(ctx context.Context, operatorUserID string, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error) {
	filter := bson.M{"operator_user_id": operatorUserID}
	return mongoutil.FindPage[*model.WalletAuditLog](ctx, w.coll, filter, pagination)
}

func (w *WalletAuditLogMgo) PageAll(ctx context.Context, userID, action, operatorUserID string, startTime, endTime *time.Time, pagination pagination.Pagination) (int64, []*model.WalletAuditLog, error) {
	filter := bson.M{}
	if userID != "" {
		filter["user_id"] = userID
	}
	if action != "" {
		filter["action"] = action
	}
	if operatorUserID != "" {
		filter["operator_user_id"] = operatorUserID
	}
	if startTime != nil || endTime != nil {
		tf := bson.M{}
		if startTime != nil {
			tf["$gte"] = *startTime
		}
		if endTime != nil {
			tf["$lte"] = *endTime
		}
		filter["create_time"] = tf
	}
	return mongoutil.FindPage[*model.WalletAuditLog](ctx, w.coll, filter, pagination)
}

func genTransactionID() string {
	return fmt.Sprintf("TX%d%s", time.Now().UnixNano(), primitive.NewObjectID().Hex()[18:])
}

func genFreezeID() string {
	return fmt.Sprintf("FZ%d%s", time.Now().UnixNano(), primitive.NewObjectID().Hex()[18:])
}

func genAuditID() string {
	return fmt.Sprintf("AL%d%s", time.Now().UnixNano(), primitive.NewObjectID().Hex()[18:])
}
