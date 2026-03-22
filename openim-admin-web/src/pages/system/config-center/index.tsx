/**
 * 配置中心（仅 etcd 模式支持热修改 & 热重启）
 *
 * 后端路由（均在 /config/* 下）:
 *   POST /config/get_config_list          — 获取所有配置文件名列表
 *   POST /config/get_config               — 读取指定配置（JSON 字符串）
 *   POST /config/set_config               — 保存指定配置
 *   POST /config/reset_config             — 重置到默认值
 *   POST /config/get_enable_config_manager — 是否启用配置管理
 *   POST /config/set_enable_config_manager — 开关配置管理功能
 */
import {
  getConfig,
  getConfigList,
  getEnableConfigManager,
  resetConfig,
  setConfig,
  setEnableConfigManager,
} from '@/services/openim';
import {
  ReloadOutlined,
  SaveOutlined,
  SettingOutlined,
} from '@ant-design/icons';
import { PageContainer } from '@ant-design/pro-components';
import {
  Alert,
  Button,
  Card,
  Col,
  Descriptions,
  Input,
  message,
  Popconfirm,
  Row,
  Select,
  Skeleton,
  Space,
  Switch,
  Tag,
  Typography,
} from 'antd';
import React, { useCallback, useEffect, useState } from 'react';

const { TextArea } = Input;

const ConfigCenter: React.FC = () => {
  const [configNames, setConfigNames] = useState<string[]>([]);
  const [environment, setEnvironment] = useState('');
  const [version, setVersion] = useState('');
  const [selected, setSelected] = useState<string>('');
  const [content, setContent] = useState('');
  const [originalContent, setOriginalContent] = useState('');
  const [loading, setLoading] = useState(false);
  const [saving, setSaving] = useState(false);
  const [enabled, setEnabled] = useState(false);
  const [initLoading, setInitLoading] = useState(true);

  const isDirty = content !== originalContent;

  // ─── 初始化：检查功能状态 & 获取列表 ─────────────────────────────
  const init = useCallback(async () => {
    setInitLoading(true);
    try {
      const [statusResp, listResp] = await Promise.all([
        getEnableConfigManager(),
        getConfigList(),
      ]);
      if (statusResp.errCode === 0) setEnabled(statusResp.data?.enable ?? false);
      if (listResp.errCode === 0) {
        setConfigNames(listResp.data?.configNames ?? []);
        setEnvironment(listResp.data?.environment ?? '');
        setVersion(listResp.data?.version ?? '');
      }
    } finally {
      setInitLoading(false);
    }
  }, []);

  useEffect(() => {
    init();
  }, [init]);

  // ─── 加载配置内容 ─────────────────────────────────────────────────
  const loadConfig = useCallback(async (name: string) => {
    if (!name) return;
    setLoading(true);
    setContent('');
    setOriginalContent('');
    try {
      const resp = await getConfig(name);
      if (resp.errCode === 0) {
        const text = typeof resp.data === 'string' ? resp.data : JSON.stringify(resp.data, null, 2);
        setContent(text);
        setOriginalContent(text);
      } else {
        message.error(resp.errMsg || '获取配置失败');
      }
    } finally {
      setLoading(false);
    }
  }, []);

  // ─── 保存 ─────────────────────────────────────────────────────────
  const handleSave = async () => {
    if (!selected) return;
    setSaving(true);
    try {
      const resp = await setConfig(selected, content);
      if (resp.errCode === 0) {
        message.success('保存成功');
        setOriginalContent(content);
      } else {
        message.error(resp.errMsg || '保存失败');
      }
    } finally {
      setSaving(false);
    }
  };

  // ─── 重置 ─────────────────────────────────────────────────────────
  const handleReset = async () => {
    if (!selected) return;
    const resp = await resetConfig(selected);
    if (resp.errCode === 0) {
      message.success('已重置为默认值');
      loadConfig(selected);
    } else {
      message.error(resp.errMsg || '重置失败');
    }
  };

  // ─── 开关配置管理功能 ─────────────────────────────────────────────
  const handleToggle = async (val: boolean) => {
    const resp = await setEnableConfigManager(val);
    if (resp.errCode === 0) {
      setEnabled(val);
      message.success(val ? '配置管理已启用' : '配置管理已禁用');
    } else {
      message.error(resp.errMsg || '操作失败');
    }
  };

  return (
    <PageContainer>
      <Space direction="vertical" size="large" style={{ width: '100%' }}>
        {/* 环境信息卡 */}
        <Card size="small" loading={initLoading}>
          <Row justify="space-between" align="middle">
            <Col>
              <Descriptions size="small" column={3}>
                {environment && (
                  <Descriptions.Item label="运行环境">
                    <Tag color={environment === 'etcd' ? 'blue' : 'default'}>
                      {environment}
                    </Tag>
                  </Descriptions.Item>
                )}
                {version && (
                  <Descriptions.Item label="服务版本">
                    <Tag>{version}</Tag>
                  </Descriptions.Item>
                )}
                <Descriptions.Item label="配置管理">
                  <Switch
                    checked={enabled}
                    onChange={handleToggle}
                    checkedChildren="已启用"
                    unCheckedChildren="已禁用"
                  />
                </Descriptions.Item>
              </Descriptions>
            </Col>
            <Col>
              <Button icon={<ReloadOutlined />} onClick={init} disabled={initLoading}>
                刷新
              </Button>
            </Col>
          </Row>
        </Card>

        {!enabled && !initLoading && (
          <Alert
            type="warning"
            showIcon
            message="配置管理功能未启用"
            description="当前服务以文件模式运行，配置管理功能仅在 etcd 部署模式下可用。如需启用，请先切换部署模式并重启服务，或联系运维人员。"
          />
        )}

        {/* 配置编辑区 */}
        <Card
          title={
            <Space>
              <SettingOutlined />
              配置编辑器
              {isDirty && <Tag color="orange">未保存</Tag>}
            </Space>
          }
          extra={
            <Space>
              <Select
                placeholder="选择配置文件"
                style={{ width: 260 }}
                value={selected || undefined}
                onChange={(v) => {
                  setSelected(v);
                  loadConfig(v);
                }}
                options={configNames.map((n) => ({ label: n, value: n }))}
                showSearch
                loading={initLoading}
              />
              <Popconfirm
                title="确定重置到默认值？"
                description="当前编辑内容将丢失，且无法恢复。"
                onConfirm={handleReset}
                disabled={!selected || !enabled}
              >
                <Button danger disabled={!selected || !enabled}>
                  重置
                </Button>
              </Popconfirm>
              <Button
                type="primary"
                icon={<SaveOutlined />}
                disabled={!isDirty || !enabled || !selected}
                loading={saving}
                onClick={handleSave}
              >
                保存
              </Button>
            </Space>
          }
        >
          {!selected ? (
            <Typography.Text type="secondary">请从上方选择一个配置文件</Typography.Text>
          ) : loading ? (
            <Skeleton active paragraph={{ rows: 10 }} />
          ) : (
            <TextArea
              value={content}
              onChange={(e) => setContent(e.target.value)}
              autoSize={{ minRows: 20, maxRows: 40 }}
              style={{ fontFamily: 'monospace', fontSize: 13 }}
              disabled={!enabled}
            />
          )}
        </Card>
      </Space>
    </PageContainer>
  );
};

export default ConfigCenter;
