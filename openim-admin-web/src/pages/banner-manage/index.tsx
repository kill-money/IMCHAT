import {
    ArrowDownOutlined,
    ArrowUpOutlined,
    DeleteOutlined,
    EditOutlined,
    PlusOutlined,
    UploadOutlined,
} from "@ant-design/icons";
import {
    PageContainer,
    ProCard,
} from "@ant-design/pro-components";
import { request } from "@umijs/max";
import {
    Button,
    Form,
    Image,
    Input,
    Modal,
    Popconfirm,
    Select,
    Space,
    Switch,
    Table,
    Tag,
    Upload,
    message
} from "antd";
import type { ColumnsType } from "antd/es/table";
import { useCallback, useEffect, useState } from "react";

// ========== 类型 ==========
interface BannerItem {
  _id: string;
  type: "image" | "video" | "text";
  title: string;
  desc: string;
  link: string;
  bgClass: string;
  src: string;
  poster: string;
  isActive: boolean;
  sort: number;
  createdAt: string;
  updatedAt: string;
}

// ========== API ==========
const BANNER_API = "/banner_api/api/admin/banners";

async function fetchBanners(): Promise<BannerItem[]> {
  const res = await request(BANNER_API, { method: "GET", skipErrorHandler: true });
  return res?.data || [];
}

async function createBanner(formData: FormData): Promise<BannerItem> {
  const res = await request(BANNER_API, {
    method: "POST",
    data: formData,
    requestType: "form",
    skipErrorHandler: true,
  });
  if (res?.errCode !== 0) throw new Error(res?.errMsg || "创建失败");
  return res.data;
}

async function updateBanner(id: string, data: Partial<BannerItem>): Promise<BannerItem> {
  const res = await request(`${BANNER_API}/${id}`, {
    method: "PUT",
    data,
    skipErrorHandler: true,
  });
  if (res?.errCode !== 0) throw new Error(res?.errMsg || "更新失败");
  return res.data;
}

async function deleteBanner(id: string): Promise<void> {
  const res = await request(`${BANNER_API}/${id}`, {
    method: "DELETE",
    skipErrorHandler: true,
  });
  if (res?.errCode !== 0) throw new Error(res?.errMsg || "删除失败");
}

async function uploadFile(id: string, file: File, field: string = "src"): Promise<string> {
  const fd = new FormData();
  fd.append("file", file);
  fd.append("field", field);
  const res = await request(`${BANNER_API}/${id}/upload`, {
    method: "POST",
    data: fd,
    requestType: "form",
    skipErrorHandler: true,
  });
  if (res?.errCode !== 0) throw new Error(res?.errMsg || "上传失败");
  return res.data.url;
}

async function updateSort(items: { _id: string; sort: number }[]): Promise<void> {
  await request(`${BANNER_API}/sort`, {
    method: "POST",
    data: { items },
    skipErrorHandler: true,
  });
}

// ========== 类型映射 ==========
const TYPE_OPTIONS = [
  { label: "图片", value: "image" },
  { label: "视频", value: "video" },
  { label: "图文", value: "text" },
];

const BG_OPTIONS = [
  { label: "蓝色渐变", value: "bg-blue" },
  { label: "绿色渐变", value: "bg-green" },
  { label: "橙色渐变", value: "bg-orange" },
  { label: "紫色渐变", value: "bg-purple" },
];

// ========== 页面组件 ==========
export default function BannerManage() {
  const [list, setList] = useState<BannerItem[]>([]);
  const [loading, setLoading] = useState(false);
  const [modalOpen, setModalOpen] = useState(false);
  const [editItem, setEditItem] = useState<BannerItem | null>(null);
  const [form] = Form.useForm();

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const data = await fetchBanners();
      setList(data);
    } catch {
      message.error("加载Banner列表失败");
    }
    setLoading(false);
  }, []);

  useEffect(() => { load(); }, [load]);

  // ---------- 新增 / 编辑弹窗 ----------
  const openCreate = () => {
    setEditItem(null);
    form.resetFields();
    form.setFieldsValue({ type: "image", bgClass: "bg-blue", isActive: true });
    setModalOpen(true);
  };

  const openEdit = (item: BannerItem) => {
    setEditItem(item);
    form.setFieldsValue({
      type: item.type,
      title: item.title,
      desc: item.desc,
      link: item.link,
      bgClass: item.bgClass,
      isActive: item.isActive,
      src: item.src,
      poster: item.poster,
    });
    setModalOpen(true);
  };

  const handleOk = async () => {
    try {
      const values = await form.validateFields();
      if (editItem) {
        // 更新
        await updateBanner(editItem._id, values);
        message.success("更新成功");
      } else {
        // 新增
        const fd = new FormData();
        Object.entries(values).forEach(([k, v]) => {
          if (v !== undefined && v !== null && k !== "fileList") {
            fd.append(k, String(v));
          }
        });
        // 如果选择了文件
        if (values.fileList?.length > 0) {
          fd.append("file", values.fileList[0].originFileObj);
        }
        await createBanner(fd);
        message.success("创建成功");
      }
      setModalOpen(false);
      load();
    } catch (err: any) {
      if (err?.errorFields) return; // form validation
      message.error(err?.message || "操作失败");
    }
  };

  // ---------- 删除 ----------
  const handleDelete = async (id: string) => {
    try {
      await deleteBanner(id);
      message.success("删除成功");
      load();
    } catch {
      message.error("删除失败");
    }
  };

  // ---------- 启用/禁用 ----------
  const handleToggle = async (item: BannerItem) => {
    try {
      await updateBanner(item._id, { isActive: !item.isActive });
      load();
    } catch {
      message.error("操作失败");
    }
  };

  // ---------- 上传替换文件 ----------
  const handleUpload = async (item: BannerItem, file: File, field: string) => {
    try {
      await uploadFile(item._id, file, field);
      message.success("上传成功");
      load();
    } catch {
      message.error("上传失败");
    }
  };

  // ---------- 排序 ----------
  const handleMove = async (index: number, direction: "up" | "down") => {
    const newList = [...list];
    const target = direction === "up" ? index - 1 : index + 1;
    if (target < 0 || target >= newList.length) return;
    [newList[index], newList[target]] = [newList[target], newList[index]];
    const sortItems = newList.map((item, idx) => ({ _id: item._id, sort: idx + 1 }));
    try {
      await updateSort(sortItems);
      load();
    } catch {
      message.error("排序失败");
    }
  };

  // ---------- 表格列 ----------
  const columns: ColumnsType<BannerItem> = [
    {
      title: "排序",
      width: 80,
      render: (_, __, index) => (
        <Space size={4}>
          <Button
            type="text"
            size="small"
            icon={<ArrowUpOutlined />}
            disabled={index === 0}
            onClick={() => handleMove(index, "up")}
          />
          <Button
            type="text"
            size="small"
            icon={<ArrowDownOutlined />}
            disabled={index === list.length - 1}
            onClick={() => handleMove(index, "down")}
          />
        </Space>
      ),
    },
    {
      title: "预览",
      width: 200,
      render: (_, record) => {
        if (record.type === "video" && record.src) {
          return (
            <video
              src={record.src}
              poster={record.poster}
              style={{ width: 180, height: 80, objectFit: "cover", borderRadius: 4 }}
              muted
              controls={false}
              onMouseEnter={(e) => (e.target as HTMLVideoElement).play()}
              onMouseLeave={(e) => { const v = e.target as HTMLVideoElement; v.pause(); v.currentTime = 0; }}
            />
          );
        }
        if (record.type === "image" && record.src) {
          return <Image src={record.src} width={180} height={80} style={{ objectFit: "cover", borderRadius: 4 }} />;
        }
        return (
          <div
            style={{
              width: 180,
              height: 80,
              borderRadius: 4,
              display: "flex",
              flexDirection: "column",
              justifyContent: "center",
              padding: "0 12px",
              color: "#fff",
              fontSize: 12,
              background:
                record.bgClass === "bg-green"
                  ? "linear-gradient(135deg,#52c41a,#389e0d)"
                  : record.bgClass === "bg-orange"
                  ? "linear-gradient(135deg,#fa8c16,#d46b08)"
                  : record.bgClass === "bg-purple"
                  ? "linear-gradient(135deg,#722ed1,#531dab)"
                  : "linear-gradient(135deg,#1890ff,#096dd9)",
            }}
          >
            <strong>{record.title}</strong>
            <span>{record.desc}</span>
          </div>
        );
      },
    },
    {
      title: "类型",
      dataIndex: "type",
      width: 80,
      render: (t: string) => {
        const map: Record<string, { color: string; text: string }> = {
          image: { color: "blue", text: "图片" },
          video: { color: "red", text: "视频" },
          text: { color: "green", text: "图文" },
        };
        const m = map[t] || { color: "default", text: t };
        return <Tag color={m.color}>{m.text}</Tag>;
      },
    },
    { title: "标题", dataIndex: "title", width: 150 },
    { title: "链接", dataIndex: "link", width: 120, ellipsis: true },
    {
      title: "状态",
      width: 80,
      render: (_, record) => (
        <Switch
          checked={record.isActive}
          checkedChildren="启用"
          unCheckedChildren="禁用"
          onChange={() => handleToggle(record)}
        />
      ),
    },
    {
      title: "上传/替换",
      width: 160,
      render: (_, record) => {
        if (record.type === "text") return <span style={{ color: "#999" }}>图文无需上传</span>;
        return (
          <Space>
            <Upload
              showUploadList={false}
              accept={record.type === "video" ? "video/*" : "image/*"}
              beforeUpload={(file) => { handleUpload(record, file, "src"); return false; }}
            >
              <Button size="small" icon={<UploadOutlined />}>
                {record.type === "video" ? "视频" : "图片"}
              </Button>
            </Upload>
            {record.type === "video" && (
              <Upload
                showUploadList={false}
                accept="image/*"
                beforeUpload={(file) => { handleUpload(record, file, "poster"); return false; }}
              >
                <Button size="small" icon={<UploadOutlined />}>封面</Button>
              </Upload>
            )}
          </Space>
        );
      },
    },
    {
      title: "操作",
      width: 120,
      render: (_, record) => (
        <Space>
          <Button type="link" icon={<EditOutlined />} onClick={() => openEdit(record)}>
            编辑
          </Button>
          <Popconfirm title="确定删除？" onConfirm={() => handleDelete(record._id)}>
            <Button type="link" danger icon={<DeleteOutlined />}>
              删除
            </Button>
          </Popconfirm>
        </Space>
      ),
    },
  ];

  // ---------- 表单中的类型字段 ----------
  const formType = Form.useWatch("type", form);

  return (
    <PageContainer title="Banner 轮播管理" subTitle="管理用户端首页轮播图片和视频">
      <ProCard>
        <div style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            新增 Banner
          </Button>
        </div>
        <Table
          rowKey="_id"
          columns={columns}
          dataSource={list}
          loading={loading}
          pagination={false}
          scroll={{ x: 1000 }}
        />
      </ProCard>

      {/* 新增 / 编辑弹窗 */}
      <Modal
        title={editItem ? "编辑 Banner" : "新增 Banner"}
        open={modalOpen}
        onOk={handleOk}
        onCancel={() => setModalOpen(false)}
        width={560}
        destroyOnClose
      >
        <Form form={form} layout="vertical" autoComplete="off">
          <Form.Item name="type" label="类型" rules={[{ required: true }]}>
            <Select options={TYPE_OPTIONS} />
          </Form.Item>
          <Form.Item name="title" label="标题">
            <Input placeholder="Banner 标题（可选）" />
          </Form.Item>

          {formType === "text" && (
            <>
              <Form.Item name="desc" label="描述">
                <Input placeholder="副标题/描述文字" />
              </Form.Item>
              <Form.Item name="bgClass" label="背景色">
                <Select options={BG_OPTIONS} />
              </Form.Item>
            </>
          )}

          {formType !== "text" && !editItem && (
            <Form.Item
              name="fileList"
              label={formType === "video" ? "上传视频" : "上传图片"}
              valuePropName="fileList"
              getValueFromEvent={(e) => (Array.isArray(e) ? e : e?.fileList)}
            >
              <Upload
                maxCount={1}
                beforeUpload={() => false}
                accept={formType === "video" ? "video/*" : "image/*"}
              >
                <Button icon={<UploadOutlined />}>选择文件</Button>
              </Upload>
            </Form.Item>
          )}

          {formType !== "text" && editItem && (
            <Form.Item name="src" label="资源URL">
              <Input placeholder="图片/视频 URL（通过上传按钮替换）" />
            </Form.Item>
          )}

          {formType === "video" && editItem && (
            <Form.Item name="poster" label="封面图URL">
              <Input placeholder="视频封面图 URL" />
            </Form.Item>
          )}

          <Form.Item name="link" label="点击跳转链接">
            <Input placeholder="点击后跳转的页面路径，如 /conversation" />
          </Form.Item>

          {editItem && (
            <Form.Item name="isActive" label="是否启用" valuePropName="checked">
              <Switch checkedChildren="启用" unCheckedChildren="禁用" />
            </Form.Item>
          )}
        </Form>
      </Modal>
    </PageContainer>
  );
}
