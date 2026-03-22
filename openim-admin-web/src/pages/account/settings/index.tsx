import { changeAdminPassword, updateAdminInfo } from '@/services/openim/api';
import { PageContainer, ProForm, ProFormText } from '@ant-design/pro-components';
import { Button, Card, message } from 'antd';
import { useModel } from '@umijs/max';
import React, { useMemo, useState } from 'react';

const AccountSettings: React.FC = () => {
  const { initialState, setInitialState } = useModel('@@initialState');
  const currentUser = initialState?.currentUser;
  const [savingProfile, setSavingProfile] = useState(false);
  const [savingPassword, setSavingPassword] = useState(false);

  const profileInitial = useMemo(
    () => ({
      account: currentUser?.account,
      nickname: currentUser?.nickname,
      faceURL: currentUser?.faceURL,
      level: currentUser?.level,
    }),
    [currentUser]
  );

  const handleProfileSave = async (values: { nickname?: string; faceURL?: string }) => {
    setSavingProfile(true);
    const resp = await updateAdminInfo({
      nickname: values.nickname,
      faceURL: values.faceURL,
    });
    if (resp.errCode === 0) {
      message.success('已更新个人信息');
      const userInfo = await initialState?.fetchUserInfo?.();
      setInitialState((s) => ({ ...s, currentUser: userInfo }));
      setSavingProfile(false);
      return true;
    }
    message.error(resp.errMsg || '更新失败');
    setSavingProfile(false);
    return false;
  };

  const handlePasswordSave = async (values: { currentPassword: string; newPassword: string; confirmPassword: string }) => {
    if (values.newPassword !== values.confirmPassword) {
      message.error('两次输入的新密码不一致');
      return false;
    }
    setSavingPassword(true);
    const resp = await changeAdminPassword(values.currentPassword, values.newPassword);
    if (resp.errCode === 0) {
      message.success('密码修改成功');
      setSavingPassword(false);
      return true;
    }
    message.error(resp.errMsg || '修改失败');
    setSavingPassword(false);
    return false;
  };

  return (
    <PageContainer>
      <Card title="个人信息" style={{ marginBottom: 16 }}>
        <ProForm
          submitter={{
            render: (props) => (
              <Button type="primary" onClick={() => props.form?.submit?.()} loading={savingProfile}>
                保存
              </Button>
            ),
          }}
          initialValues={profileInitial}
          onFinish={handleProfileSave}
        >
          <ProFormText name="account" label="账号" disabled />
          <ProFormText name="nickname" label="昵称" />
          <ProFormText name="faceURL" label="头像 URL" />
          <ProFormText name="level" label="等级" disabled />
        </ProForm>
      </Card>

      <Card title="修改密码">
        <ProForm
          submitter={{
            render: (props) => (
              <Button type="primary" onClick={() => props.form?.submit?.()} loading={savingPassword}>
                修改密码
              </Button>
            ),
          }}
          onFinish={handlePasswordSave}
        >
          <ProFormText.Password name="currentPassword" label="旧密码" rules={[{ required: true }]} />
          <ProFormText.Password name="newPassword" label="新密码" rules={[{ required: true }]} />
          <ProFormText.Password name="confirmPassword" label="确认新密码" rules={[{ required: true }]} />
        </ProForm>
      </Card>
    </PageContainer>
  );
};

export default AccountSettings;
