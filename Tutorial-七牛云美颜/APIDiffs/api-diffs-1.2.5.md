# PLCameraStreamingKit 1.2.4 to 1.2.5 API Differences

```
PLStreamingSession.h
```

- *Added* property `@property (nonatomic, assign) BOOL  autoReconnectEnable;`

```
PLAudioStreamingConfiguration.h
```

- *Modified* property `@property (nonatomic, assign) NSUInteger encodedAudioSampleRate;` to `@property (nonatomic, assign) PLStreamingAudioSampleRate encodedAudioSampleRate;`
- *Added* method `+(PLStreamingAudioSampleRate)mostSimilarSupportedValueWithEncodedAudioSampleRate:(NSUInteger)sampleRate;`
- *Modified* method `- (instancetype)initWithEncodedAudioSampleRate:(NSUInteger)sampleRate encodedNumberOfChannels:(UInt32)numberOfChannels audioBitRate:(PLStreamingAudioBitRate)audioBitRate;` to `- (instancetype)initWithEncodedAudioSampleRate:(PLStreamingAudioSampleRate)sampleRate encodedNumberOfChannels:(UInt32)numberOfChannels audioBitRate:(PLStreamingAudioBitRate)audioBitRate;`

## General Headers
