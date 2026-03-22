import {
  addSingleUser,
  batchCreateUsers,
  blockUser,
  deleteUsers,
  forceLogout,
  getUserBlockStatus,
  getUserIPLogs,
  getUserJoinedGroups,
  resetUserPassword,
  searchUsersWithIP,
  setAppRole,
  setOfficialStatus,
  unblockUser,
  updateUserBasicInfo,
} from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  ModalForm,
  PageContainer,
  ProFormDigit,
  ProFormSelect,
  ProFormText,
  ProTable,
} from '@ant-design/pro-components';
import {
  Avatar,
  Badge,
  Button,
  Descriptions,
  Divider,
  Drawer,
  Form,
  Input,
  message,
  Modal,
  Popconfirm,
  Select,
  Space,
  Switch,
  Table,
  Tabs,
  Tag,
  Tooltip,
  Typography,
} from 'antd';
import dayjs from 'dayjs';
import React, { useCallback, useRef, useState } from 'react';

const { Text } = Typography;

// ─── 本地用户标签存储（localStorage）────────────────────────────────────────────
const TAGS_KEY = 'admin_user_tags';

function loadTags(): Record<string, string[]> {
  try {
    return JSON.parse(localStorage.getItem(TAGS_KEY) ?? '{}');
  } catch {
    return {};
  }
}

function saveTags(all: Record<string, string[]>) {
  localStorage.setItem(TAGS_KEY, JSON.stringify(all));
}

function useUserTags() {
  const [allTags, setAllTags] = useState<Record<string, string[]>>(loadTags);

  const getTagsForUser = useCallback((userID: string) => allTags[userID] ?? [], [allTags]);

  const setTagsForUser = useCallback((userID: string, tags: string[]) => {
    setAllTags((prev) => {
      const next = { ...prev, [userID]: tags };
      saveTags(next);
      return next;
    });
  }, []);

  const allUsedTags = Array.from(new Set(Object.values(allTags).flat())).sort();
  return { getTagsForUser, setTagsForUser, allUsedTags };
}

// ─── 操作日志条目 ────────────────────────────────────────────────────────────
interface OpLogEntry {
  time: number;
  action: string;
  extra?: string;
}

const UserList: React.FC = () => {
  const actionRef = useRef<ActionType>(undefined);

  // ─── 行选中（批量操作）────────────────────────────────────────────────────
  const [selectedRowKeys, setSelectedRowKeys] = useState<string[]>([]);
  const [selectedRows, setSelectedRows] = useState<OPENIM.UserInfo[]>([]);

  // ─── 封禁状态（本次会话跟踪）─────────────────────────────────────────────
  const [blockedSet, setBlockedSet] = useState<Set<string>>(new Set());

  // ─── 操作日志（会话内，按 userID 分组）────────────────────────────────────
  const [opLog, setOpLog] = useState<Record<string, OpLogEntry[]>>({});

  // ─── 新建用户弹窗 ─────────────────────────────────────────────────────────
  const [createOpen, setCreateOpen] = useState(false);

  // ─── 编辑用户弹窗 ─────────────────────────────────────────────────────────
  const [editOpen, setEditOpen] = useState(false);
  const [editUser, setEditUser] = useState<OPENIM.UserInfo | null>(null);
  const [editForm] = Form.useForm();

  // ─── 详情抽屉 ─────────────────────────────────────────────────────────────
  const [detailOpen, setDetailOpen] = useState(false);
  const [detailUser, setDetailUser] = useState<OPENIM.UserInfo | null>(null);
  const [detailTab, setDetailTab] = useState('info');
  const [detailRole, setDetailRole] = useState(0);
  const [roleSaving, setRoleSaving] = useState(false);
  const [detailIsOfficial, setDetailIsOfficial] = useState(0);
  const [officialSaving, setOfficialSaving] = useState(false);
  const [ipLogs, setIpLogs] = useState<OPENIM.UserIPLogEntry[]>([]);
  const [ipLogsTotal, setIpLogsTotal] = useState(0);
  const [ipLogsPage, setIpLogsPage] = useState(1);
  const [joinedGroups, setJoinedGroups] = useState<OPENIM.GroupInfo[]>([]);
  const [joinedGroupsTotal, setJoinedGroupsTotal] = useState(0);
  const [newTag, setNewTag] = useState('');

  // ─── 批量创建弹窗 ─────────────────────────────────────────────────────────
  const [batchModalOpen, setBatchModalOpen] = useState(false);

  // ─── 标签过滤 ─────────────────────────────────────────────────────────────
  const [tagFilter, setTagFilter] = useState<string>('');
  const { getTagsForUser, setTagsForUser, allUsedTags } = useUserTags();

  // ─── Helpers ──────────────────────────────────────────────────────────────
  const addOpLog = useCallback((userID: string, action: string, extra?: string) => {
    setOpLog((prev) => {
      const entry: OpLogEntry = { time: Date.now(), action, extra };
      return { ...prev, [userID]: [entry, ...(prev[userID] ?? [])].slice(0, 50) };
    });
  }, []);

  const markBlocked = useCallback((userID: string, blocked: boolean) => {
    setBlockedSet((prev) => {
      const next = new Set(prev);
      if (blocked) next.add(userID);
      else next.delete(userID);
      return next;
    });
  }, []);

  const openDetail = useCallback(
    async (record: OPENIM.UserInfo) => {
      setDetailUser(record);
      setDetailRole(record.appRole ?? 0);
      setDetailIsOfficial(record.isOfficial ?? 0);
      setDetailTab('info');
      setIpLogs([]);
      setIpLogsTotal(0);
      setIpLogsPage(1);
      setJoinedGroups([]);
      setJoinedGroupsTotal(0);
      setDetailOpen(true);
      if (record.userID) {
        getUserIPLogs(record.userID, { pageNumber: 1, showNumber: 20 }).then((resp) => {
          if (resp.errCode === 0 && resp.data) {
            setIpLogs(resp.data.logs ?? []);
            setIpLogsTotal(resp.data.total ?? 0);
          }
        });
      }
    },
    [],
  );

  const loadJoinedGroups = useCallback(async (userID: string, page = 1) => {
    try {
      const resp = await getUserJoinedGroups(userID, { pageNumber: page, showNumber: 20 });
      if (resp.errCode === 0 && resp.data) {
        setJoinedGroups(resp.data.groups ?? []);
        setJoinedGroupsTotal(resp.data.total ?? 0);
      }
    } catch {}
  }, []);

  // ─── 封禁操作 ─────────────────────────────────────────────────────────────
  const handleBlock = useCallback(
    async (record: OPENIM.UserInfo, reason: string) => {
      const resp = await blockUser(record.userID, reason);
      if (resp.errCode === 0) {
        message.success(`已封禁 ${record.nickname ?? record.userID}`);
        markBlocked(record.userID, true);
        addOpLog(record.userID, '封禁账号', `原因：${reason}`);
        actionRef.current?.reload?.();
      } else {
        message.error(resp.errMsg ?? '封禁失败');
      }
    },
    [markBlocked, addOpLog],
  );

  const handleUnblock = useCallback(
    async (record: OPENIM.UserInfo) => {
      const resp = await unblockUser([record.userID]);
      if (resp.errCode === 0) {
        message.success(`已解封 ${record.nickname ?? record.userID}`);
        markBlocked(record.userID, false);
        addOpLog(record.userID, '解封账号');
        actionRef.current?.reload?.();
      } else {
        message.error(resp.errMsg ?? '解封失败');
      }
    },
    [markBlocked, addOpLog],
  );

  const handleForceLogout = useCallback(
    async (record: OPENIM.UserInfo) => {
      const resp = await forceLogout(record.userID);
      if (resp.errCode === 0) {
        message.success(`已强制 ${record.nickname ?? record.userID} 下线`);
        addOpLog(record.userID, '强制下线');
      } else {
        message.error(resp.errMsg ?? '操作失败');
      }
    },
    [addOpLog],
  );

  const handleDelete = useCallback(
    async (userIDs: string[], nameLabel: string) => {
      // 二次密码验证：弹出密码输入框，获取管理员密码后再调用 API
      let pwd = '';
      try {
        await new Promise<void>((resolve, reject) => {
          Modal.confirm({
            title: '安全验证',
            content: (
              <Input.Password
                placeholder="请输入管理员密码以确认删除"
                onChange={(e) => { pwd = e.target.value; }}
              />
            ),
            okText: '确认删除',
            cancelText: '取消',
            onOk: () => {
              if (!pwd.trim()) {
                message.warning('请输入管理员密码');
                return Promise.reject();
              }
              resolve();
              return Promise.resolve();
            },
            onCancel: () => reject(new Error('cancelled')),
          });
        });
      } catch {
        return; // 用户取消
      }
      const resp = await deleteUsers(userIDs, pwd);
      if (resp.errCode === 0) {
        message.success(`已删除 ${nameLabel}`);
        userIDs.forEach((id) => addOpLog(id, '删除账号'));
        setSelectedRowKeys([]);
        setSelectedRows([]);
        actionRef.current?.reload?.();
      } else {
        message.error(resp.errMsg ?? '删除失败');
      }
    },
    [addOpLog],
  );

  // ─── 批量操作 ─────────────────────────────────────────────────────────────
  const handleBatchBlock = useCallback(() => {
    let reason = '';
    Modal.confirm({
      title: `批量封禁 ${selectedRows.length} 个用户`,
      content: (
        <Input
          placeholder="封禁原因（必填）"
          onChange={(e) => {
            reason = e.target.value;
          }}
        />
      ),
      onOk: async () => {
        if (!reason.trim()) {
          message.warning('请填写封禁原因');
          return Promise.reject();
        }
        let failed = 0;
        for (const row of selectedRows) {
          const resp = await blockUser(row.userID, reason);
          if (resp.errCode === 0) {
            markBlocked(row.userID, true);
            addOpLog(row.userID, '批量封禁', `原因：${reason}`);
          } else {
            failed++;
          }
        }
        message.success(`批量封禁完成，失败 ${failed} 个`);
        setSelectedRowKeys([]);
        setSelectedRows([]);
        actionRef.current?.reload?.();
      },
    });
  }, [selectedRows, markBlocked, addOpLog]);

  const handleBatchForceLogout = useCallback(async () => {
    let failed = 0;
    for (const row of selectedRows) {
      const resp = await forceLogout(row.userID);
      if (resp.errCode === 0) addOpLog(row.userID, '批量强制下线');
      else failed++;
    }
    message.success(`批量强制下线完成，失败 ${failed} 个`);
    setSelectedRowKeys([]);
    setSelectedRows([]);
  }, [selectedRows, addOpLog]);

  const handleBatchDelete = useCallback(() => {
    const names = selectedRows.map((r) => r.nickname ?? r.userID).join('、');
    Modal.confirm({
      title: '确认删除',
      content: `即将物理删除 ${selectedRows.length} 个用户账号（${names}），操作不可恢复，确认？`,
      okButtonProps: { danger: true },
      onOk: () => handleDelete(selectedRows.map((r) => r.userID), names),
    });
  }, [selectedRows, handleDelete]);

  // ─── 导出 CSV ──────────────────────────────────────────────────────────────
  const handleExportCSV = useCallback(async () => {
    message.loading({ content: '正在导出...', key: 'csv' });
    try {
      const resp = await searchUsersWithIP({
        pagination: { pageNumber: 1, showNumber: 2000 },
      });
      const users = resp.data?.users ?? [];
      const headers = ['userID', '昵称', '手机号', '邮箱', '性别', '注册时间', '最后登录IP', '最后登录时间', '角色', '官方'];
      const rows = users.map((u) =>
        [
          u.userID,
          u.nickname ?? '',
          u.phoneNumber ?? '',
          u.email ?? '',
          u.gender === 1 ? '男' : u.gender === 2 ? '女' : '未知',
          u.createTime ? dayjs(u.createTime).format('YYYY-MM-DD HH:mm') : '',
          u.lastIP ?? '',
          u.lastIPTime ? dayjs(u.lastIPTime).format('YYYY-MM-DD HH:mm') : '',
          u.appRole === 1 ? '用户端管理员' : '普通用户',
          u.isOfficial === 1 ? '官方金V' : '否',
        ]
          .map((v) => `"${String(v).replace(/"/g, '""')}"`)
          .join(','),
      );
      const csv = '\uFEFF' + [headers.join(','), ...rows].join('\n');
      const blob = new Blob([csv], { type: 'text/csv;charset=utf-8;' });
      const url = URL.createObjectURL(blob);
      const a = document.createElement('a');
      a.href = url;
      a.download = `用户列表_${dayjs().format('YYYYMMDD_HHmm')}.csv`;
      a.click();
      URL.revokeObjectURL(url);
      message.success({ content: `已导出 ${users.length} 条记录`, key: 'csv' });
    } catch {
      message.error({ content: '导出失败', key: 'csv' });
    }
  }, []);

  // ─── 表格列定义 ───────────────────────────────────────────────────────────
  const columns: ProColumns<OPENIM.UserInfo>[] = [
    {
      title: '头像',
      dataIndex: 'faceURL',
      search: false,
      width: 56,
      render: (_, record) => (
        <Avatar src={record.faceURL} size={36}>
          {record.nickname?.[0]}
        </Avatar>
      ),
    },
    // 关键词搜索（虚拟列，只在搜索表单中显示）
    {
      title: '关键词',
      dataIndex: 'keyword',
      hideInTable: true,
      fieldProps: { placeholder: '搜索用户ID / 昵称 / 手机号 / IP', allowClear: true },
    },
    { title: '用户ID', dataIndex: 'userID', copyable: true, width: 180, search: false },
    { title: '昵称', dataIndex: 'nickname', width: 120, search: false },
    { title: '手机号', dataIndex: 'phoneNumber', width: 130, search: false },
    {
      title: '最后登录IP',
      dataIndex: 'lastIP',
      width: 120,
      search: false,
      render: (_, r) => r.lastIP ?? '-',
    },
    {
      title: '最后登录时间',
      dataIndex: 'lastIPTime',
      search: false,
      width: 155,
      render: (_, r) =>
        r.lastIPTime ? dayjs(r.lastIPTime).format('MM-DD HH:mm') : '-',
    },
    {
      title: '性别',
      dataIndex: 'gender',
      valueType: 'select',
      width: 70,
      valueEnum: {
        0: { text: '未设置' },
        1: { text: '男' },
        2: { text: '女' },
      },
      render: (_, r) => (r.gender === 1 ? '男' : r.gender === 2 ? '女' : '-'),
    },
    {
      title: '角色',
      dataIndex: 'appRole',
      valueType: 'select',
      width: 120,
      valueEnum: {
        0: { text: '普通用户' },
        1: { text: '用户端管理员', status: 'Processing' },
      },
      render: (_, r) =>
        r.appRole === 1 ? (
          <Tag color="blue">管理员</Tag>
        ) : (
          <Tag>普通</Tag>
        ),
    },
    {
      title: '官方',
      dataIndex: 'isOfficial',
      search: false,
      width: 60,
      render: (_, r) => (r.isOfficial === 1 ? <Tag color="gold">金V</Tag> : '-'),
    },
    {
      title: '注册时间',
      dataIndex: 'createTime',
      search: false,
      width: 155,
      render: (_, r) =>
        r.createTime ? dayjs(r.createTime).format('MM-DD HH:mm') : '-',
    },
    {
      title: '状态',
      dataIndex: '_status',
      search: false,
      width: 80,
      render: (_, r) =>
        blockedSet.has(r.userID) ? (
          <Badge status="error" text="已封禁" />
        ) : (
          <Badge status="success" text="正常" />
        ),
    },
    {
      title: '标签',
      dataIndex: '_tags',
      search: false,
      width: 160,
      render: (_, record) => {
        const tags = getTagsForUser(record.userID);
        if (!tags.length)
          return (
            <Text type="secondary" style={{ fontSize: 12 }}>
              —
            </Text>
          );
        return (
          <Space size={4} wrap>
            {tags.slice(0, 2).map((t) => (
              <Tag key={t} color="blue" style={{ margin: 0, fontSize: 11 }}>
                {t}
              </Tag>
            ))}
            {tags.length > 2 && (
              <Tooltip title={tags.slice(2).join(', ')}>
                <Tag style={{ margin: 0, fontSize: 11 }}>+{tags.length - 2}</Tag>
              </Tooltip>
            )}
          </Space>
        );
      },
    },
    {
      title: '操作',
      valueType: 'option',
      width: 240,
      render: (_, record) => [
        <a key="detail" onClick={() => openDetail(record)}>
          详情
        </a>,
        <a
          key="edit"
          onClick={() => {
            setEditUser(record);
            editForm.setFieldsValue({
              nickname: record.nickname,
              gender: record.gender ?? 0,
              ex: record.ex ?? '',
            });
            setEditOpen(true);
          }}
        >
          编辑
        </a>,
        blockedSet.has(record.userID) ? (
          <Popconfirm
            key="unblock"
            title="确认解封此用户？"
            onConfirm={() => handleUnblock(record)}
          >
            <a style={{ color: '#52c41a' }}>解封</a>
          </Popconfirm>
        ) : (
          <a
            key="block"
            style={{ color: '#ff7875' }}
            onClick={() => {
              let reason = '';
              Modal.confirm({
                title: `封禁 ${record.nickname ?? record.userID}`,
                content: (
                  <Input
                    placeholder="封禁原因（必填）"
                    onChange={(e) => {
                      reason = e.target.value;
                    }}
                  />
                ),
                okButtonProps: { danger: true },
                onOk: async () => {
                  if (!reason.trim()) {
                    message.warning('请填写原因');
                    return Promise.reject();
                  }
                  await handleBlock(record, reason);
                },
              });
            }}
          >
            封禁
          </a>
        ),
        <Popconfirm
          key="logout"
          title="确认强制此用户下线？"
          onConfirm={() => handleForceLogout(record)}
        >
          <a>下线</a>
        </Popconfirm>,
        <Popconfirm
          key="delete"
          title={
            <>
              确认删除用户 <Text code>{record.userID}</Text>？
              <br />
              此操作不可恢复。
            </>
          }
          okButtonProps={{ danger: true }}
          onConfirm={() =>
            handleDelete([record.userID], record.nickname ?? record.userID)
          }
        >
          <a style={{ color: '#ff4d4f' }}>删除</a>
        </Popconfirm>,
      ],
    },
  ];

  // ─── 详情抽屉 Tabs ─────────────────────────────────────────────────────────
  const detailTabItems = detailUser
    ? [
        {
          key: 'info',
          label: '基本信息',
          children: (
            <div style={{ paddingTop: 8 }}>
              <Descriptions column={1} size="small" bordered>
                <Descriptions.Item label="用户ID">
                  <Text copyable>{detailUser.userID}</Text>
                </Descriptions.Item>
                <Descriptions.Item label="昵称">
                  {detailUser.nickname ?? '-'}
                </Descriptions.Item>
                <Descriptions.Item label="手机号">
                  {detailUser.phoneNumber ?? '-'}
                </Descriptions.Item>
                <Descriptions.Item label="邮箱">
                  {detailUser.email ?? '-'}
                </Descriptions.Item>
                <Descriptions.Item label="性别">
                  {detailUser.gender === 1
                    ? '男'
                    : detailUser.gender === 2
                    ? '女'
                    : '未设置'}
                </Descriptions.Item>
                <Descriptions.Item label="注册时间">
                  {detailUser.createTime
                    ? dayjs(detailUser.createTime).format('YYYY-MM-DD HH:mm')
                    : '-'}
                </Descriptions.Item>
                <Descriptions.Item label="最后登录IP">
                  {detailUser.lastIP ?? '-'}
                </Descriptions.Item>
                <Descriptions.Item label="最后登录时间">
                  {detailUser.lastIPTime
                    ? dayjs(detailUser.lastIPTime).format('YYYY-MM-DD HH:mm')
                    : '-'}
                </Descriptions.Item>
                {detailUser.ex && (
                  <Descriptions.Item label="签名/扩展">
                    <Text ellipsis style={{ maxWidth: 240 }}>
                      {detailUser.ex}
                    </Text>
                  </Descriptions.Item>
                )}
              </Descriptions>

              <Divider plain style={{ margin: '16px 0 8px', textAlign: 'left' }}>
                官方账号
              </Divider>
              <Space style={{ marginBottom: 12 }}>
                <Switch
                  checkedChildren="金V官方"
                  unCheckedChildren="普通"
                  checked={detailIsOfficial === 1}
                  loading={officialSaving}
                  onChange={async (checked) => {
                    const val = checked ? 1 : 0;
                    setOfficialSaving(true);
                    try {
                      const resp = await setOfficialStatus(
                        detailUser.userID,
                        val,
                      );
                      if (resp.errCode === 0) {
                        message.success(
                          checked ? '已设为官方账号' : '已取消官方标识',
                        );
                        setDetailIsOfficial(val);
                        setDetailUser({ ...detailUser, isOfficial: val });
                        addOpLog(
                          detailUser.userID,
                          checked ? '设为官方账号' : '取消官方账号',
                        );
                        actionRef.current?.reload?.();
                      } else {
                        message.error(resp.errMsg ?? '操作失败');
                      }
                    } finally {
                      setOfficialSaving(false);
                    }
                  }}
                />
              </Space>

              <Divider plain style={{ margin: '12px 0 8px', textAlign: 'left' }}>
                重置密码
              </Divider>
              <Button
                size="small"
                onClick={() => {
                  let newPwd = '';
                  Modal.confirm({
                    title: `重置 ${detailUser.nickname ?? detailUser.userID} 的密码`,
                    content: (
                      <Input.Password
                        placeholder="输入新密码（至少 6 位）"
                        onChange={(e) => {
                          newPwd = e.target.value;
                        }}
                      />
                    ),
                    onOk: async () => {
                      if (!newPwd || newPwd.length < 6) {
                        message.error('密码至少 6 位');
                        return Promise.reject();
                      }
                      const resp = await resetUserPassword(
                        detailUser.userID,
                        newPwd,
                      );
                      if (resp.errCode === 0) {
                        message.success('密码已重置');
                        addOpLog(detailUser.userID, '重置密码');
                      } else {
                        message.error(resp.errMsg ?? '重置失败');
                        return Promise.reject();
                      }
                    },
                  });
                }}
              >
                重置密码
              </Button>

              <Divider plain style={{ margin: '12px 0 8px', textAlign: 'left' }}>
                用户角色
              </Divider>
              <Space>
                <Select
                  value={detailRole}
                  onChange={setDetailRole}
                  style={{ width: 170 }}
                  options={[
                    { label: '普通用户', value: 0 },
                    { label: '用户端管理员', value: 1 },
                  ]}
                />
                <Button
                  size="small"
                  type="primary"
                  loading={roleSaving}
                  onClick={async () => {
                    // 二次密码验证：提权操作需确认管理员密码
                    let pwd = '';
                    try {
                      await new Promise<void>((resolve, reject) => {
                        Modal.confirm({
                          title: '安全验证',
                          content: (
                            <Input.Password
                              placeholder="请输入管理员密码以确认角色修改"
                              onChange={(e) => { pwd = e.target.value; }}
                            />
                          ),
                          okText: '确认修改',
                          cancelText: '取消',
                          onOk: () => {
                            if (!pwd.trim()) {
                              message.warning('请输入管理员密码');
                              return Promise.reject();
                            }
                            resolve();
                            return Promise.resolve();
                          },
                          onCancel: () => reject(new Error('cancelled')),
                        });
                      });
                    } catch {
                      return; // 用户取消
                    }
                    setRoleSaving(true);
                    try {
                      const resp = await setAppRole(
                        detailUser.userID,
                        detailRole,
                        pwd,
                      );
                      if (resp.errCode === 0) {
                        message.success('已保存');
                        setDetailUser({ ...detailUser, appRole: detailRole });
                        addOpLog(
                          detailUser.userID,
                          `角色改为 ${detailRole === 1 ? '用户端管理员' : '普通用户'}`,
                        );
                        actionRef.current?.reload?.();
                      } else {
                        message.error(resp.errMsg ?? '保存失败');
                      }
                    } finally {
                      setRoleSaving(false);
                    }
                  }}
                >
                  保存角色
                </Button>
              </Space>

              <Divider plain style={{ margin: '12px 0 8px', textAlign: 'left' }}>
                用户标签
              </Divider>
              <Space size={6} wrap style={{ marginBottom: 8 }}>
                {getTagsForUser(detailUser.userID).map((t) => (
                  <Tag
                    key={t}
                    color="blue"
                    closable
                    onClose={() => {
                      setTagsForUser(
                        detailUser.userID,
                        getTagsForUser(detailUser.userID).filter(
                          (x) => x !== t,
                        ),
                      );
                      actionRef.current?.reload?.();
                    }}
                  >
                    {t}
                  </Tag>
                ))}
                {getTagsForUser(detailUser.userID).length === 0 && (
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    暂无标签
                  </Text>
                )}
              </Space>
              <Space>
                <Select
                  style={{ width: 140 }}
                  placeholder="选择或输入标签"
                  showSearch
                  allowClear
                  value={newTag || undefined}
                  onSearch={setNewTag}
                  onChange={(v) => setNewTag(v ?? '')}
                  options={allUsedTags
                    .filter(
                      (t) => !getTagsForUser(detailUser.userID).includes(t),
                    )
                    .map((t) => ({ label: t, value: t }))}
                  onInputKeyDown={(e) => {
                    if (e.key === 'Enter' && newTag.trim()) {
                      const t = newTag.trim();
                      if (!getTagsForUser(detailUser.userID).includes(t)) {
                        setTagsForUser(detailUser.userID, [
                          ...getTagsForUser(detailUser.userID),
                          t,
                        ]);
                      }
                      setNewTag('');
                    }
                  }}
                />
                <Button
                  size="small"
                  type="primary"
                  onClick={() => {
                    const t = newTag.trim();
                    if (!t) return;
                    if (!getTagsForUser(detailUser.userID).includes(t)) {
                      setTagsForUser(detailUser.userID, [
                        ...getTagsForUser(detailUser.userID),
                        t,
                      ]);
                    }
                    setNewTag('');
                  }}
                >
                  添加
                </Button>
              </Space>

              <Divider plain style={{ margin: '12px 0 8px', textAlign: 'left' }}>
                快捷操作
              </Divider>
              <Space wrap>
                {blockedSet.has(detailUser.userID) ? (
                  <Popconfirm
                    title="确认解封？"
                    onConfirm={() => handleUnblock(detailUser)}
                  >
                    <Button size="small" type="primary">
                      解封账号
                    </Button>
                  </Popconfirm>
                ) : (
                  <Button
                    size="small"
                    danger
                    onClick={() => {
                      let reason = '';
                      Modal.confirm({
                        title: '封禁此用户',
                        content: (
                          <Input
                            placeholder="封禁原因（必填）"
                            onChange={(e) => {
                              reason = e.target.value;
                            }}
                          />
                        ),
                        okButtonProps: { danger: true },
                        onOk: async () => {
                          if (!reason.trim()) {
                            message.warning('请填写原因');
                            return Promise.reject();
                          }
                          await handleBlock(detailUser, reason);
                        },
                      });
                    }}
                  >
                    封禁账号
                  </Button>
                )}
                <Popconfirm
                  title="确认强制下线？"
                  onConfirm={() => handleForceLogout(detailUser)}
                >
                  <Button size="small">强制下线</Button>
                </Popconfirm>
                <Popconfirm
                  title={
                    <>
                      确认删除用户 <Text code>{detailUser.userID}</Text>？
                      <br />
                      不可恢复。
                    </>
                  }
                  okButtonProps={{ danger: true }}
                  onConfirm={async () => {
                    await handleDelete(
                      [detailUser.userID],
                      detailUser.nickname ?? detailUser.userID,
                    );
                    setDetailOpen(false);
                  }}
                >
                  <Button size="small" danger>
                    删除账号
                  </Button>
                </Popconfirm>
              </Space>
            </div>
          ),
        },
        {
          key: 'logs',
          label: '登录记录',
          children: (
            <Table<OPENIM.UserIPLogEntry>
              size="small"
              rowKey={(_, i) => String(i)}
              dataSource={ipLogs}
              style={{ marginTop: 8 }}
              columns={[
                { title: 'IP', dataIndex: 'ip', width: 130 },
                {
                  title: '登录时间',
                  dataIndex: 'loginTime',
                  width: 160,
                  render: (t: number) =>
                    t
                      ? dayjs(t > 1e12 ? t : t * 1000).format(
                          'YYYY-MM-DD HH:mm',
                        )
                      : '-',
                },
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
                    getUserIPLogs(detailUser.userID, {
                      pageNumber: page,
                      showNumber: 20,
                    }).then((resp) => {
                      if (resp.errCode === 0 && resp.data) {
                        setIpLogs(resp.data.logs ?? []);
                        setIpLogsTotal(resp.data.total ?? 0);
                      }
                    });
                  }
                },
              }}
            />
          ),
        },
        {
          key: 'groups',
          label: '所属群组',
          children: (
            <Table<OPENIM.GroupInfo>
              size="small"
              rowKey="groupID"
              dataSource={joinedGroups}
              style={{ marginTop: 8 }}
              locale={{ emptyText: '暂未加入任何群组' }}
              columns={[
                {
                  title: '头像',
                  dataIndex: 'faceURL',
                  width: 44,
                  render: (url: string, r: OPENIM.GroupInfo) => (
                    <Avatar src={url} size={32}>
                      {r.groupName?.[0]}
                    </Avatar>
                  ),
                },
                { title: '群名称', dataIndex: 'groupName', ellipsis: true },
                {
                  title: '群ID',
                  dataIndex: 'groupID',
                  width: 180,
                  ellipsis: true,
                },
                { title: '成员数', dataIndex: 'memberCount', width: 70 },
              ]}
              pagination={{
                total: joinedGroupsTotal,
                pageSize: 20,
                showSizeChanger: false,
                onChange: (page) =>
                  loadJoinedGroups(detailUser!.userID, page),
              }}
            />
          ),
        },
        {
          key: 'oplog',
          label: '操作日志',
          children: (
            <Table<OpLogEntry>
              size="small"
              rowKey="time"
              dataSource={opLog[detailUser?.userID ?? ''] ?? []}
              style={{ marginTop: 8 }}
              locale={{ emptyText: '本次会话暂无操作记录' }}
              columns={[
                {
                  title: '时间',
                  dataIndex: 'time',
                  width: 100,
                  render: (t: number) => dayjs(t).format('HH:mm:ss'),
                },
                { title: '操作', dataIndex: 'action', width: 140 },
                {
                  title: '备注',
                  dataIndex: 'extra',
                  render: (v?: string) => v ?? '-',
                },
              ]}
              pagination={false}
            />
          ),
        },
      ]
    : [];

  // ─── 渲染 ─────────────────────────────────────────────────────────────────
  return (
    <PageContainer>
      {/* 批量操作栏 */}
      {selectedRowKeys.length > 0 && (
        <div
          style={{
            background: '#e6f4ff',
            border: '1px solid #91caff',
            borderRadius: 6,
            padding: '8px 16px',
            marginBottom: 12,
            display: 'flex',
            alignItems: 'center',
            gap: 12,
          }}
        >
          <Text>
            已选 <Text strong>{selectedRowKeys.length}</Text> 个用户
          </Text>
          <Button size="small" danger onClick={handleBatchBlock}>
            批量封禁
          </Button>
          <Button size="small" onClick={handleBatchForceLogout}>
            批量强制下线
          </Button>
          <Button size="small" danger onClick={handleBatchDelete}>
            批量删除
          </Button>
          <Button
            size="small"
            onClick={() => {
              setSelectedRowKeys([]);
              setSelectedRows([]);
            }}
          >
            取消选择
          </Button>
        </div>
      )}

      <ProTable<OPENIM.UserInfo>
        headerTitle="用户列表"
        actionRef={actionRef}
        rowKey="userID"
        columns={columns}
        scroll={{ x: 1480, y: 600 }}
        virtual
        rowSelection={{
          selectedRowKeys,
          onChange: (keys, rows) => {
            setSelectedRowKeys(keys as string[]);
            setSelectedRows(rows);
          },
        }}
        toolBarRender={() => [
          <Select
            key="tagFilter"
            allowClear
            placeholder="按标签筛选"
            style={{ width: 150 }}
            value={tagFilter || undefined}
            onChange={(v) => setTagFilter(v ?? '')}
            options={allUsedTags.map((t) => ({ label: t, value: t }))}
          />,
          <Button key="export" onClick={handleExportCSV}>
            导出 CSV
          </Button>,
          <Button key="create" onClick={() => setCreateOpen(true)}>
            新建用户
          </Button>,
          <Button
            key="batch"
            type="primary"
            onClick={() => setBatchModalOpen(true)}
          >
            批量创建
          </Button>,
        ]}
        request={async (params) => {
          const resp = await searchUsersWithIP({
            keyword: params.keyword || undefined,
            pagination: {
              pageNumber: params.current || 1,
              showNumber: params.pageSize || 20,
            },
            genders:
              params.gender !== undefined && params.gender !== ''
                ? [Number(params.gender)]
                : undefined,
          });
          let users = resp.data?.users ?? [];

          // 从 user_ext 获取封禁状态（后端已双写，单源查询）
          if (users.length > 0) {
            try {
              const statusResp = await getUserBlockStatus(
                users.map((u) => u.userID),
              );
              if (
                statusResp.errCode === 0 &&
                Array.isArray(statusResp.data)
              ) {
                const nextSet = new Set<string>();
                for (const s of statusResp.data) {
                  if (s?.userID && !!s.isBlocked) nextSet.add(s.userID);
                }
                setBlockedSet(nextSet);
              }
            } catch {
              // 降级：保持本地 blockedSet
            }
          }
          // 客户端过滤：标签、角色
          if (tagFilter) {
            users = users.filter((u) =>
              getTagsForUser(u.userID).includes(tagFilter),
            );
          }
          if (params.appRole !== undefined && params.appRole !== '') {
            users = users.filter(
              (u) => (u.appRole ?? 0) === Number(params.appRole),
            );
          }
          return {
            data: users,
            total:
              tagFilter || params.appRole !== ''
                ? users.length
                : (resp.data?.total ?? 0),
            success: resp.errCode === 0,
          };
        }}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto', defaultCollapsed: false }}
      />

      {/* 详情抽屉 */}
      <Drawer
        title={
          detailUser
            ? `${detailUser.nickname ?? detailUser.userID}`
            : '用户详情'
        }
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        width={600}
        extra={
          detailUser && (
            <Space>
              {detailUser.isOfficial === 1 && <Tag color="gold">金V</Tag>}
              {detailUser.appRole === 1 && <Tag color="blue">管理员</Tag>}
              {blockedSet.has(detailUser.userID) && (
                <Tag color="red">已封禁</Tag>
              )}
            </Space>
          )
        }
      >
        <Tabs
          activeKey={detailTab}
          onChange={(key) => {
            setDetailTab(key);
            if (
              key === 'groups' &&
              detailUser &&
              joinedGroups.length === 0
            ) {
              loadJoinedGroups(detailUser.userID);
            }
          }}
          items={detailTabItems}
        />
      </Drawer>

      {/* 编辑用户弹窗 */}
      <Modal
        title={`编辑用户 — ${editUser?.nickname ?? editUser?.userID}`}
        open={editOpen}
        onCancel={() => setEditOpen(false)}
        onOk={async () => {
          try {
            const values = await editForm.validateFields();
            const resp = await updateUserBasicInfo(editUser!.userID, {
              nickname: values.nickname || undefined,
              gender:
                values.gender !== undefined ? Number(values.gender) : undefined,
              ex: values.ex || undefined,
            });
            if (resp.errCode === 0) {
              message.success('已保存');
              addOpLog(editUser!.userID, '修改用户资料');
              actionRef.current?.reload?.();
              setEditOpen(false);
            } else {
              message.error(resp.errMsg ?? '保存失败');
            }
          } catch {}
        }}
        destroyOnClose
      >
        <Form
          form={editForm}
          layout="vertical"
          style={{ marginTop: 16 }}
        >
          <Form.Item name="nickname" label="昵称">
            <Input placeholder="用户显示昵称" maxLength={50} />
          </Form.Item>
          <Form.Item name="gender" label="性别">
            <Select
              options={[
                { label: '未设置', value: 0 },
                { label: '男', value: 1 },
                { label: '女', value: 2 },
              ]}
            />
          </Form.Item>
          <Form.Item name="ex" label="个性签名 / 扩展字段">
            <Input.TextArea
              rows={3}
              placeholder="个性签名或扩展 JSON 字符串"
              maxLength={200}
            />
          </Form.Item>
        </Form>
      </Modal>

      {/* 新建用户弹窗 */}
      <ModalForm
        title="新建用户"
        open={createOpen}
        onOpenChange={setCreateOpen}
        modalProps={{ destroyOnClose: true }}
        onFinish={async (values) => {
          const resp = await addSingleUser({
            account: values.account.trim(),
            nickname: values.nickname.trim(),
            password: values.password,
            phoneNumber: values.phoneNumber?.trim() || undefined,
            email: values.email?.trim() || undefined,
            gender: values.gender ?? 0,
          });
          if (resp.errCode === 0) {
            message.success('用户创建成功');
            actionRef.current?.reload?.();
            return true;
          }
          message.error(resp.errMsg ?? '创建失败');
          return false;
        }}
      >
        <ProFormText
          name="account"
          label="账号（用户名）"
          placeholder="用于登录，例如 user001"
          rules={[
            { required: true, message: '请输入账号' },
            { min: 3, message: '账号至少 3 位' },
          ]}
        />
        <ProFormText
          name="nickname"
          label="昵称"
          placeholder="显示昵称"
          rules={[{ required: true, message: '请输入昵称' }]}
        />
        <ProFormText.Password
          name="password"
          label="初始密码"
          placeholder="至少 6 位"
          rules={[
            { required: true, message: '请输入密码' },
            { min: 6, message: '密码至少 6 位' },
          ]}
        />
        <ProFormText
          name="phoneNumber"
          label="手机号"
          placeholder="选填"
          rules={[
            {
              pattern: /^\d{7,15}$/,
              message: '手机号格式不正确',
            },
          ]}
        />
        <ProFormText name="email" label="邮箱" placeholder="选填" />
        <ProFormSelect
          name="gender"
          label="性别"
          initialValue={0}
          options={[
            { label: '未设置', value: 0 },
            { label: '男', value: 1 },
            { label: '女', value: 2 },
          ]}
        />
      </ModalForm>

      {/* 批量创建用户弹窗 */}
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
            message.success(
              `创建成功 ${resp.data.created} 个，跳过 ${resp.data.skipped} 个`,
            );
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
            {
              pattern: /^.*\d+$/,
              message: '用户名必须以数字结尾，例如 bab001',
            },
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
