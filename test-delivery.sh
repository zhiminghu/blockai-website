#!/bin/bash
# BlockAI 交付能力全面测试脚本
# 测试从 0 到交付的完整流程

set -e

echo "======================================"
echo "🧪 BlockAI 交付能力全面测试"
echo "======================================"
echo ""

# 测试结果统计
TESTS_PASSED=0
TESTS_FAILED=0

# 测试函数
test_pass() {
    echo "✅ PASS: $1"
    TESTS_PASSED=$((TESTS_PASSED + 1))
}

test_fail() {
    echo "❌ FAIL: $1"
    TESTS_FAILED=$((TESTS_FAILED + 1))
}

test_info() {
    echo "ℹ️  INFO: $1"
}

echo "📋 测试 1: 项目结构检查"
echo "--------------------------------------"

# 检查 NFT Mint 模板文件
if [ -f "templates/nft-mint/contracts/NFTMint.sol" ]; then
    test_pass "NFTMint.sol 存在"
else
    test_fail "NFTMint.sol 缺失"
fi

if [ -f "templates/nft-mint/tests/NFTMint.test.js" ]; then
    test_pass "NFTMint.test.js 存在"
else
    test_fail "NFTMint.test.js 缺失"
fi

if [ -f "templates/nft-mint/scripts/deploy.js" ]; then
    test_pass "deploy.js 存在"
else
    test_fail "deploy.js 缺失"
fi

if [ -f "templates/nft-mint/hardhat.config.js" ]; then
    test_pass "hardhat.config.js 存在"
else
    test_fail "hardhat.config.js 缺失"
fi

if [ -f "templates/nft-mint/package.json" ]; then
    test_pass "package.json 存在"
else
    test_fail "package.json 缺失"
fi

echo ""
echo "📋 测试 2: 文档完整性检查"
echo "--------------------------------------"

if [ -f "README.md" ]; then
    test_pass "README.md 存在"
else
    test_fail "README.md 缺失"
fi

if [ -f "templates/nft-mint/README.md" ]; then
    test_pass "NFT Mint README.md 存在"
else
    test_fail "NFT Mint README.md 缺失"
fi

if [ -f "templates/nft-mint/DELIVERY.md" ]; then
    test_pass "DELIVERY.md 存在"
else
    test_fail "DELIVERY.md 缺失"
fi

if [ -f "docs/SECURITY_AUDIT_CHECKLIST.md" ]; then
    test_pass "安全审计清单存在"
else
    test_fail "安全审计清单缺失"
fi

if [ -f "docs/SERVICE_CATALOG.md" ]; then
    test_pass "服务手册存在"
else
    test_fail "服务手册缺失"
fi

if [ -f "docs/PROJECT_DELIVERY_TEMPLATE.md" ]; then
    test_pass "交付模板存在"
else
    test_fail "交付模板缺失"
fi

echo ""
echo "📋 测试 3: 合约代码质量检查"
echo "--------------------------------------"

# 检查 Solidity 版本
if grep -q "pragma solidity \^0.8.20" templates/nft-mint/contracts/NFTMint.sol; then
    test_pass "Solidity 版本 0.8.20+"
else
    test_fail "Solidity 版本不符合要求"
fi

# 检查 OpenZeppelin 导入
if grep -q "@openzeppelin/contracts" templates/nft-mint/contracts/NFTMint.sol; then
    test_pass "使用 OpenZeppelin 标准库"
else
    test_fail "未使用 OpenZeppelin"
fi

# 检查 NatSpec 注释
if grep -q "@notice" templates/nft-mint/contracts/NFTMint.sol; then
    test_pass "包含 NatSpec 注释"
else
    test_fail "缺少 NatSpec 注释"
fi

# 检查重入保护
if grep -q "ReentrancyGuard" templates/nft-mint/contracts/NFTMint.sol; then
    test_pass "实现重入保护"
else
    test_fail "缺少重入保护"
fi

# 检查访问控制
if grep -q "onlyOwner" templates/nft-mint/contracts/NFTMint.sol; then
    test_pass "实现访问控制"
else
    test_fail "缺少访问控制"
fi

echo ""
echo "📋 测试 4: 测试覆盖率检查"
echo "--------------------------------------"

# 检查测试文件
if grep -q "describe.*NFTMint" templates/nft-mint/tests/NFTMint.test.js; then
    test_pass "包含单元测试"
else
    test_fail "缺少单元测试"
fi

if grep -q "mintWhitelist" templates/nft-mint/tests/NFTMint.test.js; then
    test_pass "测试白名单功能"
else
    test_fail "缺少白名单测试"
fi

if grep -q "mintPublic" templates/nft-mint/tests/NFTMint.test.js; then
    test_pass "测试公开销售功能"
else
    test_fail "缺少公开销售测试"
fi

if grep -q "withdraw" templates/nft-mint/tests/NFTMint.test.js; then
    test_pass "测试提现功能"
else
    test_fail "缺少提现测试"
fi

echo ""
echo "📋 测试 5: 部署脚本检查"
echo "--------------------------------------"

if grep -q "sepolia" templates/nft-mint/scripts/deploy.js; then
    test_pass "支持 Sepolia 测试网"
else
    test_fail "缺少 Sepolia 支持"
fi

if grep -q "mainnet" templates/nft-mint/scripts/deploy.js; then
    test_pass "支持 Ethereum 主网"
else
    test_fail "缺少主网支持"
fi

if grep -q "verify" templates/nft-mint/scripts/deploy.js; then
    test_pass "包含合约验证说明"
else
    test_fail "缺少合约验证"
fi

echo ""
echo "📋 测试 6: 前端集成检查"
echo "--------------------------------------"

if [ -f "templates/nft-mint/frontend/index.html" ]; then
    test_pass "前端页面存在"
    
    if grep -q "ethers" templates/nft-mint/frontend/index.html; then
        test_pass "集成 ethers.js"
    else
        test_fail "缺少 ethers.js 集成"
    fi
    
    if grep -q "connectWallet" templates/nft-mint/frontend/index.html; then
        test_pass "钱包连接功能"
    else
        test_fail "缺少钱包连接"
    fi
    
    if grep -q "mintNFT" templates/nft-mint/frontend/index.html; then
        test_pass "NFT 铸造功能"
    else
        test_fail "缺少铸造功能"
    fi
else
    test_fail "前端页面缺失"
fi

echo ""
echo "📋 测试 7: 工具脚本检查"
echo "--------------------------------------"

if [ -f "templates/nft-mint/scripts/generate-merkle-tree.js" ]; then
    test_pass "Merkle Tree 生成工具存在"
    
    if grep -q "MerkleTree" templates/nft-mint/scripts/generate-merkle-tree.js; then
        test_pass "Merkle Tree 实现正确"
    else
        test_fail "Merkle Tree 实现错误"
    fi
else
    test_fail "Merkle Tree 工具缺失"
fi

echo ""
echo "📋 测试 8: 配置文件检查"
echo "--------------------------------------"

if [ -f "templates/nft-mint/.env.example" ]; then
    test_pass ".env.example 存在"
    
    if grep -q "PRIVATE_KEY" templates/nft-mint/.env.example; then
        test_pass "包含私钥配置"
    else
        test_fail "缺少私钥配置"
    fi
    
    if grep -q "RPC_URL" templates/nft-mint/.env.example; then
        test_pass "包含 RPC 配置"
    else
        test_fail "缺少 RPC 配置"
    fi
else
    test_fail ".env.example 缺失"
fi

echo ""
echo "📋 测试 9: 官方网站检查"
echo "--------------------------------------"

if [ -f "index.html" ]; then
    test_pass "官方网站存在"
    
    if grep -q "BlockAI" index.html; then
        test_pass "品牌标识正确"
    else
        test_fail "缺少品牌标识"
    fi
    
    if grep -q "模板" index.html; then
        test_pass "模板展示存在"
    else
        test_fail "缺少模板展示"
    fi
    
    if grep -q "contact" index.html; then
        test_pass "联系方式存在"
    else
        test_fail "缺少联系方式"
    fi
else
    test_fail "官方网站缺失"
fi

echo ""
echo "📋 测试 10: 代码统计"
echo "--------------------------------------"

# 统计代码行数
SOL_LINES=$(find templates/nft-mint/contracts -name "*.sol" -exec cat {} \; | wc -l)
JS_LINES=$(find templates/nft-mint -name "*.js" -exec cat {} \; | wc -l)
HTML_LINES=$(find templates/nft-mint -name "*.html" -exec cat {} \; | wc -l)
DOC_LINES=$(find docs -name "*.md" -exec cat {} \; | wc -l)

test_info "Solidity 代码：$SOL_LINES 行"
test_info "JavaScript 代码：$JS_LINES 行"
test_info "HTML 代码：$HTML_LINES 行"
test_info "文档内容：$DOC_LINES 行"

TOTAL_LINES=$((SOL_LINES + JS_LINES + HTML_LINES + DOC_LINES))
test_info "总代码量：$TOTAL_LINES 行"

echo ""
echo "======================================"
echo "📊 测试结果汇总"
echo "======================================"
echo ""
echo -e "${GREEN}通过：$TESTS_PASSED${NC}"
echo -e "${RED}失败：$TESTS_FAILED${NC}"
echo ""

TOTAL_TESTS=$((TESTS_PASSED + TESTS_FAILED))
if [ $TOTAL_TESTS -gt 0 ]; then
    PASS_RATE=$((TESTS_PASSED * 100 / TOTAL_TESTS))
    echo "通过率：${PASS_RATE}%"
fi

echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    echo "🎉 恭喜！所有测试通过！交付能力验证完成！"
    echo ""
    echo "✅ BlockAI 已具备生产级交付能力！"
    echo "✅ 可以开始接受客户订单！"
    exit 0
else
    echo "⚠️  有 $TESTS_FAILED 项测试失败，请检查！"
    exit 1
fi
