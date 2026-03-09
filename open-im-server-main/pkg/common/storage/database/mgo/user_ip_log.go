package mgo

import (
	"context"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/database"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/tools/db/mongoutil"
	"github.com/openimsdk/tools/db/pagination"
	"github.com/openimsdk/tools/errs"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func NewUserIPLogMongo(db *mongo.Database) (database.UserIPLog, error) {
	coll := db.Collection(database.UserIPLogName)
	_, err := coll.Indexes().CreateMany(context.Background(), []mongo.IndexModel{
		{
			Keys: bson.D{{Key: "user_id", Value: 1}, {Key: "login_time", Value: -1}},
		},
		{
			Keys: bson.D{{Key: "ip", Value: 1}},
		},
		{
			Keys:    bson.D{{Key: "login_time", Value: 1}},
			Options: options.Index().SetExpireAfterSeconds(90 * 24 * 3600), // 90天自动过期
		},
	})
	if err != nil {
		return nil, errs.Wrap(err)
	}
	return &UserIPLogMgo{coll: coll}, nil
}

type UserIPLogMgo struct {
	coll *mongo.Collection
}

func (u *UserIPLogMgo) Create(ctx context.Context, log *model.UserIPLog) error {
	log.ID = primitive.NewObjectID()
	if log.LoginTime.IsZero() {
		log.LoginTime = time.Now()
	}
	return mongoutil.InsertMany(ctx, u.coll, []*model.UserIPLog{log})
}

func (u *UserIPLogMgo) PageByUser(ctx context.Context, userID string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error) {
	return mongoutil.FindPage[*model.UserIPLog](ctx, u.coll, bson.M{"user_id": userID}, pagination,
		options.Find().SetSort(bson.D{{Key: "login_time", Value: -1}}))
}

func (u *UserIPLogMgo) GetLastLog(ctx context.Context, userID string) (*model.UserIPLog, error) {
	opts := options.FindOne().SetSort(bson.D{{Key: "login_time", Value: -1}})
	return mongoutil.FindOne[*model.UserIPLog](ctx, u.coll, bson.M{"user_id": userID}, opts)
}

func (u *UserIPLogMgo) SearchByIP(ctx context.Context, ip string, pagination pagination.Pagination) (int64, []*model.UserIPLog, error) {
	filter := bson.M{"ip": bson.M{"$regex": primitive.Regex{Pattern: ip, Options: "i"}}}
	return mongoutil.FindPage[*model.UserIPLog](ctx, u.coll, filter, pagination,
		options.Find().SetSort(bson.D{{Key: "login_time", Value: -1}}))
}

func (u *UserIPLogMgo) DeleteBefore(ctx context.Context, before time.Time) error {
	_, err := u.coll.DeleteMany(ctx, bson.M{"login_time": bson.M{"$lt": before}})
	return errs.Wrap(err)
}
