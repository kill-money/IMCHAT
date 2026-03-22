import { disable2FA, get2FAStatus, setup2FA, verify2FA } from '@/services/openim/api';
import { PageContainer } from '@ant-design/pro-components';
import { Button, Card, Input, message, Space, Tag, Typography } from 'antd';
import React, { useEffect, useState } from 'react';

const { Text } = Typography;

interface SetupInfo {
  secret: string;
  otpauthURI: string;
  issuer: string;
  digits: number;
  period: number;
}

const TwoFAPage: React.FC = () => {
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [setupInfo, setSetupInfo] = useState<SetupInfo | null>(null);
  const [verifyCode, setVerifyCode] = useState('');
  const [disableCode, setDisableCode] = useState('');
  const [loading, setLoading] = useState(false);

  const fetchStatus = async () => {
    const resp = await get2FAStatus();
    if (resp.errCode === 0) {
      setEnabled(!!resp.data?.enabled);
      return;
    }
    message.error(resp.errMsg || '获取 2FA 状态失败');
  };

  useEffect(() => {
    fetchStatus();
  }, []);

  const handleSetup = async () => {
    setLoading(true);
    const resp = await setup2FA();
    if (resp.errCode === 0 && resp.data) {
      setSetupInfo(resp.data as SetupInfo);
      message.success('已生成密钥，请完成绑定');
    } else {
      message.error(resp.errMsg || '生成密钥失败');
    }
    setLoading(false);
  };

  const handleVerify = async () => {
    if (verifyCode.length !== 6) {
      message.error('请输入 6 位验证码');
      return;
    }
    setLoading(true);
    const resp = await verify2FA(verifyCode);
    if (resp.errCode === 0) {
      message.success('2FA 已启用');
      setSetupInfo(null);
      setVerifyCode('');
      await fetchStatus();
    } else {
      message.error(resp.errMsg || '验证失败');
    }
    setLoading(false);
  };

  const handleDisable = async () => {
    if (disableCode.length !== 6) {
      message.error('请输入 6 位验证码');
      return;
    }
    setLoading(true);
    const resp = await disable2FA(disableCode);
    if (resp.errCode === 0) {
      message.success('2FA 已禁用');
      setDisableCode('');
      await fetchStatus();
    } else {
      message.error(resp.errMsg || '禁用失败');
    }
    setLoading(false);
  };

  return (
    <PageContainer>
      <Card style={{ marginBottom: 16 }}>
        <Space size={12} align="center">
          <Text strong>当前状态：</Text>
          {enabled === null ? (
            <Tag color="default">加载中</Tag>
          ) : enabled ? (
            <Tag color="green">已启用</Tag>
          ) : (
            <Tag color="red">未启用</Tag>
          )}
        </Space>
      </Card>

      {!enabled && (
        <Card title="绑定 2FA" style={{ marginBottom: 16 }}>
          <Space direction="vertical" style={{ width: '100%' }} size={12}>
            <Button type="primary" onClick={handleSetup} loading={loading}>
              生成 2FA 密钥
            </Button>
            {setupInfo && (
              <div>
                <div><Text strong>Secret：</Text>{setupInfo.secret}</div>
                <div><Text strong>otpauthURI：</Text>{setupInfo.otpauthURI}</div>
                <div><Text type="secondary">请在 Authenticator 中手动添加上述密钥或 URI。</Text></div>
              </div>
            )}
            <Input
              placeholder="输入 6 位验证码"
              maxLength={6}
              value={verifyCode}
              onChange={(e) => setVerifyCode(e.target.value.replace(/\D/g, ''))}
              style={{ width: 240 }}
            />
            <Button type="primary" onClick={handleVerify} loading={loading}>
              验证并启用
            </Button>
          </Space>
        </Card>
      )}

      {enabled && (
        <Card title="禁用 2FA">
          <Space direction="vertical" size={12}>
            <Input
              placeholder="输入 6 位验证码"
              maxLength={6}
              value={disableCode}
              onChange={(e) => setDisableCode(e.target.value.replace(/\D/g, ''))}
              style={{ width: 240 }}
            />
            <Button danger onClick={handleDisable} loading={loading}>
              禁用 2FA
            </Button>
          </Space>
        </Card>
      )}
    </PageContainer>
  );
};

export default TwoFAPage;
