# P-Skills 自进化系统 v2 设计文档

> 基于 SkillOpt 的 ReflACT 流水线，适配 P-Skills 的开发流程场景。

## 1. 核心理念

### SkillOpt 的关键洞察

把 **skill 文档当作可训练状态**，用类似深度学习的训练循环优化它：
- Edit 操作 = 梯度更新
- Validation Gate = 验证集评估
- Learning Rate = 编辑预算
- Slow Update = 正则化/EMA

### P-Skills 的适配挑战

| SkillOpt | P-Skills | 适配方案 |
|----------|----------|----------|
| Benchmark 评分 | 无标准评分 | 代理信号：用户行为 + 执行指标 |
| 明确的任务集 | 开发流程场景 | 从实际使用中采集轨迹 |
| 离线训练循环 | 在线持续学习 | Session 级别的微训练 |
| 单一 skill 文档 | 多个 skill 文件 | Per-skill 独立进化 |

## 2. 反馈信号设计

### 2.1 隐式信号（自动采集）

```typescript
interface ObservationSignal {
  // 工具使用模式
  tool: string;           // Edit, Write, Bash, Read...
  file_path: string;
  file_ext: string;
  duration_ms: number;

  // Skill 执行信号
  skill_triggered: string;  // 触发的 skill 名称
  skill_completed: boolean; // 是否完成整个流程
  skill_skipped: boolean;   // 用户是否跳过某阶段
  stages_completed: string[]; // 完成的阶段列表

  // 用户行为信号
  user_reverted: boolean;   // 用户是否回滚了 skill 建议的修改
  user_manually_edited: boolean; // 用户是否手动修改了 skill 建议的输出

  // 上下文
  session_id: string;
  project_id: string;
  timestamp: string;
}
```

### 2.2 显式信号（可选）

```typescript
interface FeedbackSignal {
  skill_name: string;
  rating: 1 | 2 | 3 | 4 | 5;
  comment?: string;
  session_id: string;
}
```

### 2.3 代理评分公式

```
score = w1 * completion_rate      // 流程完成率
      + w2 * (1 - revert_rate)    // 未回滚率
      + w3 * efficiency_score     // 效率得分（工具调用次数的倒数）
      + w4 * user_rating          // 用户评分（如有）
```

## 3. 训练循环（ReflACT 适配版）

```
┌─────────────────────────────────────────────────────────────────┐
│                    P-Skills 自进化循环                            │
├─────────────────────────────────────────────────────────────────┤
│  Session 级别（每次会话）：                                        │
│    ① Observe   — hooks 采集行为数据                               │
│    ② Store     — 写入 observations.jsonl                         │
│                                                                 │
│  Epoch 级别（每 N 次会话或手动触发）：                              │
│    ③ Reflect   — 分析观察数据，识别模式                            │
│    ④ Propose   — 生成 skill 改进 patches                         │
│    ⑤ Validate  — 对比改进前后的效果                                │
│    ⑥ Apply     — 应用验证通过的改进                                │
│    ⑦ Protect   — Slow Update 保护区维护                           │
└─────────────────────────────────────────────────────────────────┘
```

## 4. 数据结构

### 4.1 Edit 操作（复用 SkillOpt）

```typescript
type EditOp = 'append' | 'insert_after' | 'replace' | 'delete';

interface Edit {
  op: EditOp;
  content: string;      // 新内容
  target?: string;      // 目标文本（replace/delete 时）
  section?: string;     // 目标 section
  reasoning: string;    // 为什么做这个编辑
  confidence: number;   // 置信度 0-1
  support_count: number; // 支持该编辑的观察数
}

interface Patch {
  edits: Edit[];
  reasoning: string;
  source: 'observation' | 'feedback' | 'analysis';
}
```

### 4.2 训练状态

```typescript
interface TrainingState {
  project_id: string;
  skill_name: string;
  epoch: number;
  step: number;

  // 分数追踪
  current_score: number;
  best_score: number;
  best_step: number;
  best_skill_content: string;

  // 编辑历史
  applied_edits: Edit[];
  rejected_edits: Edit[];

  // 学习率调度
  learning_rate: number;
  lr_scheduler: 'constant' | 'linear' | 'cosine';
}
```

### 4.3 目录结构

```
~/.p-skills/learning/
├── projects/
│   └── <project_id>/
│       ├── observations.jsonl          # 原始观察数据
│       ├── feedback.jsonl              # 用户反馈
│       ├── training_state.json         # 训练状态
│       ├── epochs/
│       │   ├── epoch_001/
│       │   │   ├── reflections.json    # 反思结果
│       │   │   ├── patches.json        # 生成的 patches
│       │   │   ├── validation.json     # 验证结果
│       │   │   └── skill_snapshot.md   # 该 epoch 的 skill 快照
│       │   └── epoch_002/
│       │       └── ...
│       └── best_skills/
│           ├── fix-bug.md              # 最佳版本
│           └── develop-feature.md
└── global/
    ├── meta_patterns.jsonl             # 跨项目模式
    └── evolution_log.jsonl             # 进化日志
```

## 5. Hooks 集成

### 5.1 数据采集层

```javascript
// hooks/learning-observer.js (PostToolUse)
// 采集工具使用和 skill 执行信号

function observe(input) {
  const signal = {
    tool: input.tool_name,
    file_path: extractFilePath(input),
    session_id: input.session_id,
    project_id: getProjectId(),
    timestamp: new Date().toISOString(),

    // Skill 执行信号
    skill_triggered: detectTriggeredSkill(input),
    skill_completed: false, // 后续更新

    // 默认值，后续由 session-tracker 更新
    user_reverted: false,
    user_manually_edited: false,
  };

  appendObservation(signal);
}
```

### 5.2 Session 追踪层

```javascript
// hooks/session-tracker.js (PostToolUse + Stop)
// 追踪整个 session 的 skill 执行情况

function trackSession(input) {
  // 记录 session 开始
  if (input.tool_name === 'SessionStart') {
    startSession(input.session_id);
  }

  // 追踪 skill 阶段
  if (isSkillStage(input)) {
    updateSessionProgress(input.session_id, input);
  }

  // Session 结束时计算分数
  if (input.tool_name === 'Stop') {
    const score = calculateSessionScore(input.session_id);
    updateTrainingState(score);
  }
}
```

### 5.3 训练触发层

```javascript
// hooks/evolution-trigger.js (Stop)
// 每 N 个 session 触发一次训练循环

function maybeTriggerTraining(sessionCount) {
  const TRAINING_INTERVAL = 5; // 每 5 个 session 训练一次

  if (sessionCount % TRAINING_INTERVAL === 0) {
    // 异步触发训练循环
    spawn('node', ['evolution-train.js', '--project', projectId], {
      detached: true,
      stdio: 'ignore',
    });
  }
}
```

### 5.4 应用层

```javascript
// hooks/skill-applier.js (SessionStart)
// 加载最佳 skill 版本到会话上下文

function loadBestSkills(projectId) {
  const bestSkillsDir = `~/.p-skills/learning/projects/${projectId}/best_skills`;
  const skills = readdirSync(bestSkillsDir);

  return skills.map(skill => {
    const content = readFileSync(join(bestSkillsDir, skill), 'utf8');
    return { name: skill.replace('.md', ''), content };
  });
}
```

## 6. Reflect 阶段设计

### 6.1 观察分析 Prompt

```markdown
你是一个 skill 优化专家。分析以下 agent 行为观察数据，识别改进模式。

## 当前 Skill
{{skill_content}}

## 观察数据（最近 {{N}} 个 session）
{{observations}}

## 分析要求
1. 识别最常见的失败模式
2. 识别用户跳过的阶段
3. 识别被回滚的建议
4. 提出具体的 skill 编辑建议

## 输出格式
{
  "failure_patterns": [...],
  "skip_patterns": [...],
  "revert_patterns": [...],
  "patch": {
    "reasoning": "...",
    "edits": [
      {"op": "append|insert_after|replace|delete", "content": "...", "target": "..."}
    ]
  }
}
```

### 6.2 慢更新 Prompt（Epoch 级别）

```markdown
你是 skill 的战略顾问。比较同一个 skill 在不同 epoch 的表现，提供长期优化指导。

## 上一 Epoch 的 Skill
{{prev_skill}}

## 当前 Epoch 的 Skill
{{curr_skill}}

## 纵向对比数据
{{comparison_data}}

## 上一 Epoch 的指导
{{prev_guidance}}

## 要求
1. 反思上一 epoch 的指导是否有效
2. 识别系统性漂移或退化
3. 提供新的战略指导

## 输出
{
  "reasoning": "...",
  "guidance": "..."  // 直接可执行的指导
}
```

## 7. Validation Gate 设计

### 7.1 代理验证指标

```typescript
function calculateValidationScore(
  observations: Observation[],
  skillVersion: string
): ValidationScore {
  return {
    // 流程完成率
    completion_rate: observations.filter(o => o.skill_completed).length
                     / observations.length,

    // 建议采纳率（未回滚）
    adoption_rate: observations.filter(o => !o.user_reverted).length
                   / observations.length,

    // 效率得分（工具调用次数的倒数归一化）
    efficiency_score: 1 / (1 + avgToolCalls(observations)),

    // 综合分数
    composite: 0.4 * completion_rate
             + 0.3 * adoption_rate
             + 0.3 * efficiency_score,
  };
}
```

### 7.2 Gate 决策

```typescript
function validationGate(
  candidateScore: number,
  currentScore: number,
  bestScore: number,
  mode: 'hard' | 'soft' = 'hard'
): GateAction {
  if (mode === 'hard') {
    // 硬门禁：必须严格提升
    if (candidateScore > bestScore) return 'accept_new_best';
    if (candidateScore > currentScore) return 'accept';
    return 'reject';
  } else {
    // 软门禁：允许小幅波动
    const threshold = 0.02;
    if (candidateScore > bestScore + threshold) return 'accept_new_best';
    if (candidateScore > currentScore - threshold) return 'accept';
    return 'reject';
  }
}
```

## 8. Learning Rate 调度

```typescript
class SkillLRScheduler {
  constructor(
    private mode: 'constant' | 'linear' | 'cosine',
    private maxEdits: number = 4,
    private minEdits: number = 1,
    private totalEpochs: number = 10
  ) {}

  getEditBudget(epoch: number): number {
    switch (this.mode) {
      case 'constant':
        return this.maxEdits;
      case 'linear':
        return Math.max(
          this.minEdits,
          Math.round(this.maxEdits * (1 - epoch / this.totalEpochs))
        );
      case 'cosine':
        return Math.max(
          this.minEdits,
          Math.round(
            this.minEdits + 0.5 * (this.maxEdits - this.minEdits) *
            (1 + Math.cos(Math.PI * epoch / this.totalEpochs))
          )
        );
    }
  }
}
```

## 9. 实现路线图

### Phase 1：数据采集层 ✅ 已完成
- [x] 重写 `learning-observer.js`，采集工具使用和 skill 执行信号
- [x] 新增 `session-tracker.js`，追踪 session 级别指标
- [x] 更新 `meta-skill-update.js`，追踪 skill 文件编辑
- [x] 更新 `session-learning.js`，加载学习到的模式
- [x] 更新 `hooks.json`，注册所有 hooks
- [ ] 新增 `feedback-collector.js`，采集用户显式反馈（可选）

### Phase 2：分析层 ✅ 已完成
- [x] 实现 `evolution-train.js`，训练循环主控
- [x] 实现反思阶段：分析观察数据，识别模式
- [x] 实现提议阶段：生成 skill 改进 patches
- [ ] 设计并测试更精细的 Reflect Prompt（需要 LLM 集成）

### Phase 3：验证层 ✅ 已完成
- [x] 实现代理评分：基于置信度和支持数
- [x] 实现 Gate 决策：hard/soft 模式
- [x] 实现学习率调度：constant/linear/cosine
- [ ] 实现 A/B 对比机制（需要更多数据）

### Phase 4：应用层 ✅ 已完成
- [x] 实现 `applyEdits()`：应用验证通过的改进
- [x] 实现 skill 快照和备份
- [x] 实现进化日志记录
- [ ] 实现 Slow Update 保护区（需要更多 epoch 数据）

### Phase 5：集成测试（进行中）
- [x] 基本功能测试
- [ ] 端到端测试
- [ ] 性能优化
- [ ] 文档和示例

## 10. 与现有系统的关系

```
P-Skills 架构
├── 核心系统（skills/）
│   └── 通用开发流程 skills
├── Claude Code 增强层（skills/claude-code/）
│   ├── hooks（数据采集）
│   ├── rules（行为规范）
│   └── skills（辅助技能）
└── 自进化系统（learning/）  ← 本设计
    ├── 观察层（hooks 集成）
    ├── 分析层（LLM 驱动）
    ├── 验证层（代理评分）
    └── 应用层（skill 更新）
```

自进化系统是 P-Skills 的**元层**，它不替代现有的 skill 系统，而是持续优化它。
