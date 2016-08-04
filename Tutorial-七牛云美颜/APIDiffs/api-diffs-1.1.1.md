# PLCameraStreamingKit 1.1.0 to 1.1.1 API Differences

## General Headers

```PLStreamingSession.h```

- *Modified* property `@property (nonatomic, copy) PLVideoStreamingConfiguration  *videoConfiguration;` from `strong` to `copy`
- *Added* method `+ (NSString *)versionInfo;`