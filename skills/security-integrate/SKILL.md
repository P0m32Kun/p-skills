---
name: security-integrate
description: >
  Use when integrating security tools into CI/CD, building security pipelines,
  or automating security checks. Use when user says "集成安全工具", "安全自动化",
  "security integration", "security automation".
---

# 安全工具集成

> 将安全工具集成到开发流程中。

## 前置条件

- 安全工具已选定
- 集成目标已明确（CI/CD、监控平台等）

## 流程

### 1. 了解工具输入输出格式

#### 输入格式

```bash
# Nuclei
nuclei -u http://target.com -t cves/

# Semgrep
semgrep --config=auto .

# SonarQube
sonar-scanner -Dsonar.projectKey=myproject
```

#### 输出格式

```json
// Nuclei JSON 输出
{
  "template-id": "CVE-2021-44228",
  "info": {
    "name": "Log4j RCE",
    "severity": "critical"
  },
  "host": "http://target.com",
  "matched-at": "http://target.com/api"
}

// Semgrep JSON 输出
{
  "results": [
    {
      "check_id": "python.lang.security.injection.sql-injection",
      "path": "app.py",
      "start": {"line": 42},
      "message": "SQL injection"
    }
  ]
}
```

### 2. 编写 Parser

```python
from typing import List, Dict
from dataclasses import dataclass

@dataclass
class Vulnerability:
    id: str
    name: str
    severity: str
    file: str
    line: int
    message: str

class NucleiParser:
    """解析 Nuclei JSON 输出"""

    def parse(self, json_output: str) -> List[Vulnerability]:
        """解析 JSON 输出"""
        import json
        data = json.loads(json_output)

        vulns = []
        for item in data:
            vuln = Vulnerability(
                id=item.get("template-id", ""),
                name=item.get("info", {}).get("name", ""),
                severity=item.get("info", {}).get("severity", "info"),
                file=item.get("host", ""),
                line=0,
                message=item.get("matcher-name", "")
            )
            vulns.append(vuln)

        return vulns

class SemgrepParser:
    """解析 Semgrep JSON 输出"""

    def parse(self, json_output: str) -> List[Vulnerability]:
        """解析 JSON 输出"""
        import json
        data = json.loads(json_output)

        vulns = []
        for item in data.get("results", []):
            vuln = Vulnerability(
                id=item.get("check_id", ""),
                name=item.get("check_id", ""),
                severity="medium",
                file=item.get("path", ""),
                line=item.get("start", {}).get("line", 0),
                message=item.get("message", "")
            )
            vulns.append(vuln)

        return vulns
```

### 3. 编写 Pipeline Tool

```python
#!/usr/bin/env python3
"""
安全扫描 Pipeline Tool

集成多个安全工具，统一输出格式。
"""

import subprocess
import json
from typing import List, Dict
from dataclasses import dataclass

@dataclass
class ScanResult:
    tool: str
    vulnerabilities: List[Vulnerability]
    scan_time: float
    status: str

class SecurityPipeline:
    """安全扫描 Pipeline"""

    def __init__(self, target: str):
        self.target = target
        self.results: List[ScanResult] = []

    def run_nuclei(self) -> ScanResult:
        """运行 Nuclei 扫描"""
        import time
        start = time.time()

        try:
            result = subprocess.run(
                ["nuclei", "-u", self.target, "-json"],
                capture_output=True,
                text=True,
                timeout=300
            )

            parser = NucleiParser()
            vulns = parser.parse(result.stdout)

            return ScanResult(
                tool="nuclei",
                vulnerabilities=vulns,
                scan_time=time.time() - start,
                status="success"
            )
        except Exception as e:
            return ScanResult(
                tool="nuclei",
                vulnerabilities=[],
                scan_time=time.time() - start,
                status=f"error: {e}"
            )

    def run_semgrep(self) -> ScanResult:
        """运行 Semgrep 扫描"""
        import time
        start = time.time()

        try:
            result = subprocess.run(
                ["semgrep", "--config=auto", "--json", "."],
                capture_output=True,
                text=True,
                timeout=300
            )

            parser = SemgrepParser()
            vulns = parser.parse(result.stdout)

            return ScanResult(
                tool="semgrep",
                vulnerabilities=vulns,
                scan_time=time.time() - start,
                status="success"
            )
        except Exception as e:
            return ScanResult(
                tool="semgrep",
                vulnerabilities=[],
                scan_time=time.time() - start,
                status=f"error: {e}"
            )

    def run_all(self) -> List[ScanResult]:
        """运行所有扫描"""
        self.results.append(self.run_nuclei())
        self.results.append(self.run_semgrep())
        return self.results

    def generate_report(self) -> str:
        """生成报告"""
        report = "# 安全扫描报告\n\n"
        report += f"**目标**: {self.target}\n\n"

        for result in self.results:
            report += f"## {result.tool}\n\n"
            report += f"- **状态**: {result.status}\n"
            report += f"- **耗时**: {result.scan_time:.2f}s\n"
            report += f"- **发现漏洞**: {len(result.vulnerabilities)}\n\n"

            if result.vulnerabilities:
                report += "| ID | 名称 | 严重性 | 文件 | 行号 |\n"
                report += "|---|---|---|---|---|\n"
                for vuln in result.vulnerabilities:
                    report += f"| {vuln.id} | {vuln.name} | {vuln.severity} | {vuln.file} | {vuln.line} |\n"
                report += "\n"

        return report

def main():
    import sys

    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} <target>")
        sys.exit(1)

    target = sys.argv[1]

    pipeline = SecurityPipeline(target)
    results = pipeline.run_all()

    report = pipeline.generate_report()
    print(report)

    # 保存报告
    with open("security-report.md", "w") as f:
        f.write(report)

    print("\n[+] Report saved to security-report.md")

if __name__ == "__main__":
    main()
```

### 4. 集成测试

```python
import pytest
from security_pipeline import NucleiParser, SemgrepParser

class TestNucleiParser:
    def test_parse_valid_json(self):
        parser = NucleiParser()
        json_output = '''
        [
          {
            "template-id": "CVE-2021-44228",
            "info": {"name": "Log4j RCE", "severity": "critical"},
            "host": "http://target.com"
          }
        ]
        '''
        vulns = parser.parse(json_output)
        assert len(vulns) == 1
        assert vulns[0].id == "CVE-2021-44228"
        assert vulns[0].severity == "critical"

    def test_parse_empty_json(self):
        parser = NucleiParser()
        vulns = parser.parse("[]")
        assert len(vulns) == 0
```

### 5. 更新文档

```markdown
## 安全工具集成文档

### 工具列表
- **Nuclei**：漏洞扫描
- **Semgrep**：代码审计

### 使用方法
```bash
# 运行扫描
python3 security_pipeline.py http://target.com

# 查看报告
cat security-report.md
```

### CI/CD 集成
```yaml
# .github/workflows/security.yml
- name: Security Scan
  run: python3 security_pipeline.py ${{ env.TARGET }}
```
```

## 完成标准

- [ ] 工具输入输出格式已了解
- [ ] Parser 已编写
- [ ] Pipeline Tool 已编写
- [ ] 集成测试已通过
- [ ] 文档已更新

## 参考

- `security/research.md` — 安全工具调研
- `security/poc.md` — PoC 编写
- [Nuclei](https://github.com/projectdiscovery/nuclei) — 漏洞扫描
- [Semgrep](https://github.com/returntocorp/semgrep) — 代码审计
