import { cancelMuteGroup, dismissGroup, getGroups, muteGroup, setOfficialGroup } from '@/services/openim';
import type { ActionType, ProColumns } from '@ant-design/pro-components';
import { PageContainer, ProTable } from '@ant-design/pro-components';
import { Avatar, message, Popconfirm, Space, Tag } from 'antd';
import dayjs from 'dayjs';
import React, { useRef, useState } from 'react';

const groupStatusMap: Record<number, { text: string; color: string }> = {
  0: { text: '正常', color: 'green' },
  1: { text: '封禁', color: 'red' },
  2: { text: '已解散', color: 'default' },
  3: { text: '全员禁言', color: 'orange' },
};

const GroupManage: React.FC = () => {
  const actionRef = useRef<ActionType>(null);
  const [officialMap, setOfficialMap] = useState<Record<string, boolean>>({});

  const handleSetOfficial = async (groupID: string, isOfficial: boolean) => {
    const resp = await setOfficialGroup(groupID, isOfficial);
    if (resp.errCode === 0) {
      message.success(isOfficial ? '已设为官方群' : '已取消官方群');
      setOfficialMap((m) => ({ ...m, [groupID]: isOfficial }));
    } else {
      message.error(resp.errMsg);
    }
  };

  const columns: ProColumns<OPENIM.GroupInfo>[] = [
    {
      title: '头像',
      dataIndex: 'faceURL',
      search: false,
      width: 60,
      render: (_, r) => <Avatar src={r.faceURL} size="small">{r.groupName?.[0]}</Avatar>,
    },
    { title: '群ID', dataIndex: 'groupID', copyable: true, width: 200 },
    { title: '群名称', dataIndex: 'groupName', width: 150 },
    { title: '群主ID', dataIndex: 'ownerUserID', width: 180, search: false },
    { title: '成员数', dataIndex: 'memberCount', width: 80, search: false },
    {
      title: '状态',
      dataIndex: 'status',
      search: false,
      width: 90,
      render: (_, r) => {
        const st = groupStatusMap[r.status] || { text: '未知', color: 'default' };
        return <Tag color={st.color}>{st.text}</Tag>;
      },
    },
    {
      title: '创建时间',
      dataIndex: 'createTime',
      search: false,
      width: 170,
      render: (_, r) => r.createTime ? dayjs(r.createTime).format('YYYY-MM-DD HH:mm') : '-',
    },
    {
      title: '官方',
      dataIndex: 'groupID',
      search: false,
      width: 70,
      render: (_, r) => officialMap[r.groupID] ? <Tag color="blue">官方</Tag> : null,
    },
    {
      title: '操作',
      valueType: 'option',
      width: 230,
      render: (_, record) => (
        <Space>
          {officialMap[record.groupID] ? (
            <a onClick={() => handleSetOfficial(record.groupID, false)}>取消官方</a>
          ) : (
            <a onClick={() => handleSetOfficial(record.groupID, true)} style={{ color: '#1677ff' }}>设为官方</a>
          )}
          <Popconfirm
            title="确定解散该群组？此操作不可撤销"
            onConfirm={async () => {
              const resp = await dismissGroup(record.groupID);
              if (resp.errCode === 0) {
                message.success('已解散');
                actionRef.current?.reload();
              } else message.error(resp.errMsg);
            }}
          >
            <a className="ant-typography ant-typography-danger">解散</a>
          </Popconfirm>
          <a onClick={async () => {
            const resp = await muteGroup(record.groupID);
            if (resp.errCode === 0) {
              message.success('已禁言');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}>禁言</a>
          <a onClick={async () => {
            const resp = await cancelMuteGroup(record.groupID);
            if (resp.errCode === 0) {
              message.success('已取消禁言');
              actionRef.current?.reload();
            } else message.error(resp.errMsg);
          }}>取消禁言</a>
        </Space>
      ),
    },
  ];

  return (
    <PageContainer>
      <ProTable<OPENIM.GroupInfo>
        headerTitle="群组列表"
        actionRef={actionRef}
        rowKey="groupID"
        columns={columns}
        scroll={{ x: 'max-content', y: 600 }}
        virtual
        request={async (params) => {
          const resp = await getGroups(
            { pageNumber: params.current || 1, showNumber: params.pageSize || 20 },
            params.groupName,
            params.groupID,
          );
          return {
            data: resp.data?.groups || [],
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

export default GroupManage;
