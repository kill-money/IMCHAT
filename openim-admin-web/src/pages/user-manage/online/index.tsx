import { getUsersOnlineStatus, searchUsers } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { PageContainer, ProTable } from '@ant-design/pro-components';
import { Button, message, Tag } from 'antd';
import React, { useRef, useState } from 'react';

const platformMap: Record<number, string> = {
  1: 'iOS', 2: 'Android', 3: 'Windows', 4: 'macOS', 5: 'Web', 6: 'MiniWeb', 7: 'Linux', 8: 'Admin',
};

interface OnlineRow {
  userID: string;
  nickname: string;
  platforms: string[];
}

const OnlineUsers: React.FC = () => {
  const actionRef = useRef<ActionType>(undefined);
  const [data, setData] = useState<OnlineRow[]>([]);
  const [loading, setLoading] = useState(false);

  const columns: ProColumns<OnlineRow>[] = [
    { title: '用户ID', dataIndex: 'userID', width: 200 },
    { title: '昵称', dataIndex: 'nickname', width: 150 },
    {
      title: '在线平台',
      dataIndex: 'platforms',
      render: (_, r) => r.platforms.map((p) => <Tag color="green" key={p}>{p}</Tag>),
    },
  ];

  const fetchOnlineUsers = async () => {
    setLoading(true);
    try {
      const usersResp = await searchUsers({
        pagination: { pageNumber: 1, showNumber: 100 },
      });
      if (usersResp.errCode !== 0 || !usersResp.data?.users?.length) {
        setData([]);
        setLoading(false);
        return;
      }
      const userIDs = usersResp.data.users.map((u) => u.userID);
      const statusResp = await getUsersOnlineStatus(userIDs);
      const users = usersResp.data.users;
      const statusList = statusResp.data?.statusList || [];
      const onlineRows: OnlineRow[] = [];
      for (const st of statusList) {
        if (st.status === 1 || (st.platformIDs && st.platformIDs.length > 0)) {
          const user = users.find((u) => u.userID === st.userID);
          onlineRows.push({
            userID: st.userID,
            nickname: user?.nickname || st.userID,
            platforms: (st.platformIDs || []).map((p) => platformMap[p] || `P${p}`),
          });
        }
      }
      setData(onlineRows);
    } catch (e) {
      message.error('获取在线状态失败');
    }
    setLoading(false);
  };

  return (
    <PageContainer>
      <ProTable<OnlineRow>
        headerTitle="在线用户"
        columns={columns}
        dataSource={data}
        loading={loading}
        rowKey="userID"
        search={false}
        toolBarRender={() => [
          <Button key="refresh" type="primary" loading={loading} onClick={fetchOnlineUsers}>
            刷新在线状态
          </Button>,
        ]}
        pagination={{ defaultPageSize: 20 }}
      />
    </PageContainer>
  );
};

export default OnlineUsers;
