#!/usr/bin/env node
/**
 * BlockAI Merkle Tree Generator
 * 用于生成白名单 Merkle Root
 */

const { MerkleTree } = require('merkletreejs');
const keccak256 = require('keccak256');
const fs = require('fs');
const path = require('path');

// 示例白名单地址
const whitelistAddresses = [
  '0x1234567890123456789012345678901234567890',
  '0x2345678901234567890123456789012345678901',
  '0x3456789012345678901234567890123456789012',
  // 添加更多地址...
];

/**
 * 从文件读取地址列表
 * @param {string} filePath - 文件路径（每行一个地址）
 * @returns {string[]} 地址数组
 */
function readAddressesFromFile(filePath) {
  const content = fs.readFileSync(filePath, 'utf8');
  return content
    .split('\n')
    .map(addr => addr.trim())
    .filter(addr => addr.length > 0 && addr.startsWith('0x'));
}

/**
 * 生成 Merkle Tree
 * @param {string[]} addresses - 地址列表
 * @returns {Object} Merkle Tree 相关数据
 */
function generateMerkleTree(addresses) {
  // 验证地址格式
  addresses.forEach(addr => {
    if (!addr.match(/^0x[a-fA-F0-9]{40}$/)) {
      throw new Error(`Invalid address format: ${addr}`);
    }
  });

  // 创建叶子节点
  const leaves = addresses.map(addr => 
    keccak256(Buffer.from(addr.slice(2).toLowerCase(), 'hex'))
  );

  // 创建 Merkle Tree
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });

  // 获取根哈希
  const root = tree.getRoot().toString('hex');

  return {
    root,
    rootHex: `0x${root}`,
    leaves: leaves.map(l => `0x${l.toString('hex')}`),
    tree: tree
  };
}

/**
 * 获取地址的 Merkle Proof
 * @param {Object} tree - Merkle Tree 对象
 * @param {string} address - 地址
 * @returns {string[]} Proof 数组
 */
function getMerkleProof(tree, address) {
  const leaf = keccak256(Buffer.from(address.slice(2).toLowerCase(), 'hex'));
  const proof = tree.getProof(leaf);
  return proof.map(p => p.data);
}

/**
 * 验证 Proof
 * @param {Object} tree - Merkle Tree 对象
 * @param {string} root - 根哈希
 * @param {string} address - 地址
 * @param {string[]} proof - Proof 数组
 * @returns {boolean} 验证结果
 */
function verifyProof(tree, root, address, proof) {
  const leaf = keccak256(Buffer.from(address.slice(2).toLowerCase(), 'hex'));
  return tree.verify(proof, leaf, root);
}

// 主函数
function main() {
  console.log('🌳 BlockAI Merkle Tree Generator\n');
  console.log('================================\n');

  // 检查是否有输入文件
  const inputFile = process.argv[2];
  let addresses = whitelistAddresses;

  if (inputFile && fs.existsSync(inputFile)) {
    console.log(`📄 读取文件：${inputFile}`);
    addresses = readAddressesFromFile(inputFile);
    console.log(`✅ 读取到 ${addresses.length} 个地址\n`);
  } else {
    console.log('⚠️  使用示例地址列表\n');
  }

  if (addresses.length === 0) {
    console.error('❌ 错误：没有地址！');
    console.log('用法：node generate-merkle-tree.js [whitelist.txt]');
    process.exit(1);
  }

  // 生成 Merkle Tree
  console.log('🔨 生成 Merkle Tree...');
  const { root, rootHex, tree } = generateMerkleTree(addresses);

  console.log(`✅ 生成成功！\n`);

  // 输出结果
  console.log('📊 结果:');
  console.log('-----------------------------------');
  console.log(`地址数量：${addresses.length}`);
  console.log(`Merkle Root: ${rootHex}`);
  console.log('-----------------------------------\n');

  // 生成示例 Proof
  if (addresses.length > 0) {
    const testAddress = addresses[0];
    const proof = getMerkleProof(tree, testAddress);
    const isValid = verifyProof(tree, Buffer.from(root, 'hex'), testAddress, proof);

    console.log('🧪 示例验证:');
    console.log('-----------------------------------');
    console.log(`测试地址：${testAddress}`);
    console.log(`Proof 长度：${proof.length}`);
    console.log(`验证结果：${isValid ? '✅ 有效' : '❌ 无效'}`);
    console.log('-----------------------------------\n');
  }

  // 保存结果
  const outputDir = path.join(__dirname, '..', 'merkle-output');
  if (!fs.existsSync(outputDir)) {
    fs.mkdirSync(outputDir, { recursive: true });
  }

  const outputFile = path.join(outputDir, `merkle-tree-${Date.now()}.json`);
  const output = {
    root: rootHex,
    addresses: addresses,
    generatedAt: new Date().toISOString(),
    totalAddresses: addresses.length
  };

  fs.writeFileSync(outputFile, JSON.stringify(output, null, 2));
  console.log(`💾 结果已保存：${outputFile}\n`);

  // 生成部署脚本片段
  const scriptOutput = path.join(outputDir, `merkle-deploy-snippet-${Date.now()}.js`);
  const snippet = `
// 在部署脚本中使用此 Merkle Root
const MERKLE_ROOT = "${rootHex}";

// 部署后设置
await nftMint.setMerkleRoot("${rootHex}");
console.log("✅ Merkle Root 已设置");
`;

  fs.writeFileSync(scriptOutput, snippet);
  console.log(`📝 部署片段已保存：${scriptOutput}\n`);

  console.log('================================');
  console.log('✅ 完成！\n');

  // 使用说明
  console.log('📖 使用说明:');
  console.log('-----------------------------------');
  console.log('1. 将 Merkle Root 复制到部署脚本');
  console.log('2. 部署合约后调用 setMerkleRoot()');
  console.log('3. 为用户生成 Proof 用于白名单铸造');
  console.log('4. 测试：使用示例地址验证 Proof');
  console.log('-----------------------------------\n');
}

// 运行
main();
