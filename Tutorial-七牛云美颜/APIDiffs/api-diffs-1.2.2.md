# PLCameraStreamingKit 1.2.1 to 1.2.2 API Differences

```
PLStreamingSession.h
```

- *Added* method `- (void)restartWithCompleted:(void (^)(BOOL success))handler;`

```
PLAudioStreamingConfiguration.h
```

- *Modified* property `@property (nonatomic, assign, readonly) NSUInteger encodedAudioSampleRate;` to `@property (nonatomic, assign) NSUInteger encodedAudioSampleRate;`
- *Added* method `- (instancetype)initWithAudioQuality:(NSString *)quality;`
- *Added* method `- (instancetype)initWithEncodedAudioSampleRate:(NSUInteger)sampleRate encodedNumberOfChannels:(UInt32)numberOfChannels audioBitRate:(PLStreamingAudioBitRate)audioBitRate;`

```
PLTypeDefines.h
```

- *Added* enum `PLStreamErrorReconnectFailed = -1400`

## General Headers
