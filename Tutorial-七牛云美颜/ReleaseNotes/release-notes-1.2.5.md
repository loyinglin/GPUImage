# PLStreamingKit Release Notes for 1.2.5

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

- 功能
  - 新增自动重连功能
- 缺陷
  - 修复 `-pushAudioBuffer:asbd:` 方法当 `asbd` 为 `NULL` 时 crash 的问题
  - 修复 iOS 8 下的音频编码内存泄露问题
  - 修复 `-restartWithCompleted:` 方法可能导致的播放没有画面和声音的问题
  - 修复网络丢包率高时可能导致的 DNS 无法正常超时返回的问题
  - 修复偶尔出现的死锁问题
  - 修复时间戳生成时机不当可能导致的音画不同步问题
