import { blockUser, searchBlockUsers, unblockUser } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormText, ProFormTextArea, ProTable } from '@ant-design/pro-components';
import { Button, message, Popconfirm } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';

const BlockManage: React.FC = () => {
  const actionRef = useRef<ActionType>();

  const columns: ProColumns<OPENIM.BlockUser>[] = [
    { title: '用户ID', dataIndex: 'userID', copyable: true, width: 180 },
    { title: '昵称', dataIndex: 'nickname', width: 120, search: false },
    { title: '封禁原因', dataIndex: 'reason', width: 200, search: false },
    { title: '操作人', dataIndex: 'opAdminAccount', width: 120, search: false },
    {
      title: '封禁时间',
      dataIndex: 'createTime',
      search: false,
      width: 170,
      render: (_, r) => r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定解封该用户？"
          onConfirm={async () => {
            const resp = await unblockUser([record.userID]);
            if (resp.errCode === 0) {
              message.success('解封成功');
              actionRef.current?.reload();
            } else {
              message.error(resp.errMsg);
            }
          }}
        >
          <a>解封</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.BlockUser>
        headerTitle="封禁用户列表"
        actionRef={actionRef}
        rowKey="userID"
        columns={columns}
        request={async (params) => {
          const resp = await searchBlockUsers(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
            params.userID,
          );
          return {
            data: resp.data?.blocks || [],
            total: resp.data?.total || 0,
            success: resp.errCode === 0,
          };
        }}
        toolBarRender={() => [
          <ModalForm<{ userID: string; reason: string }>
            key="block"
            title="封禁用户"
            trigger={<Button type="primary" danger>封禁用户</Button>}
            onFinish={async (values) => {
              const resp = await blockUser(values.userID, values.reason);
              if (resp.errCode === 0) {
                message.success('封禁成功');
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg);
              return false;
            }}
          >
            <ProFormText name="userID" label="用户ID" rules={[{ required: true }]} />
            <ProFormTextArea name="reason" label="封禁原因" rules={[{ required: true }]} />
          </ModalForm>,
        ]}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto' }}
      />
    </PageContainer>
  );
};

export default BlockManage;
