import Cocoa
import AVFoundation
import DeepAR
@objcMembers
class SampleComposerObj: NSObject, DeepARDelegate {

    private let deepAR: DeepAR = DeepAR.init()
    

//    private let openGLContext: NSOpenGLContext = NSOpenGLContext()

    private let CVPixelBufferCreateOptions: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]
    
    override init() {
        super.init()
        self.deepAR.setLicenseKey("949a402a628926a9ceb24be7ab4210d72f5220b091a54b64a061a02ab8f48f3b9948e48704073c67")
        self.deepAR.delegate = self
        self.deepAR.initializeOffscreen(withWidth: 1, height: 1)

        //        do {
//            try (self.deepAR.initializeOffscreen(withWidth: 1, height: 1))
//        } catch {
//            print("ERROR CREATING")
//        }
//        print("HERE")

//        self.startRunning()
    }

    func startRunning() {
//        self.deepAR.setLicenseKey("949a402a628926a9ceb24be7ab4210d72f5220b091a54b64a061a02ab8f48f3b9948e48704073c67")
//        self.deepAR.delegate = self
//        self.deepAR.initialize()
     
//        self.deepAR.resume()
//        self.deepAR.switchEffect(withSlot: "0", path: Bundle.main.path(forResource: "fire", ofType: nil))
//
        
//        startPollingSettings()
//        cameraCapture.output.setSampleBufferDelegate(self, queue: .main)
//        cameraCapture.startRunning()
    }
    
  
    func didInitialize() {
        print("INITLAIZED")
//        self.deepAR.startCapture(withOutputWidth: 1280, outputHeight: 720, subframe: CGRect(x: 0, y: 0, width: 1280, height: 720))
//        var pixelBuffer: CVPixelBuffer?
//
//        _ = CVPixelBufferCreate(
//            kCFAllocatorDefault,
//            1280,
//            720,
//            kCVPixelFormatType_32BGRA,
//            self.CVPixelBufferCreateOptions as CFDictionary,
//            &pixelBuffer
//        )
//        self.deepAR.processFrame(pixelBuffer, mirror: false, orientation: 0)
    }
    func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        print("CALLED")
//        guard let imageBuffer =     CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//        let cameraImage = CIImage(cvImageBuffer: imageBuffer)
//
//        var pixelBuffer: CVPixelBuffer?
//
//        _ = CVPixelBufferCreate(
//            kCFAllocatorDefault,
//            1280,
//            720,
//            kCVPixelFormatType_32BGRA,
//            self.CVPixelBufferCreateOptions as CFDictionary,
//            &pixelBuffer
//        )
//
//        if let pixelBuffer = pixelBuffer {
//            context.render(cameraImage, to: pixelBuffer)
//            delegate?.videoComposer(self, didComposeImageBuffer: pixelBuffer)
//        }
//        self.textImage = self.makeTextCIImage(text: "FRAME FOUND")
    }

  

 

}

extension NSFont {

    func lineHeight() -> CGFloat {
        return CGFloat(ceilf(Float(ascender + descender + leading)))
    }
}

extension NSImage {

    convenience init(color: NSColor, size: NSSize) {
        self.init(size: size)
        lockFocus()
        color.drawSwatch(in: NSRect(origin: .zero, size: size))
        unlockFocus()
    }

    func resized(to newSize: NSSize) -> NSImage? {
        if let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil, pixelsWide: Int(newSize.width), pixelsHigh: Int(newSize.height),
            bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
            colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0
            ) {
            bitmapRep.size = newSize
            NSGraphicsContext.saveGraphicsState()
            NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmapRep)
            draw(in: NSRect(x: 0, y: 0, width: newSize.width, height: newSize.height), from: .zero, operation: .copy, fraction: 1.0)
            NSGraphicsContext.restoreGraphicsState()

            let resizedImage = NSImage(size: newSize)
            resizedImage.addRepresentation(bitmapRep)
            return resizedImage
        }

        return nil
    }

    var ciImage: CIImage? {
        let newImage = self.resized(to: size)!
        guard let data = newImage.tiffRepresentation, let bitmap = NSBitmapImageRep(data: data) else { return nil }
        return CIImage(bitmapImageRep: bitmap)
    }
}
