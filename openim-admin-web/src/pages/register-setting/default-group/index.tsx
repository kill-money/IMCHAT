import { addDefaultGroups, deleteDefaultGroups, searchDefaultGroups } from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormText, ProTable } from '@ant-design/pro-components';
import { Avatar, Button, message, Popconfirm } from 'antd';
import React, { useRef } from 'react';

const DefaultGroup: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.GroupInfo>[] = [
    {
      title: '头像',
      dataIndex: 'faceURL',
      search: false,
      width: 60,
      render: (_, r) => <Avatar src={r.faceURL} size="small">{r.groupName?.[0]}</Avatar>,
    },
    { title: '群ID', dataIndex: 'groupID', width: 200, copyable: true },
    { title: '群名称', dataIndex: 'groupName', width: 150, search: false },
    { title: '成员数', dataIndex: 'memberCount', width: 80, search: false },
    {
      title: '操作',
      valueType: 'option',
      width: 80,
      render: (_, record) => (
        <Popconfirm
          title="确定移除该默认群组？"
          onConfirm={async () => {
            const resp = await deleteDefaultGroups([record.groupID]);
            if (resp.errCode === 0) {
              message.success('已移除');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}
        >
          <a className="ant-typography ant-typography-danger">移除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.GroupInfo>
        headerTitle="默认群组列表"
        actionRef={actionRef}
        rowKey="groupID"
        columns={columns}
        toolBarRender={() => [
          <ModalForm
            key="add"
            title="添加默认群组"
            trigger={<Button type="primary" icon={<PlusOutlined />}>添加默认群组</Button>}
            onFinish={async (values: { groupIDs: string }) => {
              const ids = values.groupIDs.split(/[,，\s]+/).filter(Boolean);
              const resp = await addDefaultGroups(ids);
              if (resp.errCode === 0) {
                message.success('添加成功');
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg);
              return false;
            }}
          >
            <ProFormText
              name="groupIDs"
              label="群组ID"
              rules={[{ required: true }]}
              placeholder="多个ID用逗号分隔"
            />
          </ModalForm>,
        ]}
        request={async (params) => {
          const resp = await searchDefaultGroups(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
          );
          return {
            data: resp.data?.groups || [],
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

export default DefaultGroup;
