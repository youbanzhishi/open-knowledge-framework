#!/bin/bash
# 测试工程师 - 角色专属环境配置

# 测试报告目录
export TEST_REPORT_DIR="$REPO_DIR/交接台/测试报告"
mkdir -p "$TEST_REPORT_DIR" 2>/dev/null || true

# Bug单目录
export BUG_DIR="$REPO_DIR/交接台/bug单"

echo "  🧪 TEST_REPORT_DIR=$TEST_REPORT_DIR"
echo "  🧪 BUG_DIR=$BUG_DIR"
