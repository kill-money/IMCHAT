import { adminLogin, setTokens } from '@/services/openim';
import { LockOutlined, UserOutlined } from '@ant-design/icons';
import { LoginForm, ProFormText } from '@ant-design/pro-components';
import { history, useModel } from '@umijs/max';
import { message } from 'antd';
import React, { useState } from 'react';

const Login: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const { initialState, setInitialState } = useModel('@@initialState');

  const handleSubmit = async (values: { account: string; password: string }) => {
    setLoading(true);
    try {
      const resp = await adminLogin(values.account, values.password);
      if (resp.errCode === 0 && resp.data) {
        setTokens(resp.data.adminToken, resp.data.imToken);
        message.success('登录成功');
        const userInfo = await initialState?.fetchUserInfo?.();
        setInitialState((s) => ({ ...s, currentUser: userInfo }));
        history.push('/dashboard');
      } else {
        message.error(resp.errMsg || '登录失败');
      }
    } catch (error: any) {
      message.error('登录失败，请检查网络连接');
    }
    setLoading(false);
  };

  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: '100vh', background: '#f0f2f5' }}>
      <LoginForm
        title="OpenIM 管理后台"
        subTitle="即时通讯管理平台"
        onFinish={handleSubmit}
        loading={loading}
      >
        <ProFormText
          name="account"
          fieldProps={{ size: 'large', prefix: <UserOutlined /> }}
          placeholder="管理员账号"
          rules={[{ required: true, message: '请输入账号' }]}
        />
        <ProFormText.Password
          name="password"
          fieldProps={{ size: 'large', prefix: <LockOutlined /> }}
          placeholder="密码"
          rules={[{ required: true, message: '请输入密码' }]}
        />
      </LoginForm>
    </div>
  );
};

export default Login;
