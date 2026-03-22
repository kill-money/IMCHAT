import {
  getAdminPermissions,
  getMyPermissions,
  searchAdmins,
  setAdminPermissions,
} from '@/services/openim/api';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  ModalForm,
  PageContainer,
  ProFormSelect,
  ProTable,
} from '@ant-design/pro-components';
import { Button, Card, message, Space, Tag, Typography } from 'antd';
import dayjs from 'dayjs';
import React, { useEffect, useMemo, useRef, useState } from 'react';

const { Text } = Typography;

const PermissionsPage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);
  const [myPermissions, setMyPermissions] = useState<string[]>([]);
  const [wellKnownCodes, setWellKnownCodes] = useState<string[]>([]);
  const [editingAdmin, setEditingAdmin] = useState<OPENIM.AdminAccount | null>(null);
  const [editingPerms, setEditingPerms] = useState<string[]>([]);
  const [permModalOpen, setPermModalOpen] = useState(false);
  const [batchOpen, setBatchOpen] = useState(false);
  const [selectedAdmins, setSelectedAdmins] = useState<OPENIM.AdminAccount[]>([]);

  useEffect(() => {
    const fetchMyPerms = async () => {
      const resp = await getMyPermissions();
      if (resp.errCode === 0) {
        setMyPermissions(resp.data?.permissions ?? []);
        setWellKnownCodes((resp.data as any)?.wellKnownCodes ?? []);
      }
    };
    fetchMyPerms();
  }, []);

  const permissionOptions = useMemo(() => {
    const codes = [...new Set(["*", ...wellKnownCodes])];
    return codes.map((code) => ({ label: code, value: code }));
  }, [wellKnownCodes]);

  const openPermissionEditor = async (record: OPENIM.AdminAccount) => {
    setEditingAdmin(record);
    const resp = await getAdminPermissions(record.userID);
    if (resp.errCode === 0) {
      setEditingPerms(resp.data?.permissions ?? []);
      setPermModalOpen(true);
    } else {
      message.error(resp.errMsg || '加载权限失败');
    }
  };

  const columns: ProColumns<OPENIM.AdminAccount>[] = [
    { title: '账号', dataIndex: 'account', width: 180 },
    { title: '昵称', dataIndex: 'nickname', width: 160 },
    { title: '级别', dataIndex: 'level', width: 80, search: false },
    {
      title: '创建时间',
      dataIndex: 'createTime',
      width: 170,
      search: false,
      render: (_, r) => (r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      valueType: 'option',
      width: 140,
      render: (_, record) => (
        <Space>
          <a onClick={() => openPermissionEditor(record)}>设置权限</a>
        </Space>
      ),
    },
  ];

  return (
    <PageContainer>
      <Card style={{ marginBottom: 16 }}>
        <Space size={8} wrap>
          <Text strong>当前账号权限：</Text>
          {(myPermissions.length ? myPermissions : ['(empty)']).map((p) => (
            <Tag key={p} color={p === '*' ? 'gold' : 'geekblue'}>
              {p}
            </Tag>
          ))}
        </Space>
      </Card>

      <ProTable<OPENIM.AdminAccount>
        headerTitle="管理员权限管理"
        actionRef={actionRef}
        rowKey="userID"
        columns={columns}
        request={async (params) => {
          const resp = await searchAdmins({
            pageNumber: params.current || 1,
            showNumber: params.pageSize || 20,
          });
          return {
            data: resp.data?.adminAccounts || [],
            total: resp.data?.total || 0,
            success: resp.errCode === 0,
          };
        }}
        rowSelection={{
          onChange: (_, rows) => setSelectedAdmins(rows),
        }}
        toolBarRender={() => [
          <Button
            key="batch"
            disabled={selectedAdmins.length === 0}
            onClick={() => setBatchOpen(true)}
          >
            批量设置权限
          </Button>,
        ]}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto' }}
      />

      <ModalForm
        title={`设置权限：${editingAdmin?.account ?? ''}`}
        open={permModalOpen}
        onOpenChange={(open) => setPermModalOpen(open)}
        onFinish={async (values: { permissions?: string[] }) => {
          if (!editingAdmin) return false;
          const perms = values.permissions ?? [];
          const resp = await setAdminPermissions(editingAdmin.userID, perms);
          if (resp.errCode === 0) {
            message.success('权限已更新');
            setPermModalOpen(false);
            actionRef.current?.reload();
            return true;
          }
          message.error(resp.errMsg || '更新失败');
          return false;
        }}
        initialValues={{ permissions: editingPerms }}
      >
        <ProFormSelect
          name="permissions"
          label="权限码"
          mode="multiple"
          options={permissionOptions}
          placeholder="选择权限码（可包含 * 全权限）"
        />
      </ModalForm>

      <ModalForm
        title={`批量设置权限（${selectedAdmins.length} 人）`}
        open={batchOpen}
        onOpenChange={(open) => setBatchOpen(open)}
        onFinish={async (values: { permissions?: string[] }) => {
          const perms = values.permissions ?? [];
          const results = await Promise.all(
            selectedAdmins.map((admin) => setAdminPermissions(admin.userID, perms))
          );
          const failed = results.find((r) => r.errCode !== 0);
          if (!failed) {
            message.success('批量更新成功');
            setBatchOpen(false);
            actionRef.current?.reload();
            return true;
          }
          message.error(failed.errMsg || '批量更新失败');
          return false;
        }}
      >
        <ProFormSelect
          name="permissions"
          label="权限码"
          mode="multiple"
          options={permissionOptions}
          placeholder="选择权限码（可包含 * 全权限）"
          rules={[{ required: true, message: '请选择至少一个权限码' }]}
        />
      </ModalForm>
    </PageContainer>
  );
};

export default PermissionsPage;
