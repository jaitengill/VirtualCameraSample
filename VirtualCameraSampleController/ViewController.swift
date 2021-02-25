import Cocoa
import DeepAR
import SwiftUI

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate, DeepARDelegate {

    @IBOutlet weak var mainTextField: NSTextField!
    
    @IBOutlet weak var imageView: NSImageView!

    private let context = CIContext()

    private var deepAR: DeepAR!

    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoSession: AVCaptureSession!
    private var cameraDevice: AVCaptureDevice!

    private let CVPixelBufferCreateOptions: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]

    deinit {
        let panel = NSFontManager.shared.fontPanel(true)
        panel?.close()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.prepareCamera()
        self.startSession()
        self.deepAR = DeepAR.init()
        self.deepAR.setLicenseKey("7ff7ace09d26a88cbe4c677bb384fbe4dd792fc91f28847bb5a0cce13cc5efa2d88bda88924f93f5")
        self.deepAR.delegate = self
        self.deepAR.initializeOffscreen(withWidth: 1, height: 1)
        self.deepAR.startCapture(withOutputWidth: 1280, outputHeight: 720, subframe: CGRect(x: 0, y: 0, width: 1280, height: 720))

//        SampleComposerObj.init()
//        self.deepAR.setLicenseKey("62d5b2615f2df5a495f41f5b617ae7eed7eb7f4f67eab92f9dc57327e3b2db87537013befcbe6398")

        mainTextField.delegate = self
    }
    
    
    func didInitialize() {
        self.deepAR?.setRenderingResolutionWithWidth(1280, height: 720)
        self.deepAR?.switchEffect(withSlot: "0", path: Bundle.main.path(forResource: "fire", ofType: nil))

//        self.deepAR.changeLiveMode(false)
        print("INITALIZED")
    }
    
    func didSwitchEffect(_ slot: String!) {
        
    }
    func startSession() {
        if let videoSession = videoSession {
            if !videoSession.isRunning {
                videoSession.startRunning()
            }
        }
    }

    func stopSession() {
        if let videoSession = videoSession {
            if videoSession.isRunning {
                videoSession.stopRunning()
            }
        }
    }
    
    func prepareCamera() {
        self.videoSession = AVCaptureSession()
        self.videoSession.sessionPreset = AVCaptureSession.Preset.high
        self.previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] {
            for device in devices {
                if device.hasMediaType(AVMediaType.video) {
                    cameraDevice = device
                    if cameraDevice != nil {
                        do {
                            let input = try AVCaptureDeviceInput(device: cameraDevice)
                            if videoSession.canAddInput(input) {
                                videoSession.addInput(input)
                            }
                            
                            if let previewLayer = self.previewLayer {
                                if ((previewLayer.connection?.isVideoMirroringSupported) != nil) {
                                    previewLayer.connection?.automaticallyAdjustsVideoMirroring = false
                                    previewLayer.connection?.isVideoMirrored = true
                                }
                                previewLayer.frame = self.view.bounds
                                view.layer = previewLayer
                                view.wantsLayer = true
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sample buffer delegate", attributes: []))
               if videoSession.canAddOutput(videoOutput) {
                   videoSession.addOutput(videoOutput)
               }
        }
        
    }

    override func viewDidAppear() {
        mainTextField.window?.makeFirstResponder(mainTextField)
        let current = SettingsPasteboard.shared.current()
        mainTextField.stringValue = current["text1"] as? String ?? ""
    }

    @IBAction func sendButton_action(_ sender: Any) {
        SettingsPasteboard.shared.settings["text1"] = mainTextField.stringValue
        SettingsPasteboard.shared.update()
    }

    @IBAction func clearButton_action(_ sender: Any) {
        SettingsPasteboard.shared.settings["text1"] = ""
        SettingsPasteboard.shared.update()
    }
    
    func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        let myPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        let myCIimage         = CIImage(cvPixelBuffer: myPixelBuffer!)
        let rep = NSCIImageRep(ciImage: myCIimage)
        let nsImage = NSImage(size: rep.size)
        nsImage.addRepresentation(rep)
        if((nsImage) != nil) {
            DispatchQueue.main.async {
                self.imageView.image =  nsImage
            }

        }
//                let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//                CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
//                let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
//                let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//                // Get BGRA value for pixel (43, 17)
//                let luma: UInt32 = int32Buffer[17 * int32PerRow + 10]
//
//                CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//                print(String(luma))
//        let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//          // Lock the base address of the pixel buffer
//          CVPixelBufferLockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
//
//
//          // Get the number of bytes per row for the pixel buffer
//          let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer!);
//
//          // Get the number of bytes per row for the pixel buffer
//          let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer!);
//          // Get the pixel buffer width and height
//          let width = CVPixelBufferGetWidth(imageBuffer!);
//          let height = CVPixelBufferGetHeight(imageBuffer!);
//
//          // Create a device-dependent RGB color space
//          let colorSpace = CGColorSpaceCreateDeviceRGB();
//
//          // Create a bitmap graphics context with the sample buffer data
//          var bitmapInfo: UInt32 = CGBitmapInfo.byteOrder32Little.rawValue
//          bitmapInfo |= CGImageAlphaInfo.premultipliedFirst.rawValue & CGBitmapInfo.alphaInfoMask.rawValue
//          //let bitmapInfo: UInt32 = CGBitmapInfo.alphaInfoMask.rawValue
//          let context = CGContext.init(data: baseAddress, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
//          // Create a Quartz image from the pixel data in the bitmap graphics context
//          let quartzImage = context?.makeImage();
//          // Unlock the pixel buffer
//          CVPixelBufferUnlockBaseAddress(imageBuffer!, CVPixelBufferLockFlags.readOnly);
//
//          // Create an image object from the Quartz image
////          let image = UIImage.init(cgImage: quartzImage!);
//
//        self.imageView.image =        NSImage.init(cgImage: quartzImage!, size: NSSize(width: 200, height: 200))
        
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
//                        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//                        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
//                        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
//                        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//                        // Get BGRA value for pixel (43, 17)
//                        let luma: UInt32 = int32Buffer[17 * int32PerRow + 10]
//
//                        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//                        print(String(luma))
//        let imageBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
////        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
////
//        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
//        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        // Get BGRA value for pixel (43, 17)
//        let luma: UInt32 = int32Buffer[17 * int32PerRow + 10]
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))

//        print(String(luma))
        
//                let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                  // Lock the base address of the pixel buffer
//        let myPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        self.deepAR?.enqueueCameraFrame(sampleBuffer, mirror: false)

    

//        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        let cameraImage = CIImage(cvImageBuffer: imageBuffer)
//
//        var pixelBuffer: CVPixelBuffer?
//
//          _ = CVPixelBufferCreate(
//              kCFAllocatorDefault,
//              Int(cameraImage.extent.size.width),
//              Int(cameraImage.extent.height),
//              kCVPixelFormatType_32BGRA,
//              self.CVPixelBufferCreateOptions as CFDictionary,
//              &pixelBuffer
//          )
//
//      if let pixelBuffer = pixelBuffer {
//        context.render(cameraImage, to: pixelBuffer)
//        self.deepAR?.processFrame(pixelBuffer, mirror: false, orientation: 0)
//      }
////
    }
}

extension ViewController: NSTextFieldDelegate {

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
            SettingsPasteboard.shared.settings["text1"] =  mainTextField.stringValue
            SettingsPasteboard.shared.update()
            return true
        }
        return false
    }
}
