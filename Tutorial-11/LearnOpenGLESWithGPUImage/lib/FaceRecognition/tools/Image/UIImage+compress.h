
#import <Foundation/Foundation.h>


@interface UIImage (Compress)
- (UIImage *)compressedImage;
- (CGFloat)compressionQuality;
- (NSData *)compressedData;
- (NSData *)compressedData:(CGFloat)compressionQuality;

@end
