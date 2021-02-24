import Cocoa
import AVFoundation
import DeepAR

@objc
protocol VideoComposerDelegate: class {
    func videoComposer(_ composer: VideoComposer, didComposeImageBuffer imageBuffer: CVImageBuffer)
}

@objcMembers
class VideoComposer: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate, DeepARDelegate {

    weak var delegate: VideoComposerDelegate?

    private let deepAR = DeepAR();
    private let cameraCapture = CameraCapture()
    private let context = CIContext()
    private var settingsTimer: Timer?

    private let filter = CIFilter(name: "CISourceOverCompositing")
    private var textImage: CIImage?

    private var count = 0;

    private let CVPixelBufferCreateOptions: [String: Any] = [
        kCVPixelBufferCGImageCompatibilityKey as String: true,
        kCVPixelBufferCGBitmapContextCompatibilityKey as String: true,
        kCVPixelBufferIOSurfacePropertiesKey as String: [:]
    ]

    deinit {
        stopRunning()
    }

    func startRunning() {
        self.deepAR.setLicenseKey("949a402a628926a9ceb24be7ab4210d72f5220b091a54b64a061a02ab8f48f3b9948e48704073c67")
        self.deepAR.delegate = self
        self.deepAR.initializeOffscreen(withWidth: 1, height: 1)
        self.deepAR.setRenderingResolutionWithWidth(1280, height: 720)
//        startPollingSettings()
        cameraCapture.output.setSampleBufferDelegate(self, queue: .main)
        cameraCapture.startRunning()
    }
    
    func didInitialize() {
        
    }

    func stopRunning() {
        settingsTimer?.invalidate()
        settingsTimer = nil
        cameraCapture.stopRunning()
    }

    private func startPollingSettings() {
        settingsTimer?.invalidate()
        settingsTimer = nil
        settingsTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            let settings = SettingsPasteboard.shared.current()
            let text1 = settings["text1"] as? String ?? "Version One"
            self.textImage = self.makeTextCIImage(text: text1)
        }
        settingsTimer?.fire()
    }

    func frameAvailable(_ sampleBuffer: CMSampleBuffer!) {
        self.count += 1
        self.textImage = self.makeTextCIImage(text: String(self.count))
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }

        let cameraImage = CIImage(cvImageBuffer: imageBuffer)
        let compositedImage = compose(bgImage: cameraImage, overlayImage: self.textImage)

        var pixelBuffer: CVPixelBuffer?

        _ = CVPixelBufferCreate(
            kCFAllocatorDefault,
            Int(compositedImage.extent.size.width),
            Int(compositedImage.extent.height),
            kCVPixelFormatType_32BGRA,
            self.CVPixelBufferCreateOptions as CFDictionary,
            &pixelBuffer
        )

        if let pixelBuffer = pixelBuffer {
            context.render(compositedImage, to: pixelBuffer)
            delegate?.videoComposer(self, didComposeImageBuffer: pixelBuffer)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if output == cameraCapture.output {
            
            self.deepAR.enqueueCameraFrame(sampleBuffer, mirror: false)
//            guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
//
//            let cameraImage = CIImage(cvImageBuffer: imageBuffer)
//            let compositedImage = compose(bgImage: cameraImage, overlayImage: self.textImage)
//
//            var pixelBuffer: CVPixelBuffer?
//
//            _ = CVPixelBufferCreate(
//                kCFAllocatorDefault,
//                Int(compositedImage.extent.size.width),
//                Int(compositedImage.extent.height),
//                kCVPixelFormatType_32BGRA,
//                self.CVPixelBufferCreateOptions as CFDictionary,
//                &pixelBuffer
//            )
//
//            if let pixelBuffer = pixelBuffer {
//                context.render(compositedImage, to: pixelBuffer)
//                delegate?.videoComposer(self, didComposeImageBuffer: pixelBuffer)
//            }
        }
    }

    private func makeTextCIImage(text: String) -> CIImage? {
        let font = NSFont(name: "HiraginoSans-W8", size: 100) ?? NSFont.systemFont(ofSize: 100)
        let size = NSSize(width: 1280.0, height: 720)

        let image = NSImage(size: size, flipped: false) { (rect) -> Bool in
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = .center

            let rectangle = NSRect(x: 0, y: 40, width: size.width, height: font.lineHeight() + 12.0)
            let textAttributes = [
                .strokeColor: NSColor.black,
                .foregroundColor: NSColor.white,
                .strokeWidth: -2,
                .font: font,
                .paragraphStyle: paragraphStyle
                ] as [NSAttributedString.Key : Any]
            (text as NSString).draw(in: rectangle, withAttributes: textAttributes)
            return true
        }

        return image.ciImage
    }

    private func compose(bgImage: CIImage, overlayImage: CIImage?) -> CIImage {
        guard let filter = filter, let overlayImage = overlayImage else {
            return bgImage
        }
        filter.setValue(overlayImage, forKeyPath: kCIInputImageKey)
        filter.setValue(bgImage, forKeyPath: kCIInputBackgroundImageKey)
        return filter.outputImage!
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
