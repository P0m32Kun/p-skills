# 优秀 Skill 仓库分析

> 分析 superpowers, gstack, andrej-karpathy-skills, mattpocock/skills 的设计模式

## 1. superpowers 特点

### 核心设计模式

**HARD-GATE 阻断机制**
```markdown
<HARD-GATE>
Do NOT invoke any implementation skill, write any code, scaffold any project, 
or take any implementation action until you have presented a design and the 
user has approved it.
</HARD-GATE>
```
- 强制检查点，不能跳过
- 明确的阻断条件
- 防止 agent 偷懒

**Anti-Patterns 反模式**
```markdown
## Anti-Pattern: "This Is Too Simple To Need A Design"

Every project goes through this process. A todo list, a single-function 
utility, a config change — all of them.
```
- 明确说明什么不能做
- 解释为什么不能做
- 防止常见错误

**详细 Checklist**
```markdown
## Checklist

You MUST create a task for each of these items and complete them in order:

1. **Explore project context** — check files, docs, recent commits
2. **Offer visual companion** — this is its own message
3. **Ask clarifying questions** — one at a time
...
```
- 可执行的步骤
- 明确的完成标准
- 防止遗漏

**流程图**
```dot
digraph brainstorming {
    "Explore project context" -> "Visual questions ahead?";
    ...
}
```
- 可视化流程
- 清晰的分支逻辑

### 我们可以学习的
- [x] 增加 HARD-GATE 阻断机制
- [x] 增加 Anti-Patterns 反模式
- [x] 细化 Checklist
- [ ] 增加流程图（可选，当前用文本流程图）

---

## 2. gstack 特点

### 核心设计模式

**模板化**
```yaml
---
name: review
preamble-tier: 4
version: 1.0.0
description: Pre-landing PR review. (gstack)
allowed-tools:
  - Bash
  - Read
  - Edit
---
<!-- AUTO-GENERATED from SKILL.md.tmpl — do not edit directly -->
```
- 统一的 frontmatter 格式
- 自动生成文档
- 版本管理

**Preamble 脚本**
```bash
_UPD=$(~/.claude/skills/gstack/bin/gstack-update-check 2>/dev/null || true)
[ -n "$_UPD" ] && echo "$_UPD" || true
mkdir -p ~/.gstack/sessions
...
```
- 执行前的环境检查
- 自动化配置
- Telemetry 收集

**分类清晰**
```
gstack/
├── autoplan/SKILL.md
├── benchmark/SKILL.md
├── review/SKILL.md
├── ship/SKILL.md
└── bin/
    ├── chrome-cdp
    ├── dev-setup
    └── ...
```
- 每个 skill 一个目录
- 可执行脚本与 skill 分离

### 我们可以学习的
- [x] 统一 frontmatter 格式
- [ ] 增加 preamble 脚本（环境检查）— 用 check-deps.sh 替代
- [ ] 每个 skill 一个目录 — 当前单文件结构更简洁
- [x] 增加版本管理

---

## 3. andrej-karpathy-skills 特点

### 核心设计模式

**行为准则**
```markdown
## 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
```
- 明确的行为规范
- 防止 LLM 常见错误
- 简洁有力

**反 LLM 错误**
```markdown
## 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
```
- 针对 LLM 的常见问题
- 具体的避免清单
- 可操作的指导

**目标驱动**
```markdown
## 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
```
- 明确的成功标准
- 可验证的结果
- 循环直到完成

### 我们可以学习的
- [x] 增加行为准则（防 LLM 错误）— 通过 Anti-Patterns 实现
- [x] 增加反模式清单
- [x] 明确成功标准
- [x] 目标驱动执行

---

## 4. mattpocock/skills 特点

### 核心设计模式

**分类清晰**
```
skills/
├── engineering/     # 工程技能
├── productivity/    # 生产力技能
├── misc/           # 杂项
├── personal/       # 个人技能
└── in-progress/    # 开发中
```
- 按用途分类
- 渐进式披露
- 开发中技能隔离

**Context.md**
```markdown
# CONTEXT.md

This file contains domain-specific knowledge that skills reference.
```
- 领域知识集中管理
- ADR（架构决策记录）
- 技能引用上下文

**Handoff 能力**
```markdown
## handoff

Compact the current conversation into a handoff document for another agent.
```
- 会话交接
- 上下文传递
- 跨 agent 协作

**渐进式披露**
```markdown
## Philosophy

**Core principle**: Tests should verify behavior through public interfaces, 
not implementation details.
```
- 先讲原则
- 再讲细节
- 最后讲示例

### 我们可以学习的
- [x] 增加分类（workflow, testing, security, docs, release）
- [x] 增加 CONTEXT.md（领域知识）
- [ ] 增加 handoff 能力 — 通过 AgentMemory 集成实现
- [x] 渐进式披露（原则 → 细节 → 示例）

---

## 优化计划

> 以下计划大部分已完成，标注了当前状态。

### Phase 1：格式优化
1. [x] 统一 frontmatter 格式（name, description, version, tags, triggers）
2. [ ] 每个 skill 一个目录（skill-name/SKILL.md）— 当前单文件结构更简洁
3. [x] 增加版本管理

### Phase 2：内容优化
1. [x] 增加 HARD-GATE 阻断机制
2. [x] 增加 Anti-Patterns 反模式
3. [x] 增加行为准则（防 LLM 错误）— 通过 Anti-Patterns 实现
4. [x] 细化 Checklist

### Phase 3：结构优化
1. [x] 增加 CONTEXT.md（领域知识）
2. [ ] 增加 handoff 能力 — 通过 AgentMemory 集成实现
3. [ ] 增加 preamble 脚本（环境检查）— 用 check-deps.sh 替代

### Phase 4：流程优化
1. [ ] 增加流程图（可选，当前用文本流程图）
2. [x] 增加决策树
3. [x] 增加成功标准模板
