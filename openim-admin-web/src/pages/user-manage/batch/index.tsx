/**
 * 批量创建用户页面（二开）
 *
 * 支持：前缀+序号规则生成账号、统一密码、可选角色；
 * 提交后展示完整创建结果列表。
 */
import { batchCreateUsers } from '@/services/openim';
import { ProColumns, ProTable } from '@ant-design/pro-components';
import {
  Alert,
  Button,
  Card,
  Col,
  Divider,
  Form,
  Input,
  InputNumber,
  Row,
  Select,
  Space,
  Steps,
  Typography,
} from 'antd';
import React, { useState } from 'react';

const { Title, Text, Paragraph } = Typography;

interface CreatedUser {
  username: string;
}

const BatchCreatePage: React.FC = () => {
  const [form] = Form.useForm();
  const [submitting, setSubmitting] = useState(false);
  const [result, setResult] = useState<{
    created: number;
    skipped: number;
    usernames: string[];
  } | null>(null);
  const [currentStep, setCurrentStep] = useState(0);

  const handleSubmit = async () => {
    try {
      const values = await form.validateFields();
      setSubmitting(true);
      const resp = await batchCreateUsers({
        start_username: values.start_username,
        count: values.count,
        password: values.password,
        role: values.role,
      });
      setResult(resp?.data ?? null);
      setCurrentStep(1);
    } catch (e: any) {
      // validation error or API error handled by form / request interceptor
    } finally {
      setSubmitting(false);
    }
  };

  const handleReset = () => {
    form.resetFields();
    setResult(null);
    setCurrentStep(0);
  };

  const columns: ProColumns<CreatedUser>[] = [
    {
      title: '序号',
      valueType: 'index',
      width: 60,
    },
    {
      title: '用户名',
      dataIndex: 'username',
      copyable: true,
    },
  ];

  return (
    <div style={{ maxWidth: 900, margin: '0 auto' }}>
      <Title level={4}>批量创建用户</Title>
      <Paragraph type="secondary">
        按前缀+起始编号规则生成指定数量的账号；每批次最多 999 个。
        <br />
        例如：起始用户名 <Text code>bab001</Text>，数量 <Text code>10</Text>
        {' '}→ 创建 bab001 ~ bab010。
      </Paragraph>

      <Steps
        current={currentStep}
        style={{ marginBottom: 24 }}
        items={[
          { title: '填写参数' },
          { title: '查看结果' },
        ]}
      />

      {currentStep === 0 && (
        <Card>
          <Form
            form={form}
            layout="vertical"
            initialValues={{ count: 10, role: '' }}
          >
            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  name="start_username"
                  label="起始用户名"
                  rules={[
                    { required: true, message: '请输入起始用户名' },
                    {
                      pattern: /^.*\d+$/,
                      message: '用户名须以数字结尾，如 user001',
                    },
                  ]}
                  extra="格式：任意前缀 + 数字后缀，如 user001、bab10"
                >
                  <Input placeholder="bab001" maxLength={32} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item
                  name="count"
                  label="创建数量"
                  rules={[
                    { required: true, message: '请输入数量' },
                    {
                      type: 'number',
                      min: 1,
                      max: 999,
                      message: '数量须在 1 ~ 999 之间',
                    },
                  ]}
                >
                  <InputNumber min={1} max={999} style={{ width: '100%' }} />
                </Form.Item>
              </Col>
            </Row>

            <Row gutter={16}>
              <Col span={12}>
                <Form.Item
                  name="password"
                  label="统一密码"
                  rules={[
                    { required: true, message: '请输入密码' },
                    { min: 6, message: '密码不少于 6 位' },
                  ]}
                  extra="所有新用户使用同一密码，建议首次登录后强制修改"
                >
                  <Input.Password placeholder="至少 6 位" maxLength={32} />
                </Form.Item>
              </Col>
              <Col span={12}>
                <Form.Item name="role" label="用户角色（可选）">
                  <Select
                    allowClear
                    placeholder="默认为普通用户"
                    options={[
                      { label: '普通用户', value: '' },
                      { label: '操作员', value: 'operator' },
                      { label: '管理员', value: 'admin' },
                    ]}
                  />
                </Form.Item>
              </Col>
            </Row>

            <Divider />

            <Space>
              <Button
                type="primary"
                loading={submitting}
                onClick={handleSubmit}
              >
                开始创建
              </Button>
              <Button onClick={() => form.resetFields()}>重置</Button>
            </Space>
          </Form>
        </Card>
      )}

      {currentStep === 1 && result && (
        <>
          <Alert
            type="success"
            showIcon
            message={
              <>
                创建完成 — 成功 <Text strong>{result.created}</Text> 个
                {result.skipped > 0 && (
                  <>
                    ，跳过（已存在）<Text strong>{result.skipped}</Text> 个
                  </>
                )}
              </>
            }
            style={{ marginBottom: 16 }}
          />

          <ProTable<CreatedUser>
            rowKey="username"
            dataSource={result.usernames.map((u) => ({ username: u }))}
            columns={columns}
            search={false}
            pagination={{ pageSize: 20 }}
            toolBarRender={() => [
              <Button key="again" type="primary" onClick={handleReset}>
                再次创建
              </Button>,
            ]}
            headerTitle={`已创建账号列表（共 ${result.created} 个）`}
          />
        </>
      )}
    </div>
  );
};

export default BatchCreatePage;
