import {
  getClientConfig,
  getDashboardStats,
  getGroupCreateStats,
  getLoginUserCount,
  getNewUserCount,
} from '@/services/openim';
import {
  CloudServerOutlined,
  LoginOutlined,
  MessageOutlined,
  SettingOutlined,
  TeamOutlined,
  UsergroupAddOutlined,
  WifiOutlined,
} from '@ant-design/icons';
import { PageContainer, StatisticCard } from '@ant-design/pro-components';
import { Col, Descriptions, Row, Spin, Tag } from 'antd';
import dayjs from 'dayjs';
import React, { useEffect, useRef, useState } from 'react';

const ONLINE_REFRESH_MS = 10_000; // 10 秒刷新在线人数

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    todayNewUsers: 0,
    todayActiveUsers: 0,
    totalGroups: 0,
  });
  const [onlineCount, setOnlineCount] = useState(0);
  const [clientConfig, setClientConfig] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(true);
  const timerRef = useRef<ReturnType<typeof setInterval> | undefined>(undefined);

  // 拉取在线用户数（轻量 API，可高频轮询）
  const fetchOnlineCount = () => {
    getDashboardStats()
      .then((res) => {
        if (res?.data) {
          setOnlineCount(res.data.onlineUserCount ?? 0);
        }
      })
      .catch(() => {});
  };

  useEffect(() => {
    const now = dayjs();
    const startMs = now.subtract(7, 'day').startOf('day').valueOf();
    const endMs = now.endOf('day').valueOf();

    Promise.all([
      getNewUserCount(startMs, endMs).catch(() => null),
      getLoginUserCount(startMs, endMs).catch(() => null),
      getGroupCreateStats(now.subtract(7, 'day').format('YYYY-MM-DD'), now.format('YYYY-MM-DD')).catch(() => null),
      getClientConfig().catch(() => null),
      getDashboardStats().catch(() => null),
    ]).then(([newUser, loginUser, groupStats, configResp, dashResp]) => {
      const weeklyNewUsers = newUser?.data?.date_count
        ? Object.values(newUser.data.date_count).reduce((a: number, b: number) => a + b, 0)
        : 0;
      setStats({
        totalUsers: newUser?.data?.total ?? 0,
        todayNewUsers: weeklyNewUsers,
        todayActiveUsers: loginUser?.data?.loginCount ?? 0,
        totalGroups: groupStats?.data?.total ?? 0,
      });
      setOnlineCount(dashResp?.data?.onlineUserCount ?? 0);
      if (configResp?.data?.config) {
        setClientConfig(configResp.data.config);
      }
      setLoading(false);
    });

    // 每 10 秒刷新在线用户数
    timerRef.current = setInterval(fetchOnlineCount, ONLINE_REFRESH_MS);
    return () => {
      if (timerRef.current) clearInterval(timerRef.current);
    };
  }, []);

  return (
    <PageContainer>
      <Row gutter={[16, 16]}>
        <Col xs={24} sm={12} lg={6}>
          <StatisticCard
            statistic={{
              title: '实时在线用户',
              value: onlineCount,
              icon: <WifiOutlined style={{ fontSize: 32, color: '#13c2c2' }} />,
              description: <span style={{ color: '#999', fontSize: 12 }}>每10秒自动刷新</span>,
            }}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatisticCard
            statistic={{
              title: '注册用户总数',
              value: stats.totalUsers,
              icon: <TeamOutlined style={{ fontSize: 32, color: '#1890ff' }} />,
            }}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatisticCard
            statistic={{
              title: '近7日新增用户',
              value: stats.todayNewUsers,
              icon: <UsergroupAddOutlined style={{ fontSize: 32, color: '#52c41a' }} />,
            }}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatisticCard
            statistic={{
              title: '近7日活跃用户',
              value: stats.todayActiveUsers,
              icon: <LoginOutlined style={{ fontSize: 32, color: '#faad14' }} />,
            }}
          />
        </Col>
        <Col xs={24} sm={12} lg={6}>
          <StatisticCard
            statistic={{
              title: '群组总数',
              value: stats.totalGroups,
              icon: <MessageOutlined style={{ fontSize: 32, color: '#722ed1' }} />,
            }}
          />
        </Col>
      </Row>

      {/* 客户端配置概览 */}
      <Row gutter={[16, 16]} style={{ marginTop: 24 }}>
        <Col xs={24} lg={12}>
          <Spin spinning={loading}>
            <StatisticCard
              title={
                <span>
                  <SettingOutlined style={{ marginRight: 8 }} />
                  客户端配置
                </span>
              }
              chart={
                Object.keys(clientConfig).length > 0 ? (
                  <Descriptions column={1} size="small" bordered>
                    {Object.entries(clientConfig).map(([key, value]) => (
                      <Descriptions.Item key={key} label={key}>
                        {value === '0' || value === '1' ? (
                          <Tag color={value === '1' ? 'green' : 'default'}>
                            {value === '1' ? '启用' : '禁用'}
                          </Tag>
                        ) : (
                          value
                        )}
                      </Descriptions.Item>
                    ))}
                  </Descriptions>
                ) : (
                  <span style={{ color: '#999' }}>暂无配置项</span>
                )
              }
            />
          </Spin>
        </Col>
        <Col xs={24} lg={12}>
          <StatisticCard
            title={
              <span>
                <CloudServerOutlined style={{ marginRight: 8 }} />
                系统状态
              </span>
            }
            chart={
              <Descriptions column={1} size="small" bordered>
                <Descriptions.Item label="IM Server">
                  <Tag color="green">运行中</Tag> :10001 / :10002
                </Descriptions.Item>
                <Descriptions.Item label="Chat API">
                  <Tag color="green">运行中</Tag> :10008
                </Descriptions.Item>
                <Descriptions.Item label="Admin API">
                  <Tag color="green">运行中</Tag> :10009
                </Descriptions.Item>
                <Descriptions.Item label="未登录用户数">
                  {stats.totalUsers - stats.todayActiveUsers}
                </Descriptions.Item>
              </Descriptions>
            }
          />
        </Col>
      </Row>
    </PageContainer>
  );
};

export default Dashboard;
