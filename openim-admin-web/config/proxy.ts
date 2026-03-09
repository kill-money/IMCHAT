/**
 * @name 代理的配置
 * @see 在生产环境 代理是无法生效的，所以这里没有生产环境的配置
 * -------------------------------
 * The agent cannot take effect in the production environment
 * so there is no configuration of the production environment
 * For details, please see
 * https://pro.ant.design/docs/deploy
 *
 * @doc https://umijs.org/docs/guides/proxy
 */
export default {
  dev: {
    // OpenIM Admin API (后台管理接口 → :10009)
    "/admin_api/": {
      target: "http://localhost:10009",
      changeOrigin: true,
      pathRewrite: { "^/admin_api": "" },
    },
    // OpenIM Chat API (用户聊天接口 → :10008)
    "/chat_api/": {
      target: "http://localhost:10008",
      changeOrigin: true,
      pathRewrite: { "^/chat_api": "" },
    },
    // OpenIM IM API (核心 IM 接口 → :10002)
    "/im_api/": {
      target: "http://localhost:10002",
      changeOrigin: true,
      pathRewrite: { "^/im_api": "" },
    },
    // Banner 管理微服务 (→ :10011)
    "/banner_api/": {
      target: "http://localhost:10011",
      changeOrigin: true,
      pathRewrite: { "^/banner_api": "" },
    },
  },
  /**
   * @name 详细的代理配置
   * @doc https://github.com/chimurai/http-proxy-middleware
   */
  test: {
    // localhost:8000/api/** -> https://preview.pro.ant.design/api/**
    "/api/": {
      target: "https://proapi.azurewebsites.net",
      changeOrigin: true,
      pathRewrite: { "^": "" },
    },
  },
  pre: {
    "/api/": {
      target: "your pre url",
      changeOrigin: true,
      pathRewrite: { "^": "" },
    },
  },
};
