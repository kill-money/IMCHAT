/**
 * 白名单管理页面（二开）
 * 管理哪些手机号/邮箱允许登录系统
 */
import {
  addWhitelistUser,
  deleteWhitelistUsers,
  getClientConfig,
  searchWhitelist,
  setClientConfig,
  updateWhitelistUser,
} from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  ModalForm,
  PageContainer,
  ProFormSelect,
  ProFormText,
  ProTable,
} from '@ant-design/pro-components';
import { Button, message, Popconfirm, Switch, Tag, Tooltip } from 'antd';
import dayjs from 'dayjs';
import React, { useEffect, useRef, useState } from 'react';

const PERMISSION_LABELS: Record<string, string> = {
  view_ip: '查看IP',
  ban_user: '封禁用户',
  view_chat_log: '查看聊天记录',
  broadcast: '广播消息',
};

const ROLE_LABELS: Record<string, { label: string; color: string }> = {
  admin: { label: '管理员', color: 'red' },
  operator: { label: '操作员', color: 'orange' },
  user: { label: '普通用户', color: 'blue' },
};

/** 白名单登录功能开关 key（对应后端 constant.WhitelistLoginEnabledKey） */
const WHITELIST_ENABLED_KEY = 'whitelistLoginEnabled';

const WhitelistPage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);
  const [addOpen, setAddOpen] = useState(false);
  const [whitelistEnabled, setWhitelistEnabled] = useState(false);
  const [toggleLoading, setToggleLoading] = useState(false);

  // 加载白名单功能开关状态
  useEffect(() => {
    getClientConfig().then((resp) => {
      if (resp.errCode === 0 && resp.data) {
        setWhitelistEnabled(resp.data.config?.[WHITELIST_ENABLED_KEY] === '1');
      }
    });
  }, []);

  const handleToggle = async (checked: boolean) => {
    setToggleLoading(true);
    const resp = await setClientConfig({ [WHITELIST_ENABLED_KEY]: checked ? '1' : '0' });
    setToggleLoading(false);
    if (resp.errCode === 0) {
      setWhitelistEnabled(checked);
      message.success(checked ? '白名单登录已开启' : '白名单登录已关闭（所有账号可登录）');
    } else {
      message.error(resp.errMsg ?? '操作失败');
    }
  };

  const columns: ProColumns<OPENIM.WhitelistUser>[] = [
    {
      title: '标识符',
      dataIndex: 'identifier',
      width: 200,
      copyable: true,
    },
    {
      title: '类型',
      dataIndex: 'type',
      width: 80,
      search: false,
      render: (_, r) => (r.type === 1 ? <Tag color="blue">手机</Tag> : <Tag color="purple">邮箱</Tag>),
    },
    {
      title: '角色',
      dataIndex: 'role',
      width: 100,
      search: false,
      render: (_, r) => {
        const info = ROLE_LABELS[r.role] ?? { label: r.role, color: 'default' };
        return <Tag color={info.color}>{info.label}</Tag>;
      },
    },
    {
      title: '权限',
      dataIndex: 'permissions',
      width: 240,
      search: false,
      render: (_, r) =>
        (r.permissions ?? []).map((p) => (
          <Tag key={p} color="geekblue" style={{ marginBottom: 2 }}>
            {PERMISSION_LABELS[p] ?? p}
          </Tag>
        )),
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
              const resp = await updateWhitelistUser({ id: r.id, status: checked ? 1 : 0 });
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
      title: '备注',
      dataIndex: 'remark',
      width: 140,
      search: false,
      ellipsis: true,
    },
    {
      title: '添加时间',
      dataIndex: 'createTime',
      width: 160,
      search: false,
      render: (_, r) => (r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定从白名单中移除此条目？"
          onConfirm={async () => {
            const resp = await deleteWhitelistUsers([record.id]);
            if (resp.errCode === 0) {
              message.success('已删除');
              actionRef.current?.reload();
            } else {
              message.error(resp.errMsg ?? '删除失败');
            }
          }}
        >
          <a className="ant-typography ant-typography-danger">删除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      {/* 白名单功能全局开关 */}
      <div
        style={{
          display: 'flex',
          alignItems: 'center',
          gap: 12,
          marginBottom: 16,
          padding: '12px 16px',
          background: '#f5f5f5',
          borderRadius: 8,
          border: '1px solid #e0e0e0',
        }}
      >
        <span style={{ fontWeight: 600, fontSize: 14 }}>白名单登录验证：</span>
        <Switch
          checked={whitelistEnabled}
          loading={toggleLoading}
          onChange={handleToggle}
          checkedChildren="已开启"
          unCheckedChildren="已关闭"
        />
        <span style={{ color: '#888', fontSize: 12 }}>
          {whitelistEnabled
            ? '当前仅允许白名单内的账号登录'
            : '当前所有已注册账号均可登录（白名单不生效）'}
        </span>
      </div>

      <ProTable<OPENIM.WhitelistUser>
        headerTitle="登录白名单"
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
            添加白名单
          </Button>,
        ]}
        request={async (params) => {
          const resp = await searchWhitelist({
            keyword: params.identifier ?? params.keyword ?? '',
            status: -1,
            pageNum: params.current ?? 1,
            showNum: params.pageSize ?? 20,
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

      {/* 添加白名单 Modal */}
      <ModalForm
        title="添加白名单"
        open={addOpen}
        onOpenChange={setAddOpen}
        onFinish={async (values) => {
          const resp = await addWhitelistUser({
            identifier: values.identifier,
            type: parseInt(values.type),
            role: values.role ?? 'user',
            permissions: values.permissions ?? [],
            remark: values.remark ?? '',
          });
          if (resp.errCode === 0) {
            message.success('添加成功');
            actionRef.current?.reload();
            return true;
          }
          message.error(resp.errMsg ?? '添加失败');
          return false;
        }}
      >
        <ProFormSelect
          name="type"
          label="类型"
          rules={[{ required: true }]}
          options={[
            { value: '1', label: '手机号' },
            { value: '2', label: '邮箱' },
          ]}
        />
        <ProFormText
          name="identifier"
          label="标识符"
          placeholder="手机号如 +8613800138000，邮箱如 user@example.com"
          rules={[{ required: true }]}
        />
        <ProFormSelect
          name="role"
          label="角色"
          initialValue="user"
          options={[
            { value: 'admin', label: '管理员' },
            { value: 'operator', label: '操作员' },
            { value: 'user', label: '普通用户' },
          ]}
        />
        <ProFormSelect
          name="permissions"
          label="权限"
          mode="multiple"
          options={Object.entries(PERMISSION_LABELS).map(([value, label]) => ({ value, label }))}
        />
        <ProFormText name="remark" label="备注" />
      </ModalForm>
    </PageContainer>
  );
};

export default WhitelistPage;
