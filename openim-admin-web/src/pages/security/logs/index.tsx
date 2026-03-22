/**
 * 安全审计日志页面（二开）
 * 实时查看管理员操作记录：登录、封禁、重置密码等操作均记录在案。
 */
import { searchSecurityLogs } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import {
  PageContainer,
  ProTable,
} from '@ant-design/pro-components';
import { Badge, Space, Tag, Typography } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';
const { Text } = Typography;

// 操作动作中文标签
const ACTION_LABELS: Record<string, { label: string; color: string }> = {
  login: { label: '管理员登录', color: 'blue' },
  ban_user: { label: '封禁用户', color: 'red' },
  unban_user: { label: '解封用户', color: 'green' },
  reset_pass: { label: '重置密码', color: 'orange' },
  batch_create: { label: '批量创建', color: 'purple' },
  add_whitelist: { label: '添加白名单', color: 'cyan' },
  del_whitelist: { label: '删除白名单', color: 'magenta' },
  mute_group: { label: '禁言群组', color: 'volcano' },
  dismiss_group: { label: '解散群组', color: 'red' },
  force_logout: { label: '强制下线', color: 'geekblue' },
};

const TARGET_LABELS: Record<string, string> = {
  user: '用户',
  group: '群组',
  ip: 'IP地址',
  system: '系统',
};

const SecurityLogsPage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.SecurityLog>[] = [
    {
      title: '时间',
      dataIndex: 'created_at',
      width: 180,
      render: (_, record) =>
        dayjs(record.created_at).format('YYYY-MM-DD HH:mm:ss'),
      search: false,
    },
    {
      title: '操作者',
      dataIndex: 'operator_id',
      width: 160,
      render: (_, record) => (
        <Space direction="vertical" size={0}>
          <Text strong style={{ fontSize: 13 }}>
            {record.operator_name || record.operator_id}
          </Text>
          <Text type="secondary" style={{ fontSize: 11 }}>
            {record.operator_id}
          </Text>
        </Space>
      ),
    },
    {
      title: '操作',
      dataIndex: 'action',
      width: 140,
      valueType: 'select',
      fieldProps: {
        allowClear: true,
        placeholder: '全部操作',
        options: [
          { label: '全部', value: '' },
          ...Object.entries(ACTION_LABELS).map(([k, v]) => ({ label: v.label, value: k })),
        ],
      },
      render: (_, record) => {
        const info = ACTION_LABELS[record.action];
        return info ? (
          <Tag color={info.color}>{info.label}</Tag>
        ) : (
          <Tag>{record.action}</Tag>
        );
      },
    },
    {
      title: '对象',
      dataIndex: 'target_id',
      width: 200,
      render: (_, record) =>
        record.target_id ? (
          <Space>
            <Tag color="default">
              {TARGET_LABELS[record.target_type] ?? record.target_type}
            </Tag>
            <Text copyable style={{ fontSize: 12 }}>
              {record.target_id}
            </Text>
          </Space>
        ) : (
          <Text type="secondary">—</Text>
        ),
      search: false,
    },
    {
      title: '详情',
      dataIndex: 'detail',
      ellipsis: true,
      search: false,
    },
    {
      title: '来源 IP',
      dataIndex: 'ip',
      width: 140,
      search: false,
    },
    {
      title: '结果',
      dataIndex: 'success',
      width: 80,
      search: false,
      render: (_, record) =>
        record.success ? (
          <Badge status="success" text="成功" />
        ) : (
          <Badge status="error" text="失败" />
        ),
    },
    {
      title: '时间范围',
      dataIndex: 'timeRange',
      hideInTable: true,
      valueType: 'dateTimeRange',
      fieldProps: { showTime: true, style: { width: '100%' } },
    },
    {
      title: '关键词',
      dataIndex: 'keyword',
      hideInTable: true,
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.SecurityLog>
        actionRef={actionRef}
        rowKey="_id"
        columns={columns}
        search={{ labelWidth: 80 }}
        pagination={{ pageSize: 20 }}
        headerTitle="安全审计日志"
        toolBarRender={false}
        request={async (params) => {
          const timeRange = params.timeRange as [string, string] | undefined;
          const resp = await searchSecurityLogs({
            keyword: params.keyword,
            action: params.action,
            start_time: timeRange?.[0] ? dayjs(timeRange[0]).toISOString() : undefined,
            end_time: timeRange?.[1] ? dayjs(timeRange[1]).toISOString() : undefined,
            pageNum: params.current,
            showNum: params.pageSize,
          });
          return {
            data: resp?.data?.list ?? [],
            total: resp?.data?.total ?? 0,
            success: true,
          };
        }}
      />
    </PageContainer>
  );
};

export default SecurityLogsPage;
