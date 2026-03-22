import { useState, useEffect, useCallback } from "react";
import { PageContainer } from "@ant-design/pro-components";
import {
  Table,
  Button,
  Space,
  Modal,
  Form,
  Input,
  Select,
  Switch,
  Popconfirm,
  Tag,
  message,
} from "antd";
import { PlusOutlined } from "@ant-design/icons";
import type { ColumnsType } from "antd/es/table";
import {
  getFilterRules,
  upsertFilterRule,
  deleteFilterRule,
  type ContentFilterRule,
} from "@/services/openim/api";

const ruleTypeOptions = [
  { label: "手机号", value: "phone" },
  { label: "微信号", value: "wechat" },
  { label: "QQ号", value: "qq" },
  { label: "邮箱", value: "email" },
  { label: "自定义", value: "custom" },
];

const actionOptions = [
  { label: "拦截", value: "block" },
  { label: "警告", value: "warn" },
  { label: "掩码", value: "mask" },
];

const actionColorMap: Record<string, string> = {
  block: "red",
  warn: "orange",
  mask: "blue",
};

export default function ContentFilterPage() {
  const [rules, setRules] = useState<ContentFilterRule[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editingRule, setEditingRule] = useState<ContentFilterRule | null>(null);
  const [form] = Form.useForm();

  const fetchRules = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getFilterRules();
      setRules(res.data?.rules ?? []);
    } catch {
      message.error("加载过滤规则失败");
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchRules();
  }, [fetchRules]);

  const handleAdd = () => {
    setEditingRule(null);
    form.resetFields();
    form.setFieldsValue({ enabled: true, action: "block", ruleType: "custom" });
    setModalOpen(true);
  };

  const handleEdit = (rule: ContentFilterRule) => {
    setEditingRule(rule);
    form.setFieldsValue(rule);
    setModalOpen(true);
  };

  const handleDelete = async (ruleID: string) => {
    try {
      await deleteFilterRule(ruleID);
      message.success("已删除");
      fetchRules();
    } catch {
      message.error("删除失败");
    }
  };

  const handleSubmit = async () => {
    const values = await form.validateFields();
    try {
      await upsertFilterRule({
        ...values,
        ruleID: editingRule?.ruleID,
      });
      message.success(editingRule ? "已更新" : "已添加");
      setModalOpen(false);
      fetchRules();
    } catch {
      message.error("保存失败");
    }
  };

  const columns: ColumnsType<ContentFilterRule> = [
    {
      title: "规则类型",
      dataIndex: "ruleType",
      width: 100,
      render: (v: string) =>
        ruleTypeOptions.find((o) => o.value === v)?.label ?? v,
    },
    {
      title: "匹配模式",
      dataIndex: "pattern",
      ellipsis: true,
      render: (v: string) => <code>{v}</code>,
    },
    {
      title: "触发动作",
      dataIndex: "action",
      width: 90,
      render: (v: string) => (
        <Tag color={actionColorMap[v] ?? "default"}>
          {actionOptions.find((o) => o.value === v)?.label ?? v}
        </Tag>
      ),
    },
    {
      title: "状态",
      dataIndex: "enabled",
      width: 80,
      render: (v: boolean) =>
        v ? <Tag color="green">启用</Tag> : <Tag>禁用</Tag>,
    },
    {
      title: "操作",
      width: 150,
      render: (_, record) => (
        <Space>
          <Button type="link" size="small" onClick={() => handleEdit(record)}>
            编辑
          </Button>
          <Popconfirm title="确定删除？" onConfirm={() => handleDelete(record.ruleID)}>
            <Button type="link" size="small" danger>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  return (
    <PageContainer>
      <div style={{ marginBottom: 16 }}>
        <Button type="primary" icon={<PlusOutlined />} onClick={handleAdd}>
          添加规则
        </Button>
      </div>
      <Table
        rowKey="ruleID"
        columns={columns}
        dataSource={rules}
        loading={loading}
        pagination={{ pageSize: 20, showTotal: (t) => `共 ${t} 条` }}
      />
      <Modal
        title={editingRule ? "编辑规则" : "添加规则"}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        destroyOnClose
      >
        <Form form={form} layout="vertical">
          <Form.Item name="ruleType" label="规则类型" rules={[{ required: true }]}>
            <Select options={ruleTypeOptions} />
          </Form.Item>
          <Form.Item
            name="pattern"
            label="匹配模式（正则表达式）"
            rules={[{ required: true, message: "请输入正则表达式" }]}
          >
            <Input placeholder="例如: \b1[3-9]\d{9}\b" />
          </Form.Item>
          <Form.Item name="action" label="触发动作" rules={[{ required: true }]}>
            <Select options={actionOptions} />
          </Form.Item>
          <Form.Item name="description" label="备注">
            <Input.TextArea rows={2} />
          </Form.Item>
          <Form.Item name="enabled" label="启用" valuePropName="checked">
            <Switch />
          </Form.Item>
        </Form>
      </Modal>
    </PageContainer>
  );
}
