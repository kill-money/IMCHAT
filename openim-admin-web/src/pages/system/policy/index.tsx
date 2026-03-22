import {
  evalPolicy,
  getPolicyHistory,
  getPolicyRules,
  validatePolicy,
} from '@/services/openim';
import { CheckCircleOutlined, CloseCircleOutlined, PlayCircleOutlined } from '@ant-design/icons';
import { PageContainer } from '@ant-design/pro-components';
import {
  Button,
  Card,
  Col,
  Descriptions,
  Empty,
  Form,
  Input,
  message,
  Row,
  Space,
  Statistic,
  Table,
  Tag,
} from 'antd';
import React, { useCallback, useEffect, useState } from 'react';

const PolicyEngine: React.FC = () => {
  const [rules, setRules] = useState<Array<Record<string, unknown>>>([]);
  const [version, setVersion] = useState(0);
  const [historyVersion, setHistoryVersion] = useState(0);
  const [loading, setLoading] = useState(false);
  const [validateResult, setValidateResult] = useState<{ valid: boolean; error?: string } | null>(null);
  const [evalResult, setEvalResult] = useState<{ matched: boolean } | null>(null);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    try {
      const [rulesResp, historyResp] = await Promise.all([
        getPolicyRules().catch(() => null),
        getPolicyHistory().catch(() => null),
      ]);
      if (rulesResp?.data) {
        setRules(rulesResp.data.rules ?? []);
        setVersion(rulesResp.data.version ?? 0);
      }
      if (historyResp?.data) {
        setHistoryVersion(historyResp.data.currentVersion ?? 0);
      }
    } catch {
      // ignore
    }
    setLoading(false);
  }, []);

  useEffect(() => { fetchAll(); }, [fetchAll]);

  const handleValidate = async (values: { expression: string }) => {
    try {
      const resp = await validatePolicy(values.expression);
      setValidateResult(resp?.data ?? null);
      message.success(resp?.data?.valid ? '表达式有效' : '表达式无效');
    } catch {
      message.error('验证失败');
    }
  };

  const handleEval = async (values: { variables: string }) => {
    try {
      const vars = JSON.parse(values.variables);
      const resp = await evalPolicy(vars);
      setEvalResult(resp?.data ?? null);
      message.success('评估完成');
    } catch (e) {
      message.error('JSON 解析错误或评估失败');
    }
  };

  const ruleColumns = [
    { title: 'ID', dataIndex: 'id', width: 80 },
    { title: '名称', dataIndex: 'name', width: 200 },
    { title: '条件', dataIndex: 'condition', ellipsis: true },
    { title: '优先级', dataIndex: 'priority', width: 80 },
    { title: '状态', dataIndex: 'enabled', width: 80,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? '启用' : '禁用'}</Tag> },
  ];

  return (
    <PageContainer>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic title="策略规则数" value={rules.length} />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic title="当前版本" value={version} />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic title="历史版本" value={historyVersion} />
          </Card>
        </Col>
      </Row>

      <Card title="策略规则" style={{ marginTop: 16 }} loading={loading}
        extra={<Button onClick={fetchAll}>刷新</Button>}>
        {rules.length > 0 ? (
          <Table rowKey="id" dataSource={rules} columns={ruleColumns} pagination={false} size="small" />
        ) : (
          <Empty description="暂无策略规则" />
        )}
      </Card>

      <Row gutter={16} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}>
          <Card title="表达式验证">
            <Form onFinish={handleValidate}>
              <Form.Item name="expression" rules={[{ required: true }]}>
                <Input.TextArea rows={3} placeholder='例如: user.role == "admin"' />
              </Form.Item>
              <Form.Item>
                <Button type="primary" htmlType="submit" icon={<CheckCircleOutlined />}>
                  验证
                </Button>
              </Form.Item>
            </Form>
            {validateResult && (
              <Tag
                icon={validateResult.valid ? <CheckCircleOutlined /> : <CloseCircleOutlined />}
                color={validateResult.valid ? 'success' : 'error'}
              >
                {validateResult.valid ? '表达式有效' : `无效: ${validateResult.error}`}
              </Tag>
            )}
          </Card>
        </Col>
        <Col xs={24} lg={12}>
          <Card title="策略评估测试">
            <Form onFinish={handleEval}>
              <Form.Item name="variables" rules={[{ required: true }]}>
                <Input.TextArea
                  rows={3}
                  placeholder='{"userID":"123","action":"send_message","role":"user"}'
                />
              </Form.Item>
              <Form.Item>
                <Button type="primary" htmlType="submit" icon={<PlayCircleOutlined />}>
                  评估
                </Button>
              </Form.Item>
            </Form>
            {evalResult && (
              <Descriptions bordered size="small">
                <Descriptions.Item label="匹配结果">
                  <Tag color={evalResult.matched ? 'green' : 'orange'}>
                    {evalResult.matched ? '匹配' : '未匹配'}
                  </Tag>
                </Descriptions.Item>
              </Descriptions>
            )}
          </Card>
        </Col>
      </Row>
    </PageContainer>
  );
};

export default PolicyEngine;
