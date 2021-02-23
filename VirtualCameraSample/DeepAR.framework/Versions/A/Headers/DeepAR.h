//
//  DeepAR.h
//  ar
//
//  Created by Kod Biro on 04/08/2020.
//

#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

typedef struct {
    BOOL detected;
    float translation[3];
    float rotation[3];
    float poseMatrix[16];
    float landmarks[68*3];
    float landmarks2d[68*3];
    float faceRect[4];
    float emotions[5]; // 0=neutral, 1=happiness, 2=surprise, 3=sadness, 4=anger
    float actionUnits[63];
    int numberOfActionUnits;
} FaceData;

typedef struct {
    FaceData faceData[4];
} MultiFaceData;

typedef struct {
    float x;
    float y;
    float z;
    float w;
} Vector4;

typedef struct {
    float x;
    float y;
    float z;
} Vector3;

typedef enum
{
    Undefined, // 0

    RGBA,      // 1
    BGRA,      // 2
    ARGB,      // 3
    ABGR,      // 4
    
    COUNT
} OutputFormat;

typedef enum {
    DEEPAR_ERROR_TYPE_DEBUG,
    DEEPAR_ERROR_TYPE_INFO,
    DEEPAR_ERROR_TYPE_WARNING,
    DEEPAR_ERROR_TYPE_ERROR
} ARErrorType;

@protocol DeepARDelegate <NSObject>

@optional

// Called when screenshot is taken
- (void)didTakeScreenshot:(NSImage*)screenshot;

// Called when the engine initialization is complete.
- (void)didInitialize;

// Called when the face appears or disappears.
- (void)faceVisiblityDidChange:(BOOL)faceVisible;

// Called when the new frame is available
- (void)frameAvailable:(CMSampleBufferRef)sampleBuffer;

- (void)faceTracked:(MultiFaceData)faceData;

- (void)numberOfFacesVisibleChanged:(NSInteger)facesVisible;

- (void)didFinishShutdown;

- (void)imageVisibilityChanged:(NSString*)gameObjectName imageVisible:(BOOL)imageVisible;

- (void)didSwitchEffect:(NSString*)slot;

- (void)animationTransitionedToState:(NSString*)state;

// Called when the video recording is started.
- (void)didStartVideoRecording;

// Called when the video recording is finished and video file is saved.
- (void)didFinishVideoRecording:(NSString*)videoFilePath;

// Called if there is error encountered while recording video
- (void)recordingFailedWithError:(NSError*)error;

- (void)onErrorWithCode:(ARErrorType)code error:(NSString*)error;

@end

@interface DeepAR : NSObject

@property (nonatomic, weak) id<DeepARDelegate> delegate;

@property (nonatomic, readonly) BOOL visionInitialized;
@property (nonatomic, readonly) BOOL renderingInitialized;
@property (nonatomic, readonly) BOOL faceVisible;
@property (nonatomic, readonly) CGSize renderingResolution;

// You can get your license key on https://developer.deepar.ai
- (void)setLicenseKey:(NSString*)key;

// Starts the engine initialization for rendering into given window.
- (void)initializeWithWidth:(NSInteger)width height:(NSInteger)height context:(NSOpenGLContext*)context;

// Starts the engine initialization where only components for computer vision are initialized (no rendering).
- (void)initialize;

// Starts the engine initialization for rendering into created view.
- (NSView*)initializeViewWithFrame:(NSRect)frame;

// Starts the engine initialization for rendering into offscreen texture.
- (void)initializeOffscreenWithWidth:(NSInteger)width height:(NSInteger)height;

// Gets if only vision API is evaulating (no rendering).
- (BOOL)isVisionOnly;

// Changes the rendering/output resolution
- (void)setRenderingResolutionWithWidth:(NSInteger)width height:(NSInteger)height;

// Creates a new view into which engine will render.
- (NSView*)switchToRenderingToViewWithFrame:(CGRect)frame;

// Switches to offscreen rendering.
- (void)switchToRenderingOffscreenWithWidth:(NSInteger)width height:(NSInteger)height;

// Change if should render frame by frame or render continuously.
// liveMode - YES for render continuously; NO for render frame by frame.
- (void)changeLiveMode:(BOOL)liveMode;

// Shutdowns the engine
- (void)shutdown;

// Process the camera frame. Supported input resolutions are 640x480, 480x640, 1280x720, 720x1280
- (void)processFrame:(CVPixelBufferRef)imageBuffer mirror:(BOOL)mirror orientation:(NSInteger) orientation;

// Process the camera frame and fills the given buffer with processed pixels. Supported input resolutions are 640x480, 480x640, 1280x720, 720x1280.
// Requires frame capturing to be started!
- (void)processFrameAndReturn:(CVPixelBufferRef)imageBuffer outputBuffer:(CVPixelBufferRef)outputBuffer mirror:(BOOL)mirror orientation:(NSInteger) orientation;

// Passes the camera frame into the engine. This should only be called after initializeWithCustomCameraUsingPreset.
- (void)enqueueCameraFrame:(CMSampleBufferRef)sampleBuffer mirror:(BOOL)mirror;

// Load and switch to effect.
// slot - this parameter is used to specify a "namespace" for effect. No two effects can be in
// one slot, so if we load new effect into already occupied slot, the old effect will be
// removed.
// path - The absolute path to the effect file.
- (void)switchEffectWithSlot:(NSString*)slot path:(NSString*)path;

// Switch effect for the face. Allowed values for face parameters are 0,1,2,3.
// This will only work if the DeepAR SDK build has multi face tracking enabled
- (void)switchEffectWithSlot:(NSString*)slot path:(NSString*)path face:(NSInteger)face;
- (void)switchEffectWithSlot:(NSString*)slot path:(NSString*)path face:(NSInteger)face targetGameObject:(NSString*)targetGameObject;
- (void)switchEffectWithSlot:(NSString*)slot data:(uint8_t*)effectData size:(NSInteger)size face:(uint32_t)face;
// Captures the screen. Delegate method didTakeScreenshot will be called when capture is finished.
- (void)takeScreenshot;

// Starts streaming the subframes to delegate method frameAvailable.
// CGRect subframe defines the area we want to record in normalized coordinates (from 0.0 to 1.0)
- (void)startCaptureWithOutputWidth:(NSInteger)outputWidth outputHeight:(NSInteger)outputHeight subframe:(CGRect)subframe;

// Start capturing with custom output image format.
- (void)startCaptureWithOutputWidthAndFormat:(NSInteger)outputWidth outputHeight:(NSInteger)outputHeight subframe:(CGRect)subframe outputImageFormat:(OutputFormat)outputFormat;

// Stops streaming
- (void)stopCapture;

// Fire trigger for all animation controllers
- (void)fireTrigger:(NSString*)trigger;

- (void)touchEvent;

// Display debuging stats on screen (if rendering is on).
- (void)showStats:(BOOL) enabled;
// Display debuging landmarks on screen
- (void)showLandmarks:(BOOL) enabled;
// Change face detection sensitivity
- (void)setFaceDetectionSensitivity:(NSInteger)sensitivity;

// Change a float parameter on a GameObject, the parameter variable contains parameter name, eg. blendshape name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter floatValue:(float)value;
// Change a vector4 parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter vectorValue:(Vector4)value;
// Change a vector3 parameter on a GameObject, the parameter variable contains parameter name, eg. transform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter vector3Value:(Vector3)value;
// Change a bool parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter boolValue:(BOOL)value;
// Change a string parameter on a GameObject, eg. blend mode
- (void)changeParameter:(NSString *)gameObject component:(NSString *)component parameter:(NSString *)parameter stringValue:(NSString *)value;
// Change an image parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter image:(NSImage*)image;
// Change an image parameter on a GameObject, the parameter variable contains parameter name, eg. uniform name
- (void)changeParameter:(NSString*)gameObject component:(NSString*)component parameter:(NSString*)parameter image:(uint8_t*)image width:(NSInteger)width height:(NSInteger)height;

// Resumes the rendering
- (void)resume;

// Pauses the rendering.
- (void)pause;

- (void)setParameterWithKey:(NSString*)key value:(NSString*)value;

@end

#import "CameraController.h"
