package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strings"
	"time"
)

// ---- OpenIM Webhook 请求/响应结构 ----

type CallbackReq struct {
	CallbackCommand  string   `json:"callbackCommand"`
	SendID           string   `json:"sendID"`
	ServerMsgID      string   `json:"serverMsgID"`
	ClientMsgID      string   `json:"clientMsgID"`
	OperationID      string   `json:"operationID"`
	SenderPlatformID int32    `json:"senderPlatformID"`
	SenderNickname   string   `json:"senderNickname"`
	SessionType      int32    `json:"sessionType"`
	ContentType      int32    `json:"contentType"`
	Content          string   `json:"content"`
	SendTime         int64    `json:"sendTime"`
	Status           int32    `json:"status"`
	AtUserIDList     []string `json:"atUserList"`

	// 单聊
	RecvID string `json:"recvID"`
	// 群聊
	GroupID string `json:"groupID"`

	// 用户上下线
	UserID     string `json:"userID"`
	PlatformID int    `json:"platformID"`
	Platform   string `json:"platform"`
}

type CallbackResp struct {
	ActionCode int32  `json:"actionCode"` // 0=放行, 非0=拦截
	ErrCode    int32  `json:"errCode"`
	ErrMsg     string `json:"errMsg"`
	ErrDlt     string `json:"errDlt"`
	NextCode   int32  `json:"nextCode"`
}

// ---- 敏感词过滤 ----

var badWords = []string{
	// 在这里添加敏感词
}

func containsBadWord(content string) (bool, string) {
	lower := strings.ToLower(content)
	for _, w := range badWords {
		if strings.Contains(lower, strings.ToLower(w)) {
			return true, w
		}
	}
	return false, ""
}

// ---- 处理函数 ----

func handleCallback(w http.ResponseWriter, r *http.Request) {
	var req CallbackReq
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "bad request", http.StatusBadRequest)
		return
	}

	resp := CallbackResp{ActionCode: 0} // 默认放行

	switch req.CallbackCommand {

	// ===== 消息发送前拦截 =====
	case "callbackBeforeSendSingleMsgCommand", "callbackBeforeSendGroupMsgCommand":
		if hit, word := containsBadWord(req.Content); hit {
			log.Printf("[BLOCK] sendID=%s content hit word=%q", req.SendID, word)
			resp = CallbackResp{ActionCode: 1, ErrCode: 10001, ErrMsg: "消息包含违禁内容"}
		} else {
			log.Printf("[PASS]  sendID=%s -> %s cmd=%s contentType=%d",
				req.SendID, target(req), req.CallbackCommand, req.ContentType)
		}

	// ===== 消息发送后 (异步, 审计日志) =====
	case "callbackAfterSendSingleMsgCommand", "callbackAfterSendGroupMsgCommand":
		log.Printf("[AUDIT] sendID=%s -> %s contentType=%d content=%s",
			req.SendID, target(req), req.ContentType, truncate(req.Content, 100))

	// ===== 消息存 DB 后 =====
	case "callbackAfterMsgSaveDBCommand":
		log.Printf("[SAVED] msgID=%s sendID=%s contentType=%d", req.ServerMsgID, req.SendID, req.ContentType)

	// ===== 用户上下线 =====
	case "callbackUserOnlineCommand":
		log.Printf("[ONLINE]  userID=%s platform=%s", req.UserID, req.Platform)
	case "callbackUserOfflineCommand":
		log.Printf("[OFFLINE] userID=%s platform=%s", req.UserID, req.Platform)

	// ===== 用户注册 =====
	case "callbackBeforeUserRegisterCommand":
		log.Printf("[REGISTER] userID=%s", req.SendID)
		// 可以在这里拒绝注册

	// ===== 好友相关 =====
	case "callbackBeforeAddFriendCommand":
		log.Printf("[FRIEND] sendID=%s wants to add friend", req.SendID)

	// ===== 群相关 =====
	case "callbackBeforeCreateGroupCommand":
		log.Printf("[GROUP] sendID=%s creating group", req.SendID)

	default:
		log.Printf("[HOOK] command=%s operationID=%s", req.CallbackCommand, req.OperationID)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(resp)
}

func target(req CallbackReq) string {
	if req.GroupID != "" {
		return "group:" + req.GroupID
	}
	return "user:" + req.RecvID
}

func truncate(s string, maxLen int) string {
	r := []rune(s)
	if len(r) > maxLen {
		return string(r[:maxLen]) + "..."
	}
	return s
}

func main() {
	port := 10006
	mux := http.NewServeMux()
	mux.HandleFunc("/callback", handleCallback)

	server := &http.Server{
		Addr:         fmt.Sprintf(":%d", port),
		Handler:      mux,
		ReadTimeout:  10 * time.Second,
		WriteTimeout: 10 * time.Second,
	}

	log.Printf("Webhook server starting on :%d", port)
	if err := server.ListenAndServe(); err != nil {
		log.Fatal(err)
	}
}
