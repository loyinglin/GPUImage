# PLStreamingKit Release Notes for 1.0.2

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

### 稳定性

- 修复 dns 解析失败时无 error 回调的问题

### 音频

- 优化音频数据默认为单声道，与 iOS 设备单声道采集贴近

### rtmp

- 针对没有音频 configuration 的推流，优化发送的 onMetaData 信息，只携带视频信息，极大缩短 ffplay, ijkplayer 的等待时间