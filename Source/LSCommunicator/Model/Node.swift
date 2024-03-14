//
//  File.swift
//  
//
//  Created by Guru on 27/02/24.
//

import Foundation
import CocoaAsyncSocket
import CoreBluetooth

public struct Node {
    
    let id: String
    let friendlyName: String
    let model: String
    let ipAddress: String
    let port: UInt16
    let firmwareVersion: String
    var luciSocket: GCDAsyncSocket?
    
}

public struct BLEDevice {
    
    public let id = UUID()
    public let bleFriendlyName: String
    private (set) var peripheral: CBPeripheral
}
