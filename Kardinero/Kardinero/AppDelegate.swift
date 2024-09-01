import Cocoa

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Log to check if this method is being called
        print("applicationDidFinishLaunching is called.")

        // Create a simple window with a button
        let windowRect = NSRect(x: 0, y: 0, width: 400, height: 200)
        window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Test Window"
        
        // Add a simple button to test interaction
        let button = NSButton(frame: NSRect(x: 100, y: 60, width: 200, height: 40))
        button.title = "Click Me"
        button.target = self
        button.action = #selector(buttonClicked(_:))
        window.contentView?.addSubview(button)
        
        // Show the window
        window.makeKeyAndOrderFront(nil)
        
        // Log to confirm window was added
        print("Window and button added.")
    }

    @objc func buttonClicked(_ sender: NSButton) {
        print("Button clicked!")
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        return true
    }
}
