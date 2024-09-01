import Cocoa
import UniformTypeIdentifiers
class ViewController: NSViewController {
    @IBOutlet weak var addFileButton: NSButton!
    @IBOutlet weak var findInfo: NSButton!
    @IBOutlet weak var convertButton: NSButton!
    override func viewDidLoad() {
        print("AA")
        super.viewDidLoad()
      
    }
    
    @IBAction func convertCsv(_ sender: Any) {
    }
    // Example IBOutlets for the buttons
   
    @IBAction func addFileButton(_ sender: Any) {
        print("Works")
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType(filenameExtension: "scp")!]
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        
        if openPanel.runModal() == .OK, let filePath = openPanel.url?.path {
            do {
                // Read the SCP-ECG file and extract the ECG data
                let scpParser = SCPParser()
                let ecgData = try scpParser.extractEcgData(fileBytes: Data(contentsOf: URL(fileURLWithPath: filePath)))
                
                // Create a new window to display the ECG plot
                let ecgWindowController = EcgWindowController(ecgData: ecgData)
                ecgWindowController.showWindow(self)
                
            } catch {
                print("Error reading the SCP-ECG file: \(error.localizedDescription)")
                
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Error"
                alert.informativeText = "Failed to read the SCP-ECG file. Please ensure the file is valid.\nError: \(error.localizedDescription)"
                alert.runModal()
            }
        }
    }
    
    @IBAction func findInfo(_ sender: Any) {
        print("infoworks")
        let openPanel = NSOpenPanel()
        
        openPanel.allowsMultipleSelection = false
        openPanel.allowedContentTypes = [UTType(filenameExtension: "scp")!]
        openPanel.canChooseDirectories = false
        openPanel.canCreateDirectories = false
        
        if openPanel.runModal() == .OK, let filePath = openPanel.url?.path {
            do {
                // Read the SCP-ECG file and extract the ECG data
                let scpParser = SCPParser()
                let patientInfo = scpParser.extractInfoFromScp(filePath: filePath)

                
                // Create a new window to display the ECG plot
                let infoWindowController = InfoWindowController(info: patientInfo)
                infoWindowController.showWindow(self)
                
            } catch {
                print("Error reading the SCP-ECG file: \(error.localizedDescription)")
                
                let alert = NSAlert()
                alert.alertStyle = .critical
                alert.messageText = "Error"
                alert.informativeText = "Failed to read the SCP-ECG file. Please ensure the file is valid.\nError: \(error.localizedDescription)"
                alert.runModal()
            }
        }
    }
    

    
  
    
    func readScpData(from filePath: String) -> [[Int]]? {
        do {
            let fileBytes = try Data(contentsOf: URL(fileURLWithPath: filePath))
            
            let numChannels = 12
            let numDataPoints = 1000
            
            var ecgChannels: [[Int]] = Array(repeating: Array(repeating: 0, count: numDataPoints), count: numChannels)
            
            for i in 0..<numChannels {
                for j in 0..<numDataPoints {
                    ecgChannels[i][j] = Int(fileBytes[(i * numDataPoints) + j])
                }
            }
            return ecgChannels
        } catch {
            print("Error reading the SCP-ECG file: \(error.localizedDescription)")
            return nil
        }
    }
    
    func extractEcgData(from fileBytes: Data) -> [[Int]] {
        let startIndex = 1000 // Adjust as needed
        let numberOfDataPoints = 5000 // Example length
        
        var ecgData: [[Int]] = Array(repeating: Array(repeating: 0, count: numberOfDataPoints), count: 12)
        
        // Extract primary leads (I, II, V1-V6)
        for lead in 0..<8 {
            if fileBytes.count < startIndex + numberOfDataPoints * 2 {
                fatalError("Invalid SCP-ECG file: insufficient data length for lead \(lead + 1).")
            }
            
            for i in 0..<numberOfDataPoints {
                ecgData[lead][i] = Int(Int16(bitPattern: UInt16(fileBytes[startIndex + lead * numberOfDataPoints * 2 + i * 2]) << 8 |
                                             UInt16(fileBytes[startIndex + lead * numberOfDataPoints * 2 + i * 2 + 1])))
            }
        }
        
        // Calculate derived leads (III, aVR, aVL, aVF)
        let leadI = ecgData[0]
        let leadII = ecgData[1]
        var leadIII = [Int](repeating: 0, count: numberOfDataPoints)
        var aVR = [Int](repeating: 0, count: numberOfDataPoints)
        var aVL = [Int](repeating: 0, count: numberOfDataPoints)
        var aVF = [Int](repeating: 0, count: numberOfDataPoints)
        
        for i in 0..<numberOfDataPoints {
            leadIII[i] = leadII[i] - leadI[i]
            aVR[i] = -(leadI[i] + leadII[i]) / 2
            aVL[i] = (leadI[i] - leadIII[i]) / 2
            aVF[i] = (leadII[i] + leadIII[i]) / 2
        }
        
        // Assign derived leads to the ecgData array
        ecgData[2] = leadIII
        ecgData[3] = aVR
        ecgData[4] = aVL
        ecgData[5] = aVF
        
        return ecgData
    }
}
