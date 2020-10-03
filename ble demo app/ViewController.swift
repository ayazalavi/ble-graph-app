//
//  ViewController.swift
//  ble demo app
//
//  Created by Miranz  Technologies on 9/21/20.
//  Copyright © 2020 Ayaz Alavi. All rights reserved.
//

import UIKit
import CorePlot


class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var graphView: CPTGraphHostingView!
    @IBOutlet weak var graphContainer: UIView!
    @IBOutlet weak var toolbar: UIToolbar!
    
    var data: [DataObject] = DataObject.getAll()
    
    let reuseID = "DefaultCell"
    
    let bluecolor = UIColor(red: 0/255, green: 51/255, blue: 153/255, alpha: 1.0)
    
    var timer, timer2: Timer?
    
    var tablerect, graphrect: CGRect!
    
    var currentIndex = 0
    
    var plotData = [DataObject]()
    
    var plotx, ploty, plotz: CPTScatterPlot!
    
    var maxDataPoints = 100
    
    var frameRate = 5.0
    
    var alphaValue = 0.25
    
    var timeDuration:Double = 0.1
    
    var selectedGraph: DataTypes = .ACC
    
    lazy var stackView: UIStackView = {
        var labels = [UILabel]() //= BLE.allCases.map({ _ in UILabel.label })
        for type in BLE.allCases {
           let label = UILabel.label
           label.textColor = UIColor(red: 0/255, green: 51/255, blue: 153/255, alpha: 1.0)
           label.font = UIFont(name: "Georgia Bold", size: 14)
           label.text = "\(type)"
           labels.append(label)
        }
        let stackview = UIStackView(arrangedSubviews: labels)
        stackview.frame = CGRect(x: 0, y: 0, width: self.tableView.frame.size.width, height: 35)
        stackview.distribution = .fillEqually
        stackview.alignment = .center
        return stackview
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        BluetoothScanner.shared.delegate = self
        BluetoothScanner.shared.startScanning()
        
        tableView.register(CustomCell.self, forCellReuseIdentifier: reuseID)
        tableView.rowHeight = 25
        
        reloadTable()
        resetGraph()
    }
    
    func reloadTable() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            self.tableView.reloadData()
        }
    }
    
    func resetGraph(){
        configureGraphtView()
        configureGraphAxis()
        configurePlot()
        
        if let items = toolbar.items {
            _ = items.map({ $0.action = #selector(updateGraphType(_:))})
        }
    }
    
  @objc func fireTimer(){
        guard self.data.count > 0 else { return }
        let graph = self.graphView.hostedGraph
        let plot1 = graph?.plot(withIdentifier: "x" as NSCopying)
        let plot2 = graph?.plot(withIdentifier: "y" as NSCopying)
        let plot3 = graph?.plot(withIdentifier: "z" as NSCopying)
        if((plot1) != nil){
            if(self.plotData.count >= maxDataPoints){
                self.plotData.removeFirst()
                plot1?.deleteData(inIndexRange:NSRange(location: 0, length: 1))
                plot2?.deleteData(inIndexRange:NSRange(location: 0, length: 1))
                plot3?.deleteData(inIndexRange:NSRange(location: 0, length: 1))
            }
        }
        guard let plotSpace = graph?.defaultPlotSpace as? CPTXYPlotSpace else { return }
        
        let location: NSInteger
        if self.currentIndex >= maxDataPoints {
            location = self.currentIndex - maxDataPoints + 2
        } else {
            location = 0
        }
        
        let range: NSInteger
        
        if location > 0 {
            range = location-1
        } else {
            range = 0
        }
        
        let oldRange =  CPTPlotRange(locationDecimal: CPTDecimalFromDouble(Double(range)), lengthDecimal: CPTDecimalFromDouble(Double(maxDataPoints-2)))
        let newRange =  CPTPlotRange(locationDecimal: CPTDecimalFromDouble(Double(location)), lengthDecimal: CPTDecimalFromDouble(Double(maxDataPoints-2)))

        CPTAnimation.animate(plotSpace, property: "xRange", from: oldRange, to: newRange, duration:0.3)
        
        self.currentIndex += 1;
    
        
        let point = self.data[0]
        self.plotData.append(point)
        let (yMin, yMax) = self.plotData.reduce((0, 0)) { (result, newData) -> (Double, Double) in
            let (x1, y1, z1) = newData.accelerometer.getAcc()
            let (alt) = newData.altitude.getAlt()
            let (x2, y2, z2) = newData.gyro.getGyro()
            let (x3, y3, z3) = newData.magneto.getMag()
            let ymin = min(x1, y1, z1, Double(alt), x2, y2, z2, x3, y3, z3, result.0)
            let ymax = max(x1, y1, z1, Double(alt), x2, y2, z2, x3, y3, z3, result.1)
            return (ymin, ymax)
        }
        plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(Double(yMin-1)), lengthDecimal: CPTDecimalFromDouble(Double(yMax - yMin)+2))
//        xValue.text = #"X: \#(String(format:"%.2f",Double(self.plotData.last!)))"#
//        yValue.text = #"Y: \#(UInt(self.currentIndex!)) Sec"#
        plot1?.insertData(at: UInt(self.plotData.count-1), numberOfRecords: 1)
        plot2?.insertData(at: UInt(self.plotData.count-1), numberOfRecords: 1)
        plot3?.insertData(at: UInt(self.plotData.count-1), numberOfRecords: 1)
    
    
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        tablerect = tableView.frame
        graphrect = graphContainer.frame
    }
    
    func getTitle()->String {
        switch selectedGraph {
            case .ACC:
                return "Accelerometer"
            case .GYRO:
                return "Gyro Sensor"
            case .MAG:
                return "Magneto Meter"
            case .ALT:
                return "Altitude"
        }
    }
    
    @objc func updateGraphType(_ sender: Any) {
        guard let button = sender as? UIBarButtonItem else { return }
        //self.timer2?.invalidate()
        self.plotData.removeAll()
        self.currentIndex = 0
        self.selectedGraph = DataTypes(rawValue: button.tag) ?? .ACC
        graphView.hostedGraph?.title = self.getTitle()
    }
    
    func configureGraphtView(){
        graphView.allowPinchScaling = false
        self.plotData.removeAll()
        self.currentIndex = 0
    }
    
    func configureGraphAxis(){
        
        let graph = CPTXYGraph(frame: graphView.bounds)
        graph.plotAreaFrame?.masksToBorder = false
        graphView.hostedGraph = graph
        graph.backgroundColor = UIColor.clear.cgColor
        graph.paddingBottom = 40.0
        graph.paddingLeft = 40.0
        graph.paddingTop = 30.0
        graph.paddingRight = 15.0
        

        //Set title for graph
        let titleStyle = CPTMutableTextStyle()
        titleStyle.color = CPTColor.init(cgColor: bluecolor.cgColor)
        titleStyle.fontName = "HelveticaNeue-Bold"
        titleStyle.fontSize = 20.0
        titleStyle.textAlignment = .center
        graph.titleTextStyle = titleStyle

        graph.title = self.getTitle()
        graph.titlePlotAreaFrameAnchor = .top
        graph.titleDisplacement = CGPoint(x: 0.0, y: 0.0)
        
        let axisSet = graph.axisSet as! CPTXYAxisSet
        
        let axisTextStyle = CPTMutableTextStyle()
        axisTextStyle.color = CPTColor.init(cgColor: bluecolor.cgColor)
        axisTextStyle.fontName = "HelveticaNeue-Bold"
        axisTextStyle.fontSize = 10.0
        axisTextStyle.textAlignment = .center
        let lineStyle = CPTMutableLineStyle()
        lineStyle.lineColor = CPTColor.init(cgColor: bluecolor.cgColor)
        lineStyle.lineWidth = 5
        let gridLineStyle = CPTMutableLineStyle()
        gridLineStyle.lineColor = CPTColor.init(cgColor: UIColor.lightGray.cgColor)
        gridLineStyle.lineWidth = 0.5
       

        if let x = axisSet.xAxis {
            x.majorIntervalLength   = 20
            x.minorTicksPerInterval = 5
            x.labelTextStyle = axisTextStyle
            x.minorGridLineStyle = gridLineStyle
            x.axisLineStyle = lineStyle
            x.axisConstraints = CPTConstraints(lowerOffset: 0.0)
            x.delegate = self
        }

        if let y = axisSet.yAxis {
            y.majorIntervalLength   = 5
            y.minorTicksPerInterval = 5
            y.minorGridLineStyle = gridLineStyle
            y.labelTextStyle = axisTextStyle
            //y.alternatingBandFills = [CPTFill(color: CPTColor.init(cgColor: bluecolor.cgColor)),CPTFill(color: CPTColor.init(cgColor: bluecolor.cgColor))]
            y.axisLineStyle = lineStyle
            y.axisConstraints = CPTConstraints(lowerOffset: 0.0)
            y.delegate = self
        }

        // Set plot space
        let xMin = 0.0
        let xMax = 100.0
        let yMin = -10
        let yMax = 10
        guard let plotSpace = graph.defaultPlotSpace as? CPTXYPlotSpace else { return }
        plotSpace.xRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(xMin), lengthDecimal: CPTDecimalFromDouble(xMax - xMin))
        plotSpace.yRange = CPTPlotRange(locationDecimal: CPTDecimalFromDouble(Double(yMin)), lengthDecimal: CPTDecimalFromDouble(Double(yMax - yMin)))
        
    }
    
    func configurePlot(){
        plotx = CPTScatterPlot()
        let plotLineStile = CPTMutableLineStyle()
        plotLineStile.lineJoin = .round
        plotLineStile.lineCap = .round
        plotLineStile.lineWidth = 2
        plotLineStile.lineColor = CPTColor(cgColor: bluecolor.cgColor)
        plotx.dataLineStyle = plotLineStile
        plotx.curvedInterpolationOption = .catmullCustomAlpha
        plotx.interpolation = .curved
        plotx.identifier = "x" as NSCoding & NSCopying & NSObjectProtocol
        guard let graph = graphView.hostedGraph else { return }
        plotx.dataSource = (self as CPTPlotDataSource)
        plotx.delegate = (self as CALayerDelegate)
        graph.add(plotx, to: graph.defaultPlotSpace)
        
        ploty = CPTScatterPlot()
        let plotLineStile2 = CPTMutableLineStyle()
        plotLineStile2.lineJoin = .round
        plotLineStile2.lineCap = .round
        plotLineStile2.lineWidth = 2
        plotLineStile2.lineColor = CPTColor.orange()
        ploty.dataLineStyle = plotLineStile2
        ploty.curvedInterpolationOption = .catmullCustomAlpha
        ploty.interpolation = .curved
        ploty.identifier = "y" as NSCoding & NSCopying & NSObjectProtocol
        ploty.dataSource = (self as CPTPlotDataSource)
        ploty.delegate = (self as CALayerDelegate)
        graph.add(ploty, to: graph.defaultPlotSpace)
        
        plotz = CPTScatterPlot()
        let plotLineStile3 = CPTMutableLineStyle()
        plotLineStile3.lineJoin = .round
        plotLineStile3.lineCap = .round
        plotLineStile3.lineWidth = 2
        plotLineStile3.lineColor = CPTColor.black()
        plotz.dataLineStyle = plotLineStile3
        plotz.curvedInterpolationOption = .catmullCustomAlpha
        plotz.interpolation = .curved
        plotz.identifier = "z" as NSCoding & NSCopying & NSObjectProtocol
        plotz.dataSource = (self as CPTPlotDataSource)
        plotz.delegate = (self as CALayerDelegate)
        graph.add(plotz, to: graph.defaultPlotSpace)
        
    }
    
    @IBAction func handleViewChange(_ sender: Any) {
        guard let seg = sender as? UISegmentedControl else { return }
        print(seg.selectedSegmentIndex)
        
        switch seg.selectedSegmentIndex {
            case 0:
                reloadTable()
                timer2?.invalidate()
                UIView.animate(withDuration: 0.2, animations: {
                    self.tableView.frame = self.tablerect
                    self.tableView.alpha = 1
                    self.graphContainer.frame.origin = CGPoint(x: 0, y: -1 * self.graphContainer.frame.size.height)
                    self.graphContainer.isHidden = true
                }) { (bool) in
                }
            default:
                timer?.invalidate()
                timer2?.invalidate()
                timer2 = Timer.scheduledTimer(withTimeInterval: self.timeDuration, repeats: true, block: { (_) in
                    self.fireTimer()
                })
                self.tablerect = self.tableView.frame
                UIView.animate(withDuration: 0.2, animations: {
                    self.tableView.frame.origin = CGPoint(x: 0, y: -1 * self.tableView.frame.size.height)
                    self.tableView.alpha = 0
                    self.graphContainer.frame = self.graphrect
                    self.graphContainer.isHidden = false
                }) { (bool) in
                    
                }
        }
    }
    
}

extension ViewController: CPTScatterPlotDataSource, CPTScatterPlotDelegate {
    func numberOfRecords(for plot: CPTPlot) -> UInt {
        return UInt(self.plotData.count)
    }

    func scatterPlot(_ plot: CPTScatterPlot, plotSymbolWasSelectedAtRecord idx: UInt, with event: UIEvent) {
    }

     func number(for plot: CPTPlot, field: UInt, record: UInt) -> Any? {
        
       switch CPTScatterPlotField(rawValue: Int(field))! {
        
            case .X:
                return NSNumber(value: Int(record) + self.currentIndex-self.plotData.count)

            case .Y:
                let dao = self.plotData[Int(record)]
                guard let identifier = plot.identifier as? String else { return 0 }
                print(identifier)
                switch selectedGraph {
                    case .ACC:
                        let (ax, ay, az) = dao.accelerometer.getAcc()
                        switch identifier {
                            case "x":
                                return ax
                            case "y":
                                return ay
                            default:
                                return az
                        }
                    case .MAG:
                    let (ax, ay, az) = dao.magneto.getMag()
                    switch identifier {
                        case "x":
                            return ax
                        case "y":
                            return ay
                        default:
                            return az
                    }
                    case .GYRO:
                    let (ax, ay, az) = dao.gyro.getGyro()
                    switch identifier {
                        case "x":
                            return ax
                        case "y":
                            return ay
                        default:
                            return az
                    }
                    case .ALT:
                    let (ax) = dao.altitude.getAlt()
                    switch identifier{
                        case "x":
                            return ax
                    default:
                        return -1000;
                    }
                }
            default:
                return 0
        
        }
        
    }
}

extension ViewController: DataDelegate {
    
    func save() {
        DataObject.save(dataObjects: self.data)
    }

    func sendData(data: DataObject) {
        self.data.insert(data, at: 0)
    }
    
    func showError(alert: UIAlertController) {
        self.present(alert, animated: true, completion: nil)
    }
    
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell: CustomCell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? CustomCell {
            cell.data = data[indexPath.item]
            cell.contentView.backgroundColor = indexPath.item % 2 == 0 ? .lightGray : .clear
            return cell
        }
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return stackView
    }
    
}

fileprivate extension UILabel {
    
    static var label: UILabel {
        let textView = UILabel()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.textAlignment = .center
        return textView
    }
    
}

fileprivate class CustomCell: UITableViewCell {
    
    var data: DataObject? {
        didSet {
            
            if let data_ = data {
                let acc = data_.accelerometer
                switch acc {
                    case .Accelerometer(let x, let y, let z):
                        if let label1 = stackView.arrangedSubviews[BLE.AX.rawValue] as? UILabel,
                            let label2 = stackView.arrangedSubviews[BLE.AY.rawValue] as? UILabel,
                            let label3 = stackView.arrangedSubviews[BLE.AZ.rawValue] as? UILabel {
                            label1.text = "\(x)"
                            label2.text = "\(y)"
                            label3.text = "\(z)"
                        }
                    default:
                        print("not accelerometer")
                }
                let gyr = data_.gyro
                switch gyr {
                    case .GYRO(let x, let y, let z):
                        if let label1 = stackView.arrangedSubviews[BLE.GX.rawValue] as? UILabel,
                            let label2 = stackView.arrangedSubviews[BLE.GY.rawValue] as? UILabel,
                            let label3 = stackView.arrangedSubviews[BLE.GZ.rawValue] as? UILabel {
                            label1.text = "\(x)"
                            label2.text = "\(y)"
                            label3.text = "\(z)"
                        }
                    default:
                        print("not gyro")
                }
                let mag = data_.magneto
                switch mag {
                    case .MAGNEOMETER(let x, let y, let z):
                        if let label1 = stackView.arrangedSubviews[BLE.MX.rawValue] as? UILabel,
                            let label2 = stackView.arrangedSubviews[BLE.MY.rawValue] as? UILabel,
                            let label3 = stackView.arrangedSubviews[BLE.MZ.rawValue] as? UILabel {
                            label1.text = "\(x)"
                            label2.text = "\(y)"
                            label3.text = "\(z)"
                        }
                    default:
                        print("not magneto")
                }
                let alt = data_.altitude
                switch alt {
                    case .ALTITUDE(let x):
                        if let label1 = stackView.arrangedSubviews[BLE.EV.rawValue] as? UILabel {
                            label1.text = "\(x)"
                        }
                    default:
                        print("not altitude")
                }
            }
        }
    }
    
    lazy var stackView: UIStackView = {
        var labels = [UILabel]() //= BLE.allCases.map({ _ in UILabel.label })
        for type in BLE.allCases {
           let label = UILabel.label
           label.textColor = UIColor(red: 0/255, green: 51/255, blue: 153/255, alpha: 1.0)
           label.font = UIFont(name: "Georgia", size: 14)
           label.text = "\(type)"
           // label.backgroundColor = .black
           labels.append(label)
        }
        let stackview = UIStackView(arrangedSubviews: labels)
        stackview.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: 25)
        stackview.distribution = .fillEqually
        stackview.alignment = .fill
        stackview.backgroundColor = .clear
        return stackview
    }()
    
    lazy var view: UIView = {
        let view_ = UIView(frame: self.frame)
       // view_.backgroundColor = .orange
        view_.addSubview(self.stackView)
        return view_
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()

    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
       addSubview(view)
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        stackView.frame = CGRect(x: 0, y: 0, width: self.frame.size.width, height: 25)
        view.frame = contentView.frame
        stackView.layoutIfNeeded()
    }
}

