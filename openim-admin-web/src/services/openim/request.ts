import { request } from "@umijs/max";
import md5 from "md5";

const IM_TOKEN_KEY = "openim_im_token";
const DEVICE_ID_KEY = "openim_device_id";

/** 生成请求级 traceID（operationID + X-Request-ID 复用） */
function generateTraceID(): string {
  return `${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;
}

/** 从 Cookie 中提取 CSRF Token（Double Submit Cookie 模式） */
function getCSRFToken(): string {
  const match = document.cookie.match(/(?:^|;\s*)csrf_token=([^;]+)/);
  return match?.[1] ?? '';
}

/** 构建公共请求头 */
function commonHeaders(): Record<string, string> {
  const traceID = generateTraceID();
  return {
    operationID: traceID,
    "X-Request-ID": traceID,
    "X-Device-ID": getDeviceID(),
    "X-CSRF-Token": getCSRFToken(),
  };
}

/** 获取或生成设备指纹 ID（持久化到 localStorage — 非敏感数据） */
export function getDeviceID(): string {
  let deviceID = localStorage.getItem(DEVICE_ID_KEY);
  if (!deviceID) {
    // 生成 UUID v4
    deviceID = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, (c) => {
      const r = (Math.random() * 16) | 0;
      const v = c === "x" ? r : (r & 0x3) | 0x8;
      return v.toString(16);
    });
    localStorage.setItem(DEVICE_ID_KEY, deviceID);
  }
  return deviceID;
}

/**
 * admin_token 和 refresh_token 存储在 HttpOnly Cookie 中（JS 不可读），
 * 由后端 Set-Cookie 写入，请求通过 credentials:'include' 自动携带。
 * im_token 仍需 JS 发送 header（openim-server 无法读 Cookie），使用 sessionStorage。
 */

/** 获取 im token（sessionStorage — 关闭标签页即清除） */
export function getImToken(): string {
  return sessionStorage.getItem(IM_TOKEN_KEY) || "";
}

/** 保存 tokens（admin/refresh 由 Cookie 处理，此处仅保存 imToken） */
export function setTokens(_adminToken: string, imToken?: string, _refreshToken?: string) {
  if (imToken) sessionStorage.setItem(IM_TOKEN_KEY, imToken);
}

/** 清除 token（Cookie 由后端清除或过期自动失效） */
export function clearTokens() {
  sessionStorage.removeItem(IM_TOKEN_KEY);
}

/** 是否已登录 — imToken 存在即视为已登录（admin_token 在 HttpOnly Cookie 中不可读） */
export function isLoggedIn(): boolean {
  return !!getImToken();
}

// ——— 刷新锁，防止并发请求同时触发多次 refresh ———
let _refreshPromise: Promise<boolean> | null = null;

/** 用 refreshToken 换取新的 accessToken（Cookie 自动携带 refresh_token） */
async function tryRefreshToken(): Promise<boolean> {
  if (_refreshPromise) return _refreshPromise;

  _refreshPromise = (async () => {
    try {
      const resp = await request<OPENIM.BaseResponse<OPENIM.RefreshTokenResult>>(
        "/admin_api/account/token/refresh",
        {
          method: "POST",
          data: {},
          headers: commonHeaders(),
          credentials: "include",
          skipErrorHandler: true,
        }
      );
      if (resp.errCode === 0 && resp.data?.adminToken) {
        // admin_token/refresh_token 已由后端 Set-Cookie 更新
        return true;
      }
      clearTokens();
      return false;
    } catch {
      clearTokens();
      return false;
    } finally {
      _refreshPromise = null;
    }
  })();
  return _refreshPromise;
}

/** 处理 token 过期：先尝试刷新，失败后跳转登录页 */
async function handleTokenExpiry(): Promise<never> {
  const ok = await tryRefreshToken();
  if (!ok) {
    clearTokens();
    window.location.href = "/user/login";
  }
  // 刷新成功时抛出，让调用方重试（由各 request 函数负责重试一次）
  throw new Error("TOKEN_REFRESHED");
}

/** 调用 admin API (:10009)，admin_token 由 HttpOnly Cookie 自动携带 */
export async function adminRequest<T = any>(
  url: string,
  data?: Record<string, any>
): Promise<OPENIM.BaseResponse<T>> {
  const doRequest = () =>
    request<OPENIM.BaseResponse<T>>(`/admin_api${url}`, {
      method: "POST",
      data,
      headers: commonHeaders(),
      credentials: "include",
      skipErrorHandler: true,
    });

  const resp = await doRequest();
  if (resp.errCode === 1501) {
    await handleTokenExpiry();
    // 如果刷新成功，重试一次（handleTokenExpiry 成功时会 throw，这里不会有第二次 1501）
    return doRequest();
  }
  return resp;
}

/** 调用 IM API (:10002) */
export async function imRequest<T = any>(
  url: string,
  data?: Record<string, any>
): Promise<OPENIM.BaseResponse<T>> {
  const resp = await request<OPENIM.BaseResponse<T>>(`/im_api${url}`, {
    method: "POST",
    data,
    headers: { token: getImToken(), ...commonHeaders() },
    skipErrorHandler: true,
  });
  if (resp.errCode === 1501) {
    clearTokens();
    window.location.href = "/user/login";
    throw new Error("Token expired");
  }
  return resp;
}

/** 调用 Chat API (:10008), admin_token 由 HttpOnly Cookie 自动携带 */
export async function chatRequest<T = any>(
  url: string,
  data?: Record<string, any>
): Promise<OPENIM.BaseResponse<T>> {
  const resp = await request<OPENIM.BaseResponse<T>>(`/chat_api${url}`, {
    method: "POST",
    data,
    headers: commonHeaders(),
    credentials: "include",
    skipErrorHandler: true,
  });
  if (resp.errCode === 1501) {
    clearTokens();
    window.location.href = "/user/login";
    throw new Error("Token expired");
  }
  return resp;
}

// ——— 敏感操作 Nonce Challenge-Response v2 (HMAC-SHA256 + action binding) ———

/**
 * HMAC-SHA256 (Web Crypto API)
 * @returns 小写 hex 字符串
 */
async function hmacSHA256(message: string, key: string): Promise<string> {
  const enc = new TextEncoder();
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    enc.encode(key),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"]
  );
  const sig = await crypto.subtle.sign("HMAC", cryptoKey, enc.encode(message));
  return Array.from(new Uint8Array(sig))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * 获取一次性 nonce（绑定 action，有效期 60s）。
 * 后端：POST /admin_api/account/confirm/challenge
 */
async function fetchChallenge(action: string): Promise<string> {
  const resp = await adminRequest<{ nonce: string; expire: number }>(
    "/account/confirm/challenge",
    { action }
  );
  if (resp.errCode !== 0 || !resp.data?.nonce) {
    throw new Error(resp.errMsg || "获取 challenge 失败");
  }
  return resp.data.nonce;
}

/**
 * 敏感操作专用请求 v2：HMAC-SHA256 + action-bound nonce。
 *
 * 流程：
 *  1. fetchChallenge(action) → nonce
 *  2. hash = HMAC-SHA256( nonce + ":" + action, MD5(password) )
 *  3. 请求目标 API 携带 X-Confirm-Hash / X-Confirm-Nonce / X-Confirm-Action
 *
 * @param url       API path（例如 "/wallet/adjust"）
 * @param data      请求体
 * @param password  管理员明文密码（仅在内存，用完即弃）
 * @param action    操作标识（wallet_adjust / user_delete）
 */
export async function sensitiveAdminRequest<T = any>(
  url: string,
  data: Record<string, any> | undefined,
  password: string,
  action: string
): Promise<OPENIM.BaseResponse<T>> {
  // Step 1：获取一次性 nonce（绑定 action）
  const nonce = await fetchChallenge(action);

  // Step 2：HMAC-SHA256( nonce + ":" + action, MD5(password) )
  const passwordMd5 = md5(password);
  const confirmHash = await hmacSHA256(nonce + ":" + action, passwordMd5);

  // Step 3：带签名头请求目标接口（admin_token 由 Cookie 自动携带）
  const resp = await request<OPENIM.BaseResponse<T>>(`/admin_api${url}`, {
    method: "POST",
    data,
    headers: {
      ...commonHeaders(),
      "X-Confirm-Hash": confirmHash,
      "X-Confirm-Nonce": nonce,
      "X-Confirm-Action": action,
    },
    credentials: "include",
    skipErrorHandler: true,
  });
  if (resp.errCode === 1501) {
    await handleTokenExpiry();
    return sensitiveAdminRequest<T>(url, data, password, action);
  }
  return resp;
}
