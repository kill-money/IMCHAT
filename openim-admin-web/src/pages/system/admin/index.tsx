import { addAdmin, deleteAdmin, searchAdmins } from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormText, ProTable } from '@ant-design/pro-components';
import { Button, message, Popconfirm } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';

const AdminManage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.AdminAccount>[] = [
    { title: '账号', dataIndex: 'account', width: 180 },
    { title: '昵称', dataIndex: 'nickname', width: 150 },
    { title: '级别', dataIndex: 'level', width: 80, search: false },
    {
      title: '创建时间',
      dataIndex: 'createTime',
      width: 170,
      search: false,
      render: (_, r) => r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '操作',
      valueType: 'option',
      width: 100,
      render: (_, record) => (
        <Popconfirm
          title="确定删除该管理员？"
          onConfirm={async () => {
            const resp = await deleteAdmin([record.userID]);
            if (resp.errCode === 0) {
              message.success('已删除');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}
        >
          <a className="ant-typography ant-typography-danger">删除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.AdminAccount>
        headerTitle="管理员列表"
        actionRef={actionRef}
        rowKey="account"
        columns={columns}
        toolBarRender={() => [
          <ModalForm
            key="add"
            title="添加管理员"
            trigger={<Button type="primary" icon={<PlusOutlined />}>添加管理员</Button>}
            onFinish={async (values: { account: string; password: string; nickname?: string }) => {
              const resp = await addAdmin(values.account, values.password, values.nickname || '');
              if (resp.errCode === 0) {
                message.success('添加成功');
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg);
              return false;
            }}
          >
            <ProFormText name="account" label="账号" rules={[{ required: true }]} />
            <ProFormText.Password name="password" label="密码" rules={[{ required: true }]} />
            <ProFormText name="nickname" label="昵称" />
          </ModalForm>,
        ]}
        request={async (params) => {
          const resp = await searchAdmins(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
          );
          return {
            data: resp.data?.adminAccounts || [],
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

export default AdminManage;
