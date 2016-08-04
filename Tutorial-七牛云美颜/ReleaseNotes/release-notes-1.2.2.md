# PLStreamingKit Release Notes for 1.2.2

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
  - 支持初始化的时候传入 stream 为 nil
  - 支持调节音频编码采样率
  - 支持快速重连操作，方便 4G 推流时切换 WIFI 场景快速切换网络
  - 完善了音频出错时的 log
