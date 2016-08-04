# PLCameraStreamingKit 1.1.6 to 1.2.0 API Differences

## General Headers

```
PLStreamingSession.h
```
- *Deprecated* property `@property (nonatomic, copy, readonly) PLVideoStreamingConfiguration  *videoConfiguration`
- *Deprecated* property `@property (nonatomic, copy, readonly) PLAudioStreamingConfiguration  *audioConfiguration`
- *Deprecated* method `- (instancetype)initWithVideoConfiguration:(PLVideoStreamingConfiguration *)videoConfiguration audioConfiguration:(PLAudioStreamingConfiguration *)audioConfiguration stream:(PLStream *)stream`
- *Deprecated* method `- (instancetype)initWithVideoConfiguration:(PLVideoStreamingConfiguration *)videoConfiguration audioConfiguration:(PLAudioStreamingConfiguration *)audioConfiguration stream:(PLStream *)stream dns:(QNDnsManager *)dns`
- *Deprecated* method `- (void)reloadVideoConfiguration:(PLVideoStreamingConfiguration *)videoConfiguration`
- *Deprecated* method `- (void)reloadAudioConfiguration:(PLAudioStreamingConfiguration *)audioConfiguration`

- *Added* property `@property (nonatomic, copy, readonly) PLVideoStreamingConfiguration  *videoStreamingConfiguration;`
- *Added* property `@property (nonatomic, copy, readonly) PLAudioStreamingConfiguration  *audioStreamingConfiguration;`
- *Added* method `- (instancetype)initWithVideoStreamingConfiguration:(PLVideoStreamingConfiguration *)videoStreamingConfiguration audioStreamingConfiguration:(PLAudioStreamingConfiguration *)audioStreamingConfiguration stream:(PLStream *)stream;`
- *Added* method `- (instancetype)initWithVideoStreamingConfiguration:(PLVideoStreamingConfiguration *)videoStreamingConfiguration audioStreamingConfiguration:(PLAudioStreamingConfiguration *)audioStreamingConfiguration stream:(PLStream *)stream dns:(QNDnsManager *)dns;`
- *Added* method `- (void)reloadVideoStreamingConfiguration:(PLVideoStreamingConfiguration *)videoStreamingConfiguration;`
- *Added* method `- (void)reloadAudioStreamingConfiguration:(PLAudioStreamingConfiguration *)audioStreamingConfiguration;`
