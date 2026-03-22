import { adminLogin, login2FA, setTokens } from '@/services/openim';
import { LockOutlined, SafetyOutlined, UserOutlined } from '@ant-design/icons';
import { ProFormText } from '@ant-design/pro-components';
import { history, useModel } from '@umijs/max';
import { Button, message } from 'antd';
import React, { useState } from 'react';

/* ── 样式常量 ── */
const PAGE_BG = 'linear-gradient(135deg, #0b1528 0%, #102a4a 50%, #1a3a5c 100%)';
const CARD_BG = 'rgba(255,255,255,0.06)';
const CARD_BORDER = '1px solid rgba(255,255,255,0.10)';
const CARD_SHADOW = '0 8px 32px rgba(0,0,0,0.35)';
const TEXT_PRIMARY = '#e8edf3';
const TEXT_SECONDARY = 'rgba(255,255,255,0.55)';
const ACCENT = '#3b82f6';

const pageStyle: React.CSSProperties = {
  display: 'flex',
  justifyContent: 'center',
  alignItems: 'center',
  minHeight: '100vh',
  background: PAGE_BG,
  padding: 24,
};

const cardStyle: React.CSSProperties = {
  width: 400,
  maxWidth: '100%',
  padding: '40px 36px 32px',
  background: CARD_BG,
  border: CARD_BORDER,
  borderRadius: 16,
  boxShadow: CARD_SHADOW,
  backdropFilter: 'blur(12px)',
};

const logoStyle: React.CSSProperties = {
  display: 'block',
  width: 72,
  height: 72,
  margin: '0 auto 16px',
  borderRadius: 14,
  objectFit: 'contain',
};

const titleStyle: React.CSSProperties = {
  textAlign: 'center',
  fontSize: 22,
  fontWeight: 600,
  color: TEXT_PRIMARY,
  margin: 0,
  lineHeight: 1.4,
};

const subtitleStyle: React.CSSProperties = {
  textAlign: 'center',
  fontSize: 13,
  color: TEXT_SECONDARY,
  margin: '6px 0 28px',
};

const inputStyle: React.CSSProperties = {
  background: 'rgba(255,255,255,0.07)',
  borderColor: 'rgba(255,255,255,0.15)',
  color: TEXT_PRIMARY,
};

const Login: React.FC = () => {
  const [loading, setLoading] = useState(false);
  const { initialState, setInitialState } = useModel('@@initialState');
  const [needs2FA, setNeeds2FA] = useState(false);
  const [tempToken, setTempToken] = useState('');
  const [totpCode, setTotpCode] = useState('');

  const handleSubmit = async (values: { account: string; password: string }) => {
    setLoading(true);
    try {
      const resp = await adminLogin(values.account, values.password);
      if (resp.errCode === 0 && resp.data) {
        if ((resp.data as any).requires2FA) {
          setTempToken((resp.data as any).tempToken);
          setNeeds2FA(true);
          message.info('请输入双因素认证码');
          setLoading(false);
          return;
        }
        setTokens(resp.data.adminToken, resp.data.imToken, resp.data.refreshToken);
        message.success('登录成功');
        const userInfo = await initialState?.fetchUserInfo?.();
        setInitialState((s) => ({ ...s, currentUser: userInfo }));
        history.push('/dashboard');
      } else {
        message.error(resp.errMsg || '登录失败');
      }
    } catch {
      message.error('登录失败，请检查网络连接');
    }
    setLoading(false);
  };

  const handle2FASubmit = async () => {
    if (totpCode.length !== 6) {
      message.error('请输入 6 位验证码');
      return;
    }
    setLoading(true);
    try {
      const resp = await login2FA(tempToken, totpCode);
      if (resp.errCode === 0 && resp.data) {
        setTokens(resp.data.adminToken, resp.data.imToken, resp.data.refreshToken);
        message.success('双因素认证通过');
        const userInfo = await initialState?.fetchUserInfo?.();
        setInitialState((s) => ({ ...s, currentUser: userInfo }));
        history.push('/dashboard');
      } else {
        message.error(resp.errMsg || '验证码无效');
      }
    } catch {
      message.error('验证失败');
    }
    setLoading(false);
  };

  /* ── 2FA 页面 ── */
  if (needs2FA) {
    return (
      <div style={pageStyle}>
        <div className="login-dark-inputs" style={cardStyle}>
          <img src="/logo.png" alt="logo" style={logoStyle} />
          <h2 style={{ ...titleStyle, marginBottom: 8 }}>双因素认证</h2>
          <p style={subtitleStyle}>
            请打开 Authenticator 应用，输入 6 位验证码
          </p>
          <ProFormText
            fieldProps={{
              size: 'large',
              prefix: <SafetyOutlined style={{ color: TEXT_SECONDARY }} />,
              maxLength: 6,
              value: totpCode,
              onChange: (e) => setTotpCode(e.target.value.replace(/\D/g, '')),
              onPressEnter: handle2FASubmit,
              style: { ...inputStyle, textAlign: 'center', letterSpacing: 8, fontSize: 22 },
            }}
            placeholder="000000"
          />
          <Button
            type="primary"
            block
            size="large"
            loading={loading}
            disabled={totpCode.length !== 6}
            onClick={handle2FASubmit}
            style={{ marginTop: 12, height: 44, borderRadius: 8, background: ACCENT, borderColor: ACCENT }}
          >
            验证
          </Button>
          <div style={{ textAlign: 'center', marginTop: 16 }}>
            <a
              style={{ color: ACCENT }}
              onClick={() => { setNeeds2FA(false); setTempToken(''); setTotpCode(''); }}
            >
              返回登录
            </a>
          </div>
        </div>
      </div>
    );
  }

  /* ── 登录页面 ── */
  return (
    <div style={pageStyle}>
      <div className="login-dark-inputs" style={cardStyle}>
        <img src="/logo.png" alt="logo" style={logoStyle} />
        <h1 style={titleStyle}>OpenIM 管理后台</h1>
        <p style={subtitleStyle}>即时通讯管理平台</p>

        <form
          onSubmit={async (e) => {
            e.preventDefault();
            const fd = new FormData(e.currentTarget);
            const account = (fd.get('account') as string)?.trim();
            const password = (fd.get('password') as string)?.trim();
            if (!account || !password) {
              message.warning('请填写账号和密码');
              return;
            }
            await handleSubmit({ account, password });
          }}
        >
          <div style={{ marginBottom: 20 }}>
            <ProFormText
              name="account"
              fieldProps={{
                size: 'large',
                prefix: <UserOutlined style={{ color: TEXT_SECONDARY }} />,
                style: inputStyle,
              }}
              placeholder="管理员账号"
              rules={[{ required: true, message: '请输入账号' }]}
            />
          </div>
          <div style={{ marginBottom: 4 }}>
            <ProFormText.Password
              name="password"
              fieldProps={{
                size: 'large',
                prefix: <LockOutlined style={{ color: TEXT_SECONDARY }} />,
                style: inputStyle,
              }}
              placeholder="密码"
              rules={[{ required: true, message: '请输入密码' }]}
            />
          </div>
          <Button
            type="primary"
            htmlType="submit"
            block
            size="large"
            loading={loading}
            style={{ height: 44, borderRadius: 8, marginTop: 8, background: ACCENT, borderColor: ACCENT, fontWeight: 500 }}
          >
            登 录
          </Button>
        </form>

        <p style={{ textAlign: 'center', color: TEXT_SECONDARY, fontSize: 12, marginTop: 28, marginBottom: 0 }}>
          © {new Date().getFullYear()} OpenIM · 即时通讯管理系统
        </p>
      </div>
    </div>
  );
};

export default Login;
