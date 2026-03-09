import { batchCreateUsers, forceLogout, getUserIPLogs, searchUsersWithIP } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormDigit, ProFormSelect, ProFormText, ProTable } from '@ant-design/pro-components';
import { Avatar, Button, Drawer, message, Popconfirm, Select, Space, Table } from 'antd';
import dayjs from 'dayjs';
import React, { useRef, useState } from 'react';

const UserList: React.FC = () => {
  const actionRef = useRef<ActionType>();
  const [detailOpen, setDetailOpen] = useState(false);
  const [detailUser, setDetailUser] = useState<OPENIM.UserInfo | null>(null);
  const [ipLogs, setIpLogs] = useState<OPENIM.UserIPLogEntry[]>([]);
  const [ipLogsTotal, setIpLogsTotal] = useState(0);
  const [ipLogsPage, setIpLogsPage] = useState(1);
  const [roleSaving, setRoleSaving] = useState(false);
  const [detailRole, setDetailRole] = useState(0);
  const [batchModalOpen, setBatchModalOpen] = useState(false);

  const columns: ProColumns<OPENIM.UserInfo>[] = [
    {
      title: '头像',
      dataIndex: 'faceURL',
      search: false,
      width: 60,
      render: (_, record) => <Avatar src={record.faceURL} size="small">{record.nickname?.[0]}</Avatar>,
    },
    { title: '用户ID', dataIndex: 'userID', copyable: true, width: 180 },
    { title: '昵称', dataIndex: 'nickname', width: 120 },
    { title: '手机号', dataIndex: 'phoneNumber', width: 130, search: false },
    { title: '邮箱', dataIndex: 'email', width: 160, search: false },
    {
      title: '最后登录 IP',
      dataIndex: 'lastIP',
      width: 120,
      search: true,
      render: (_, r) => r.lastIP ?? '-',
    },
    {
      title: '最后登录时间',
      dataIndex: 'lastIPTime',
      search: false,
      width: 160,
      render: (_, r) => (r.lastIPTime ? dayjs(r.lastIPTime).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '角色',
      dataIndex: 'appRole',
      search: false,
      width: 90,
      render: (_, r) => (r.appRole === 1 ? '用户端管理员' : '普通用户'),
    },
    {
      title: '性别',
      dataIndex: 'gender',
      search: false,
      width: 60,
      render: (_, r) => r.gender === 1 ? '男' : r.gender === 2 ? '女' : '-',
    },
    {
      title: '注册时间',
      dataIndex: 'createTime',
      search: false,
      width: 170,
      render: (_, r) => r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '操作',
      valueType: 'option',
      width: 180,
      render: (_, record) => (
        <Space>
          <a
            onClick={() => {
              setDetailUser(record);
              setDetailRole(record.appRole ?? 0);
              setDetailOpen(true);
              setIpLogs([]);
              setIpLogsTotal(0);
              setIpLogsPage(1);
              if (record.userID) {
                getUserIPLogs(record.userID, { pageNumber: 1, showNumber: 20 }).then((resp) => {
                  if (resp.errCode === 0 && resp.data) {
                    setIpLogs(resp.data.logs ?? []);
                    setIpLogsTotal(resp.data.total ?? 0);
                  }
                });
              }
            }}
          >
            详情
          </a>
          <Popconfirm
            title="确定强制该用户下线？"
            onConfirm={async () => {
              const resp = await forceLogout(record.userID);
              if (resp.errCode === 0) message.success('已强制下线');
              else message.error(resp.errMsg);
            }}
          >
            <a>强制下线</a>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.UserInfo>
        headerTitle="用户列表"
        actionRef={actionRef}
        rowKey="userID"
        columns={columns}
        toolBarRender={() => [
          <Button key="batch" type="primary" onClick={() => setBatchModalOpen(true)}>
            批量创建用户
          </Button>,
        ]}
        request={async (params) => {
          const resp = await searchUsersWithIP({
            keyword: params.userID || params.nickname || params.lastIP || undefined,
            pagination: {
              pageNumber: params.current || 1,
              showNumber: params.pageSize || 20,
            },
          });
          return {
            data: resp.data?.users ?? [],
            total: resp.data?.total ?? 0,
            success: resp.errCode === 0,
          };
        }}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto' }}
      />
      <Drawer
        title={detailUser ? `用户详情 - ${detailUser.nickname ?? detailUser.userID}` : '用户详情'}
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        width={560}
      >
        {detailUser && (
          <>
            <p><strong>用户ID：</strong>{detailUser.userID}</p>
            <p><strong>昵称：</strong>{detailUser.nickname ?? '-'}</p>
            <p><strong>最后登录 IP：</strong>{detailUser.lastIP ?? '-'}</p>
            <p><strong>最后登录时间：</strong>{detailUser.lastIPTime ? dayjs(detailUser.lastIPTime).format('YYYY-MM-DD HH:mm') : '-'}</p>
            <p style={{ marginTop: 16 }}><strong>用户角色：</strong></p>
            <Space>
              <Select
                value={detailRole}
                onChange={setDetailRole}
                style={{ width: 160 }}
                options={[
                  { label: '普通用户', value: 0 },
                  { label: '用户端管理员', value: 1 },
                ]}
              />
              <a
                onClick={async () => {
                  setRoleSaving(true);
                  try {
                    const { setAppRole } = await import('@/services/openim');
                    const resp = await setAppRole(detailUser.userID, detailRole);
                    if (resp.errCode === 0) {
                      message.success('已保存');
                      setDetailUser({ ...detailUser, appRole: detailRole });
                      actionRef.current?.reload?.();
                    } else {
                      message.error(resp.errMsg ?? '保存失败');
                    }
                  } finally {
                    setRoleSaving(false);
                  }
                }}
              >
                {roleSaving ? '保存中...' : '保存'}
              </a>
            </Space>
            <p style={{ marginTop: 24 }}><strong>IP 登录历史：</strong></p>
            <Table<OPENIM.UserIPLogEntry>
              size="small"
              rowKey={(_, i) => String(i)}
              dataSource={ipLogs}
              columns={[
                { title: 'IP', dataIndex: 'ip', width: 130 },
                { title: '登录时间', dataIndex: 'loginTime', width: 160, render: (t: number) => (t ? dayjs(t > 1e12 ? t : t * 1000).format('YYYY-MM-DD HH:mm') : '-') },
                { title: '设备', dataIndex: 'device', ellipsis: true },
                { title: '平台', dataIndex: 'platform', width: 80 },
              ]}
              pagination={{
                current: ipLogsPage,
                total: ipLogsTotal,
                pageSize: 20,
                showSizeChanger: false,
                onChange: (page) => {
                  setIpLogsPage(page);
                  if (detailUser?.userID) {
                    getUserIPLogs(detailUser.userID, { pageNumber: page, showNumber: 20 }).then((resp) => {
                      if (resp.errCode === 0 && resp.data) {
                        setIpLogs(resp.data.logs ?? []);
                        setIpLogsTotal(resp.data.total ?? 0);
                      }
                    });
                  }
                },
              }}
            />
          </>
        )}
      </Drawer>
      <ModalForm
        title="批量创建用户"
        open={batchModalOpen}
        onOpenChange={setBatchModalOpen}
        modalProps={{ destroyOnClose: true }}
        onFinish={async (values) => {
          const resp = await batchCreateUsers({
            start_username: values.start_username,
            count: values.count,
            password: values.password,
            role: values.role ?? 'user',
          });
          if (resp.errCode === 0 && resp.data) {
            message.success(`创建成功 ${resp.data.created} 个，跳过 ${resp.data.skipped} 个`);
            actionRef.current?.reload?.();
            return true;
          }
          message.error(resp.errMsg ?? '批量创建失败');
          return false;
        }}
      >
        <ProFormText
          name="start_username"
          label="起始用户名"
          placeholder="例如：bab001"
          rules={[
            { required: true, message: '请输入起始用户名' },
            { pattern: /^.*\d+$/, message: '用户名必须以数字结尾，例如 bab001' },
          ]}
          extra="自动解析前缀和数字位数，例如 bab001 → bab001, bab002, bab003..."
        />
        <ProFormDigit
          name="count"
          label="创建数量"
          min={1}
          max={999}
          initialValue={10}
          rules={[{ required: true }]}
        />
        <ProFormText.Password
          name="password"
          label="登录密码"
          rules={[
            { required: true, message: '请输入密码' },
            { min: 6, message: '密码至少 6 位' },
          ]}
        />
        <ProFormSelect
          name="role"
          label="用户角色"
          initialValue="user"
          options={[
            { label: '普通用户', value: 'user' },
            { label: '用户端管理员', value: 'admin' },
          ]}
        />
      </ModalForm>
    </PageContainer>
  );
};

export default UserList;
