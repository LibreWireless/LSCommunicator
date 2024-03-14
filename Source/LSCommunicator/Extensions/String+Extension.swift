//
//  File.swift
//  
//
//  Created by Guru on 28/02/24.
//

import Foundation
import CommonCrypto

extension String {
    /// Helper function to parse the string message
    /// For ex: if message is PORT:7777 , and you need the value for field PORT: then this function comes in handy
    /// - Parameter field: provide the field name to be parsed from message (ex: PORT:)
    /// - Returns: the value of field provided (for this ex this function returns 7777)
    func parseMessage(for field : String) -> String {
        let newline: CharacterSet = .newlines
        var msgScanner = Scanner(string: self)
        
        /*Unicode standards
         0x000d - carriage return
         0x000a - line feed
         0x0085 - nextline*/
        
        var out: NSString? = nil
        if msgScanner.isAtEnd{
            msgScanner = Scanner(string: self)
        }
        //    msgScanner.charactersToBeSkipped = escapeCharSet
        msgScanner.caseSensitive = false
        
        while (!msgScanner.isAtEnd) {
            if msgScanner.scanString(field, into: &out) {
                msgScanner.scanUpToCharacters(from: newline, into: &out)
                return (out ?? "") as String
            }
            msgScanner.scanUpToCharacters(from: newline, into: nil)
        }
        return ""
    }
    
    /// Helper function to parse the starting line of multi line string
    /// - Returns: first line
    func parseFirstLine() -> String? {
        let stringToSplit = self.components(separatedBy: "\n")
        var startLine = stringToSplit[0]
        startLine = startLine.replacingOccurrences(of: "\r", with: "")
        return startLine
    }
    
        
    mutating func MD5() -> String {
        let length = Int(CC_MD5_DIGEST_LENGTH)
        let messageData = self.data(using:.utf8)!
        var digestData = Data(count: length)
        
        _ = digestData.withUnsafeMutableBytes { digestBytes -> UInt8 in
            messageData.withUnsafeBytes { messageBytes -> UInt8 in
                if let messageBytesBaseAddress = messageBytes.baseAddress,
                   let digestBytesBlindMemory = digestBytes.bindMemory(to: UInt8.self).baseAddress {
                    let messageLength = CC_LONG(messageData.count)
                    CC_MD5(messageBytesBaseAddress, messageLength, digestBytesBlindMemory)
                }
                return 0
            }
        }
        return toHexString(data: [UInt8](digestData), length: length)
    }
    
    func toHexString(data: [UInt8], length: Int) -> String {
        let hash = NSMutableString(capacity: length * 2)
        for i in 0..<length {
            hash.append(String(format: "%02x", data[i]))
        }
        return hash as String
    }
}

func validateString(text: Any?) -> String {
    guard var text = text as? String else { return "" }
    if (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || text == "<null>" || text == "(null)") {
        text = ""
    }
    return text
}
