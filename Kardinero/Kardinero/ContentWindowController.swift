import Cocoa

class ContentWindowController: NSWindowController {

    init(content: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 400),
            styleMask: [.closable, .titled, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "File Content"
        let contentViewController = ContentViewController(content: content)
        window.contentViewController = contentViewController
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class ContentViewController: NSViewController {

    private var content: String

    init(content: String) {
        self.content = content
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 600, height: 400))

        let textView = NSTextView(frame: self.view.bounds)
        textView.isEditable = false
        textView.string = content
        textView.autoresizingMask = [.width, .height]
        
        self.view.addSubview(textView)
    }
}
