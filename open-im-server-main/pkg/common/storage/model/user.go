// Copyright © 2023 OpenIM. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package model

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type User struct {
	UserID           string    `bson:"user_id"`
	Nickname         string    `bson:"nickname"`
	FaceURL          string    `bson:"face_url"`
	Ex               string    `bson:"ex"`
	AppMangerLevel   int32     `bson:"app_manger_level"`
	GlobalRecvMsgOpt int32     `bson:"global_recv_msg_opt"`
	CreateTime       time.Time `bson:"create_time"`
	LastLoginIP      string    `bson:"last_login_ip"`
	LastLoginTime    time.Time `bson:"last_login_time"`
	AppRole          int32     `bson:"app_role"` // 0-普通用户 1-用户端管理员 2-超级管理员
}

// AppRole 常量
const (
	AppRoleNormal   int32 = 0 // 普通用户
	AppRoleAppAdmin int32 = 1 // 用户端管理员
	AppRoleSuper    int32 = 2 // 超级管理员
)

// UserIPLog 用户 IP 登录历史记录
type UserIPLog struct {
	ID        primitive.ObjectID `bson:"_id"`
	UserID    string             `bson:"user_id"`
	IP        string             `bson:"ip"`
	Platform  string             `bson:"platform"`
	LoginTime time.Time          `bson:"login_time"`
}

func (u *User) GetNickname() string {
	return u.Nickname
}

func (u *User) GetFaceURL() string {
	return u.FaceURL
}

func (u *User) GetUserID() string {
	return u.UserID
}

func (u *User) GetEx() string {
	return u.Ex
}
