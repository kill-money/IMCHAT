import requests

API_KEY = 'YOUR_302AI_API_KEY'

url = "https://api.302.ai/v1/chat/completions"

task_document = """
（将现有 App（iOS + Android）全部页面、组件、样式重构为统一的“温暖希望·绿色行动”视觉体系，实现 100% 视觉一致性、零旧样式残留、可量化验收。

🧱 一、必须遵守的总原则（零例外）
1. 全局统一化
所有页面、组件、按钮、卡片、Header 必须使用全局组件库

禁止任何旧 StyleSheet / CSS / 内联样式

禁止硬编码颜色、尺寸、字体

2. 视觉调性
主基调：温暖、希望、信任、行动力

主色：绿色

点缀：橙色

风格：公益、温暖、专业、可信赖

3. 适配规范
设计基准：375pt（iOS）/ 360dp（Android）

所有尺寸必须使用 Spacing 变量

点击区域 ≥ 48×48dp

深色模式暂不支持

🎨 二、全局 Theme（必须先完成）
颜色变量（禁止硬编码）
名称	值
Primary	#2E7D32
Accent	#FF9800
Success	#4CAF50
Warning	#F44336
Background	#F8F9FA
CardBackground	#FFFFFF
TextPrimary	#212121
TextSecondary	#757575
TextHint	#BDBDBD
Divider	#EEEEEE
Overlay	rgba(0,0,0,0.6)
迁移要求：  
全局搜索 # / rgb / rgba → 全部替换为 Theme 变量。

✍️ 三、排版与间距（全局 Text + Spacing）
字体体系
H1：20sp SemiBold

H2：18sp Medium

Body：16sp Regular

Caption：14sp Regular

Button：16sp Medium

行高：1.5×字号

Spacing（严格 4 的倍数）
4 / 8 / 12 / 16 / 24 / 32 / 48 dp

迁移要求：  
所有 <Text> 必须使用全局 Text 组件。

🧭 四、Header（全局唯一组件）
规范
高度：56dp

背景：白色 + 底部阴影

左：返回箭头 + Logo

中：标题（18sp SemiBold）

右：搜索 → 消息（带红点） → 头像

Props
代码
title
showBack
rightIcons[]
onRightPress
迁移要求：  
删除所有页面自定义 Header → 全部替换为全局 Header。

🧩 五、卡片与容器（核心重构）
Card 规范
背景：白色

圆角：16dp

阴影：0 2 8 rgba(0,0,0,0.06)

Padding：16×12

间距：12dp

图片比例：16:9 或 1:1

标签：绿/橙，圆角20dp

迁移要求：  
全局搜索 card / box / container / shadow / borderRadius → 全部替换为 <Card />。

📐 六、布局规范
页面结构
代码
Header（固定）
↓
ScrollView（带下拉刷新）
↓
内容区
↓
BottomSafeArea
网格
2 列：(屏幕宽度 - 48) / 2

横向列表
卡片宽度：屏幕宽度 - 32dp

🧰 七、全局 UI 组件库（必须建立）
目录结构：

代码
components/ui/
  Header.tsx
  Card.tsx
  Button.tsx
  Tag.tsx
  ProgressBar.tsx
  Icon.tsx
  Modal.tsx
  TabBar.tsx
  Text.tsx
  Badge.tsx
  EmptyState.tsx
Button 规范
主按钮：绿色底 + 白字

辅助按钮：橙色

线框按钮：绿色边框

禁用态：#BDBDBD

📅 八、执行计划（10 天）
Day 1
完成 Theme

完成 Header / Card / Button / Text / Icon 等核心组件

Day 2
全局替换 Header

全局替换 Card

Day 3
替换 Button / Icon / 空状态 / Loading

Day 4–6
重构所有剩余页面

删除所有旧样式文件

Day 7
自查 + 对比截图（首页 + 5 个关键页面）

Day 8–10
修复问题

回归测试

上线准备

✔ 九、强制验收清单（必须全部通过）
Header 100% 一致

卡片圆角 16dp，无旧样式

颜色全部来自 Theme

间距全部来自 Spacing

所有按钮、标签、进度条统一

图片占位图统一

点击区域 ≥ 48dp

全局搜索无硬编码颜色

Modal、空状态、Loading 全部统一

无任何旧样式残留）
"""

payload = {
    "model": "claude-3-7-sonnet-20250219",
    "messages": [
        {
            "role": "user",
            "content": f"请根据以下文档执行任务：\n\n{task_document}"
        }
    ]
}

headers = {
    "Authorization": f"Bearer {API_KEY}",
    "Content-Type": "application/json"
}

res = requests.post(url, json=payload, headers=headers)
print(res.json()["choices"][0]["message"]["content"])
