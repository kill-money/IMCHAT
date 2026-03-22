import { PageContainer } from '@ant-design/pro-components';
import { Button, Card, Descriptions } from 'antd';
import { history, useModel } from '@umijs/max';
import dayjs from 'dayjs';
import React from 'react';

const AccountCenter: React.FC = () => {
  const { initialState } = useModel('@@initialState');
  const user = initialState?.currentUser;

  return (
    <PageContainer>
      <Card
        title="个人中心"
        extra={
          <Button type="primary" onClick={() => history.push('/account/settings')}>
            编辑资料
          </Button>
        }
      >
        <Descriptions column={2} bordered>
          <Descriptions.Item label="账号">{user?.account || '-'}</Descriptions.Item>
          <Descriptions.Item label="昵称">{user?.nickname || '-'}</Descriptions.Item>
          <Descriptions.Item label="用户ID">{user?.userID || '-'}</Descriptions.Item>
          <Descriptions.Item label="等级">{user?.level ?? '-'}</Descriptions.Item>
          <Descriptions.Item label="创建时间">
            {user?.createTime ? dayjs(user.createTime).format('YYYY-MM-DD HH:mm') : '-'}
          </Descriptions.Item>
        </Descriptions>
      </Card>
    </PageContainer>
  );
};

export default AccountCenter;
