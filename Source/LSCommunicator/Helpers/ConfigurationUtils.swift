//
//  ConfigurationUtils.swift
//  
//
//  Created by Guru on 11/03/24.
//

import UIKit

class ConfigurationUtils {
    
    static func encodeConfigurationData(data: Data, usingHexKey hexKey: inout String, hexIV: inout String) -> Data? {
        
        let encryptedPayload = data.encryptedDataWithHexKey(hexKey: &hexKey,
                                                            hexIV: &hexIV)
        
        return encryptedPayload
    }
    
    static func encodeAndPrintPlainText(plainText: String,
                                        hexKey: inout String,
                                        hexIV: inout String,
                                        isPassword: Bool) -> Data? {
        var data = plainText.data(using: .utf8)!
        if(isPassword) {
            data = plainText.data(using: .utf8)!
        }
        let encryptedPayload = data.encryptedDataWithHexKey(hexKey: &hexKey, hexIV: &hexIV)
        return encryptedPayload
    }
    
    static func encodeToPercentEscapeString(string: String) -> String? {
        return string.addingPercentEncoding(withAllowedCharacters: CharacterSet(charactersIn: "!*'();:@&=+$,/?%#[]"))
    }
    
    static func constructConfigurationMessage(command: BLECommand,
                                              withData message: Data,
                                              withIV iv: inout String,
                                              withRemainingFramgentsCount moreFragmentsToSend: Int,
                                              withFragmentlength fragmentLength: Int) -> Data {
        func decodeNibble(u: UInt16) -> UInt8? {
            switch(u) {
            case 0x30 ... 0x39:
                return UInt8(u - 0x30)
            case 0x41 ... 0x46:
                return UInt8(u - 0x41 + 10)
            case 0x61 ... 0x66:
                return UInt8(u - 0x61 + 10)
            default:
                return nil
            }
        }
        
        guard let data = NSMutableData(capacity: iv.utf16.count/2) else {
            return Data()
        }
        
        var iter = iv.utf16.makeIterator()
        while let c1 = iter.next() {
            guard
                let val1 = decodeNibble(u: c1),
                let c2 = iter.next(),
                let val2 = decodeNibble(u: c2)
            else { return Data() }
            var value = val1 << 4 + val2
            data.append(&value, length: 1)
        }
        
        let fragmentLength = fragmentLength + data.count + 1
        var startBytes = [UInt8](repeating: UInt8(), count: 10)
        startBytes[0] = 0xAB
        startBytes[1] = UInt8(command.rawValue)
        startBytes[2] = 0xEF
        startBytes[3] = 0xBE
        startBytes[4] = 0xAD
        startBytes[5] = 0xDE
        startBytes[6] = UInt8(moreFragmentsToSend)
        startBytes[7] = UInt8(fragmentLength) & 0xFF
        startBytes[8] = (UInt8(fragmentLength) >> 8) & 0xFF
        startBytes[9] = UInt8(data.count)
        
        let header: NSMutableData = NSMutableData(bytes: startBytes, length: startBytes.count)
        header.append(data as Data)

        header.append(message)
        
        var endByte = [UInt8](repeating: UInt8(), count: 1)
        endByte[0] = 0xCD
        header.append(Data(bytes: endByte, count: endByte.count))
        
        return header as Data
    }
}
