//
//  File.swift
//  
//
//  Created by Guru on 28/02/24.
//

import Foundation

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
}
