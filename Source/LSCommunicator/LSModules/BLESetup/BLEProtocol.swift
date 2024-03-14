//
//  BLEProtocol.swift
//  
//
//  Created by Guru on 12/03/24.
//

import UIKit

public enum BLEMessageType {
    case friendlyName(String?)
    case wifiScanList(Result<WiFiScanListItems?, Error>)
    case connectingWiFi
    case wifiConnection(Result<Int?, Error>)
}

public protocol BLEStateDelegate: AnyObject {
    func bluetoothStateDidUpdate(state: BluetoothState)
}

public protocol BLEDiscoveryDelegate: AnyObject {
    func didDiscoverDevice(device: BLEDevice)
}

public protocol BLEConnectionDelegate: AnyObject {
    func bluetoothConnectionSucceded()
    func failedToConnectTobluetoothDevice(withError error: Error)
}

public protocol BLEReadWriteDelegate: AnyObject {
    func didWriteMessage()
    func didReadMessage(of type: BLEMessageType)
}
