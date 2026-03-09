import { addDefaultFriends, deleteDefaultFriends, searchDefaultFriends } from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormText, ProTable } from '@ant-design/pro-components';
import { Avatar, Button, message, Popconfirm } from 'antd';
import React, { useRef } from 'react';

const DefaultFriend: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.UserInfo>[] = [
    {
      title: '头像',
      dataIndex: 'faceURL',
      search: false,
      width: 60,
      render: (_, r) => <Avatar src={r.faceURL} size="small">{r.nickname?.[0]}</Avatar>,
    },
    { title: 'UserID', dataIndex: 'userID', width: 200, copyable: true },
    { title: '昵称', dataIndex: 'nickname', width: 150, search: false },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定移除该默认好友？"
          onConfirm={async () => {
            const resp = await deleteDefaultFriends([record.userID]);
            if (resp.errCode === 0) {
              message.success('已移除');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}
        >
          <a className="ant-typography ant-typography-danger">移除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.UserInfo>
        headerTitle="默认好友列表"
        actionRef={actionRef}
        rowKey="userID"
        columns={columns}
        toolBarRender={() => [
          <ModalForm
            key="add"
            title="添加默认好友"
            trigger={<Button type="primary" icon={<PlusOutlined />}>添加默认好友</Button>}
            onFinish={async (values: { userIDs: string }) => {
              const ids = values.userIDs.split(/[,，\s]+/).filter(Boolean);
              const resp = await addDefaultFriends(ids);
              if (resp.errCode === 0) {
                message.success('添加成功');
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg);
              return false;
            }}
          >
            <ProFormText
              name="userIDs"
              label="用户ID"
              rules={[{ required: true }]}
              placeholder="多个ID用逗号分隔"
            />
          </ModalForm>,
        ]}
        request={async (params) => {
          const resp = await searchDefaultFriends(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
          );
          return {
            data: resp.data?.users || [],
            total: resp.data?.total || 0,
            success: resp.errCode === 0,
          };
        }}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto' }}
      />
    </PageContainer>
  );
};

export default DefaultFriend;
