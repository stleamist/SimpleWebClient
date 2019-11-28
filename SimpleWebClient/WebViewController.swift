import Cocoa
import WebKit

class WebViewController: NSViewController {
    
    // MARK: View Outlets
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    // MARK: Observations
    
    private var webViewCanGoBackObservation: NSKeyValueObservation?
    private var webViewCanGoForwardObservation: NSKeyValueObservation?
    private var webViewURLObservation: NSKeyValueObservation?
    private var webViewEstimatedProgressObservation: NSKeyValueObservation?
    
    // MARK: Computed Properties
    
    var windowController: WindowController? { return self.view.window?.windowController as? WindowController }
    
    // MARK: Controller Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUserAgentFieldPlaceholderStringFromWebView()
        bindWebViewCanGoBackForwardToBackForwardButtons()
        bindWebViewURLToAddressField()
        bindWebViewEstimatedProgressToProgressIndicator()
    }
    
    // MARK: Setup Methods
    
    private func setupUserAgentFieldPlaceholderStringFromWebView() {
        webView.evaluateJavaScript("navigator.userAgent") { (value, error) in
            if let userAgentString = value as? String {
                self.windowController?.setUserAgentFieldPlaceholderString(userAgentString)
            }
        }
    }
    
    func bindWebViewCanGoBackForwardToBackForwardButtons() {
        webViewCanGoBackObservation = webView.observe(\WKWebView.canGoBack) { (webView, change) in
            self.windowController?.setBackForwardButtonsEnabled(backButton: webView.canGoBack, forwardButton: webView.canGoForward)
        }
        webViewCanGoForwardObservation = webView.observe(\WKWebView.canGoForward) { (webView, change) in
            self.windowController?.setBackForwardButtonsEnabled(backButton: webView.canGoBack, forwardButton: webView.canGoForward)
        }
    }
    
    private func bindWebViewURLToAddressField() {
        webViewURLObservation = webView.observe(\WKWebView.url) { (webView, change) in
            self.windowController?.setAddressFieldString(webView.url?.absoluteString)
        }
    }
    
    private func bindWebViewEstimatedProgressToProgressIndicator() {
        webViewEstimatedProgressObservation = webView.observe(\WKWebView.estimatedProgress) { (webView, change) in
            if webView.estimatedProgress == 1.0 || !webView.isLoading {
                self.progressIndicator.isHidden = true
            } else {
                self.progressIndicator.isHidden = false
            }
            self.progressIndicator.doubleValue = webView.estimatedProgress * 100
        }
    }
    
    // MARK: Methods
    
    func goWebViewBack() {
        webView.goBack()
    }
    
    func goWebViewForward() {
        webView.goForward()
    }
    
    func load(httpMethod: HTTPMethod, url: URL, body: String? = nil) {
        var request = URLRequest(url: url)
        request.httpMethod = httpMethod.rawValue
        request.httpBody = body?.data(using: .utf8)
        webView.load(request)
    }
}
