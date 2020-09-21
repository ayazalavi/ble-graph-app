//
//  ViewController.swift
//  ble demo app
//
//  Created by Miranz  Technologies on 9/21/20.
//  Copyright © 2020 Ayaz Alavi. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    
    var data: [DataObject] = DataObject.getAll()
    
    let reuseID = "DefaultCell"
    
    var timer: Timer?
    
    var tablerect: CGRect!
    
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
        
        tablerect = tableView.frame
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { (_) in
            self.tableView.reloadData()
        }
    }
    
    func reloadTable() {
        self.tableView.reloadData()
    }
    
    @IBAction func handleViewChange(_ sender: Any) {
        guard let seg = sender as? UISegmentedControl else { return }
        print(seg.selectedSegmentIndex)
        
        switch seg.selectedSegmentIndex {
            case 0:
                UIView.animate(withDuration: 0.2, animations: {
                    self.tableView.frame = self.tablerect
                    self.tableView.alpha = 1
                }) { (bool) in
                }
            default:
                self.tablerect = self.tableView.frame
                UIView.animate(withDuration: 0.2, animations: {
                    self.tableView.frame.origin = CGPoint(x: 0, y: -1 * self.tableView.frame.size.height)
                    self.tableView.alpha = 0
                }) { (bool) in
                    
                }
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

