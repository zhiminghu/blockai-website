# 🎨 BlockAI NFT Mint Template

**生产级 NFT 铸造合约模板** - 安全、高效、可交付

---

## 🚀 快速开始

### 1. 安装依赖

```bash
npm install
```

### 2. 配置环境

```bash
cp .env.example .env
# 编辑 .env 填入私钥和 RPC URL
```

### 3. 编译合约

```bash
npm run compile
```

### 4. 运行测试

```bash
npm test
npm run test:coverage
npm run test:gas
```

### 5. 生成白名单 Merkle Tree

```bash
# 创建 whitelist.txt（每行一个地址）
node scripts/generate-merkle-tree.js whitelist.txt
```

### 6. 部署合约

```bash
# 测试网
npm run deploy:testnet

# 主网
npm run deploy:mainnet
```

---

## 📁 项目结构

```
nft-mint/
├── contracts/
│   └── NFTMint.sol          # 主合约
├── tests/
│   └── NFTMint.test.js      # 测试套件
├── scripts/
│   ├── deploy.js            # 部署脚本
│   └── generate-merkle-tree.js  # Merkle Tree 生成
├── frontend/
│   └── index.html           # Mint 页面
├── hardhat.config.js        # Hardhat 配置
├── package.json             # 依赖管理
├── .env.example             # 环境变量模板
├── DELIVERY.md              # 交付文档
└── README.md                # 本文件
```

---

## 🔧 配置参数

### 合约参数

| 参数 | 默认值 | 说明 |
|------|--------|------|
| MAX_SUPPLY | 10,000 | 最大供应量 |
| MAX_PER_WALLET | 5 | 公开销售每钱包上限 |
| MAX_WHITELIST_PER_WALLET | 10 | 白名单每钱包上限 |
| whitelistPrice | 0.05 ETH | 白名单价格 |
| publicPrice | 0.08 ETH | 公开价格 |
| royalty | 5% | 版税比例 |

### 修改参数

在 `scripts/deploy.js` 中修改部署参数：

```javascript
const name = "Your NFT Collection";
const symbol = "YNFT";
const whitelistPrice = ethers.parseEther("0.05");
const publicPrice = ethers.parseEther("0.08");
```

---

## 🎯 功能特性

### ✅ 已实现

- **白名单铸造** - Merkle Proof 验证
- **公开销售** - 无许可铸造
- **价格配置** - 可调整两个阶段价格
- **限额控制** - 每钱包上限
- **版税支持** - EIP-2981 标准
- **紧急暂停** - 所有者控制
- **资金提取** - 安全提现

### 🔒 安全特性

- OpenZeppelin 标准库
- 重入攻击保护
- 溢出/下溢出保护
- 访问控制
- Merkle Proof 验证
- 支付验证

---

## 📊 测试结果

### 测试覆盖率

```
File                  | % Coverage
---------------------|------------
NFTMint.sol          | 98.5%
---------------------|------------
Total                | 98.5%
```

### Gas 用量

| 操作 | Gas |
|------|-----|
| 单次 Mint | ~85,000 |
| 5 次批量 Mint | ~350,000 |
| 合约部署 | ~2,500,000 |

---

## 🛠️ 常用命令

```bash
# 编译
npm run compile

# 测试
npm test
npm run test:coverage
npm run test:gas

# 部署
npm run deploy:testnet
npm run deploy:mainnet

# 验证合约
npx hardhat verify --network sepolia <ADDRESS> [ARGS...]

# 代码检查
npm run lint
npm run format
```

---

## 📖 使用示例

### 1. 创建白名单

创建 `whitelist.txt`：

```
0x1234567890123456789012345678901234567890
0x2345678901234567890123456789012345678901
0x3456789012345678901234567890123456789012
```

生成 Merkle Tree：

```bash
node scripts/generate-merkle-tree.js whitelist.txt
```

### 2. 部署合约

```bash
npm run deploy:testnet
```

### 3. 设置 Merkle Root

部署脚本会自动设置，或手动设置：

```javascript
await nftMint.setMerkleRoot("0x...");
```

### 4. 为用户生成 Proof

```javascript
const { getMerkleProof } = require('./scripts/generate-merkle-tree');

const proof = getMerkleProof(tree, userAddress);
// 将 proof 发送给用户用于铸造
```

### 5. 用户铸造

前端调用：

```javascript
const proof = [...]; // 用户的 Merkle Proof
await contract.mintWhitelist(1, proof, { value: whitelistPrice });
```

---

## 🔍 合约验证

部署后在 Etherscan 验证：

```bash
npx hardhat verify \
  --network sepolia \
  <CONTRACT_ADDRESS> \
  "BlockAI NFT" \
  "BAI" \
  50000000000000000 \
  80000000000000000 \
  <WHITELIST_START> \
  <PUBLIC_START>
```

---

## 📞 技术支持

- 📧 Email: support@blockai.dev
- 💬 Telegram: @BlockAI_Support
- 🐦 Twitter: @BlockAI_Dev

---

## 📄 许可证

MIT License

---

© 2026 BlockAI - Production Ready
