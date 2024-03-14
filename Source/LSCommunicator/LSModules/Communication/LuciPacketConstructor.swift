//
//  LuciPacketConstructor.swift
//  
//
//  Created by Guru on 14/03/24.
//

import UIKit

typealias short = UInt16

class LuciPacketConstructor: NSObject {
        
    private let headerSize = 10
    
    var TAG = String()
    var remoteID: short = 0
    var commandType: short = 0
    var command: short = 0
    var commandStatus: short = 0
    var CRC: short = 0
    var dataLen: short = 0
    
    var header = NSMutableData() ///Bitstream of the LUCI header
    var payloadSize: Int = 0 ///size of the LUCI payload
    var payload = NSMutableData() ///Bitstream of the LUCI header
    
    init(with message: Data, messageSize mSize: short, command cmd: short,
         commandType cmdType: short? = nil, remoteID: Int) {
        self.remoteID = short(remoteID)
        self.commandType = cmdType == nil ? 2 : cmdType!
        self.command = cmd
        self.commandStatus = 0
        self.CRC = 0
        self.dataLen = mSize
        
        var bytes = Array<short>.init(repeating: 0, count: headerSize)
        bytes[0] = self.remoteID & 0x00FF
        bytes[1] = (self.remoteID & 0xFF00) >> 8
        bytes[2] = self.commandType & 0x00FF
        bytes[3] = self.command & 0x00FF
        bytes[4] = (self.command & 0xFF00) >> 8
        bytes[5] = self.commandStatus
        bytes[6] = self.CRC & 0x00FF
        bytes[7] = (self.CRC & 0xFF00) >> 8
        bytes[8] = self.dataLen & 0x00FF
        bytes[9] = (self.dataLen & 0xFF00) >> 8
        
        let uint8Array = bytes.map({ UInt8($0) })
        header = NSMutableData(bytes: uint8Array, length: headerSize)
        payloadSize = Int(mSize)
        payload = NSMutableData()
        payload.setData(message)
    }
    
    func getMessage() -> NSMutableData {
        let data = NSMutableData()
        data.setData(header as Data)
        data.append(payload as Data)
        return data
    }
    
    func getMessageSize() -> Int {
        return payloadSize + headerSize
    }
}
