import { addForbiddenIP, deleteForbiddenIP, searchForbiddenIPs } from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { ModalForm, PageContainer, ProFormSwitch, ProFormText, ProTable } from '@ant-design/pro-components';
import { Button, message, Popconfirm, Tag } from 'antd';
import dayjs from 'dayjs';
import React, { useRef } from 'react';

const IpForbidden: React.FC = () => {
  const actionRef = useRef<ActionType>(null);

  const columns: ProColumns<OPENIM.ForbiddenIP>[] = [
    { title: 'IP 地址', dataIndex: 'ip', width: 200, copyable: true },
    {
      title: '禁止登录',
      dataIndex: 'limitLogin',
      width: 90,
      search: false,
      render: (_, r) => r.limitLogin ? <Tag color="red">是</Tag> : <Tag>否</Tag>,
    },
    {
      title: '禁止注册',
      dataIndex: 'limitRegister',
      width: 90,
      search: false,
      render: (_, r) => r.limitRegister ? <Tag color="red">是</Tag> : <Tag>否</Tag>,
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
          title="确定解除该IP封禁？"
          onConfirm={async () => {
            const resp = await deleteForbiddenIP([record.ip]);
            if (resp.errCode === 0) {
              message.success('已解除');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}
        >
          <a className="ant-typography ant-typography-danger">解除</a>
        </Popconfirm>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.ForbiddenIP>
        headerTitle="IP 封禁列表"
        actionRef={actionRef}
        rowKey="ip"
        columns={columns}
        toolBarRender={() => [
          <ModalForm
            key="add"
            title="添加 IP 封禁"
            trigger={<Button type="primary" icon={<PlusOutlined />}>封禁IP</Button>}
            onFinish={async (values: { ip: string; limitLogin: boolean; limitRegister: boolean }) => {
              const resp = await addForbiddenIP(values.ip, values.limitLogin, values.limitRegister);
              if (resp.errCode === 0) {
                message.success('已封禁');
                actionRef.current?.reload();
                return true;
              }
              message.error(resp.errMsg);
              return false;
            }}
          >
            <ProFormText name="ip" label="IP 地址" rules={[{ required: true }]} />
            <ProFormSwitch name="limitLogin" label="禁止登录" />
            <ProFormSwitch name="limitRegister" label="禁止注册" />
          </ModalForm>,
        ]}
        request={async (params) => {
          const resp = await searchForbiddenIPs(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
            params.ip,
          );
          return {
            data: resp.data?.forbiddens || [],
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

export default IpForbidden;
