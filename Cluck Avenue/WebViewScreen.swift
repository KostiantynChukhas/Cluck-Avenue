import SwiftUI
import WebKit
import Combine

struct WebViewScreen: View {
    let url: String
    @StateObject private var viewModel = WebViewModel()
    
    var body: some View {
        VStack(spacing: 0) {
            // WebView
            WebView(viewModel: viewModel, url: url)
            
            // Нижняя панель навигации
            HStack(spacing: 40) {
                // Кнопка "Назад"
                Button(action: {
                    viewModel.goBack()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.canGoBack ? .primary : .gray)
                        .frame(width: 44, height: 44)
                }
                .disabled(!viewModel.canGoBack)
                
                // Кнопка "Вперед"
                Button(action: {
                    viewModel.goForward()
                }) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(viewModel.canGoForward ? .primary : .gray)
                        .frame(width: 44, height: 44)
                }
                .disabled(!viewModel.canGoForward)
                
                Spacer()
                
                // Кнопка "Обновить"
                Button(action: {
                    viewModel.reload()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.primary)
                        .frame(width: 44, height: 44)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(Color(UIColor.systemBackground))
            .overlay(
                Rectangle()
                    .frame(height: 0.5)
                    .foregroundColor(Color(UIColor.separator)),
                alignment: .top
            )
        }
        .edgesIgnoringSafeArea(.bottom)
    }
}

// MARK: - WebView UIViewRepresentable
struct WebView: UIViewRepresentable {
    @ObservedObject var viewModel: WebViewModel
    let url: String
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        viewModel.webView = webView
        
        // Загружаем URL только при первом запуске
        if webView.url == nil, let url = URL(string: url) {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let viewModel: WebViewModel
        
        init(viewModel: WebViewModel) {
            self.viewModel = viewModel
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            print("WebView navigation failed: \(error.localizedDescription)")
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            viewModel.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            viewModel.isLoading = false
            viewModel.updateNavigationState()
        }
    }
}

// MARK: - WebView ViewModel
class WebViewModel: ObservableObject {
    @Published var canGoBack = false
    @Published var canGoForward = false
    @Published var isLoading = false
    
    weak var webView: WKWebView?
    
    func goBack() {
        webView?.goBack()
    }
    
    func goForward() {
        webView?.goForward()
    }
    
    func reload() {
        webView?.reload()
    }
    
    func updateNavigationState() {
        canGoBack = webView?.canGoBack ?? false
        canGoForward = webView?.canGoForward ?? false
    }
}
