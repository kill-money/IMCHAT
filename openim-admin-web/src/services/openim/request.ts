import { request } from "@umijs/max";

const ADMIN_TOKEN_KEY = "openim_admin_token";
const IM_TOKEN_KEY = "openim_im_token";

/** 获取 admin token */
export function getAdminToken(): string {
  return localStorage.getItem(ADMIN_TOKEN_KEY) || "";
}

/** 获取 im token */
export function getImToken(): string {
  return localStorage.getItem(IM_TOKEN_KEY) || "";
}

/** 保存双 token */
export function setTokens(adminToken: string, imToken: string) {
  localStorage.setItem(ADMIN_TOKEN_KEY, adminToken);
  localStorage.setItem(IM_TOKEN_KEY, imToken);
}

/** 清除 token */
export function clearTokens() {
  localStorage.removeItem(ADMIN_TOKEN_KEY);
  localStorage.removeItem(IM_TOKEN_KEY);
}

/** 是否已登录 */
export function isLoggedIn(): boolean {
  return !!getAdminToken() && !!getImToken();
}

/** 调用 admin API (:10009) */
export async function adminRequest<T = any>(
  url: string,
  data?: Record<string, any>
): Promise<OPENIM.BaseResponse<T>> {
  const resp = await request<OPENIM.BaseResponse<T>>(`/admin_api${url}`, {
    method: "POST",
    data,
    headers: {
      token: getAdminToken(),
      operationID: String(Date.now()),
    },
    skipErrorHandler: true,
  });
  if (resp.errCode === 1501) {
    clearTokens();
    window.location.href = "/user/login";
    throw new Error("Token expired");
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
    headers: {
      token: getImToken(),
      operationID: String(Date.now()),
    },
    skipErrorHandler: true,
  });
  if (resp.errCode === 1501) {
    clearTokens();
    window.location.href = "/user/login";
    throw new Error("Token expired");
  }
  return resp;
}

/** 调用 Chat API (:10008) */
export async function chatRequest<T = any>(
  url: string,
  data?: Record<string, any>
): Promise<OPENIM.BaseResponse<T>> {
  const resp = await request<OPENIM.BaseResponse<T>>(`/chat_api${url}`, {
    method: "POST",
    data,
    headers: {
      token: getAdminToken(),
      operationID: String(Date.now()),
    },
    skipErrorHandler: true,
  });
  if (resp.errCode === 1501) {
    clearTokens();
    window.location.href = "/user/login";
    throw new Error("Token expired");
  }
  return resp;
}
