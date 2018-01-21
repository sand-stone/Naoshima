#ifndef NaoshimaCWrapper_h
#define NaoshimaCWrapper_h
#import <Foundation/NSObject.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#ifdef __cplusplus
}
#endif

@interface NaoshimaCBridge : NSObject
+ (const void *)InitPhotoCluster: (NSString*) pathlandmarkdetectorPath faceRecoModel: (NSString*) faceRecognitionModelPath;
+ (void) FreePhotoCluster:(const void *)pc;
+ (NSArray*) GetFaceDescriptor: (const void *)pc photoPath: (NSString*) photoPath;
@end

#endif
