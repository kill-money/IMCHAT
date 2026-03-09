/**
 * 用户端管理员管理页面（二开）
 * 管理推荐系统管理员及其推荐用户列表
 */
import {
  addUserAdmin,
  getReferralUsers,
  removeUserAdmin,
  searchUserAdmins,
} from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  ModalForm,
  PageContainer,
  ProFormText,
  ProTable,
} from '@ant-design/pro-components';
import { Button, Drawer, message, Popconfirm, Tag } from 'antd';
import dayjs from 'dayjs';
import React, { useRef, useState } from 'react';

const UserAdminPage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [selectedAdminID, setSelectedAdminID] = useState('');
  const [referrals, setReferrals] = useState<OPENIM.ReferralBinding[]>([]);
  const [referralTotal, setReferralTotal] = useState(0);

  const openReferrals = async (adminID: string) => {
    setSelectedAdminID(adminID);
    const resp = await getReferralUsers(adminID);
    if (resp.errCode === 0) {
      setReferrals(resp.data?.list ?? []);
      setReferralTotal(resp.data?.total ?? 0);
    }
    setDrawerOpen(true);
  };

  const columns: ProColumns<OPENIM.UserAdmin>[] = [
    {
      title: 'UserID',
      dataIndex: 'userId',
      width: 220,
      copyable: true,
    },
    {
      title: '状态',
      dataIndex: 'enabled',
      width: 80,
      search: false,
      render: (_, r) =>
        r.enabled ? <Tag color="green">启用</Tag> : <Tag color="red">停用</Tag>,
    },
    {
      title: '添加时间',
      dataIndex: 'createdAt',
      width: 160,
      search: false,
      render: (_, r) => (r.createdAt ? dayjs(r.createdAt).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      valueType: 'option',
      width: 160,
      render: (_, record) => [
        <Button
          key="referrals"
          type="link"
          size="small"
          onClick={() => openReferrals(record.userId)}
        >
          推荐用户
        </Button>,
        <Popconfirm
          key="remove"
          title="确定移除该用户的管理员权限？"
          onConfirm={async () => {
            const resp = await removeUserAdmin(record.userId);
            if (resp.errCode === 0) {
              message.success('已移除');
              actionRef.current?.reload();
            } else {
              message.error(resp.errMsg ?? '操作失败');
            }
          }}
        >
          <a className="ant-typography ant-typography-danger">移除</a>
        </Popconfirm>,
      ],
    },
  ];

  const referralColumns: ProColumns<OPENIM.ReferralBinding>[] = [
    { title: 'UserID', dataIndex: 'userId', copyable: true },
    { title: '昵称', dataIndex: 'nickname' },
    { title: '注册IP', dataIndex: 'registerIp', copyable: true },
    {
      title: '注册时间',
      dataIndex: 'registerTime',
      render: (_, r) =>
        r.registerTime ? dayjs(r.registerTime).format('YYYY-MM-DD HH:mm') : '-',
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.UserAdmin>
        headerTitle="用户端管理员"
        actionRef={actionRef}
        rowKey="id"
        search={{ labelWidth: 'auto' }}
        toolBarRender={() => [
          <Button
            key="add"
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => setAddOpen(true)}
          >
            添加管理员
          </Button>,
        ]}
        request={async (params) => {
          const resp = await searchUserAdmins({
            keyword: params.userId ?? params.keyword ?? '',
            pagination: {
              pageNumber: params.current ?? 1,
              showNumber: params.pageSize ?? 20,
            },
          });
          if (resp.errCode !== 0) return { data: [], success: false, total: 0 };
          return {
            data: resp.data?.list ?? [],
            success: true,
            total: resp.data?.total ?? 0,
          };
        }}
        columns={columns}
        pagination={{ pageSize: 20 }}
      />

      {/* 添加管理员 */}
      <ModalForm
        title="添加用户端管理员"
        open={addOpen}
        onOpenChange={setAddOpen}
        onFinish={async (values) => {
          const resp = await addUserAdmin(values.userID);
          if (resp.errCode === 0) {
            message.success('添加成功');
            actionRef.current?.reload();
            return true;
          }
          message.error(resp.errMsg ?? '添加失败');
          return false;
        }}
      >
        <ProFormText
          name="userID"
          label="UserID"
          placeholder="请输入要提升为管理员的用户 UserID"
          rules={[{ required: true }]}
        />
      </ModalForm>

      {/* 推荐用户列表 */}
      <Drawer
        title={`推荐用户列表（管理员: ${selectedAdminID}）— 共 ${referralTotal} 人`}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        width={640}
        destroyOnClose
      >
        <ProTable<OPENIM.ReferralBinding>
          rowKey="id"
          search={false}
          toolBarRender={false}
          dataSource={referrals}
          columns={referralColumns}
          pagination={false}
        />
      </Drawer>
    </PageContainer>
  );
};

export default UserAdminPage;
