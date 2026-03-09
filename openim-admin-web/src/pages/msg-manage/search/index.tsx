import { searchMessages } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { PageContainer, ProTable } from '@ant-design/pro-components';
import { DatePicker, Tag } from 'antd';
import dayjs from 'dayjs';
import React, { useRef, useState } from 'react';

const { RangePicker } = DatePicker;

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
  const [dateRange, setDateRange] = useState<[string, string] | null>(null);

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
      renderFormItem: () => (
        <RangePicker
          onChange={(_, dateStrings) => {
            if (dateStrings[0] && dateStrings[1]) {
              setDateRange(dateStrings as [string, string]);
            } else {
              setDateRange(null);
            }
          }}
        />
      ),
    } as ProColumns<OPENIM.MessageInfo>,
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.MessageInfo>
        headerTitle="消息搜索"
        actionRef={actionRef}
        rowKey="serverMsgID"
        columns={columns}
        request={async (params) => {
          const resp = await searchMessages({
            pagination: {
              pageNumber: params.current || 1,
              showNumber: params.pageSize || 20,
            },
            sendID: params.sendID || '',
            recvID: params.recvID || '',
            sendTime: dateRange
              ? `${dayjs(dateRange[0]).valueOf()}:${dayjs(dateRange[1]).valueOf()}`
              : undefined,
          });
          return {
            data: resp.data?.chatLogs || [],
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

export default MsgSearch;
