---
name: security-poc
description: >
  Use when writing PoC (Proof of Concept) scripts, verifying vulnerabilities,
  or doing security validation. Use when user says "编写 PoC", "漏洞验证",
  "安全验证", "PoC", "vulnerability verification".
---

# PoC 编写与验证

> 漏洞 PoC 编写与靶场验证流程。

## 前置条件

- 目标资产已明确
- 漏洞类型已确定

## 流程

### 1. 明确目标资产和漏洞类型

```markdown
## 目标信息

### 资产信息
- **资产类型**：[Web 应用/API/服务/...]
- **资产地址**：[URL/IP:Port]
- **资产版本**：[版本号]

### 漏洞信息
- **漏洞类型**：[SQL注入/XSS/RCE/...]
- **CVE 编号**：[CVE-XXXX-XXXXX]（如有）
- **漏洞描述**：[漏洞描述]
```

### 2. 编写 PoC 脚本

#### PoC 脚本结构

```python
#!/usr/bin/env python3
"""
PoC 脚本：[漏洞名称]

目标：[目标描述]
漏洞：[漏洞类型]
作者：[作者]
日期：[YYYY-MM-DD]
"""

import requests
import sys
from typing import Optional

# 配置
TARGET = "http://example.com"
TIMEOUT = 10

def verify_vulnerability(target: str) -> bool:
    """
    验证漏洞是否存在

    Args:
        target: 目标地址

    Returns:
        bool: 漏洞是否存在
    """
    try:
        # 构造 payload
        payload = {
            "username": "admin' OR '1'='1",
            "password": "test"
        }

        # 发送请求
        response = requests.post(
            f"{target}/login",
            data=payload,
            timeout=TIMEOUT
        )

        # 验证结果 — 检查特定漏洞指标，不要仅凭 status_code == 200 判断
        # 示例：检查是否绕过了认证（响应中包含特定标记）
        if "登录成功" in response.text and response.status_code == 200:
            # 进一步确认：检查是否返回了管理员页面内容
            if "admin" in response.text.lower() or "dashboard" in response.text.lower():
                return True

        return False

    except Exception as e:
        print(f"Error: {e}")
        return False

def exploit_vulnerability(target: str) -> Optional[str]:
    """
    利用漏洞（可选）

    Args:
        target: 目标地址

    Returns:
        str: 利用结果
    """
    # 实现漏洞利用逻辑
    pass

def remediation() -> str:
    """
    修复建议

    Returns:
        str: 修复建议
    """
    return """
    1. 使用参数化查询
    2. 输入验证和过滤
    3. 最小权限原则
    """

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <target>")
        sys.exit(1)

    target = sys.argv[1]

    print(f"[*] Target: {target}")
    print(f"[*] Verifying vulnerability...")

    if verify_vulnerability(target):
        print("[+] Vulnerability exists!")

        result = exploit_vulnerability(target)
        if result is not None:
            print(f"[+] Exploit result: {result}")

        print(f"\n[+] Remediation:\n{remediation()}")
    else:
        print("[-] Vulnerability does not exist")

if __name__ == "__main__":
    main()
```

#### PoC 编写规范

**必须包含**：
- 文件头注释（描述、目标、作者、日期）
- 配置区域（TARGET、TIMEOUT）
- 验证函数（verify_vulnerability）
- 主函数（main）
- 错误处理

**可选包含**：
- 利用函数（exploit_vulnerability）
- 修复建议（remediation）

### 3. 靶场环境验证

> ⚠️ **法律前提**：PoC 只能在授权范围内测试。未经授权的测试 = 违法。

#### 靶场搭建

选择合适的靶场环境验证 PoC：

- **[Vulhub](https://github.com/vulhub/vulhub)** — 漏洞靶场集合，按 CVE 分类
- **[DVWA](https://github.com/digininja/DVWA)** — Web 漏洞靶场
- **[OWASP Juice Shop](https://github.com/juice-shop/juice-shop)** — 现代 Web 应用靶场

```bash
# 示例：启动靶场（以 Vulhub 为例）
# 1. 克隆 Vulhub 仓库
git clone https://github.com/vulhub/vulhub.git
cd vulhub/<vulnerability-name>

# 2. 启动靶场环境
docker-compose up -d

# 3. 确认靶场已启动
docker-compose ps

# 4. 运行 PoC（端口以 docker-compose 输出为准）
python3 poc.py http://localhost:<port>

# 5. 清理环境
docker-compose down
```

> 注意：靶场路径和端口按实际项目调整。先确认靶场镜像拉取成功再运行 PoC。

### 4. 输出 PoC 脚本 + 验证报告

```markdown
## 验证报告

### 验证时间
[YYYY-MM-DD HH:MM]

### 目标信息
- **资产**：[资产信息]
- **漏洞**：[漏洞类型]

### 验证结果
- **漏洞存在**：[是/否]
- **利用成功**：[是/否/不适用]

### PoC 脚本
- **文件**：[poc.py]
- **语言**：[Python 3]
- **依赖**：[requests, ...]

### 复现步骤
1. [步骤 1]
2. [步骤 2]
3. [步骤 3]

### 修复建议
[修复建议]
```

## 完成标准

- [ ] 目标资产已明确
- [ ] 漏洞类型已确定
- [ ] PoC 脚本已编写
- [ ] 靶场验证已通过
- [ ] 验证报告已输出

## Red Flags — STOP

当你有以下任何想法时，**停下来重新检查**：

- "直接写 PoC 就行"
- "不用搭靶场"
- "漏洞报告看一下就行"
- "PoC 跑通就算"
- "不用记录环境"

**所有这些都意味着你正在合理化跳过流程。回到 security-poc 的第一步。**

## Common Rationalizations

| 借口 | 现实 |
|------|------|
| "不用复现，看报告就行" | 不复现 = 不理解漏洞本质 |
| "靶场太麻烦搭" | 靶场是为了安全验证，避免在生产乱试 |
| "PoC 跑通就行" | 没记录环境的 PoC = 不可复现 |
| "直接打目标" | 未授权测试 = 违法 |
| "PoC 不用测试" | PoC 也可能有 bug |

## 参考

- [Vulhub](https://github.com/vulhub/vulhub) — 漏洞靶场
- [DVWA](https://github.com/digininja/DVWA) — 靶场环境
- [PoC-in-GitHub](https://github.com/ycdxsb/PoC-in-GitHub) — PoC 集合
- [OWASP Testing Guide](https://owasp.org/www-project-web-security-testing-guide/) — 测试指南
