import { useState, useEffect, useCallback } from "react";
import { PageContainer } from "@ant-design/pro-components";
import { Table, Switch, Tag, message } from "antd";
import type { ColumnsType } from "antd/es/table";
import {
  getFeatureToggles,
  setFeatureToggle,
  type FeatureToggle,
} from "@/services/openim/api";

export default function FeatureTogglePage() {
  const [toggles, setToggles] = useState<FeatureToggle[]>([]);
  const [loading, setLoading] = useState(false);
  const [switchingKey, setSwitchingKey] = useState<string | null>(null);

  const fetchToggles = useCallback(async () => {
    setLoading(true);
    try {
      const res = await getFeatureToggles();
      setToggles(res.data?.toggles ?? []);
    } catch {
      message.error("加载功能开关失败");
    }
    setLoading(false);
  }, []);

  useEffect(() => {
    fetchToggles();
  }, [fetchToggles]);

  const handleToggle = async (featureKey: string, enabled: boolean) => {
    setSwitchingKey(featureKey);
    try {
      await setFeatureToggle(featureKey, enabled);
      message.success(`已${enabled ? "启用" : "禁用"} ${featureKey}`);
      fetchToggles();
    } catch {
      message.error("操作失败");
    }
    setSwitchingKey(null);
  };

  const columns: ColumnsType<FeatureToggle> = [
    {
      title: "功能标识",
      dataIndex: "featureKey",
      width: 200,
      render: (v: string) => <Tag>{v}</Tag>,
    },
    {
      title: "说明",
      dataIndex: "description",
      ellipsis: true,
    },
    {
      title: "状态",
      dataIndex: "enabled",
      width: 100,
      render: (v: boolean, record) => (
        <Switch
          checked={v}
          loading={switchingKey === record.featureKey}
          onChange={(checked) => handleToggle(record.featureKey, checked)}
        />
      ),
    },
    {
      title: "更新时间",
      dataIndex: "updatedAt",
      width: 180,
    },
    {
      title: "操作人",
      dataIndex: "updatedBy",
      width: 140,
    },
  ];

  return (
    <PageContainer>
      <Table
        rowKey="featureKey"
        columns={columns}
        dataSource={toggles}
        loading={loading}
        pagination={false}
      />
    </PageContainer>
  );
}
