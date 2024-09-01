import Cocoa

class InfoWindowController: NSWindowController {

    init(info: String) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 200),
            styleMask: [.closable, .titled, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Patient Information"
        let infoViewController = InfoViewController(info: info)
        window.contentViewController = infoViewController
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class InfoViewController: NSViewController {

    private var info: String

    init(info: String) {
        self.info = info
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        self.view = NSView(frame: NSRect(x: 0, y: 0, width: 400, height: 200))

        let textView = NSTextView(frame: self.view.bounds)
        textView.isEditable = false
        textView.string = info
        textView.autoresizingMask = [.width, .height]
        
        self.view.addSubview(textView)
    }
}
