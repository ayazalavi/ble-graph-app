//
//  DataDelegate.swift
//  ble demo app
//
//  Created by Miranz  Technologies on 9/21/20.
//  Copyright © 2020 Ayaz Alavi. All rights reserved.
//

import Foundation
import UIKit

protocol DataDelegate: NSObject {
    
    func sendData(data: DataObject)
    
    func showError(alert: UIAlertController)
    
    func save()
}
