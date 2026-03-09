/**
 * 接待员管理页面（二开）
 * 管理接待员邀请码及其客户绑定关系
 */
import {
  deleteReceptionistBinding,
  deleteReceptionistInviteCode,
  listReceptionistBindings,
  searchReceptionistInviteCodes,
  updateReceptionistInviteCodeStatus,
} from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  PageContainer,
  ProTable,
} from '@ant-design/pro-components';
import { Button, Drawer, message, Popconfirm, Switch, Tag, Tooltip } from 'antd';
import dayjs from 'dayjs';
import React, { useRef, useState } from 'react';

const ReceptionistPage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [selectedReceptionistID, setSelectedReceptionistID] = useState('');
  const [bindings, setBindings] = useState<OPENIM.CustomerBinding[]>([]);
  const [bindingsTotal, setBindingsTotal] = useState(0);
  const bindingActionRef = useRef<ActionType>(null);

  const openBindings = async (userID: string) => {
    setSelectedReceptionistID(userID);
    const resp = await listReceptionistBindings(userID);
    if (resp.errCode === 0) {
      setBindings(resp.data?.list ?? []);
      setBindingsTotal(resp.data?.total ?? 0);
    }
    setDrawerOpen(true);
  };

  const columns: ProColumns<OPENIM.ReceptionistInviteCode>[] = [
    {
      title: '接待员 UserID',
      dataIndex: 'userId',
      width: 200,
      copyable: true,
    },
    {
      title: '邀请码',
      dataIndex: 'inviteCode',
      width: 120,
      copyable: true,
    },
    {
      title: '状态',
      dataIndex: 'status',
      width: 90,
      search: false,
      render: (_, r) => (
        <Tooltip title={r.status === 1 ? '点击禁用' : '点击启用'}>
          <Switch
            checked={r.status === 1}
            size="small"
            onChange={async (checked) => {
              const resp = await updateReceptionistInviteCodeStatus(r.id, checked ? 1 : 0);
              if (resp.errCode === 0) {
                message.success(checked ? '已启用' : '已禁用');
                actionRef.current?.reload();
              } else {
                message.error(resp.errMsg ?? '操作失败');
              }
            }}
          />
        </Tooltip>
      ),
    },
    {
      title: '创建时间',
      dataIndex: 'createdAt',
      width: 160,
      search: false,
      render: (_, r) => (r.createdAt ? dayjs(r.createdAt).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      valueType: 'option',
      width: 140,
      render: (_, record) => [
        <Button
          key="customers"
          type="link"
          size="small"
          onClick={() => openBindings(record.userId)}
        >
          查看客户
        </Button>,
        <Popconfirm
          key="delete"
          title="确定删除该邀请码？"
          onConfirm={async () => {
            const resp = await deleteReceptionistInviteCode(record.id);
            if (resp.errCode === 0) {
              message.success('已删除');
              actionRef.current?.reload();
            } else {
              message.error(resp.errMsg ?? '删除失败');
            }
          }}
        >
          <a className="ant-typography ant-typography-danger">删除</a>
        </Popconfirm>,
      ],
    },
  ];

  const bindingColumns: ProColumns<OPENIM.CustomerBinding>[] = [
    {
      title: '客户 UserID',
      dataIndex: 'customerId',
      copyable: true,
    },
    {
      title: '绑定时间',
      dataIndex: 'boundAt',
      render: (_, r) => (r.boundAt ? dayjs(r.boundAt).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定解除绑定？解除后客户可重新绑定其他接待员。"
          onConfirm={async () => {
            const resp = await deleteReceptionistBinding(record.customerId);
            if (resp.errCode === 0) {
              message.success('已解除绑定');
              setBindings((prev) => prev.filter((b) => b.customerId !== record.customerId));
              setBindingsTotal((t) => t - 1);
            } else {
              message.error(resp.errMsg ?? '操作失败');
            }
          }}
        >
          <a className="ant-typography ant-typography-danger">解绑</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.ReceptionistInviteCode>
        headerTitle="接待员邀请码"
        actionRef={actionRef}
        rowKey="id"
        search={{ labelWidth: 'auto' }}
        request={async (params) => {
          const resp = await searchReceptionistInviteCodes({
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

      <Drawer
        title={`接待员客户列表（${selectedReceptionistID}）— 共 ${bindingsTotal} 人`}
        open={drawerOpen}
        onClose={() => setDrawerOpen(false)}
        width={600}
        destroyOnClose
      >
        <ProTable<OPENIM.CustomerBinding>
          actionRef={bindingActionRef}
          rowKey="customerId"
          search={false}
          toolBarRender={false}
          dataSource={bindings}
          columns={bindingColumns}
          pagination={false}
        />
      </Drawer>
    </PageContainer>
  );
};

export default ReceptionistPage;
