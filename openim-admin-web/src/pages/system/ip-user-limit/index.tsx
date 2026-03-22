/**
 * 用户 IP 登录限制
 *
 * 功能：为特定用户指定允许登录的 IP 白名单。
 * 添加后，该用户只能从列表中的 IP 登录。
 *
 * 后端路由:
 *   POST /forbidden/user/search
 *   POST /forbidden/user/add
 *   POST /forbidden/user/del
 */
import {
  addUserIPLimitLogin,
  deleteUserIPLimitLogin,
  searchUserIPLimitLogin,
} from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  ModalForm,
  PageContainer,
  ProFormText,
  ProTable,
} from '@ant-design/pro-components';
import { Avatar, Button, message, Popconfirm, Space, Typography } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';

const IpUserLimit: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.UserIPLimitLoginItem>[] = [
    {
      title: '用户',
      dataIndex: 'userID',
      width: 220,
      render: (_, record) => (
        <Space>
          {record.user?.faceURL ? (
            <Avatar src={record.user.faceURL} size={28} />
          ) : (
            <Avatar size={28}>{record.userID.slice(-2)}</Avatar>
          )}
          <span>
            {record.user?.nickname && (
              <Typography.Text strong style={{ marginRight: 6 }}>
                {record.user.nickname}
              </Typography.Text>
            )}
            <Typography.Text type="secondary" copyable>
              {record.userID}
            </Typography.Text>
          </span>
        </Space>
      ),
    },
    {
      title: '允许 IP',
      dataIndex: 'ip',
      width: 180,
      copyable: true,
    },
    {
      title: '添加时间',
      dataIndex: 'createTime',
      width: 170,
      search: false,
      render: (_, r) =>
        r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定移除该条 IP 限制？"
          description={`用户 ${record.userID} 的 IP ${record.ip} 将被移除白名单`}
          onConfirm={async () => {
            const resp = await deleteUserIPLimitLogin([
              { userID: record.userID, ip: record.ip },
            ]);
            if (resp.errCode === 0) {
              message.success('已移除');
              actionRef.current?.reload();
            } else {
              message.error(resp.errMsg || '操作失败');
            }
          }}
        >
          <a className="ant-typography ant-typography-danger">移除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.UserIPLimitLoginItem>
        headerTitle="用户 IP 登录白名单"
        actionRef={actionRef}
        rowKey={(r) => `${r.userID}_${r.ip}`}
        columns={columns}
        toolBarRender={() => [
          <ModalForm
            key="add"
            title="添加 IP 白名单条目"
            trigger={
              <Button type="primary" icon={<PlusOutlined />}>
                添加
              </Button>
            }
            onFinish={async (values: { userID: string; ip: string }) => {
              const resp = await addUserIPLimitLogin([
                { userID: values.userID.trim(), ip: values.ip.trim() },
              ]);
              if (resp.errCode === 0) {
                message.success('添加成功');
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg || '添加失败');
              return false;
            }}
          >
            <ProFormText
              name="userID"
              label="用户 ID"
              placeholder="请输入用户 ID"
              rules={[{ required: true, message: '用户 ID 不能为空' }]}
            />
            <ProFormText
              name="ip"
              label="允许的 IP"
              placeholder="例：192.168.1.100"
              rules={[
                { required: true, message: 'IP 地址不能为空' },
                {
                  pattern: /^(\d{1,3}\.){3}\d{1,3}$/,
                  message: '请输入合法的 IPv4 地址',
                },
              ]}
            />
          </ModalForm>,
        ]}
        request={async (params) => {
          const resp = await searchUserIPLimitLogin({
            keyword: params.userID || params.ip || '',
            pagination: {
              pageNumber: params.current ?? 1,
              showNumber: params.pageSize ?? 20,
            },
          });
          return {
            data: resp.data?.list ?? [],
            total: resp.data?.total ?? 0,
            success: resp.errCode === 0,
          };
        }}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto' }}
      />
    </PageContainer>
  );
};

export default IpUserLimit;
