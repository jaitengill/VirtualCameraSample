import Cocoa
import DeepAR

class ViewController: NSViewController {

    @IBOutlet weak var mainTextField: NSTextField!

    private let deepAR = DeepAR.init()

    deinit {
        let panel = NSFontManager.shared.fontPanel(true)
        panel?.close()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.deepAR.setLicenseKey("62d5b2615f2df5a495f41f5b617ae7eed7eb7f4f67eab92f9dc57327e3b2db87537013befcbe6398")

        mainTextField.delegate = self
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
