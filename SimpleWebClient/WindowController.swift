import Cocoa
import WebKit

class WindowController: NSWindowController, NSSearchFieldDelegate {
    
    // MARK: View Outlets
    
    @IBOutlet weak var backForwardButtons: NSSegmentedControl!
    @IBOutlet weak var methodPopUpButton: NSPopUpButton!
    @IBOutlet weak var addressField: NSTextField!
    @IBOutlet weak var userAgentField: NSTextField!
    @IBOutlet weak var bodyField: NSTextField!
    
    // MARK: Toolbar Items
    
    @IBOutlet weak var addressFieldItem: NSToolbarItem!
    @IBOutlet weak var bodyFieldItem: NSToolbarItem!
    
    // MARK: Computed Properties
    
    var webViewController: WebViewController? {
        return self.contentViewController as? WebViewController
    }
    
    func setBackForwardButtonsEnabled(backButton canGoBack: Bool, forwardButton canGoForward: Bool) {
        backForwardButtons.setEnabled(canGoBack, forSegment: 0)
        backForwardButtons.setEnabled(canGoForward, forSegment: 1)
    }
    
    func setAddressFieldString(_ string: String?) {
        addressField.stringValue = string ?? ""
    }
    
    var userAgentFieldString: String? {
        return (userAgentField.stringValue != "") ? userAgentField.stringValue : nil
    }
    func setUserAgentFieldPlaceholderString(_ placeHolderString: String?) {
        userAgentField.placeholderString = placeHolderString
    }
    
    // MARK: Controller Lifecycle Methods
    
    override func windowDidLoad() {
        addressField.delegate = self
        bodyField.delegate = self
        userAgentField.delegate = self
        
        if let webView = webViewController?.webView {
            setBackForwardButtonsEnabled(backButton: webView.canGoBack, forwardButton: webView.canGoForward)
        }
        updateBodyFieldItemVisibility()
    }
    
    // MARK: View Actions
    
    @IBAction func backForwardButtonAction(_ sender: NSSegmentedControl) {
        switch sender.selectedSegment {
        case 0: webViewController?.goWebViewBack()
        case 1: webViewController?.goWebViewForward()
        default: ()
        }
    }
    
    @IBAction func popUpButtonValueDidChange(_ sender: NSPopUpButton) {
        if sender == methodPopUpButton {
            updateBodyFieldItemVisibility()
        }
    }
    
    @IBAction func goButtonDidTap(_ sender: NSButton) {
        goToURL()
    }
    
    // MARK: Methods
    
    private func goToURL() {
        guard let httpMethod = HTTPMethod(rawValue: methodPopUpButton.titleOfSelectedItem ?? "") else { return }
        
        guard var urlComponents = URLComponents(string: addressField.stringValue) else { return }
        // 스키마를 입력하지 않았을 때 "http"를 fallback으로 추가해 응용 프로그램을 열 수 없다는 알림이 뜨는 것을 방지한다.
        urlComponents.scheme = urlComponents.scheme ?? "http"
        guard let url = urlComponents.url else { return }
        
        let body = bodyField.stringValue
        
        webViewController?.load(httpMethod: httpMethod, url: url, body: body)
    }
    
    private func updateBodyFieldItemVisibility() {
        guard let toolbar = window?.toolbar else { return }
        
        if methodPopUpButton.titleOfSelectedItem == HTTPMethod.post.rawValue {
            guard let addressFieldItemIndex = toolbar.items.firstIndex(of: addressFieldItem) else { return }
            toolbar.insertItem(withItemIdentifier: bodyFieldItem.itemIdentifier, at: addressFieldItemIndex + 1)
        } else {
            guard let bodyFieldItemIndex = toolbar.items.firstIndex(of: bodyFieldItem) else { return }
            toolbar.removeItem(at: bodyFieldItemIndex)
        }
    }
}

extension WindowController: NSTextFieldDelegate {
    
    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        switch control {
        case addressField, bodyField:
            // addressField나 bodyField가 엔터 키 명령을 받았을 때 goToURL() 메소드를 실행하도록 한다.
            if (commandSelector == #selector(NSResponder.insertNewline(_:))) {
                goToURL()
                return true
            }
        default: ()
        }
        
        return false
    }
    
    func controlTextDidChange(_ obj: Notification) {
        switch obj.object as? NSControl {
        case userAgentField:
            // userAgentField의 텍스트 변경 시 webView.customUserAgent를 업데이트한다.
            webViewController?.webView.customUserAgent = userAgentFieldString
        default: ()
        }
    }
}
