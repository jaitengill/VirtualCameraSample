import Cocoa
import DeepAR
import SwiftUI

class ViewController: NSViewController, AVCaptureVideoDataOutputSampleBufferDelegate, DeepARDelegate, NSCollectionViewDataSource, NSCollectionViewDelegate {

    @IBOutlet weak var mainTextField: NSTextField!
    
    @IBOutlet weak var imageView: NSImageView!

    @IBOutlet weak var filtersView: NSCollectionView!
    @IBOutlet weak var cameraPreviewView: NSView!

    
    private let context = CIContext()

    private var deepAR: DeepAR!

    private let filters = Filters().filters

    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoSession: AVCaptureSession!
    private var cameraDevice: AVCaptureDevice!

    private var sessionQueue: DispatchQueue!
    private var videoOutputQueue: DispatchQueue!

    
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
       
        self.filtersView.delegate = self
        self.filtersView.dataSource = self
        self.filtersView.register(FilterCollectionViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FilterCollectionViewItem"))
        self.deepAR = DeepAR()
        self.deepAR.setLicenseKey("7ff7ace09d26a88cbe4c677bb384fbe4dd792fc91f28847bb5a0cce13cc5efa2d88bda88924f93f5")
        self.deepAR.delegate = self
     

        self.prepareCamera()
        self.startSession()
        self.deepAR.changeLiveMode(true)
        self.deepAR.initializeOffscreen(withWidth: 0, height: 0)
//        self.deepAR.setParameterWithKey("synchronous_vision_initialization", value: "true")
//        self.deepAR.setParameterWithKey("synchronous_vision_initialization", value: "true")

//        SampleComposerObj.init()
//        self.deepAR.setLicenseKey("62d5b2615f2df5a495f41f5b617ae7eed7eb7f4f67eab92f9dc57327e3b2db87537013befcbe6398")

//        mainTextField.delegate = self
    }
    
    
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        // 4
        
        
        let item = self.filtersView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "FilterCollectionViewItem"), for: indexPath)
         guard let collectionViewItem = item as? FilterCollectionViewItem else {return item}
        
        let filter = filters[indexPath.item]
        
        collectionViewItem.image = filter.image
        collectionViewItem.name = filter.name
         
         return collectionViewItem
    }
    
    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        let filter = self.filters[(indexPaths.first?[1])!] as FilterObject
        SettingsPasteboard.shared.settings["filter"] = filter.path
        SettingsPasteboard.shared.update()
        
        self.deepAR.switchEffect(withSlot: "0", path:         Bundle.main.path(forResource: filter.path, ofType: nil))
    }
    func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 160.0, height: 140.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 20.0, bottom: 10.0, right: 20.0)
        flowLayout.minimumInteritemSpacing = 20.0
        flowLayout.minimumLineSpacing = 20.0
        self.filtersView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
//        self.filtersView.layer?.backgroundColor = NSColor.blackColor().CGColor
    }
    
    func didInitialize() {
//        self.startSession()
        self.deepAR?.switchEffect(withSlot: "0", path: Bundle.main.path(forResource: "fire", ofType: nil))
//        self.deepAR.startCapture(withOutputWidthAndFormat: 1280, outputHeight: 720, subframe: CGRect(x: 0, y: 0, width: 1280, height: 720), outputImageFormat: BGRA)
//        self.deepAR.changeLiveMode(true)

        self.deepAR.setRenderingResolutionWithWidth(300, height: 300)
        print("INITALIZED")
    }
    
    func didSwitchEffect(_ slot: String!) {
        
    }
    func startSession() {
        if let videoSession = videoSession {
            if !videoSession.isRunning {
//                videoSession.canSetSessionPreset(AVCaptureSession.Preset.vga640x480)
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
//        self.previewLayer = AVCaptureVideoPreviewLayer(session: videoSession)
//        self.previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        if let devices = AVCaptureDevice.devices() as? [AVCaptureDevice] {
            for device in devices {
                if device.hasMediaType(AVMediaType.video) && device.localizedName == "FaceTime HD Camera (Built-in)" {
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
                                previewLayer.frame = self.cameraPreviewView.bounds
                                self.cameraPreviewView.layer = previewLayer
                                self.cameraPreviewView.wantsLayer = true
                            }
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
            }
            let videoOutput = AVCaptureVideoDataOutput()
            videoOutput.alwaysDiscardsLateVideoFrames = true
            videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)]
            videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "ai.deepar.camera.videoqueue", attributes: []))
               if videoSession.canAddOutput(videoOutput) {
                   videoSession.addOutput(videoOutput)
               }
        }
        
    }

    override func viewDidAppear() {
//        mainTextField.window?.makeFirstResponder(mainTextField)
        let current = SettingsPasteboard.shared.current()
//        mainTextField.stringValue = current["text1"] as? String ?? ""
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

//        SettingsPasteboard.shared.settings["filter"] =
//        SettingsPasteboard.shared.settings["camera"] =

//        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        print(CVPixelBufferGetHeight(pixelBuffer))
//        print(CVPixelBufferGetWidth(pixelBuffer))
//        print(CVPixelBufferGetPixelFormatName(pixelBuffer: pixelBuffer))
//
////
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
//        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
//        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        // Get BGRA value for pixel (43, 17)
//        let luma: UInt32 = int32Buffer[17 * int32PerRow + 10]
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//        print(String(luma))
        let myPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
////        print(myPixelBuffer?.pixelFormatName())
//
////        print(myPixelBuffer)
        let myCIimage         = CIImage(cvPixelBuffer: myPixelBuffer!)
        let ciContext = CIContext(options: nil)
        let videoImage = ciContext.createCGImage(myCIimage, from: CGRect(x: 0, y: 0, width: CVPixelBufferGetWidth(myPixelBuffer!), height: CVPixelBufferGetHeight(myPixelBuffer!)))!
//        print(myCIimage)
        let nsImage = NSImage(cgImage: videoImage, size: NSSize.zero)
        
        if((nsImage) != nil) {
            DispatchQueue.main.async {
                self.imageView.image =  nsImage
            }
        }

        

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
//        print(connection.isActive)
        
//        let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
////
////
//        CVPixelBufferLockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0));
//        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer), to: UnsafeMutablePointer<UInt32>.self)
//        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer)
//        // Get BGRA value for pixel (43, 17)
//        let luma: UInt32 = int32Buffer[17 * int32PerRow + 10]
//
//        CVPixelBufferUnlockBaseAddress(pixelBuffer, CVPixelBufferLockFlags(rawValue: 0))
//
//        print(CVPixelBufferGetPixelFormatName(pixelBuffer: pixelBuffer))
//
//
//        if((self.deepAR) != nil && self.deepAR.renderingInitialized && self.videoSession.isRunning) {
            self.deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
//        }
//
//        if((self.deepAR) != nil) {
//            self.deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
//        }
//                let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)!
//        self.deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
//
////        print(pixelBuffer.pixelFormatName())
//        print(self.deepAR.renderingInitialized)
//        print(self.deepAR.renderingResolution)
//        self.deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
//        if #available(OSX 10.15, *) {
//            deepAR.processFrame(sampleBuffer.imageBuffer, mirror: false, orientation: 0)
//        } else {
//            // Fallback on earlier versions
//        }

//        var pixelBuffer2: CVPixelBuffer?
//
//          _ = CVPixelBufferCreate(
//              kCFAllocatorDefault,
//              Int(1280),
//              Int(720),
//              kCVPixelFormatType_32BGRA,
//              self.CVPixelBufferCreateOptions as CFDictionary,
//              &pixelBuffer2
//          )
////
//      if let pixelBuffer2 = pixelBuffer2 {
//        self.deepAR.processFrameAndReturn(pixelBuffer, outputBuffer: pixelBuffer2, mirror: false, orientation: 0)
//        CVPixelBufferLockBaseAddress(pixelBuffer2, CVPixelBufferLockFlags(rawValue: 0));
//        let int32Buffer = unsafeBitCast(CVPixelBufferGetBaseAddress(pixelBuffer2), to: UnsafeMutablePointer<UInt32>.self)
//        let int32PerRow = CVPixelBufferGetBytesPerRow(pixelBuffer2)
//        // Get BGRA value for pixel (43, 17)
//        let luma2: UInt32 = int32Buffer[17 * int32PerRow + 10]
//        print(String(luma2))
//      }
//
//

        
//        let myPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
////        print(myPixelBuffer)
//        let myCIimage         = CIImage(cvPixelBuffer: myPixelBuffer!)
////        print(myCIimage)
//        let rep = NSCIImageRep(ciImage: myCIimage)
//        let nsImage = NSImage(size: rep.size)
//        print(nsImage)
//        nsImage.addRepresentation(rep)
////        if((nsImage) != nil) {
//            DispatchQueue.main.async {
//                self.imageView.image =  nsImage
//            }

        
        
//        deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
//
//        if #available(OSX 10.15, *) {
//        } else {
//            // Fallback on earlier versions
//        }
//        self.deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
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

        
//                let  imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
                  // Lock the base address of the pixel buffer
//        let myPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
//        var pixelBuffer: CVPixelBuffer;
//
//        let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
//        if imageBuffer != nil && (CFGetTypeID(imageBuffer) == CVPixelBufferGetTypeID()) {
//            pixelBuffer = imageBuffer!
//            self.deepAR?.processFrame(pixelBuffer, mirror: false, orientation: 0)
//
//        }
//

    

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


public func CVPixelBufferGetPixelFormatName(pixelBuffer: CVPixelBuffer) -> String {
    let p = CVPixelBufferGetPixelFormatType(pixelBuffer)
    switch p {
    case kCVPixelFormatType_1Monochrome:                   return "kCVPixelFormatType_1Monochrome"
    case kCVPixelFormatType_2Indexed:                      return "kCVPixelFormatType_2Indexed"
    case kCVPixelFormatType_4Indexed:                      return "kCVPixelFormatType_4Indexed"
    case kCVPixelFormatType_8Indexed:                      return "kCVPixelFormatType_8Indexed"
    case kCVPixelFormatType_1IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_1IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_2IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_2IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_4IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_4IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_8IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_8IndexedGray_WhiteIsZero"
    case kCVPixelFormatType_16BE555:                       return "kCVPixelFormatType_16BE555"
    case kCVPixelFormatType_16LE555:                       return "kCVPixelFormatType_16LE555"
    case kCVPixelFormatType_16LE5551:                      return "kCVPixelFormatType_16LE5551"
    case kCVPixelFormatType_16BE565:                       return "kCVPixelFormatType_16BE565"
    case kCVPixelFormatType_16LE565:                       return "kCVPixelFormatType_16LE565"
    case kCVPixelFormatType_24RGB:                         return "kCVPixelFormatType_24RGB"
    case kCVPixelFormatType_24BGR:                         return "kCVPixelFormatType_24BGR"
    case kCVPixelFormatType_32ARGB:                        return "kCVPixelFormatType_32ARGB"
    case kCVPixelFormatType_32BGRA:                        return "kCVPixelFormatType_32BGRA"
    case kCVPixelFormatType_32ABGR:                        return "kCVPixelFormatType_32ABGR"
    case kCVPixelFormatType_32RGBA:                        return "kCVPixelFormatType_32RGBA"
    case kCVPixelFormatType_64ARGB:                        return "kCVPixelFormatType_64ARGB"
    case kCVPixelFormatType_48RGB:                         return "kCVPixelFormatType_48RGB"
    case kCVPixelFormatType_32AlphaGray:                   return "kCVPixelFormatType_32AlphaGray"
    case kCVPixelFormatType_16Gray:                        return "kCVPixelFormatType_16Gray"
    case kCVPixelFormatType_30RGB:                         return "kCVPixelFormatType_30RGB"
    case kCVPixelFormatType_422YpCbCr8:                    return "kCVPixelFormatType_422YpCbCr8"
    case kCVPixelFormatType_4444YpCbCrA8:                  return "kCVPixelFormatType_4444YpCbCrA8"
    case kCVPixelFormatType_4444YpCbCrA8R:                 return "kCVPixelFormatType_4444YpCbCrA8R"
    case kCVPixelFormatType_4444AYpCbCr8:                  return "kCVPixelFormatType_4444AYpCbCr8"
    case kCVPixelFormatType_4444AYpCbCr16:                 return "kCVPixelFormatType_4444AYpCbCr16"
    case kCVPixelFormatType_444YpCbCr8:                    return "kCVPixelFormatType_444YpCbCr8"
    case kCVPixelFormatType_422YpCbCr16:                   return "kCVPixelFormatType_422YpCbCr16"
    case kCVPixelFormatType_422YpCbCr10:                   return "kCVPixelFormatType_422YpCbCr10"
    case kCVPixelFormatType_444YpCbCr10:                   return "kCVPixelFormatType_444YpCbCr10"
    case kCVPixelFormatType_420YpCbCr8Planar:              return "kCVPixelFormatType_420YpCbCr8Planar"
    case kCVPixelFormatType_420YpCbCr8PlanarFullRange:     return "kCVPixelFormatType_420YpCbCr8PlanarFullRange"
    case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:        return "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar"
    case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  return "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange"
    case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:   return "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange"
    case kCVPixelFormatType_422YpCbCr8_yuvs:               return "kCVPixelFormatType_422YpCbCr8_yuvs"
    case kCVPixelFormatType_422YpCbCr8FullRange:           return "kCVPixelFormatType_422YpCbCr8FullRange"
    case kCVPixelFormatType_OneComponent8:                 return "kCVPixelFormatType_OneComponent8"
    case kCVPixelFormatType_TwoComponent8:                 return "kCVPixelFormatType_TwoComponent8"
    case kCVPixelFormatType_30RGBLEPackedWideGamut:        return "kCVPixelFormatType_30RGBLEPackedWideGamut"
    case kCVPixelFormatType_OneComponent16Half:            return "kCVPixelFormatType_OneComponent16Half"
    case kCVPixelFormatType_OneComponent32Float:           return "kCVPixelFormatType_OneComponent32Float"
    case kCVPixelFormatType_TwoComponent16Half:            return "kCVPixelFormatType_TwoComponent16Half"
    case kCVPixelFormatType_TwoComponent32Float:           return "kCVPixelFormatType_TwoComponent32Float"
    case kCVPixelFormatType_64RGBAHalf:                    return "kCVPixelFormatType_64RGBAHalf"
    case kCVPixelFormatType_128RGBAFloat:                  return "kCVPixelFormatType_128RGBAFloat"
    case kCVPixelFormatType_14Bayer_GRBG:                  return "kCVPixelFormatType_14Bayer_GRBG"
    case kCVPixelFormatType_14Bayer_RGGB:                  return "kCVPixelFormatType_14Bayer_RGGB"
    case kCVPixelFormatType_14Bayer_BGGR:                  return "kCVPixelFormatType_14Bayer_BGGR"
    case kCVPixelFormatType_14Bayer_GBRG:                  return "kCVPixelFormatType_14Bayer_GBRG"
    default: return "UNKNOWN"
    }
}

extension CVPixelBuffer {
    
    func pixelFormatName() -> String {
        let p = CVPixelBufferGetPixelFormatType(self)
        switch p {
        case kCVPixelFormatType_1Monochrome:                   return "kCVPixelFormatType_1Monochrome"
        case kCVPixelFormatType_2Indexed:                      return "kCVPixelFormatType_2Indexed"
        case kCVPixelFormatType_4Indexed:                      return "kCVPixelFormatType_4Indexed"
        case kCVPixelFormatType_8Indexed:                      return "kCVPixelFormatType_8Indexed"
        case kCVPixelFormatType_1IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_1IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_2IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_2IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_4IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_4IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_8IndexedGray_WhiteIsZero:      return "kCVPixelFormatType_8IndexedGray_WhiteIsZero"
        case kCVPixelFormatType_16BE555:                       return "kCVPixelFormatType_16BE555"
        case kCVPixelFormatType_16LE555:                       return "kCVPixelFormatType_16LE555"
        case kCVPixelFormatType_16LE5551:                      return "kCVPixelFormatType_16LE5551"
        case kCVPixelFormatType_16BE565:                       return "kCVPixelFormatType_16BE565"
        case kCVPixelFormatType_16LE565:                       return "kCVPixelFormatType_16LE565"
        case kCVPixelFormatType_24RGB:                         return "kCVPixelFormatType_24RGB"
        case kCVPixelFormatType_24BGR:                         return "kCVPixelFormatType_24BGR"
        case kCVPixelFormatType_32ARGB:                        return "kCVPixelFormatType_32ARGB"
        case kCVPixelFormatType_32BGRA:                        return "kCVPixelFormatType_32BGRA"
        case kCVPixelFormatType_32ABGR:                        return "kCVPixelFormatType_32ABGR"
        case kCVPixelFormatType_32RGBA:                        return "kCVPixelFormatType_32RGBA"
        case kCVPixelFormatType_64ARGB:                        return "kCVPixelFormatType_64ARGB"
        case kCVPixelFormatType_48RGB:                         return "kCVPixelFormatType_48RGB"
        case kCVPixelFormatType_32AlphaGray:                   return "kCVPixelFormatType_32AlphaGray"
        case kCVPixelFormatType_16Gray:                        return "kCVPixelFormatType_16Gray"
        case kCVPixelFormatType_30RGB:                         return "kCVPixelFormatType_30RGB"
        case kCVPixelFormatType_422YpCbCr8:                    return "kCVPixelFormatType_422YpCbCr8"
        case kCVPixelFormatType_4444YpCbCrA8:                  return "kCVPixelFormatType_4444YpCbCrA8"
        case kCVPixelFormatType_4444YpCbCrA8R:                 return "kCVPixelFormatType_4444YpCbCrA8R"
        case kCVPixelFormatType_4444AYpCbCr8:                  return "kCVPixelFormatType_4444AYpCbCr8"
        case kCVPixelFormatType_4444AYpCbCr16:                 return "kCVPixelFormatType_4444AYpCbCr16"
        case kCVPixelFormatType_444YpCbCr8:                    return "kCVPixelFormatType_444YpCbCr8"
        case kCVPixelFormatType_422YpCbCr16:                   return "kCVPixelFormatType_422YpCbCr16"
        case kCVPixelFormatType_422YpCbCr10:                   return "kCVPixelFormatType_422YpCbCr10"
        case kCVPixelFormatType_444YpCbCr10:                   return "kCVPixelFormatType_444YpCbCr10"
        case kCVPixelFormatType_420YpCbCr8Planar:              return "kCVPixelFormatType_420YpCbCr8Planar"
        case kCVPixelFormatType_420YpCbCr8PlanarFullRange:     return "kCVPixelFormatType_420YpCbCr8PlanarFullRange"
        case kCVPixelFormatType_422YpCbCr_4A_8BiPlanar:        return "kCVPixelFormatType_422YpCbCr_4A_8BiPlanar"
        case kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:  return "kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange"
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange:   return "kCVPixelFormatType_420YpCbCr8BiPlanarFullRange"
        case kCVPixelFormatType_422YpCbCr8_yuvs:               return "kCVPixelFormatType_422YpCbCr8_yuvs"
        case kCVPixelFormatType_422YpCbCr8FullRange:           return "kCVPixelFormatType_422YpCbCr8FullRange"
        case kCVPixelFormatType_OneComponent8:                 return "kCVPixelFormatType_OneComponent8"
        case kCVPixelFormatType_TwoComponent8:                 return "kCVPixelFormatType_TwoComponent8"
        case kCVPixelFormatType_30RGBLEPackedWideGamut:        return "kCVPixelFormatType_30RGBLEPackedWideGamut"
        case kCVPixelFormatType_OneComponent16Half:            return "kCVPixelFormatType_OneComponent16Half"
        case kCVPixelFormatType_OneComponent32Float:           return "kCVPixelFormatType_OneComponent32Float"
        case kCVPixelFormatType_TwoComponent16Half:            return "kCVPixelFormatType_TwoComponent16Half"
        case kCVPixelFormatType_TwoComponent32Float:           return "kCVPixelFormatType_TwoComponent32Float"
        case kCVPixelFormatType_64RGBAHalf:                    return "kCVPixelFormatType_64RGBAHalf"
        case kCVPixelFormatType_128RGBAFloat:                  return "kCVPixelFormatType_128RGBAFloat"
        case kCVPixelFormatType_14Bayer_GRBG:                  return "kCVPixelFormatType_14Bayer_GRBG"
        case kCVPixelFormatType_14Bayer_RGGB:                  return "kCVPixelFormatType_14Bayer_RGGB"
        case kCVPixelFormatType_14Bayer_BGGR:                  return "kCVPixelFormatType_14Bayer_BGGR"
        case kCVPixelFormatType_14Bayer_GBRG:                  return "kCVPixelFormatType_14Bayer_GBRG"
        default: return "UNKNOWN"
        }
    }
}
