//
//  CameraController.h
//  ar
//
//  Created by Kod Biro on 04/08/2020.
//

#import <AVFoundation/AVFoundation.h>
#import "DeepAR.h"

@interface CameraController : NSObject

@property (nonatomic, weak) DeepAR* deepAR;

@property (nonatomic, strong) AVCaptureSessionPreset preset;
@property (nonatomic, assign) AVCaptureVideoOrientation videoOrientation;
@property (nonatomic, strong) AVCaptureDevice* videoDevice;
@property (nonatomic, assign) BOOL mirror;

- (instancetype)init;

- (void)checkCameraPermission;

- (void)startCamera;
- (void)stopCamera;

@end
