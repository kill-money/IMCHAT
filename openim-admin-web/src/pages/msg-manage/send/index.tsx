import { sendMessage } from '@/services/openim';
import { PageContainer } from '@ant-design/pro-components';
import { Button, Card, Form, Input, message, Select } from 'antd';
import React from 'react';

const MsgSend: React.FC = () => {
  const [form] = Form.useForm();

  const handleSend = async (values: { sendID: string; recvID: string; content: string; sessionType: number }) => {
    const resp = await sendMessage({
      sendID: values.sendID,
      recvID: values.recvID,
      senderPlatformID: 5,
      content: { text: values.content },
      contentType: 101,
      sessionType: values.sessionType,
    });
    if (resp.errCode === 0) {
      message.success('发送成功');
      form.resetFields();
    } else {
      message.error(resp.errMsg || '发送失败');
    }
  };

  return (
    <PageContainer>
      <Card title="管理员发送消息" style={{ maxWidth: 600 }}>
        <Form form={form} layout="vertical" onFinish={handleSend}>
          <Form.Item label="发送者ID" name="sendID" rules={[{ required: true, message: '请输入发送者UserID' }]}>
            <Input placeholder="发送者 UserID" />
          </Form.Item>
          <Form.Item label="接收者ID" name="recvID" rules={[{ required: true, message: '请输入接收者UserID或GroupID' }]}>
            <Input placeholder="接收者 UserID 或 GroupID" />
          </Form.Item>
          <Form.Item label="会话类型" name="sessionType" initialValue={1} rules={[{ required: true }]}>
            <Select options={[
              { label: '单聊', value: 1 },
              { label: '群聊', value: 3 },
            ]} />
          </Form.Item>
          <Form.Item label="消息内容" name="content" rules={[{ required: true, message: '请输入消息内容' }]}>
            <Input.TextArea rows={4} placeholder="消息文本内容" />
          </Form.Item>
          <Form.Item>
            <Button type="primary" htmlType="submit">发送</Button>
          </Form.Item>
        </Form>
      </Card>
    </PageContainer>
  );
};

export default MsgSend;
