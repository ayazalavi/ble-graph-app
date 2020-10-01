//
//  DataObject.swift
//  ble demo app
//
//  Created by Miranz  Technologies on 9/21/20.
//  Copyright © 2020 Ayaz Alavi. All rights reserved.
//

import Foundation

struct DataObject: Codable {
    let accelerometer: SENSORS
    let gyro: SENSORS
    let magneto: SENSORS
    let altitude: SENSORS
    
    init(accelerometer: SENSORS, gyro: SENSORS, magneto: SENSORS, altitude: SENSORS) {
        self.accelerometer = accelerometer
        self.gyro = gyro
        self.magneto = magneto
        self.altitude = altitude
    }
    
    static func getAll() -> [DataObject] {
        var data: [DataObject] = [DataObject]()
        if let data_ = UserDefaults.standard.value(forKey:"DATA") as? Data {
            if let data__ = try? PropertyListDecoder().decode(Array<DataObject>.self, from: data_) {
                data = data__
            }
        }
        return data
    }
    
    static func checkDelete(dos: inout [DataObject]) {
        if dos.count > 100 {
           _ = dos.popLast()
        }
    }
    
//    static func prepend(dataObject: DataObject) {
//        var dos = [DataObject]()
//        let products_ = getAll()
//        dos = products_
//            checkDelete(dos: &dos)
//        }
//        dos.insert(dataObject, at: 0)
//        UserDefaults.standard.set(try? PropertyListEncoder().encode(dos), forKey:"DATA")
//    }
    
    static func save(dataObjects: [DataObject]) {
        UserDefaults.standard.set(try? PropertyListEncoder().encode(dataObjects), forKey:"DATA")
    }
}

enum SENSORS {
    case Accelerometer(Double, Double, Double)
    case GYRO(Double, Double, Double)
    case MAGNEOMETER(Double, Double, Double)
    case ALTITUDE(Int)
    
    func getAcc() -> (Double, Double, Double) {
        switch self {
        case .Accelerometer(let x, let y, let z):
            return (x, y, z)
        default:
            return (0,0,0)
        }
    }
    
    func getGyro() -> (Double, Double, Double) {
        switch self {
        case .GYRO(let x, let y, let z):
            return (x, y, z)
        default:
            return (0,0,0)
        }
    }
    func getMag() -> (Double, Double, Double) {
        switch self {
        case .MAGNEOMETER(let x, let y, let z):
            return (x, y, z)
        default:
            return (0,0,0)
        }
    }
    
    func getAlt() -> (Int) {
        switch self {
        case .ALTITUDE(let x):
            return (x)
        default:
            return (0)
        }
    }
}

extension SENSORS: Codable {
    
    enum Key: CodingKey {
        case x, y, z, T
    }
    
    enum CodingError: Error {
        case unknownValue
    }
      
    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: Key.self)
        let type = try values.decode(Int.self, forKey: .T)
        let x = try values.decode(Double.self, forKey: .x)
        let y = try? values.decode(Double.self, forKey: .y)
        let z = try? values.decode(Double.self, forKey: .z)
        //print(x, y, z, type, separator: ", ")
        switch type {
            case 0:
                self = .Accelerometer(x, y!, z!)
            case 1:
                self = .GYRO(x, y!, z!)
            case 2:
                self = .MAGNEOMETER(x, y!, z!)
            default:
                self = .ALTITUDE(Int(x))
        }
        //print(type, x, y, z, separator: " - ", terminator: "-eol-")
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
            case .Accelerometer(let ax, let ay, let az):
                try container.encode(ax, forKey: .x)
                try container.encode(ay, forKey: .y)
                try container.encode(az, forKey: .z)
                try container.encode(0, forKey: .T)
            case .GYRO(let gx, let gy, let gz):
                try container.encode(gx, forKey: .x)
                try container.encode(gy, forKey: .y)
                try container.encode(gz, forKey: .z)
                try container.encode(1, forKey: .T)
            case .MAGNEOMETER(let mx, let my, let mz):
                try container.encode(mx, forKey: .x)
                try container.encode(my, forKey: .y)
                try container.encode(mz, forKey: .z)
                try container.encode(2, forKey: .T)
            case .ALTITUDE(let alt):
                try container.encode(alt, forKey: .x)
                try container.encode(3, forKey: .T)
        }
    }
}

enum BLE: Int, CaseIterable {
    case AX, AY, AZ, GX, GY, GZ, MX, MY, MZ, EV
}

enum DataError: Error {
    case DATACOUNT
}

enum DataTypes: Int {
    case ACC, GYRO, MAG, ALT
}
