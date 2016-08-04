# PLStreamingKit Release Notes for 1.1.0

## 内容

- [简介](#简介)
- [问题反馈](#问题反馈)
- [记录](#记录)
	
## 简介

PLStreamingKit 为 iOS 开发者提供直播推流 SDK。

## 问题反馈

当你遇到任何问题时，可以通过在 GitHub 的 repo 提交 ```issues``` 来反馈问题，请尽可能的描述清楚遇到的问题，如果有错误信息也一同附带，并且在 ```Labels``` 中指明类型为 bug 或者其他。

[通过这里查看已有的 issues 和提交 Bug](https://github.com/pili-engineering/PLStreamingKit/issues)

## 记录

PLStreamingKit 第一公开版本发布，提供基础的编码推流功能，音视频采集及其余工作交给开发者自己完成。

### 架构

- 重构 `PLVideoStreamingConfiguration`, 提供给开发者更大的视频编码定制自由度
- `PLVideoStreamingConfiguration` 提供了 `validate` 方法, 确保 fast fail 减少开发者 app 携带不正确编码参数上线的可能性
- 优化推送音视频数据, 添加了编码处理完后的回调