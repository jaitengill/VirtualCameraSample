import Cocoa
import SwiftUI
import AVFoundation

@available(OSX 10.15, *)
class SettingsViewController: NSViewController{

    @IBOutlet weak var deviceList: NSPopUpButton!

    private var devices: [AVCaptureDevice] = [AVCaptureDevice]()
    
    override func viewDidLoad() {
        //
        devices = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.unspecified).devices;
        
        for device in devices {
            
            deviceList.addItem(withTitle: device.localizedName)
        }
    }
    
    @IBAction func popUpSelectionDidChange(_ sender: NSPopUpButton) {
        
        let id = sender.selectedItem?.title
        let device = devices.first(where: { $0.localizedName == id })
        
        SettingsPasteboard.shared.settings["deviceId"] = device?.uniqueID
        SettingsPasteboard.shared.update()
   }
}
