import {
  createBroadcast,
  deleteBroadcasts,
  searchBroadcasts,
  sendBroadcast,
  updateBroadcast,
} from '@/services/openim';
import type { BroadcastMessage } from '@/services/openim/api';
import {
  DeleteOutlined,
  EditOutlined,
  PlusOutlined,
  SendOutlined,
} from '@ant-design/icons';
import {
  ActionType,
  PageContainer,
  ProTable,
} from '@ant-design/pro-components';
import type { ProColumns } from '@ant-design/pro-components';
import {
  Button,
  Form,
  Input,
  message,
  Modal,
  Popconfirm,
  Select,
  Space,
  Tag,
} from 'antd';
import React, { useRef, useState } from 'react';

const statusMap: Record<number, { text: string; color: string }> = {
  0: { text: '待发送', color: 'default' },
  1: { text: '已发送', color: 'green' },
  2: { text: '发送失败', color: 'red' },
  3: { text: '发送中', color: 'processing' },
};

const BroadcastPage: React.FC = () => {
  const actionRef = useRef<ActionType | undefined>(undefined);
  const [editOpen, setEditOpen] = useState(false);
  const [sendOpen, setSendOpen] = useState(false);
  const [currentRow, setCurrentRow] = useState<BroadcastMessage | null>(null);
  const [form] = Form.useForm();
  const [sendForm] = Form.useForm();

  const columns: ProColumns<BroadcastMessage>[] = [
    { title: '标题', dataIndex: 'title', ellipsis: true, width: 200 },
    {
      title: '状态',
      dataIndex: 'status',
      width: 100,
      render: (_, r) => {
        const s = statusMap[r.status] ?? { text: '未知', color: 'default' };
        return <Tag color={s.color}>{s.text}</Tag>;
      },
      valueEnum: { 0: '待发送', 1: '已发送', 2: '失败', 3: '发送中' },
    },
    { title: '目标', dataIndex: 'sendTo', ellipsis: true, width: 160 },
    {
      title: '类型',
      dataIndex: 'contentType',
      width: 80,
      render: (_, r) => (r.contentType === 2 ? 'Markdown' : '纯文本'),
    },
    { title: '创建者', dataIndex: 'createdBy', width: 120 },
    { title: '发送者', dataIndex: 'sentBy', width: 120 },
    { title: '创建时间', dataIndex: 'createdAt', width: 180 },
    { title: '发送时间', dataIndex: 'sentAt', width: 180 },
    { title: '成功数', dataIndex: 'successCount', width: 80, render: (_, r) => r.successCount ?? '-' },
    { title: '失败数', dataIndex: 'failCount', width: 80, render: (_, r) => r.failCount ?? '-' },
    {
      title: '操作',
      width: 200,
      fixed: 'right',
      render: (_, record) => (
        <Space>
          {record.status === 0 && (
            <>
              <a
                onClick={() => {
                  setCurrentRow(record);
                  form.setFieldsValue(record);
                  setEditOpen(true);
                }}
              >
                <EditOutlined /> 编辑
              </a>
              <a
                onClick={() => {
                  setCurrentRow(record);
                  setSendOpen(true);
                }}
                style={{ color: '#52c41a' }}
              >
                <SendOutlined /> 发送
              </a>
            </>
          )}
          <Popconfirm
            title="确认删除？"
            onConfirm={async () => {
              const resp = await deleteBroadcasts([record.broadcastID]);
              if (resp.errCode === 0) {
                message.success('已删除');
                actionRef.current?.reload();
              } else {
                message.error(resp.errMsg || '删除失败');
              }
            }}
          >
            <a style={{ color: '#ff4d4f' }}>
              <DeleteOutlined /> 删除
            </a>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // 创建/编辑提交
  const handleEditSubmit = async () => {
    const values = await form.validateFields();
    let resp;
    if (currentRow?.broadcastID) {
      resp = await updateBroadcast({
        broadcastID: currentRow.broadcastID,
        ...values,
      });
    } else {
      resp = await createBroadcast(values);
    }
    if (resp.errCode === 0) {
      message.success(currentRow?.broadcastID ? '更新成功' : '创建成功');
      setEditOpen(false);
      form.resetFields();
      setCurrentRow(null);
      actionRef.current?.reload();
    } else {
      message.error(resp.errMsg || '操作失败');
    }
  };

  // 发送确认
  const handleSendConfirm = async () => {
    if (!currentRow) return;
    const { password } = await sendForm.validateFields();
    const resp = await sendBroadcast(currentRow.broadcastID, password);
    if (resp.errCode === 0) {
      message.success('广播已加入发送队列');
      setSendOpen(false);
      sendForm.resetFields();
      setCurrentRow(null);
      actionRef.current?.reload();
    } else {
      message.error(resp.errMsg || '发送失败');
    }
  };

  return (
    <PageContainer>
      <ProTable<BroadcastMessage>
        headerTitle="系统广播管理"
        actionRef={actionRef}
        rowKey="broadcastID"
        columns={columns}
        scroll={{ x: 1200 }}
        search={{ labelWidth: 80 }}
        toolBarRender={() => [
          <Button
            key="create"
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => {
              setCurrentRow(null);
              form.resetFields();
              setEditOpen(true);
            }}
          >
            新建广播
          </Button>,
        ]}
        request={async (params) => {
          const resp = await searchBroadcasts({
            keyword: params.title ?? '',
            status: params.status !== undefined ? Number(params.status) : undefined,
            pagination: {
              pageNumber: params.current ?? 1,
              showNumber: params.pageSize ?? 20,
            },
          });
          return {
            data: resp.data?.broadcasts ?? [],
            total: resp.data?.total ?? 0,
            success: resp.errCode === 0,
          };
        }}
      />

      {/* 创建 / 编辑弹窗 */}
      <Modal
        title={currentRow?.broadcastID ? '编辑广播' : '新建广播'}
        open={editOpen}
        onCancel={() => {
          setEditOpen(false);
          form.resetFields();
        }}
        onOk={handleEditSubmit}
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item
            label="标题"
            name="title"
            rules={[{ required: true, message: '请输入标题' }]}
          >
            <Input placeholder="广播标题" />
          </Form.Item>
          <Form.Item
            label="内容"
            name="content"
            rules={[{ required: true, message: '请输入内容' }]}
          >
            <Input.TextArea rows={5} placeholder="广播正文内容" />
          </Form.Item>
          <Form.Item label="内容类型" name="contentType" initialValue={1}>
            <Select
              options={[
                { label: '纯文本', value: 1 },
                { label: 'Markdown', value: 2 },
              ]}
            />
          </Form.Item>
          <Form.Item label="发送目标" name="sendTo" initialValue="all">
            <Input placeholder='"all" 或逗号分隔的用户ID列表' />
          </Form.Item>
        </Form>
      </Modal>

      {/* 发送确认弹窗（需密码二次验证） */}
      <Modal
        title="确认发送广播"
        open={sendOpen}
        onCancel={() => {
          setSendOpen(false);
          sendForm.resetFields();
        }}
        onOk={handleSendConfirm}
        okText="确认发送"
        okButtonProps={{ danger: true }}
      >
        <p>
          即将发送广播: <strong>{currentRow?.title}</strong>
        </p>
        <p>目标: {currentRow?.sendTo}</p>
        <Form form={sendForm} layout="vertical">
          <Form.Item
            label="管理员密码"
            name="password"
            rules={[{ required: true, message: '请输入密码以确认操作' }]}
          >
            <Input.Password placeholder="输入管理员密码进行二次验证" />
          </Form.Item>
        </Form>
      </Modal>
    </PageContainer>
  );
};

export default BroadcastPage;
