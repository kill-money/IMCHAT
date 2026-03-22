/**
 * @name umi 的路由配置
 * @description 只支持 path,component,routes,redirect,wrappers,name,icon 的配置
 * @param path  path 只支持两种占位符配置，第一种是动态参数 :id 的形式，第二种是 * 通配符，通配符只能出现路由字符串的最后。
 * @param component 配置 location 和 path 匹配后用于渲染的 React 组件路径。可以是绝对路径，也可以是相对路径，如果是相对路径，会从 src/pages 开始找起。
 * @param routes 配置子路由，通常在需要为多个路径增加 layout 组件时使用。
 * @param redirect 配置路由跳转
 * @param wrappers 配置路由组件的包装组件，通过包装组件可以为当前的路由组件组合进更多的功能。 比如，可以用于路由级别的权限校验
 * @param name 配置路由的标题，默认读取国际化文件 menu.ts 中 menu.xxxx 的值，如配置 name 为 login，则读取 menu.ts 中 menu.login 的取值作为标题
 * @param icon 配置路由的图标，取值参考 https://ant.design/components/icon-cn， 注意去除风格后缀和大小写，如想要配置图标为 <StepBackwardOutlined /> 则取值应为 stepBackward 或 StepBackward，如想要配置图标为 <UserOutlined /> 则取值应为 user 或者 User
 * @doc https://umijs.org/docs/guides/routes
 */
export default [
  {
    path: "/user",
    layout: false,
    routes: [
      {
        name: "login",
        path: "/user/login",
        component: "./user/login",
      },
    ],
  },
  {
    path: "/dashboard",
    name: "数据概览",
    icon: "dashboard",
    component: "./dashboard",
  },
  {
    path: "/account",
    name: "账号管理",
    icon: "user",
    routes: [
      {
        path: "/account/center",
        name: "个人中心",
        component: "./account/center",
      },
      {
        path: "/account/settings",
        name: "个人设置",
        component: "./account/settings",
      },
      {
        path: "/account/permissions",
        name: "权限管理",
        component: "./account/permissions",
      },
      {
        path: "/account/2fa",
        name: "双因素认证",
        component: "./account/2fa",
      },
    ],
  },
  {
    path: "/user-manage",
    name: "用户管理",
    icon: "team",
    routes: [
      {
        path: "/user-manage/list",
        name: "用户列表",
        component: "./user-manage/list",
      },
      {
        path: "/user-manage/online",
        name: "在线用户",
        component: "./user-manage/online",
      },
      {
        path: "/user-manage/block",
        name: "封禁管理",
        component: "./user-manage/block",
      },
      {
        path: "/user-manage/batch",
        name: "批量创建",
        component: "./user-manage/batch",
      },
    ],
  },
  {
    path: "/group-manage",
    name: "群组管理",
    icon: "apartment",
    component: "./group-manage",
  },
  {
    path: "/msg-manage",
    name: "消息管理",
    icon: "message",
    routes: [
      {
        path: "/msg-manage/search",
        name: "消息搜索",
        component: "./msg-manage/search",
      },
      {
        path: "/msg-manage/send",
        name: "发送消息",
        component: "./msg-manage/send",
      },
      {
        path: "/msg-manage/broadcast",
        name: "系统广播",
        component: "./msg-manage/broadcast",
      },
    ],
  },
  {
    path: "/content-filter",
    name: "内容过滤",
    icon: "filter",
    component: "./system/content-filter",
  },
  // /applet 路由已移除：无对应组件实现
  {
    path: "/receptionist",
    name: "接待号",
    icon: "customer-service",
    component: "./security/receptionist",
  },
  {
    path: "/wallet/withdraw-audit",
    name: "提现审核",
    icon: "audit",
    component: "./system/wallet",
  },
  {
    path: "/system",
    name: "系统管理",
    icon: "setting",
    routes: [
      {
        path: "/system/admin",
        name: "管理员",
        component: "./system/admin",
      },
      {
        path: "/system/ip-forbidden",
        name: "IP封禁",
        component: "./system/ip-forbidden",
      },
      {
        path: "/system/ip-user-limit",
        name: "IP登录限制",
        component: "./system/ip-user-limit",
      },
      {
        path: "/system/user-admin",
        name: "用户端管理员",
        component: "./system/user-admin",
      },
      {
        path: "/system/wallet",
        name: "资金管理",
        component: "./system/wallet",
      },
      {
        path: "/system/config-center",
        name: "配置中心",
        component: "./system/config-center",
      },
      {
        path: "/system/content-filter",
        name: "内容过滤",
        component: "./system/content-filter",
      },
      {
        path: "/system/feature-toggle",
        name: "功能开关",
        component: "./system/feature-toggle",
      },
      {
        path: "/system/version",
        name: "版本管理",
        component: "./system/version",
      },
      {
        path: "/system/ratelimit",
        name: "限流策略",
        component: "./system/ratelimit",
      },
      {
        path: "/system/policy",
        name: "策略引擎",
        component: "./system/policy",
      },
    ],
  },
  {
    path: "/security",
    name: "安全控制",
    icon: "safety",
    routes: [
      {
        path: "/security/whitelist",
        name: "登录白名单",
        component: "./security/whitelist",
      },
      {
        path: "/security/receptionist",
        name: "接待员管理",
        component: "./security/receptionist",
      },
      {
        path: "/security/logs",
        name: "审计日志",
        component: "./security/logs",
      },
    ],
  },
  {
    path: "/banner-manage",
    name: "Banner管理",
    icon: "picture",
    hideInMenu: true, // Banner 服务（port 10011）尚未部署，暂时隐藏入口
    component: "./banner-manage",
  },
  {
    path: "/register-setting",
    name: "注册设置",
    icon: "userAdd",
    routes: [
      {
        path: "/register-setting/invitation",
        name: "邀请码",
        component: "./register-setting/invitation",
      },
      {
        path: "/register-setting/default-friend",
        name: "默认好友",
        component: "./register-setting/default-friend",
      },
      {
        path: "/register-setting/default-group",
        name: "默认群组",
        component: "./register-setting/default-group",
      },
    ],
  },
  {
    path: "/",
    redirect: "/dashboard",
  },
  {
    component: "404",
    layout: false,
    path: "./*",
  },
];
