//
//  File.swift
//  
//
//  Created by Guru on 07/03/24.
//

import Foundation
import CocoaAsyncSocket

class TLSHelper {
    
    static var tlsSetting = [String : NSObject]()
    
    var credentialsFileURL: URL? {
        let fileName = "cert"
        let fileExtension = "p12"
        let thisSourceFile = URL(fileURLWithPath: #file)
        var thisSourceDirectory = thisSourceFile.deletingLastPathComponent().deletingLastPathComponent()
        thisSourceDirectory = thisSourceDirectory.appendingPathComponent("Resources")
        return thisSourceDirectory.appendingPathComponent("\(fileName).\(fileExtension)")
    }
    
    static func initTLSSocketSettings() {
        guard let url = TLSHelper().credentialsFileURL else {
            fatalError("Missing the server cert resource from the bundle")
        }
        do {
            let p12 = try Data(contentsOf: url) as CFData
            let options = [kSecImportExportPassphrase as String: "12345678"] as CFDictionary
            
            var rawItems: CFArray?
            
            guard SecPKCS12Import(p12, options, &rawItems) == errSecSuccess else {
                fatalError("Error in p12 import")
            }
            
            let unwrappedItems = rawItems! as [AnyObject]
            let certDict = unwrappedItems[0] as! [String:AnyObject]
            var certs = [certDict["identity"]!]
            for c in certDict["chain"]! as! [AnyObject] {
                certs.append(c as! SecCertificate)
            }
            rawItems = certs as CFArray
            
            let tlsSetting: [String : Any] = [
                GCDAsyncSocketManuallyEvaluateTrust: true,
                GCDAsyncSocketSSLProtocolVersionMin: 8, // Specify TLS 1.2 as the minimum version
                GCDAsyncSocketSSLProtocolVersionMax: 8, // Specify TLS 1.2 as the maximum version
                (kCFStreamSSLCertificates as String): rawItems as! [SecCertificate],
            ]
            TLSHelper.tlsSetting = tlsSetting as! [String : NSObject]
        }
        catch {
            fatalError("Could not create server certificate")
        }
    }
}
