# 智能拍卖合约

这是一个基于以太坊的智能拍卖合约,实现了以下功能:

- 公开拍卖
- 资金绑定的竞标
- 退还资金机制
- 手动结束拍卖
- 时间加权出价奖励
- 竞拍冷却机制
- 拍卖终局延长

## 部署地址

本项目部署在 Holesky 测试网，合约地址为 [0x6ceCf1E1c79fc2B476acA9Ea659EFdDeA2cCb0DA](https://holesky.etherscan.io/address/0x6ceCf1E1c79fc2B476acA9Ea659EFdDeA2cCb0DA)

## 开发环境

本项目使用 Foundry 进行开发和测试。确保你已经安装了 Foundry。

## 测试

运行以下命令来执行测试:

```bash
forge test
```

## 部署和验证

1. 创建一个 `.env` 文件，并添加以下内容：

```
PRIVATE_KEY=你的私钥
BENEFICIARY_ADDRESS=受益人地址
ETHERSCAN_API_KEY=你的 Etherscan API 密钥
```

2. 确保你的 `foundry.toml` 文件包含以下内容：

```
[etherscan]
holesky = { key = "${ETHERSCAN_API_KEY}" }
```

3. 运行以下命令部署到 Holesky 测试网并验证合约：

```bash
forge script script/DeployAuction.s.sol:DeployAuction --rpc-url https://ethereum-holesky.publicnode.com --broadcast --verify -vvvv
```

这个命令会部署您的合约并自动在 Holesky Etherscan 上验证它。

## 合约交互

部署后,你可以使用 ethers.js 或 web3.js 库与合约进行交互。主要函数包括:

- `bid()`: 进行竞标
- `withdraw()`: 提取资金
- `endAuction()`: 结束拍卖

请确保在与合约交互时遵循其规则和限制。

## 安全考虑

- 本合约尚未经过专业审计,请谨慎使用
- 在实际使用中,建议增加更多的安全检查和访问控制
