import { getGroupCreateStats, getLoginUserCount, getNewUserCount, getUserRegisterStats } from '@/services/openim';
import { LoginOutlined, MessageOutlined, TeamOutlined, UsergroupAddOutlined } from '@ant-design/icons';
import { PageContainer, StatisticCard } from '@ant-design/pro-components';
import { Col, Row } from 'antd';
import dayjs from 'dayjs';
import React, { useEffect, useState } from 'react';

const Dashboard: React.FC = () => {
  const [stats, setStats] = useState({
    totalUsers: 0,
    todayNewUsers: 0,
    todayActiveUsers: 0,
    totalGroups: 0,
  });

  useEffect(() => {
    const today = dayjs().format('YYYY-MM-DD');
    const weekAgo = dayjs().subtract(7, 'day').format('YYYY-MM-DD');

    Promise.all([
      getNewUserCount(weekAgo, today).catch(() => null),
      getLoginUserCount(weekAgo, today).catch(() => null),
      getUserRegisterStats(weekAgo, today).catch(() => null),
      getGroupCreateStats(weekAgo, today).catch(() => null),
    ]).then(([newUser, loginUser, regStats, groupStats]) => {
      setStats({
        totalUsers: newUser?.data?.total ?? 0,
        todayNewUsers: newUser?.data?.before ?? 0,
        todayActiveUsers: loginUser?.data?.before ?? 0,
        totalGroups: groupStats?.data?.total ?? 0,
      });
    });
  }, []);

  return (
    <PageContainer>
      <Row gutter={[16, 16]}>
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
    </PageContainer>
  );
};

export default Dashboard;
