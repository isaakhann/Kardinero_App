import Cocoa
import DGCharts

class EcgWindowController: NSWindowController {
    private var ecgData: [[Int]]
    private var gridContainerView: NSView!
    private var chartViewLeadMapping: [LineChartView: Int] = [:] // Dictionary to map chart views to lead indices
    private let leadNames = ["Lead I", "Lead II", "Lead III", "Lead V1", "Lead V2", "Lead V3", "Lead V4", "Lead V5", "Lead V6", "Lead aVR", "Lead aVL", "Lead aVF"]
    private var leadData: [[Double]] = []

    init(ecgData: [[Int]]) {
        self.ecgData = ecgData
        let windowRect = NSRect(x: 0, y: 0, width: 1600, height: 800)
        let window = NSWindow(contentRect: windowRect, styleMask: [.titled, .closable, .resizable], backing: .buffered, defer: false)
        window.title = "ECG Waveform"
        
        super.init(window: window)
        self.leadData = self.prepareLeadData()
        self.initializeWindow()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initializeWindow() {
        gridContainerView = NSView(frame: NSRect(x: 20, y: 20, width: 1600, height: 800))
        let numberOfColumns = 2
        let numberOfRows = 6
        let itemWidth: CGFloat = 700
        let itemHeight: CGFloat = 120
        let spacing: CGFloat = 10
        let totalWidth = CGFloat(numberOfColumns) * (itemWidth + spacing) - spacing
        let totalHeight = CGFloat(numberOfRows) * (itemHeight + spacing) - spacing

        gridContainerView.frame.size = NSSize(width: totalWidth, height: totalHeight)

        // Create and add views for each lead
        for (index, lead) in leadNames.enumerated() {
            guard index < leadData.count else {
                print("Error: Index \(index) is out of bounds for leadData with count \(leadData.count)")
                continue
            }

            let row = index / numberOfColumns
            let column = index % numberOfColumns

            // Create a view for each lead
            let leadView = NSView(frame: NSRect(x: CGFloat(column) * (itemWidth + spacing),
                                                y: CGFloat(row) * (itemHeight + spacing),
                                                width: itemWidth, height: itemHeight))

            let chartView = LineChartView(frame: leadView.bounds)
            let dataEntries = leadData[index].enumerated().map { ChartDataEntry(x: Double($0), y: $1) }

            let dataSet = LineChartDataSet(entries: dataEntries, label: lead)
            dataSet.colors = [NSUIColor.white]
            dataSet.lineWidth = 2.0
            dataSet.circleRadius = 0.0

            let chartData = LineChartData(dataSet: dataSet)
            chartView.data = chartData
            chartView.chartDescription.text = lead
            chartView.xAxis.labelPosition = .bottom
            chartView.xAxis.drawGridLinesEnabled = true
            chartView.leftAxis.drawGridLinesEnabled = true
            chartView.rightAxis.enabled = false
            chartView.legend.enabled = false
            chartView.animate(xAxisDuration: 0.5, yAxisDuration: 0.5)

            chartViewLeadMapping[chartView] = index

            // Add gesture recognizer for click
            let clickGesture = NSClickGestureRecognizer(target: self, action: #selector(chartClicked(_:)))
            chartView.addGestureRecognizer(clickGesture)
            
            // Add gesture recognizer for pinch (zoom)
            let pinchGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
            leadView.addGestureRecognizer(pinchGesture)

            leadView.addSubview(chartView)
            gridContainerView.addSubview(leadView)
        }

        window?.contentView?.addSubview(gridContainerView)
        window?.makeKeyAndOrderFront(self)
    }

    // Handle chart click events
    @objc private func chartClicked(_ sender: NSClickGestureRecognizer) {
        guard let chartView = sender.view as? LineChartView, let leadIndex = chartViewLeadMapping[chartView] else {
            print("Click not detected correctly.")
            return
        }
        print("Lead \(leadIndex) was clicked.")
        openDetailedViewForLead(leadIndex: leadIndex)
    }

    // Handle pinch gestures for zoom
    @objc private func handlePinchGesture(_ sender: NSMagnificationGestureRecognizer) {
        guard let leadView = sender.view, let chartView = leadView.subviews.first as? LineChartView else {
            return
        }
        
        let pinchScale = sender.magnification
        if pinchScale != 0 {
            // Update the X and Y axis scales
            let scaleX = pinchScale > 0 ? 1.1 : 0.9
            let scaleY = pinchScale > 0 ? 1.1 : 0.9
            
            // Pinch horizontally for X-axis, vertically for Y-axis zoom
            if abs(sender.location(in: leadView).x) > abs(sender.location(in: leadView).y) {
                chartView.zoom(scaleX: scaleX, scaleY: 1, x: chartView.frame.width / 2, y: chartView.frame.height / 2)
            } else {
                chartView.zoom(scaleX: 1, scaleY: scaleY, x: chartView.frame.width / 2, y: chartView.frame.height / 2)
            }
        }
        
        sender.magnification = 0 // Reset magnification
    }

    // Open a new window with a detailed view of the clicked lead
    private func openDetailedViewForLead(leadIndex: Int) {
        let detailWindowController = DetailedEcgWindowController(ecgData: leadData[leadIndex], leadName: leadNames[leadIndex])
        detailWindowController.showWindow(self)
    }

    private func prepareLeadData() -> [[Double]] {
        let lead_1 = ecgData[0].map { Double($0) }
        let lead_2 = ecgData[1].map { Double($0) }

        let lead_3 = zip(lead_2, lead_1).map { $0 - $1 }
        let avr = zip(lead_1, lead_2).map { -($0 + $1) / 2 }
        let avl = zip(lead_1, lead_2).map { ($0 - $1) / 2 }
        let avf = zip(lead_2, lead_1).map { ($0 - $1) / 2 }

        let first8Leads = ecgData[..<8].map { $0.map { Double($0) } }

        return first8Leads + [lead_3, avr, avl, avf]
    }
}
