# PLCameraStreamingKit 1.1.3 to 1.1.4 API Differences

## General Headers

```PLStreamingSession.h```

- *Added* Category `PLStreamingSession (Network)`
    - *Added* `@property (nonatomic, assign) int   receiveTimeout;`
    - *Added* `@property (nonatomic, assign) int   sendTimeout;`