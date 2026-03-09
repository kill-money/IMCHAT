package controller

import (
	"context"
	"encoding/json"
	"math/rand"
	"time"

	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/database"
	"github.com/openimsdk/open-im-server/v3/pkg/common/storage/model"
	"github.com/openimsdk/protocol/constant"
	"github.com/openimsdk/protocol/msg"
	"github.com/openimsdk/protocol/relation"
	"github.com/openimsdk/protocol/sdkws"
	"github.com/openimsdk/tools/db/pagination"
	"github.com/openimsdk/tools/errs"
	"github.com/openimsdk/tools/utils/idutil"
	"github.com/openimsdk/tools/utils/timeutil"
)

type ReceptionistDatabase interface {
	// 邀请码相关
	GenInviteCode(ctx context.Context, userID string) (*model.ReceptionistInviteCode, error)
	GetInviteCode(ctx context.Context, userID string) (*model.ReceptionistInviteCode, error)
	GetInviteCodeByCode(ctx context.Context, inviteCode string) (*model.ReceptionistInviteCode, error)
	UpdateInviteCodeStatus(ctx context.Context, inviteCode string, status int32) error
	DeleteInviteCode(ctx context.Context, inviteCode string) error
	SearchInviteCodes(ctx context.Context, keyword string, pag pagination.Pagination) (int64, []*model.ReceptionistInviteCode, error)

	// 客户绑定相关
	BindCustomer(ctx context.Context, customerID, inviteCode string) error
	GetBinding(ctx context.Context, customerID string) (*model.CustomerReceptionistBinding, error)
	PageBindings(ctx context.Context, receptionistID string, keyword string, pag pagination.Pagination) (int64, []*model.CustomerReceptionistBinding, error)
	GetBindingStats(ctx context.Context, inviteCode string, receptionistID string) (codeCount int64, totalCount int64, err error)

	// 问候语相关
	SetGreeting(ctx context.Context, receptionistID, greetingText string) error
	GetGreeting(ctx context.Context, receptionistID string) (string, error)
	SearchGreetings(ctx context.Context, keyword string, pag pagination.Pagination) (int64, []*model.ReceptionistGreeting, error)

	// 发送问候语 (绑定+加好友+发消息)
	OnCustomerRegister(ctx context.Context, customerID, inviteCode string) error

	// 问候语发送日志
	SearchSendLogs(ctx context.Context, receptionistID string, startTime, endTime int64, pag pagination.Pagination) (int64, []*model.GreetingSendLog, error)
}

type receptionistDatabase struct {
	inviteCode database.ReceptionistInviteCode
	binding    database.CustomerReceptionistBinding
	greeting   database.ReceptionistGreeting
	sendLog    database.GreetingSendLog
	msgClient  msg.MsgClient
	friendCli  relation.FriendClient
}

func NewReceptionistDatabase(
	inviteCode database.ReceptionistInviteCode,
	binding database.CustomerReceptionistBinding,
	greeting database.ReceptionistGreeting,
	sendLog database.GreetingSendLog,
	msgClient msg.MsgClient,
	friendCli relation.FriendClient,
) ReceptionistDatabase {
	return &receptionistDatabase{
		inviteCode: inviteCode,
		binding:    binding,
		greeting:   greeting,
		sendLog:    sendLog,
		msgClient:  msgClient,
		friendCli:  friendCli,
	}
}

const inviteCodeChars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"

func generateCode(length int) string {
	b := make([]byte, length)
	for i := range b {
		b[i] = inviteCodeChars[rand.Intn(len(inviteCodeChars))]
	}
	return string(b)
}

func (d *receptionistDatabase) GenInviteCode(ctx context.Context, userID string) (*model.ReceptionistInviteCode, error) {
	// 检查是否已有启用的邀请码
	existing, err := d.inviteCode.GetByUserID(ctx, userID)
	if err == nil && existing != nil {
		return existing, nil
	}

	// 生成唯一6位邀请码
	var code string
	for i := 0; i < 10; i++ {
		code = generateCode(6)
		if _, err := d.inviteCode.GetByCode(ctx, code); err != nil {
			break // 该code不存在，可用
		}
	}

	inviteCode := &model.ReceptionistInviteCode{
		UserID:     userID,
		InviteCode: code,
		Status:     model.InviteCodeStatusEnabled,
		CreatedAt:  time.Now(),
	}
	if err := d.inviteCode.Create(ctx, inviteCode); err != nil {
		return nil, err
	}
	return inviteCode, nil
}

func (d *receptionistDatabase) GetInviteCode(ctx context.Context, userID string) (*model.ReceptionistInviteCode, error) {
	return d.inviteCode.GetByUserID(ctx, userID)
}

func (d *receptionistDatabase) GetInviteCodeByCode(ctx context.Context, inviteCode string) (*model.ReceptionistInviteCode, error) {
	return d.inviteCode.GetByCode(ctx, inviteCode)
}

func (d *receptionistDatabase) UpdateInviteCodeStatus(ctx context.Context, inviteCode string, status int32) error {
	return d.inviteCode.UpdateStatus(ctx, inviteCode, status)
}

func (d *receptionistDatabase) DeleteInviteCode(ctx context.Context, inviteCode string) error {
	return d.inviteCode.Delete(ctx, inviteCode)
}

func (d *receptionistDatabase) SearchInviteCodes(ctx context.Context, keyword string, pag pagination.Pagination) (int64, []*model.ReceptionistInviteCode, error) {
	return d.inviteCode.Search(ctx, keyword, pag)
}

func (d *receptionistDatabase) BindCustomer(ctx context.Context, customerID, inviteCode string) error {
	// 验证邀请码
	code, err := d.inviteCode.GetByCode(ctx, inviteCode)
	if err != nil {
		return errs.ErrArgs.WrapMsg("邀请码无效")
	}
	if code.Status != model.InviteCodeStatusEnabled {
		return errs.ErrArgs.WrapMsg("邀请码已禁用")
	}

	// 检查是否已绑定
	if _, err := d.binding.GetByCustomerID(ctx, customerID); err == nil {
		return errs.ErrArgs.WrapMsg("该客户已绑定接待员")
	}

	binding := &model.CustomerReceptionistBinding{
		CustomerID:     customerID,
		ReceptionistID: code.UserID,
		InviteCode:     inviteCode,
		BoundAt:        time.Now(),
	}
	return d.binding.Create(ctx, binding)
}

func (d *receptionistDatabase) GetBinding(ctx context.Context, customerID string) (*model.CustomerReceptionistBinding, error) {
	return d.binding.GetByCustomerID(ctx, customerID)
}

func (d *receptionistDatabase) PageBindings(ctx context.Context, receptionistID string, keyword string, pag pagination.Pagination) (int64, []*model.CustomerReceptionistBinding, error) {
	return d.binding.PageByReceptionist(ctx, receptionistID, keyword, pag)
}

func (d *receptionistDatabase) GetBindingStats(ctx context.Context, inviteCode string, receptionistID string) (int64, int64, error) {
	codeCount, err := d.binding.CountByInviteCode(ctx, inviteCode)
	if err != nil {
		return 0, 0, err
	}
	totalCount, err := d.binding.CountByReceptionist(ctx, receptionistID)
	if err != nil {
		return 0, 0, err
	}
	return codeCount, totalCount, nil
}

func (d *receptionistDatabase) SetGreeting(ctx context.Context, receptionistID, greetingText string) error {
	return d.greeting.Upsert(ctx, &model.ReceptionistGreeting{
		ReceptionistID: receptionistID,
		GreetingText:   greetingText,
		UpdatedAt:      time.Now(),
	})
}

func (d *receptionistDatabase) GetGreeting(ctx context.Context, receptionistID string) (string, error) {
	g, err := d.greeting.GetByReceptionistID(ctx, receptionistID)
	if err != nil {
		return model.DefaultGreetingText, nil
	}
	return g.GreetingText, nil
}

func (d *receptionistDatabase) SearchGreetings(ctx context.Context, keyword string, pag pagination.Pagination) (int64, []*model.ReceptionistGreeting, error) {
	return d.greeting.Search(ctx, keyword, pag)
}

// OnCustomerRegister 客户注册时: 绑定→加好友→发问候语
func (d *receptionistDatabase) OnCustomerRegister(ctx context.Context, customerID, inviteCode string) error {
	// 1. 绑定客户到接待员
	if err := d.BindCustomer(ctx, customerID, inviteCode); err != nil {
		return err
	}

	// 获取绑定信息（得到 receptionistID）
	binding, err := d.binding.GetByCustomerID(ctx, customerID)
	if err != nil {
		return err
	}

	// 2. 互相加好友（使用 ImportFriends 跳过审批）
	_, err = d.friendCli.ImportFriends(ctx, &relation.ImportFriendReq{
		OwnerUserID:   binding.ReceptionistID,
		FriendUserIDs: []string{customerID},
	})
	if err != nil {
		// 加好友失败不阻塞后续流程，记录日志即可
		_ = err
	}

	// 3. 获取问候语
	greetingText, _ := d.GetGreeting(ctx, binding.ReceptionistID)

	// 4. 发送问候消息
	textContent := map[string]string{"content": greetingText}
	contentBytes, _ := json.Marshal(textContent)

	sendMsgReq := &msg.SendMsgReq{
		MsgData: &sdkws.MsgData{
			SendID:           binding.ReceptionistID,
			RecvID:           customerID,
			ClientMsgID:      idutil.GetMsgIDByMD5(binding.ReceptionistID),
			SenderPlatformID: constant.AdminPlatformID,
			SessionType:      constant.SingleChatType,
			MsgFrom:          constant.SysMsgType,
			ContentType:      constant.Text,
			Content:          contentBytes,
			CreateTime:       timeutil.GetCurrentTimestampByMill(),
		},
	}

	status := model.GreetingSendSuccess
	_, err = d.msgClient.SendMsg(ctx, sendMsgReq)
	if err != nil {
		status = model.GreetingSendFailed
	}

	// 5. 记录发送日志
	_ = d.sendLog.Create(ctx, &model.GreetingSendLog{
		ReceptionistID: binding.ReceptionistID,
		CustomerID:     customerID,
		GreetingText:   greetingText,
		SentAt:         time.Now(),
		Status:         status,
	})

	return nil
}

func (d *receptionistDatabase) SearchSendLogs(ctx context.Context, receptionistID string, startTime, endTime int64, pag pagination.Pagination) (int64, []*model.GreetingSendLog, error) {
	return d.sendLog.Search(ctx, receptionistID, startTime, endTime, pag)
}
