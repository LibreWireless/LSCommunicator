//
//  Data+Extension.swift
//  
//
//  Created by Guru on 11/03/24.
//

import UIKit
import CommonCrypto

extension Data {
    
    func fillDataArray(dataPtr: inout UnsafeMutableRawPointer, length: Int, hexString: inout String) {
        let data = dataFromHexString(string: &hexString)
        assert((data.count + 1) == length, "The hex provided didn't decode to match length")
        let total_bytes = length + 1 * MemoryLayout<CChar>.size
        dataPtr = malloc(total_bytes)
        bzero(dataPtr, total_bytes)
        memcpy(dataPtr, (data as NSData).bytes, data.count)
    }
    
    func encryptedDataWithHexKey(hexKey: inout String, hexIV: inout String) -> Data? {
        var keyData = hexKey.data(using: .utf8)!
        var keyPtr = keyData.withUnsafeMutableBytes { $0 }.baseAddress!
        fillDataArray(dataPtr: &keyPtr, length: kCCKeySizeAES128 + 1, hexString: &hexKey)
        
        var ivData = hexIV.data(using: .utf8)!
        var ivPtr = ivData.withUnsafeMutableBytes { $0 }.baseAddress!
        fillDataArray(dataPtr: &ivPtr, length: kCCKeySizeAES128 + 1, hexString: &hexIV)
        
        let dataLength = self.count
        let bufferSize: size_t = dataLength + kCCBlockSizeAES128
        let buffer = malloc(bufferSize)
        
        var numBytesEncrypted: size_t = 0
        
        let status = CCCrypt(CCOperation(kCCEncrypt), CCAlgorithm(kCCAlgorithmAES), CCOptions(kCCOptionPKCS7Padding), keyPtr, kCCKeySizeAES128, ivPtr, (self as NSData).bytes, dataLength, buffer, bufferSize, &numBytesEncrypted)
        
        free(keyPtr)
        free(ivPtr)
        
        if (status == kCCSuccess) {
            return Data(bytes: buffer!, count: numBytesEncrypted)
        }
        
        free(buffer)
        return nil
    }
    
    public func dataFromHexString(string: inout String) -> Data {
        // Convert 0 ... 9, a ... f, A ...F to their decimal value,
        // return nil for all other input characters
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
        
        guard let data = NSMutableData(capacity: string.utf16.count/2) else {
            return Data()
        }
        
        var iter = string.utf16.makeIterator()
        while let c1 = iter.next() {
            guard
                let val1 = decodeNibble(u: c1),
                let c2 = iter.next(),
                let val2 = decodeNibble(u: c2)
            else { return Data() }
            var value = val1 << 4 + val2
            data.append(&value, length: 1)
        }
        return data as Data
    }
}
