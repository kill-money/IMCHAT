import {
  checkDistRateLimit,
  checkRateLimit,
  getDistRateLimitStats,
  getRateLimitStats,
  getRuleVersion,
  getShardList,
} from '@/services/openim';
import { ReloadOutlined, SearchOutlined } from '@ant-design/icons';
import { PageContainer } from '@ant-design/pro-components';
import {
  Button,
  Card,
  Col,
  Descriptions,
  Form,
  Input,
  message,
  Row,
  Select,
  Space,
  Statistic,
  Table,
  Tag,
} from 'antd';
import React, { useCallback, useEffect, useState } from 'react';

const RateLimitManage: React.FC = () => {
  const [stats, setStats] = useState<{
    totalAllowed: number;
    totalDenied: number;
    rules: Array<{ level: string; identity: string; allowed: number; denied: number }>;
  }>({ totalAllowed: 0, totalDenied: 0, rules: [] });
  const [distStats, setDistStats] = useState<Record<string, unknown>>({});
  const [ruleVersion, setRuleVersion] = useState(0);
  const [shards, setShards] = useState<Array<{ key: string; description?: string }>>([]);
  const [loading, setLoading] = useState(false);
  const [checkResult, setCheckResult] = useState<string | null>(null);

  const fetchAll = useCallback(async () => {
    setLoading(true);
    try {
      const [statsResp, distResp, versionResp, shardsResp] = await Promise.all([
        getRateLimitStats().catch(() => null),
        getDistRateLimitStats().catch(() => null),
        getRuleVersion().catch(() => null),
        getShardList().catch(() => null),
      ]);
      if (statsResp?.data) setStats(statsResp.data as typeof stats);
      if (distResp?.data) setDistStats(distResp.data);
      if (versionResp?.data) setRuleVersion(versionResp.data.version);
      if (shardsResp?.data) setShards(shardsResp.data.shards ?? []);
    } catch {
      // ignore
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchAll();
  }, [fetchAll]);

  const handleCheck = async (values: { level: string; identity: string }) => {
    try {
      const [local, dist] = await Promise.all([
        checkRateLimit(values.level, values.identity).catch(() => null),
        checkDistRateLimit(values.level, values.identity).catch(() => null),
      ]);
      const localAllowed = local?.data?.allowed ?? 'N/A';
      const distAllowed = dist?.data?.allowed ?? 'N/A';
      setCheckResult(`本地: ${localAllowed ? '允许' : '拒绝'} | 分布式: ${distAllowed ? '允许' : '拒绝'}`);
      message.success('检查完成');
    } catch {
      message.error('检查失败');
    }
  };

  return (
    <PageContainer>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic title="总允许请求" value={stats.totalAllowed} valueStyle={{ color: '#52c41a' }} />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic title="总拒绝请求" value={stats.totalDenied} valueStyle={{ color: '#ff4d4f' }} />
          </Card>
        </Col>
        <Col xs={24} sm={8}>
          <Card>
            <Statistic title="规则引擎版本" value={ruleVersion} />
          </Card>
        </Col>
      </Row>

      <Card title="限流检查" style={{ marginTop: 16 }}>
        <Form layout="inline" onFinish={handleCheck}>
          <Form.Item name="level" rules={[{ required: true }]} initialValue="user">
            <Select style={{ width: 120 }}>
              <Select.Option value="user">用户级</Select.Option>
              <Select.Option value="group">群组级</Select.Option>
              <Select.Option value="system">系统级</Select.Option>
            </Select>
          </Form.Item>
          <Form.Item name="identity" rules={[{ required: true, message: '输入用户/群组ID' }]}>
            <Input placeholder="用户ID 或 群组ID" style={{ width: 240 }} />
          </Form.Item>
          <Form.Item>
            <Space>
              <Button type="primary" htmlType="submit" icon={<SearchOutlined />}>检查</Button>
              <Button icon={<ReloadOutlined />} onClick={fetchAll} loading={loading}>刷新</Button>
            </Space>
          </Form.Item>
        </Form>
        {checkResult && (
          <div style={{ marginTop: 12 }}>
            <Tag color="blue">{checkResult}</Tag>
          </div>
        )}
      </Card>

      <Card title="分片信息" style={{ marginTop: 16 }}>
        <Table
          rowKey="key"
          dataSource={shards}
          columns={[
            { title: '分片键', dataIndex: 'key', width: 200 },
            { title: '描述', dataIndex: 'description', render: (v: string) => v || '-' },
          ]}
          pagination={false}
          size="small"
        />
      </Card>

      <Card title="分布式限流详情" style={{ marginTop: 16 }}>
        <Descriptions column={2} bordered size="small">
          {Object.entries(distStats).map(([key, value]) => (
            <Descriptions.Item key={key} label={key}>
              {typeof value === 'object' ? JSON.stringify(value) : String(value)}
            </Descriptions.Item>
          ))}
        </Descriptions>
      </Card>
    </PageContainer>
  );
};

export default RateLimitManage;
