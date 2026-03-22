import { searchMessages, adminRecallMessage } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { PageContainer, ProTable } from '@ant-design/pro-components';
import { message, Popconfirm, Tag } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';

const contentTypeMap: Record<number, string> = {
  101: '文本',
  102: '图片',
  103: '语音',
  104: '视频',
  105: '文件',
  106: '名片',
  107: '位置',
  108: '自定义',
  114: '引用',
  115: '合并',
};

const MsgSearch: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.MessageInfo>[] = [
    { title: '发送者ID', dataIndex: 'sendID', width: 180, copyable: true },
    { title: '接收者ID', dataIndex: 'recvID', width: 180, copyable: true },
    {
      title: '消息类型',
      dataIndex: 'contentType',
      width: 100,
      search: false,
      render: (_, r) => <Tag>{contentTypeMap[r.contentType] || `类型${r.contentType}`}</Tag>,
    },
    {
      title: '内容',
      dataIndex: 'content',
      search: false,
      ellipsis: true,
      width: 300,
    },
    {
      title: '发送时间',
      dataIndex: 'sendTime',
      search: false,
      width: 170,
      render: (_, r) => r.sendTime ? dayjs(r.sendTime).format('YYYY-MM-DD HH:mm:ss') : '-',
    },
    {
      title: '时间范围',
      dataIndex: 'dateRange',
      hideInTable: true,
      valueType: 'dateTimeRange',
      fieldProps: { showTime: false, placeholder: ['开始时间', '结束时间'] },
    },
    {
      title: '操作',
      valueType: 'option',
      width: 100,
      render: (_, record) => (
        <Popconfirm
          title="确定撤回此消息？此操作不可恢复"
          onConfirm={async () => {
            const resp = await adminRecallMessage({
              conversationID: record.conversationID ?? '',
              seq: record.seq ?? 0,
              senderID: record.sendID,
              sendTime: typeof record.sendTime === 'number' ? record.sendTime : dayjs(record.sendTime).valueOf(),
            });
            if (resp.errCode === 0) {
              message.success('已撤回');
              actionRef.current?.reload();
            } else {
              message.error(resp.errMsg ?? '撤回失败');
            }
          }}
        >
          <a className="ant-typography ant-typography-danger">撤回</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.MessageInfo>
        headerTitle="消息搜索"
        actionRef={actionRef}
        rowKey="serverMsgID"
        columns={columns}
        scroll={{ x: 'max-content', y: 600 }}
        virtual
        request={async (params) => {
          const dr = params.dateRange as [string, string] | undefined;
          const resp = await searchMessages({
            pagination: {
              pageNumber: params.current || 1,
              showNumber: params.pageSize || 20,
            },
            sendID: params.sendID || '',
            recvID: params.recvID || '',
            sendTime: dr?.[0] && dr?.[1]
              ? `${dayjs(dr[0]).valueOf()}:${dayjs(dr[1]).valueOf()}`
              : undefined,
          });
          return {
            data: resp.data?.chatLogs || [],
            total: resp.data?.chatLogsNum || 0,
            success: resp.errCode === 0,
          };
        }}
        pagination={{ defaultPageSize: 20 }}
        search={{ labelWidth: 'auto' }}
      />
    </PageContainer>
  );
};

export default MsgSearch;
