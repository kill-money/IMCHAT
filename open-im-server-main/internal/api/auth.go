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

package api

import (
	"fmt"

	"github.com/gin-gonic/gin"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/controller"
	"github.com/openimsdk/protocol/auth"
	"github.com/openimsdk/protocol/constant"
	"github.com/openimsdk/tools/a2r"
	"github.com/openimsdk/tools/log"
)

type AuthApi struct {
	Client auth.AuthClient
	ipDB   controller.UserIPDatabase // 可为 nil
}

func NewAuthApi(client auth.AuthClient) AuthApi {
	return AuthApi{Client: client}
}

func NewAuthApiWithIPDB(client auth.AuthClient, ipDB controller.UserIPDatabase) AuthApi {
	return AuthApi{Client: client, ipDB: ipDB}
}

func (o *AuthApi) GetAdminToken(c *gin.Context) {
	a2r.Call(c, auth.AuthClient.GetAdminToken, o.Client)
}

func (o *AuthApi) GetUserToken(c *gin.Context) {
	if o.ipDB == nil {
		a2r.Call(c, auth.AuthClient.GetUserToken, o.Client)
		return
	}
	// 通过 a2r.Option 在请求解析后和响应成功后捕获用户信息并记录 IP
	var userID string
	var platformID int32
	clientIP := GetClientIP(c)

	opt := &a2r.Option[auth.GetUserTokenReq, auth.GetUserTokenResp]{
		BindAfter: func(req *auth.GetUserTokenReq) error {
			userID = req.UserID
			platformID = req.PlatformID
			return nil
		},
		RespAfter: func(resp *auth.GetUserTokenResp) error {
			// token 获取成功，异步记录登录 IP
			if clientIP != "" && userID != "" {
				platform := constant.PlatformID2Name[int(platformID)]
				if platform == "" {
					platform = fmt.Sprintf("platform_%d", platformID)
				}
				go func() {
					if err := o.ipDB.RecordLogin(c.Copy(), userID, clientIP, platform); err != nil {
						log.ZWarn(c, "record login IP in GetUserToken", err)
					}
				}()
			}
			return nil
		},
	}
	a2r.Call(c, auth.AuthClient.GetUserToken, o.Client, opt)
}

func (o *AuthApi) ParseToken(c *gin.Context) {
	a2r.Call(c, auth.AuthClient.ParseToken, o.Client)
}

func (o *AuthApi) ForceLogout(c *gin.Context) {
	a2r.Call(c, auth.AuthClient.ForceLogout, o.Client)
}
