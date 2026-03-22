/**
 * 资金管理页面
 * 管理员查询/调整用户钱包余额、查看流水
 */
import {
  adjustWalletBalance,
  getUserWallet,
  getWalletTransactions,
  listWithdrawRequests,
  reviewWithdraw,
  type WithdrawRequest,
} from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  ModalForm,
  PageContainer,
  ProFormDigit,
  ProFormRadio,
  ProFormText,
  ProFormTextArea,
  ProTable,
} from '@ant-design/pro-components';
import { Button, Card, Descriptions, Drawer, message, Popconfirm, Tag, Tabs, Input } from 'antd';
import dayjs from 'dayjs';
import React, { useRef, useState } from 'react';

const WalletPage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);
  const [searchUserID, setSearchUserID] = useState('');
  const [inputUserID, setInputUserID] = useState('');
  const [wallet, setWallet] = useState<OPENIM.WalletAccount | null>(null);
  const [walletLoading, setWalletLoading] = useState(false);
  const [adjustOpen, setAdjustOpen] = useState(false);
  const [txDrawerOpen, setTxDrawerOpen] = useState(false);

  const handleSearch = async () => {
    if (!inputUserID.trim()) return;
    setWalletLoading(true);
    try {
      const resp = await getUserWallet(inputUserID.trim());
      if (resp.errCode === 0) {
        setWallet(resp.data);
        setSearchUserID(inputUserID.trim());
        actionRef.current?.reload();
      } else {
        message.error(resp.errMsg ?? '查询失败');
      }
    } finally {
      setWalletLoading(false);
    }
  };

  const txColumns: ProColumns<OPENIM.WalletTransaction>[] = [
    {
      title: '时间',
      dataIndex: 'createdAt',
      width: 160,
      render: (_, r) => (r.createdAt ? dayjs(r.createdAt).format('YYYY-MM-DD HH:mm') : '-'),
    },
    {
      title: '变动金额',
      dataIndex: 'amount',
      width: 120,
      render: (_, r) => {
        const yuan = (r.amount / 100).toFixed(2);
        return r.amount >= 0 ? (
          <Tag color="green">+¥{yuan}</Tag>
        ) : (
          <Tag color="red">-¥{Math.abs(r.amount / 100).toFixed(2)}</Tag>
        );
      },
    },
    {
      title: '余额（分）',
      dataIndex: 'balanceAfter',
      width: 120,
      render: (_, r) => `¥${(r.balanceAfter / 100).toFixed(2)}`,
    },
    {
      title: '备注',
      dataIndex: 'note',
      ellipsis: true,
    },
    {
      title: '操作管理员',
      dataIndex: 'opAdminID',
      width: 180,
    },
  ];

  return (
    <PageContainer>
      {/* 搜索区域 */}
      <Card
        style={{ marginBottom: 16 }}
        title="查询用户钱包"
      >
        <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
          <input
            placeholder="请输入用户 UserID"
            value={inputUserID}
            onChange={(e) => setInputUserID(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSearch()}
            style={{
              padding: '4px 8px',
              border: '1px solid #d9d9d9',
              borderRadius: 4,
              width: 300,
              fontSize: 14,
            }}
          />
          <Button type="primary" loading={walletLoading} onClick={handleSearch}>
            查询
          </Button>
        </div>
      </Card>

      {/* 余额卡片 */}
      {wallet && (
        <Card
          style={{ marginBottom: 16 }}
          title={`用户钱包：${wallet.userID}`}
          extra={
            <div style={{ display: 'flex', gap: 8 }}>
              <Button onClick={() => setTxDrawerOpen(true)}>查看流水</Button>
              <Button type="primary" onClick={() => setAdjustOpen(true)}>
                调整余额
              </Button>
            </div>
          }
        >
          <Descriptions>
            <Descriptions.Item label="UserID">{wallet.userID}</Descriptions.Item>
            <Descriptions.Item label="余额">
              <Tag color="blue" style={{ fontSize: 16 }}>
                ¥ {(wallet.balance / 100).toFixed(2)}
              </Tag>
            </Descriptions.Item>
            <Descriptions.Item label="货币">{wallet.currency}</Descriptions.Item>
            <Descriptions.Item label="最后更新">
              {wallet.updatedAt ? dayjs(wallet.updatedAt).format('YYYY-MM-DD HH:mm') : '-'}
            </Descriptions.Item>
          </Descriptions>
        </Card>
      )}

      {/* 调整余额 ModalForm */}
      <ModalForm
        title="调整余额"
        open={adjustOpen}
        onOpenChange={setAdjustOpen}
        onFinish={async (values) => {
          if (!wallet) return false;
          // type: 'credit' = 入账, 'debit' = 扣款
          const delta = values.type === 'credit'
            ? Math.round(values.amount * 100)
            : -Math.round(values.amount * 100);
          const resp = await adjustWalletBalance({
            userID: wallet.userID,
            amount: delta,
            note: values.note ?? '',
          }, values.confirmPassword);
          if (resp.errCode === 0) {
            message.success('操作成功');
            // Refresh wallet display
            const freshResp = await getUserWallet(wallet.userID);
            if (freshResp.errCode === 0) setWallet(freshResp.data);
            actionRef.current?.reload();
            return true;
          }
          message.error(resp.errMsg ?? '操作失败');
          return false;
        }}
      >
        <ProFormRadio.Group
          name="type"
          label="操作类型"
          initialValue="credit"
          options={[
            { label: '入账（增加余额）', value: 'credit' },
            { label: '扣款（减少余额）', value: 'debit' },
          ]}
          rules={[{ required: true }]}
        />
        <ProFormDigit
          name="amount"
          label="金额（元）"
          min={0.01}
          fieldProps={{ precision: 2, step: 1 }}
          rules={[{ required: true }]}
        />
        <ProFormTextArea
          name="note"
          label="备注"
          placeholder="请输入操作备注（可选）"
          fieldProps={{ rows: 2 }}
        />
        <ProFormText.Password
          name="confirmPassword"
          label="管理员密码"
          placeholder="请输入您的登录密码以确认操作"
          rules={[{ required: true, message: '请输入管理员密码' }]}
        />
      </ModalForm>

      {/* 流水 Drawer */}
      <Drawer
        title={`流水记录 — ${searchUserID}`}
        open={txDrawerOpen}
        onClose={() => setTxDrawerOpen(false)}
        width={680}
        destroyOnClose
      >
        <ProTable<OPENIM.WalletTransaction>
          rowKey="id"
          actionRef={actionRef}
          search={false}
          toolBarRender={false}
          request={async (params) => {
            if (!searchUserID) return { data: [], success: true, total: 0 };
            const resp = await getWalletTransactions({
              userID: searchUserID,
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
          columns={txColumns}
          pagination={{ pageSize: 20 }}
        />
      </Drawer>

      {/* 提现审批 Tab (below the above wallet section) */}
      <Card title="提现申请审批" style={{ marginTop: 16 }}>
        <ProTable<WithdrawRequest>
          rowKey="ID"
          search={false}
          request={async (params) => {
            const resp = await listWithdrawRequests("", {
              pageNumber: params.current ?? 1,
              showNumber: params.pageSize ?? 20,
            });
            if (resp.errCode !== 0) return { data: [], success: false, total: 0 };
            return {
              data: resp.data?.list ?? [],
              success: true,
              total: resp.data?.total ?? 0,
            };
          }}
          columns={[
            { title: '用户ID', dataIndex: 'UserID', width: 180, copyable: true },
            {
              title: '金额',
              dataIndex: 'Amount',
              width: 120,
              render: (_, r) => `¥${(r.Amount / 100).toFixed(2)}`,
            },
            {
              title: '状态',
              dataIndex: 'Status',
              width: 100,
              render: (_, r) => {
                const colorMap: Record<string, string> = { pending: 'orange', approved: 'green', rejected: 'red' };
                const labelMap: Record<string, string> = { pending: '待审批', approved: '已通过', rejected: '已拒绝' };
                return <Tag color={colorMap[r.Status] ?? 'default'}>{labelMap[r.Status] ?? r.Status}</Tag>;
              },
            },
            { title: '备注', dataIndex: 'Note', ellipsis: true },
            { title: '审批意见', dataIndex: 'Reason', ellipsis: true },
            {
              title: '时间',
              dataIndex: 'CreatedAt',
              width: 160,
              render: (_, r) => r.CreatedAt ? dayjs(r.CreatedAt).format('YYYY-MM-DD HH:mm') : '-',
            },
            {
              title: '操作',
              width: 150,
              render: (_, record) => record.Status === 'pending' ? (
                <span>
                  <Popconfirm title="确定通过此提现申请？" onConfirm={async () => {
                    const resp = await reviewWithdraw(record.ID, 'approved', '管理员批准');
                    if (resp.errCode === 0) { message.success('已通过'); } else { message.error(resp.errMsg); }
                  }}>
                    <a style={{ color: '#52c41a', marginRight: 8 }}>通过</a>
                  </Popconfirm>
                  <Popconfirm title="确定拒绝此提现申请？" onConfirm={async () => {
                    const resp = await reviewWithdraw(record.ID, 'rejected', '管理员拒绝');
                    if (resp.errCode === 0) { message.success('已拒绝'); } else { message.error(resp.errMsg); }
                  }}>
                    <a style={{ color: '#ff4d4f' }}>拒绝</a>
                  </Popconfirm>
                </span>
              ) : '-',
            },
          ]}
          pagination={{ pageSize: 20 }}
        />
      </Card>
    </PageContainer>
  );
};

export default WalletPage;
