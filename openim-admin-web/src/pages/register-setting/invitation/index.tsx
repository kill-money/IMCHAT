import { deleteInvitationCodes, genInvitationCodes, searchInvitationCodes } from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormDigit, ProTable } from '@ant-design/pro-components';
import { Button, message, Popconfirm } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';

const InvitationManage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.InvitationCode>[] = [
    { title: '邀请码', dataIndex: 'invitationCode', width: 260, copyable: true },
    {
      title: '使用次数',
      dataIndex: 'usedTimes',
      width: 90,
      search: false,
    },
    {
      title: '最后使用时间',
      dataIndex: 'lastUsedTime',
      width: 170,
      search: false,
      render: (_, r) => r.lastUsedTime ? dayjs(r.lastUsedTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '创建时间',
      dataIndex: 'createTime',
      width: 170,
      search: false,
      render: (_, r) => r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定删除该邀请码？"
          onConfirm={async () => {
            const resp = await deleteInvitationCodes([record.invitationCode]);
            if (resp.errCode === 0) {
              message.success('已删除');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}
        >
          <a className="ant-typography ant-typography-danger">删除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.InvitationCode>
        headerTitle="邀请码管理"
        actionRef={actionRef}
        rowKey="code"
        columns={columns}
        toolBarRender={() => [
          <ModalForm
            key="gen"
            title="生成邀请码"
            trigger={<Button type="primary" icon={<PlusOutlined />}>生成邀请码</Button>}
            onFinish={async (values: { num: number }) => {
              const resp = await genInvitationCodes(values.num);
              if (resp.errCode === 0) {
                message.success(`已生成 ${values.num} 个邀请码`);
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg);
              return false;
            }}
          >
            <ProFormDigit name="num" label="生成数量" min={1} max={100} initialValue={10} rules={[{ required: true }]} />
          </ModalForm>,
        ]}
        request={async (params) => {
          const resp = await searchInvitationCodes(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
            params.code,
          );
          return {
            data: resp.data?.invitationCodes || [],
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

export default InvitationManage;
