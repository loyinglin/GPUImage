# PLCameraStreamingKit 1.0.3 to 1.1.0 API Differences

## General Headers

```PLStreamingSession.h```

- *Added* method `- (void)reloadVideoConfiguration:(PLVideoStreamingConfiguration *)videoConfiguration;`
- *Added* method `- (void)pushVideoSampleBuffer:(CMSampleBufferRef)sampleBuffer completion:(void (^)(void))handler;`
- *Added* method `- (void)pushPixelBuffer:(CVPixelBufferRef)pixelBuffer completion:(void (^)(void))handler;`
- *Added* method `- (void)pushAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer completion:(void (^)(void))handler;`
- *Added* method `- (void)pushAudioBuffer:(AudioBuffer *)audioBuffer completion:(void (^)(void))handler;`
- *removed* method `- (void)beginUpdateConfiguration;`
- *removed* method `- (void)endUpdateConfiguration;`

```PLVideoStreamingConfiguration.h```

- *Modified* property to writable `@property (nonatomic, PL_STRONG) NSString *videoProfileLevel;`
- *Removed* property `@property (nonatomic, assign) PLStreamingDimension dimension;`
- *Removed* property `@property (nonatomic, PL_STRONG) NSString *videoQuality;`
- *Modified* method `+ (instancetype)configurationWithVideoSize:(CGSize)videoSize
                              videoQuality:(NSString *)quality;`
- *Added* method `- (BOOL)validate;`

```PLTypeDefines.h```

- *Removed* type `PLStreamingDimension`