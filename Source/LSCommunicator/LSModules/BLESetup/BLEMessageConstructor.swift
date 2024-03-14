//
//  BLEMessageConstructor.swift
//  
//
//  Created by Guru on 11/03/24.
//

import UIKit
import CoreBluetooth

class BLEMessageConstructor {
    
    static let shared = BLEMessageConstructor()
    
    private init() { }
        
    /// Creates BLE packet with header and data that can be sent to module
    /// - Parameters:
    ///   - command: BLE Command enum
    ///   - message: message string in utf8 formatted data
    ///   - length: length of the message
    /// - Returns: BLE Packet as Data that can be sent to module
    func constructBLEPacket(command: BLECommand,
                            withData message: Data, length: Int) -> Data {
        let bleMessageData = NSMutableData()
        
        var startBytes = Array<UInt16>.init(repeating: 0, count: 4)
        startBytes[0] = 0xAB
        startBytes[1] = command.rawValue
        startBytes[2] = UInt16((length) & 0xFF)
        startBytes[3] = UInt16(((length) >> 8) & 0xFF)
        
        let uint8HeaderArray = startBytes.map({UInt8($0)})
        let header = NSMutableData(bytes: uint8HeaderArray, length: 4)
        header.append(message)
        
        var byte = Array<UInt16>.init(repeating: 0, count: 1)
        byte[0] = 0xCD
        let uint8EndByte = byte.map({UInt8($0)})
        let endByte = NSMutableData(bytes: uint8EndByte, length: 1)
        
        bleMessageData.setData(header as Data)
        bleMessageData.append(endByte as Data)
        
        return bleMessageData as Data
    }

}
