import Cocoa
import DGCharts

class DetailedEcgWindowController: NSWindowController {
    private var ecgData: [Double]
    private var leadName: String
    
    init(ecgData: [Double], leadName: String) {
        self.ecgData = ecgData
        self.leadName = leadName
        let windowRect = NSRect(x: 0, y: 0, width: 800, height: 400)
        let window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "Detailed View of \(leadName)"
        
        super.init(window: window)
        self.initializeWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeWindow() {
        window?.makeKeyAndOrderFront(self)

        let chartView = LineChartView(frame: NSRect(x: 0, y: 0, width: 800, height: 400))
        let dataEntries = ecgData.enumerated().map { ChartDataEntry(x: Double($0), y: $1) }

        let dataSet = LineChartDataSet(entries: dataEntries, label: leadName)
        dataSet.colors = [NSUIColor.red]
        dataSet.lineWidth = 2.0

        let chartData = LineChartData(dataSet: dataSet)
        chartView.data = chartData
        chartView.chartDescription.text = leadName
        chartView.xAxis.labelPosition = .bottom
        chartView.xAxis.drawGridLinesEnabled = true
        chartView.leftAxis.drawGridLinesEnabled = true
        chartView.rightAxis.enabled = false
        chartView.legend.enabled = true
        
        window?.contentView?.addSubview(chartView)
    }
}
