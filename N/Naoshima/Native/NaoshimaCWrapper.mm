#import "opencv2/opencv.hpp"

#import <Foundation/Foundation.h>

#ifdef __cplusplus
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdocumentation"

#import "NaoshimaCWrapper.h"
#include "PhotoCluster.h"

#pragma clang pop
#endif

using namespace std;
using namespace cv;

#pragma mark - Private Declarations

@interface NaoshimaCBridge ()

#ifdef __cplusplus

#endif

@end

#pragma mark - NaoshimaCBridge

@implementation NaoshimaCBridge

#pragma mark Public

+ (const void *)InitPhotoCluster: (NSString*) pathlandmarkdetectorPath faceRecoModel: (NSString*) faceRecognitionModelPath {    
    PhotoCluster* pc = new PhotoCluster([pathlandmarkdetectorPath cStringUsingEncoding:NSUTF8StringEncoding], [faceRecognitionModelPath cStringUsingEncoding:NSUTF8StringEncoding]);
    return pc;
}

+ (void) FreePhotoCluster:(const void *)pc {    
    delete (PhotoCluster*)pc;
}

+ (NSArray*) GetFaceDescriptor: (const void *)pc photoPath: (NSString*) photoPath {
    std::vector<matrix<float,0,1>> faceDescriptors;
    ((PhotoCluster*)pc)->GetFaceDescriptor([photoPath cStringUsingEncoding:NSUTF8StringEncoding], faceDescriptors);
    NSMutableArray *container = [[NSMutableArray alloc] initWithCapacity:0];
    for (int m = 0; m < faceDescriptors.size(); m++) {
        matrix<float,0,1>& faceDescriptor = faceDescriptors[m];
        std::vector<float> faceDescriptorVec(faceDescriptor.begin(), faceDescriptor.end());
        NSMutableArray *vec = [[NSMutableArray alloc] initWithCapacity:0];
        for (int n = 0; n < faceDescriptorVec.size(); n++) {
            [vec addObject:[NSNumber numberWithDouble:faceDescriptorVec[n]]];
        }
        [container addObject: vec];
    }
    return container;
}

@end
