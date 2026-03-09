package mgo

import (
	"context"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/database"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/mongoutil"
	"github.com/openimsdk/tools/db/pagination"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// ============ ReceptionistInviteCode ============

type receptionistInviteCodeMgo struct {
	coll *mongo.Collection
}

func NewReceptionistInviteCodeMongo(db *mongo.Database) (database.ReceptionistInviteCode, error) {
	coll := db.Collection(database.ReceptionistInviteCodeName)
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{Keys: bson.D{{Key: "user_id", Value: 1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "invite_code", Value: 1}}, Options: options.Index().SetUnique(true)},
	})
	if err != nil {
		return nil, err
	}
	return &receptionistInviteCodeMgo{coll: coll}, nil
}

func (m *receptionistInviteCodeMgo) Create(ctx context.Context, code *model.ReceptionistInviteCode) error {
	return mongoutil.InsertMany(ctx, m.coll, []*model.ReceptionistInviteCode{code})
}

func (m *receptionistInviteCodeMgo) GetByUserID(ctx context.Context, userID string) (*model.ReceptionistInviteCode, error) {
	return mongoutil.FindOne[*model.ReceptionistInviteCode](ctx, m.coll, bson.M{"user_id": userID, "status": model.InviteCodeStatusEnabled})
}

func (m *receptionistInviteCodeMgo) GetByCode(ctx context.Context, inviteCode string) (*model.ReceptionistInviteCode, error) {
	return mongoutil.FindOne[*model.ReceptionistInviteCode](ctx, m.coll, bson.M{"invite_code": inviteCode})
}

func (m *receptionistInviteCodeMgo) UpdateStatus(ctx context.Context, inviteCode string, status int32) error {
	return mongoutil.UpdateOne(ctx, m.coll, bson.M{"invite_code": inviteCode}, bson.M{"$set": bson.M{"status": status}}, true)
}

func (m *receptionistInviteCodeMgo) Delete(ctx context.Context, inviteCode string) error {
	return mongoutil.DeleteOne(ctx, m.coll, bson.M{"invite_code": inviteCode})
}

func (m *receptionistInviteCodeMgo) Search(ctx context.Context, keyword string, pag pagination.Pagination) (int64, []*model.ReceptionistInviteCode, error) {
	filter := bson.M{}
	if keyword != "" {
		filter["$or"] = bson.A{
			bson.M{"user_id": bson.M{"$regex": keyword, "$options": "i"}},
			bson.M{"invite_code": bson.M{"$regex": keyword, "$options": "i"}},
		}
	}
	return mongoutil.FindPage[*model.ReceptionistInviteCode](ctx, m.coll, filter, pag, options.Find().SetSort(bson.M{"created_at": -1}))
}

func (m *receptionistInviteCodeMgo) CountByUserID(ctx context.Context, userID string) (int64, error) {
	return m.coll.CountDocuments(ctx, bson.M{"user_id": userID, "status": model.InviteCodeStatusEnabled})
}

// ============ CustomerReceptionistBinding ============

type customerReceptionistBindingMgo struct {
	coll *mongo.Collection
}

func NewCustomerReceptionistBindingMongo(db *mongo.Database) (database.CustomerReceptionistBinding, error) {
	coll := db.Collection(database.CustomerReceptionistBindingName)
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{Keys: bson.D{{Key: "customer_id", Value: 1}}, Options: options.Index().SetUnique(true)},
		{Keys: bson.D{{Key: "receptionist_id", Value: 1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "invite_code", Value: 1}}, Options: options.Index()},
	})
	if err != nil {
		return nil, err
	}
	return &customerReceptionistBindingMgo{coll: coll}, nil
}

func (m *customerReceptionistBindingMgo) Create(ctx context.Context, binding *model.CustomerReceptionistBinding) error {
	return mongoutil.InsertMany(ctx, m.coll, []*model.CustomerReceptionistBinding{binding})
}

func (m *customerReceptionistBindingMgo) GetByCustomerID(ctx context.Context, customerID string) (*model.CustomerReceptionistBinding, error) {
	return mongoutil.FindOne[*model.CustomerReceptionistBinding](ctx, m.coll, bson.M{"customer_id": customerID})
}

func (m *customerReceptionistBindingMgo) PageByReceptionist(ctx context.Context, receptionistID string, keyword string, pag pagination.Pagination) (int64, []*model.CustomerReceptionistBinding, error) {
	filter := bson.M{"receptionist_id": receptionistID}
	if keyword != "" {
		filter["customer_id"] = bson.M{"$regex": keyword, "$options": "i"}
	}
	return mongoutil.FindPage[*model.CustomerReceptionistBinding](ctx, m.coll, filter, pag, options.Find().SetSort(bson.M{"bound_at": -1}))
}

func (m *customerReceptionistBindingMgo) CountByInviteCode(ctx context.Context, inviteCode string) (int64, error) {
	return m.coll.CountDocuments(ctx, bson.M{"invite_code": inviteCode})
}

func (m *customerReceptionistBindingMgo) CountByReceptionist(ctx context.Context, receptionistID string) (int64, error) {
	return m.coll.CountDocuments(ctx, bson.M{"receptionist_id": receptionistID})
}

// ============ ReceptionistGreeting ============

type receptionistGreetingMgo struct {
	coll *mongo.Collection
}

func NewReceptionistGreetingMongo(db *mongo.Database) (database.ReceptionistGreeting, error) {
	coll := db.Collection(database.ReceptionistGreetingName)
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{Keys: bson.D{{Key: "receptionist_id", Value: 1}}, Options: options.Index().SetUnique(true)},
	})
	if err != nil {
		return nil, err
	}
	return &receptionistGreetingMgo{coll: coll}, nil
}

func (m *receptionistGreetingMgo) Upsert(ctx context.Context, g *model.ReceptionistGreeting) error {
	filter := bson.M{"receptionist_id": g.ReceptionistID}
	update := bson.M{"$set": bson.M{
		"greeting_text": g.GreetingText,
		"updated_at":    g.UpdatedAt,
	}, "$setOnInsert": bson.M{
		"receptionist_id": g.ReceptionistID,
	}}
	_, err := m.coll.UpdateOne(ctx, filter, update, options.Update().SetUpsert(true))
	return err
}

func (m *receptionistGreetingMgo) GetByReceptionistID(ctx context.Context, receptionistID string) (*model.ReceptionistGreeting, error) {
	return mongoutil.FindOne[*model.ReceptionistGreeting](ctx, m.coll, bson.M{"receptionist_id": receptionistID})
}

func (m *receptionistGreetingMgo) Search(ctx context.Context, keyword string, pag pagination.Pagination) (int64, []*model.ReceptionistGreeting, error) {
	filter := bson.M{}
	if keyword != "" {
		filter["receptionist_id"] = bson.M{"$regex": keyword, "$options": "i"}
	}
	return mongoutil.FindPage[*model.ReceptionistGreeting](ctx, m.coll, filter, pag, options.Find().SetSort(bson.M{"updated_at": -1}))
}

// ============ GreetingSendLog ============

type greetingSendLogMgo struct {
	coll *mongo.Collection
}

func NewGreetingSendLogMongo(db *mongo.Database) (database.GreetingSendLog, error) {
	coll := db.Collection(database.GreetingSendLogName)
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{Keys: bson.D{{Key: "receptionist_id", Value: 1}, {Key: "sent_at", Value: -1}}, Options: options.Index()},
		{Keys: bson.D{{Key: "customer_id", Value: 1}}, Options: options.Index()},
	})
	if err != nil {
		return nil, err
	}
	return &greetingSendLogMgo{coll: coll}, nil
}

func (m *greetingSendLogMgo) Create(ctx context.Context, log *model.GreetingSendLog) error {
	return mongoutil.InsertMany(ctx, m.coll, []*model.GreetingSendLog{log})
}

func (m *greetingSendLogMgo) Search(ctx context.Context, receptionistID string, startTime, endTime int64, pag pagination.Pagination) (int64, []*model.GreetingSendLog, error) {
	filter := bson.M{}
	if receptionistID != "" {
		filter["receptionist_id"] = receptionistID
	}
	if startTime > 0 || endTime > 0 {
		timeFilter := bson.M{}
		if startTime > 0 {
			timeFilter["$gte"] = time.UnixMilli(startTime)
		}
		if endTime > 0 {
			timeFilter["$lte"] = time.UnixMilli(endTime)
		}
		filter["sent_at"] = timeFilter
	}
	return mongoutil.FindPage[*model.GreetingSendLog](ctx, m.coll, filter, pag, options.Find().SetSort(bson.M{"sent_at": -1}))
}
