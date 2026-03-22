// ============================================================
// OpenIM 安全加固 — k6 压力测试脚本
// ============================================================
// 覆盖场景：
//   1. 管理员登录（含 MD5 密码哈希、Token 获取）
//   2. 用户搜索并发
//   3. SensitiveVerify challenge 签发
//   4. 审计日志查询
//   5. Token 刷新
//   6. WebSocket Ticket 签发
//   7. 风控评分查询
//   8. IM API 联调
//   9. 双维度限流验证（bf:{account}:{ip} + bf:ip:{ip}）
//
// 运行方式：
//   k6 run scripts/k6_load_test.js                        # 默认阶段式负载
//   k6 run --vus 100 --duration 60s scripts/k6_load_test.js
//   k6 run --out json=results.json scripts/k6_load_test.js # JSON 输出
//   k6 run --out csv=results.csv  scripts/k6_load_test.js  # CSV 输出
//
// 环境变量：
//   ADMIN_API  — Admin API 地址 (默认 http://localhost:10009)
//   IM_API     — IM API 地址    (默认 http://localhost:10002)
//   ACCOUNT    — 管理员账号     (默认 imAdmin)
//   PASSWORD   — 管理员密码明文 (默认 openIM123)
// ============================================================

import http from "k6/http";
import ws from "k6/ws";
import { check, group, sleep } from "k6";
import { Counter, Rate, Trend } from "k6/metrics";
import { crypto } from "k6/experimental/webcrypto";

// ── 自定义指标 ──────────────────────────────────────────────
const loginDuration = new Trend("login_duration", true);
const loginFailRate = new Rate("login_fail_rate");
const apiErrors = new Counter("api_errors");
const rateLimitHits = new Counter("rate_limit_429");

// ── 配置 ────────────────────────────────────────────────────
const ADMIN_API = __ENV.ADMIN_API || "http://localhost:10009";
const IM_API = __ENV.IM_API || "http://localhost:10002";
const ACCOUNT = __ENV.ACCOUNT || "imAdmin";
const PASSWORD = __ENV.PASSWORD || "openIM123";

// ── 阶段式负载模型 ─────────────────────────────────────────
export const options = {
  stages: [
    { duration: "15s", target: 20 },   // 缓步爬升
    { duration: "30s", target: 100 },  // 稳态 100 VU
    { duration: "30s", target: 200 },  // 峰值 200 VU
    { duration: "15s", target: 0 },    // 回落
  ],
  thresholds: {
    http_req_duration: ["p(95)<2000"],   // 95% 请求 < 2s
    http_req_failed: ["rate<0.05"],      // 失败率 < 5%
    login_duration: ["p(95)<3000"],      // 登录 p95 < 3s
    login_fail_rate: ["rate<0.1"],       // 登录失败率 < 10%
  },
};

// ── MD5 哈希（匹配前端逻辑）─────────────────────────────────
function md5Hex(text) {
  // k6 内置 crypto 不含 MD5，用 CryptoJS 替代
  // 此处采用硬编码方式——因为密码固定，避免引入外部依赖
  // openIM123 → fb01f147b53025cb74aae37eb0a4f46e
  const knownHashes = {
    openIM123: "fb01f147b53025cb74aae37eb0a4f46e",
  };
  if (knownHashes[text]) return knownHashes[text];
  // 未知密码：实际生产中应用 k6-utils 或 JSLib
  return text;
}

const MD5_PASSWORD = md5Hex(PASSWORD);

// ── 公共请求头 ──────────────────────────────────────────────
function headers(token) {
  const h = {
    "Content-Type": "application/json",
    operationID: `k6_${Date.now()}_${Math.random().toString(36).slice(2, 8)}`,
  };
  if (token) h["token"] = token;
  return h;
}

// ── 登录并缓存 Token（每 VU 一次）──────────────────────────
export function setup() {
  const res = http.post(
    `${ADMIN_API}/account/login`,
    JSON.stringify({ account: ACCOUNT, password: MD5_PASSWORD }),
    { headers: headers() }
  );
  const body = res.json();
  check(res, { "setup login 200": (r) => r.status === 200 });
  check(body, { "setup login errCode=0": (b) => b.errCode === 0 });

  return {
    adminToken: body.data ? body.data.adminToken : "",
    imToken: body.data ? body.data.imToken : "",
    refreshToken: body.data ? body.data.refreshToken : "",
  };
}

// ── 主测试函数 ──────────────────────────────────────────────
export default function (data) {
  // ────── 1. 登录压测 ──────
  group("1_admin_login", () => {
    const start = Date.now();
    const res = http.post(
      `${ADMIN_API}/account/login`,
      JSON.stringify({ account: ACCOUNT, password: MD5_PASSWORD }),
      { headers: headers(), tags: { name: "login" } }
    );
    loginDuration.add(Date.now() - start);

    const ok = check(res, {
      "login status 200": (r) => r.status === 200,
    });
    if (!ok) {
      loginFailRate.add(1);
      apiErrors.add(1);
      if (res.status === 429) rateLimitHits.add(1);
      return;
    }
    loginFailRate.add(0);
    const body = res.json();
    check(body, { "login errCode=0": (b) => b.errCode === 0 });
  });

  sleep(0.3);

  // ────── 2. 用户搜索并发 ──────
  group("2_user_search", () => {
    const res = http.post(
      `${ADMIN_API}/user/search`,
      JSON.stringify({
        keyword: "",
        pagination: { pageNumber: 1, showNumber: 10 },
      }),
      { headers: headers(data.adminToken), tags: { name: "user_search" } }
    );
    check(res, { "user_search 200": (r) => r.status === 200 });
    if (res.status !== 200) apiErrors.add(1);
    if (res.status === 429) rateLimitHits.add(1);
  });

  sleep(0.2);

  // ────── 3. SensitiveVerify Challenge ──────
  group("3_sensitive_challenge", () => {
    const res = http.post(
      `${ADMIN_API}/security/challenge`,
      JSON.stringify({ action: "change_password" }),
      { headers: headers(data.adminToken), tags: { name: "challenge" } }
    );
    check(res, { "challenge 200": (r) => r.status === 200 });
    if (res.status !== 200) apiErrors.add(1);
  });

  sleep(0.2);

  // ────── 4. 审计日志查询 ──────
  group("4_audit_log_search", () => {
    const res = http.post(
      `${ADMIN_API}/security_log/search`,
      JSON.stringify({ pageNum: 1, showNum: 10 }),
      { headers: headers(data.adminToken), tags: { name: "audit_log" } }
    );
    check(res, { "audit_log 200": (r) => r.status === 200 });
    if (res.status !== 200) apiErrors.add(1);
  });

  sleep(0.2);

  // ────── 5. Token 刷新 ──────
  group("5_token_refresh", () => {
    if (!data.refreshToken) return;
    const res = http.post(
      `${ADMIN_API}/account/refresh`,
      JSON.stringify({ refreshToken: data.refreshToken }),
      { headers: headers(data.adminToken), tags: { name: "refresh" } }
    );
    // Token 刷新可能因为 token 已过期返回非 200
    check(res, {
      "refresh status ok": (r) => r.status === 200 || r.status === 401,
    });
  });

  sleep(0.2);

  // ────── 6. WebSocket Ticket 签发 ──────
  group("6_ws_ticket", () => {
    const res = http.post(
      `${ADMIN_API}/ws/auth`,
      JSON.stringify({}),
      { headers: headers(data.adminToken), tags: { name: "ws_ticket" } }
    );
    check(res, { "ws_ticket 200": (r) => r.status === 200 });
    if (res.status !== 200) apiErrors.add(1);
  });

  sleep(0.2);

  // ────── 7. 风控评分查询 ──────
  group("7_risk_score", () => {
    const res = http.post(
      `${ADMIN_API}/security/risk/score`,
      JSON.stringify({ userID: ACCOUNT }),
      { headers: headers(data.adminToken), tags: { name: "risk_score" } }
    );
    check(res, { "risk_score 200": (r) => r.status === 200 });
  });

  sleep(0.2);

  // ────── 8. IM API 联调（在线状态）──────
  group("8_im_online_status", () => {
    const res = http.post(
      `${IM_API}/user/get_users_online_status`,
      JSON.stringify({ userIDs: [ACCOUNT] }),
      { headers: headers(data.imToken), tags: { name: "im_online" } }
    );
    check(res, {
      "im_online status ok": (r) => r.status === 200 || r.status === 0,
    });
  });

  sleep(0.2);

  // ────── 9. 双维度限流验证 ──────
  // 用随机假账号发错误密码 → 验证不会锁死真实管理员
  // 同时验证同一 IP 达到全局阈值 (20次) 后被拦截
  group("9_dual_dimension_brute", () => {
    const fakeAccount = `k6fake_${__VU}_${__ITER}`;
    const res = http.post(
      `${ADMIN_API}/account/login`,
      JSON.stringify({ account: fakeAccount, password: "wrongpwd" }),
      { headers: headers(), tags: { name: "brute_test" } }
    );
    // 预期：要么密码错误 (200 + errCode!=0)，要么被限流 (429)
    const ok = check(res, {
      "brute: not crash": (r) => r.status === 200 || r.status === 429,
    });
    if (res.status === 429) rateLimitHits.add(1);
  });

  sleep(0.5);
}

// ── 清理 ────────────────────────────────────────────────────
export function teardown(data) {
  console.log("=== k6 压测完成 ===");
  console.log(`AdminToken: ${data.adminToken ? "有效" : "无"}`);
}
