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

class BluetoothScanner: NSObject, BluetoothManager {
   
    var centralManager: CBCentralManager?
    let semaphore = DispatchSemaphore(value: 0)
    var readTimer: Timer?
    let cbuuids = Product.getAddedProductsCBUUIDs()
    var seatData: SeatData?
    var notifSent = false
    
    private(set) var peripherals = Dictionary<UUID, CBPeripheral>() {
        didSet {
            //self.connectToPeripherals()
        }
    }
    
    weak var delegate: SnuggoWidgetDelegate? {
           didSet {
               delegate?.updatePowerStatus(power: centralManager?.state == .poweredOn ? true : false)
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
            centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionRestoreIdentifierKey: "\(KEYS.PRODUCTS)"])
            for uuid in cbuuids {
                if let uuids = UUID(uuidString: uuid.uuidString) {
                    if let peripherals_ = centralManager?.retrievePeripherals(withIdentifiers: [uuids]) {
                        _ = peripherals_.map({self.peripherals[$0.identifier] = $0})
                    }
                    if let peripherals_ = centralManager?.retrieveConnectedPeripherals(withServices: cbuuids) {
                        _ = peripherals_.map({self.peripherals[$0.identifier] = $0})
                    }
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
            central.scanForPeripherals(withServices: cbuuids, options: nil)
            
            let peripherals_ = central.retrievePeripherals(withIdentifiers: cbuuids.map( { UUID(uuidString: $0.uuidString)! }))
            let peripherals__ = central.retrieveConnectedPeripherals(withServices: cbuuids)
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
                self?.semaphore.wait()
                DispatchQueue.main.async {
                    self?.connectToPeripherals()
                }
            }
            
        }
        else {
            NotificationManager.sendNotifications(title: "Snuggo requires bluetooth", message: "Please turn on bluetooth from settings", type: .NO_BLUETOOTH_NOTIFICATION)
        }
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { [weak self] timer in
            self?.readTimer?.invalidate()
            self?.notifSent = false
        })
    }
    
    @objc func stopScanning() {
        guard let central = self.centralManager else { return }
        
        if central.state == .poweredOn {
            for uuid in cbuuids {
                if let uuids = UUID(uuidString: uuid.uuidString) {
                    let peripherals_ = central.retrievePeripherals(withIdentifiers: [uuids])
                    _ = peripherals_.map({self.peripherals[$0.identifier] = $0})
                    let peripherals__ = central.retrieveConnectedPeripherals(withServices: cbuuids)
                    _ = peripherals__.map({self.peripherals[$0.identifier] = $0})
                }
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
            self?.delegate?.updatePowerStatus(power: false)
            self?.readTimer?.invalidate()
            self?.notifSent = false
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
                    if let seat = self?.seatData, seat.weight > 0, let notif = self?.notifSent {
                        if !notif {
                            NotificationManager.sendNotifications(title: "CHILD LEFT IN SEAT ALERT", message: "Your child is still in the car seat, please ensure a responsible adult is with the child.", type: .CHILD_LEFT_IN)
                            self?.delegate?.childLeftInCarSeat(left: true)
                            self?.notifSent = true
                        }
                    }
                } else {
                    self?.notifSent = false
                    self?.delegate?.childLeftInCarSeat(left: false)
                }
            })
        }
    }
}

// MARK: Central Manager Delegate
extension BluetoothScanner: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if delegate != nil {
            delegate?.updatePowerStatus(power: central.state == .poweredOn ? true : false)
        }
        
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
        peripheral.discoverServices(cbuuids)
        print("Connected")
        semaphore.signal()
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected \(String(describing: error))")
        semaphore.signal()
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
        if let data = characteristic.value, let json = String(bytes: data, encoding: .utf8)?.data(using: .utf8) {
            do {
                print(String(bytes: data, encoding: .utf8) ?? "")
                seatData = try JSONDecoder().decode(SeatData.self, from: json)
                if let seatData = seatData {
                    delegate?.updateCarSeatSensorsData(seat: seatData)
                    if seatData.weight == 0 {
                        if !self.notifSent {
                            NotificationManager.sendNotifications(title: "CHILD LEFT SEAT ALERT", message: "Your child has left their car seat. If this was intentional then the SMART system will switch off in 60 seconds.", type: .CHILD_LEFT_IN)
                            self.delegate?.childLeftCarSeat(left: true)
                            self.notifSent = true
                        }
                    }
                    else {
                        self.notifSent = false
                        self.delegate?.childLeftCarSeat(left: false)
                    }
                                        
                }
            } catch {
                print(error)
            }
        }
    }
    
   
}


