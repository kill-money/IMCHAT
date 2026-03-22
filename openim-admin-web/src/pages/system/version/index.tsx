import {
  addApplicationVersion,
  deleteApplicationVersion,
  pageApplicationVersions,
  updateApplicationVersion,
} from '@/services/openim';
import { PlusOutlined } from '@ant-design/icons';
import { PageContainer } from '@ant-design/pro-components';
import {
  Button,
  Form,
  Input,
  message,
  Modal,
  Popconfirm,
  Select,
  Space,
  Switch,
  Table,
  Tag,
} from 'antd';
import dayjs from 'dayjs';
import React, { useCallback, useEffect, useState } from 'react';

const PLATFORMS = [
  { label: 'Android', value: 'android' },
  { label: 'iOS', value: 'ios' },
  { label: 'Windows', value: 'windows' },
  { label: 'macOS', value: 'macos' },
  { label: 'Linux', value: 'linux' },
  { label: 'Web', value: 'web' },
];

const VersionManage: React.FC = () => {
  const [data, setData] = useState<OPENIM.ApplicationVersion[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(false);
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [editing, setEditing] = useState<OPENIM.ApplicationVersion | null>(null);
  const [form] = Form.useForm();

  const fetchData = useCallback(async (pageNum = 1) => {
    setLoading(true);
    try {
      const resp = await pageApplicationVersions({
        pagination: { pageNumber: pageNum, showNumber: 10 },
      });
      setData(resp?.data?.versions ?? []);
      setTotal(resp?.data?.total ?? 0);
    } catch {
      // ignore
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchData(page);
  }, [page, fetchData]);

  const handleAdd = () => {
    setEditing(null);
    form.resetFields();
    setModalOpen(true);
  };

  const handleEdit = (record: OPENIM.ApplicationVersion) => {
    setEditing(record);
    form.setFieldsValue(record);
    setModalOpen(true);
  };

  const handleDelete = async (ids: string[]) => {
    await deleteApplicationVersion(ids);
    message.success('删除成功');
    fetchData(page);
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    if (editing) {
      await updateApplicationVersion({ id: editing.id, ...values });
      message.success('更新成功');
    } else {
      await addApplicationVersion(values);
      message.success('添加成功');
    }
    setModalOpen(false);
    fetchData(page);
  };

  const columns = [
    { title: '平台', dataIndex: 'platform', width: 100,
      render: (v: string) => <Tag color="blue">{v}</Tag> },
    { title: '版本号', dataIndex: 'version', width: 120 },
    { title: '更新说明', dataIndex: 'text', ellipsis: true },
    { title: '下载地址', dataIndex: 'url', ellipsis: true,
      render: (v: string) => <a href={v} target="_blank" rel="noreferrer">{v}</a> },
    { title: '强制更新', dataIndex: 'force', width: 90,
      render: (v: boolean) => <Tag color={v ? 'red' : 'default'}>{v ? '是' : '否'}</Tag> },
    { title: '最新版', dataIndex: 'latest', width: 80,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? '是' : '否'}</Tag> },
    { title: '热更新', dataIndex: 'hot', width: 80,
      render: (v: boolean) => <Tag color={v ? 'orange' : 'default'}>{v ? '是' : '否'}</Tag> },
    { title: '创建时间', dataIndex: 'createTime', width: 170,
      render: (v: number) => v ? dayjs(v).format('YYYY-MM-DD HH:mm:ss') : '-' },
    {
      title: '操作', width: 150,
      render: (_: unknown, record: OPENIM.ApplicationVersion) => (
        <Space>
          <a onClick={() => handleEdit(record)}>编辑</a>
          <Popconfirm title="确认删除？" onConfirm={() => handleDelete([record.id])}>
            <a style={{ color: '#ff4d4f' }}>删除</a>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <PageContainer>
      <div style={{ marginBottom: 16 }}>
        <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd}>
          添加版本
        </Button>
      </div>
      <Table
        rowKey="id"
        columns={columns}
        dataSource={data}
        loading={loading}
        pagination={{
          current: page,
          total,
          pageSize: 10,
          onChange: setPage,
        }}
      />
      <Modal
        title={editing ? '编辑版本' : '添加版本'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        width={600}
      >
        <Form form={form} layout="vertical">
          <Form.Item name="platform" label="平台" rules={[{ required: true }]}>
            <Select options={PLATFORMS} />
          </Form.Item>
          <Form.Item name="version" label="版本号" rules={[{ required: true }]}>
            <Input placeholder="例如: 1.0.0" />
          </Form.Item>
          <Form.Item name="url" label="下载地址" rules={[{ required: true, type: 'url' }]}>
            <Input placeholder="https://..." />
          </Form.Item>
          <Form.Item name="text" label="更新说明" rules={[{ required: true }]}>
            <Input.TextArea rows={3} />
          </Form.Item>
          <Space size="large">
            <Form.Item name="force" label="强制更新" valuePropName="checked">
              <Switch />
            </Form.Item>
            <Form.Item name="latest" label="最新版本" valuePropName="checked">
              <Switch />
            </Form.Item>
            <Form.Item name="hot" label="热更新" valuePropName="checked">
              <Switch />
            </Form.Item>
          </Space>
        </Form>
      </Modal>
    </PageContainer>
  );
};

export default VersionManage;
