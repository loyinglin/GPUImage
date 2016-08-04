# PLCameraStreamingKit 1.1.5 to 1.1.6 API Differences

## General Headers

- *Added* Header `PLStreamingEnv.h`

```
PLStreamingEnv.h
```
- *Added* `+(void)initEnv;`
- *Added* `+(BOOL)isInited;`
- *Added* `+(void)enableQos:(BOOL)flag;`


```
PLStreamingSession.h
```
- *Modified* `- (void)pushAudioSampleBuffer:(CMSampleBufferRef)sampleBuffer completion:(void (^)(void))handler;` to `- (void)pushAudioBuffer:(AudioBuffer *)buffer asbd:(const AudioStreamBasicDescription *)asbd;`
- *Modified* `- (void)pushAudioBuffer:(AudioBuffer *)audioBuffer completion:(void (^)(void))handler;` to `- (void)pushAudioBuffer:(AudioBuffer *)audioBuffer asbd:(const AudioStreamBasicDescription *)asbd completion:(void (^)(BOOL success))handler;`
