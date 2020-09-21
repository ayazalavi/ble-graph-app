//
//  BluetoothScanner.swift
//  the snuggo
//
//  Created by Miranz  Technologies on 9/13/20.
//  Copyright © 2020 Ayaz Alavi. All rights reserved.
//

import Foundation
import UIKit
import CoreBluetooth


class BluetoothScanner: NSObject {
   
    var centralManager: CBCentralManager?
    let semaphore = DispatchSemaphore(value: 0)
    var readTimer: Timer?
    let cbuuid = CBUUID(string: "4fafc201-1fb5-459e-8fcc-c5c9c331914b")
    var data: DataObject?
    weak var delegate: DataDelegate?
    let restoreID = "APP_ID"
    
    private(set) var peripherals = Dictionary<UUID, CBPeripheral>() {
        didSet {
            //self.connectToPeripherals()
        }
    }

    // MARK: Singleton
    static let shared = BluetoothScanner()
    
    private override init() {
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(appWillTerminate), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    // MARK: - Callbacks
    @objc func startScanning() {
        print("start scanning")
        guard let central = self.centralManager else {
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "\(restoreID)"])
            if let uuid = UUID(uuidString: cbuuid.uuidString) {
                if let peripherals_ = centralManager?.retrievePeripherals(withIdentifiers: [uuid]) {
                    _ = peripherals_.map({self.peripherals[$0.identifier] = $0})
                }
                if let peripherals_ = centralManager?.retrieveConnectedPeripherals(withServices: [cbuuid]) {
                    _ = peripherals_.map({self.peripherals[$0.identifier] = $0})
                }
            }
            //print("\(self.peripherals)")
            return
        }
        print("checking previous conenctions")
        if central.state == .poweredOn {
            if central.isScanning {
                central.stopScan()
            }
            central.scanForPeripherals(withServices: [cbuuid], options: nil)
            
            let peripherals_ = central.retrievePeripherals(withIdentifiers: [UUID(uuidString: cbuuid.uuidString)!])
            let peripherals__ = central.retrieveConnectedPeripherals(withServices: [cbuuid])
            print(peripherals_, peripherals__, separator: " - ")
            let queue = DispatchQueue.global(qos: .background)
            queue.async { [weak self] in
                _ = peripherals_.map({
                    central.cancelPeripheralConnection($0)
                    self?.peripherals[$0.identifier] = $0
                    
                })
                _ = peripherals__.map({
                    central.cancelPeripheralConnection($0)
                    self?.peripherals[$0.identifier] = $0
                })
                if peripherals__.count > 0 || peripherals_.count > 0 {
                    self?.semaphore.wait()
                }
                DispatchQueue.main.async {
                    self?.connectToPeripherals()
                }
            }
            
        }
        else {
            let alert = UIAlertController(title: "Bluetooth needed", message: "Please turn on bluetooth", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Go to Settings", style: .cancel, handler: { (_) in
                UIApplication.shared.open(URL(string: "App-Prefs:root=Bluetooth")!, options: [.universalLinksOnly: false], completionHandler: nil)
            }))
            delegate?.showError(alert: alert)
        }
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] timer in
            self?.readTimer?.invalidate()
        })
    }
    
    @objc func stopScanning() {
        guard let central = self.centralManager else { return }
        
        if central.state == .poweredOn {
            if let uuids = UUID(uuidString: cbuuid.uuidString) {
                let peripherals_ = central.retrievePeripherals(withIdentifiers: [uuids])
                _ = peripherals_.map({self.peripherals[$0.identifier] = $0})
                let peripherals__ = central.retrieveConnectedPeripherals(withServices: [cbuuid])
                _ = peripherals__.map({self.peripherals[$0.identifier] = $0})
            }
            DispatchQueue.global(qos: .background).async { [weak self] in
                _ = self?.peripherals.mapValues {
                    if $0.state == .connected {
                        central.cancelPeripheralConnection($0)
                        self?.semaphore.wait()
                    }
                }
            }
            
            if central.isScanning {
                central.stopScan()
            }
        }
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false, block: { [weak self] timer in
            self?.peripherals.removeAll()
            self?.readTimer?.invalidate()
        })
    }

    
    @objc func appWillTerminate() {
        guard let central = self.centralManager else { return }
        if central.state == .poweredOn {
            if central.isScanning {
                central.stopScan()
            }
            _ = self.peripherals.mapValues {
                central.cancelPeripheralConnection($0)
            }
        }
        delegate?.save()
        Timer.scheduledTimer(withTimeInterval: 3, repeats: false, block: { [weak self] timer in
            self?.centralManager = nil
        })
        
    }
    
    @objc func connectToPeripherals() {
        guard self.peripherals.count > 0, let central = self.centralManager, central.state == .poweredOn else {
            print("No device discovered so far")
            return
        }
        print("peripehrals \(self.peripherals)")
        self.readTimer?.invalidate()
        let queue = DispatchQueue.global(qos: .background)
        queue.async {
            _ = self.peripherals.mapValues({ [weak self] peripheral in
                if peripheral.state != .connected {
                    central.connect(peripheral, options: nil)
                    self?.semaphore.wait()
                }
            })
        }
    }
}

// MARK: Central Manager Delegate
extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        startScanning()
    }
    
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
        //print("restore state")
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("peripheral found \(String(describing: peripheral.name))")
        peripherals[peripheral.identifier] = peripheral
        self.connectToPeripherals()
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices([cbuuid])
        print("Connected")
        semaphore.signal()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected \(String(describing: error))")
        semaphore.signal()
        self.connectToPeripherals()
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Fail to Connect")
        semaphore.signal()
    }

}

// MARK: Peripheral Delegate
extension BluetoothScanner: CBPeripheralDelegate {
    func peripheralIsReady(toSendWriteWithoutResponse peripheral: CBPeripheral) {
        //remove timer
        //print("peripherial \(peripheral.identifier) is ready")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        print("did discover services")
        for service in services {
            let thisService = service as CBService
            peripheral.discoverCharacteristics(nil, for: thisService)
        }
        
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        print("did discover characteristics")
        for charateristic in characteristics {
            let thisCharacteristic = charateristic as CBCharacteristic
            peripheral.setNotifyValue(true, for: thisCharacteristic)
            self.readTimer?.invalidate()
            self.readTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { (timer) in
                peripheral.readValue(for: thisCharacteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let data = characteristic.value, let stringData = String(bytes: data, encoding: .utf8) {
            print(stringData)
            let arr: [Double] = stringData.components(separatedBy: ",").map({ $0.toDouble() })
            guard arr.count == BLE.allCases.count else { return }
            let acc: SENSORS = SENSORS.Accelerometer(arr[BLE.AX.rawValue], arr[BLE.AY.rawValue], arr[BLE.AZ.rawValue])
            let gyr: SENSORS = SENSORS.GYRO(arr[BLE.GX.rawValue], arr[BLE.GY.rawValue], arr[BLE.GZ.rawValue])
            let mag: SENSORS = SENSORS.MAGNEOMETER(arr[BLE.MX.rawValue], arr[BLE.MY.rawValue], arr[BLE.MZ.rawValue])
            let alt: SENSORS = SENSORS.ALTITUDE(arr[BLE.EV.rawValue].toInt())
            let dataObject = DataObject(accelerometer: acc, gyro: gyr, magneto: mag, altitude: alt)
            delegate?.sendData(data: dataObject)
        }
    }
    
   
}

fileprivate extension String {
    
    func toDouble() -> Double {
        return (self as NSString).doubleValue
    }
}

fileprivate extension Double {
    
    func toInt() -> Int {
        return Int(self)
    }
}


