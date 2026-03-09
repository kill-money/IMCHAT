import { clearTokens, getAdminInfo, isLoggedIn } from '@/services/openim';
import type { Settings as LayoutSettings } from '@ant-design/pro-components';
import type { RequestConfig, RunTimeLayoutConfig } from '@umijs/max';
import { history } from '@umijs/max';
import defaultSettings from '../config/defaultSettings';

const loginPath = '/user/login';

export async function getInitialState(): Promise<{
  settings?: Partial<LayoutSettings>;
  currentUser?: OPENIM.AdminInfo;
  loading?: boolean;
  fetchUserInfo?: () => Promise<OPENIM.AdminInfo | undefined>;
}> {
  const fetchUserInfo = async () => {
    try {
      if (!isLoggedIn()) {
        history.push(loginPath);
        return undefined;
      }
      const resp = await getAdminInfo();
      if (resp.errCode === 0 && resp.data) {
        return resp.data;
      }
      clearTokens();
      history.push(loginPath);
      return undefined;
    } catch (_error) {
      clearTokens();
      history.push(loginPath);
      return undefined;
    }
  };

  const { location } = history;
  if (location.pathname !== loginPath) {
    const currentUser = await fetchUserInfo();
    return {
      fetchUserInfo,
      currentUser,
      settings: defaultSettings as Partial<LayoutSettings>,
    };
  }
  return {
    fetchUserInfo,
    settings: defaultSettings as Partial<LayoutSettings>,
  };
}

// ProLayout 配置
export const layout: RunTimeLayoutConfig = ({
  initialState,
  setInitialState,
}) => {
  return {
    avatarProps: {
      src: initialState?.currentUser?.faceURL || undefined,
      title: initialState?.currentUser?.nickname || '管理员',
      render: (_, dom) => dom,
    },
    waterMarkProps: {
      content: initialState?.currentUser?.nickname,
    },
    onPageChange: () => {
      const { location } = history;
      if (!initialState?.currentUser && location.pathname !== loginPath) {
        history.push(loginPath);
      }
    },
    menuHeaderRender: undefined,
    title: 'OpenIM 管理后台',
    ...initialState?.settings,
  };
};

export const request: RequestConfig = {
  baseURL: '',
};
