//
//  MSearchHelper.swift
//
//
//  Created by Guru on 28/02/24.
//

import Foundation

class MSearchHelper {
    
    static let mCastAddress = "239.255.255.250"
    static let mSearchPort = UInt16(1800)
    static let UDPIPAddress = "224.0.0.1"
    
    static var port = "PORT:"
    static var deviceName =  "DeviceName:"
    static var state = "State:"
    static var USN = "USN:"
    static var speakerType = "SPEAKERTYPE:"
    static var null = "0"
    static var lUCIFirstSocket = "FN:"
    static var concurrentSSID = "DDMSConcurrentSSID:"
    static var firmwareVersion = "FWVERSION:"
    static var zoneID = "ZoneID:"
    static var netMode = "NETMODE:"
    static var castModel = "CAST_MODEL:"
    static var GCAST_VERSION = "CAST_FWVERSION:"
    static var deviceCap = "SOURCE_LIST:"
    
    static func getPayload(for address: String = mCastAddress) -> Data {
        let payload = NSMutableString(string: "M-SEARCH * HTTP/1.1\r\n")
        payload.append("MX: 10\r\n")
        payload.append("ST: urn:schemas-upnp-org:device:DDMSServer:1\r\n")
        payload.append("HOST: \(address):1800\r\n")
        payload.append("MAN: \"ssdp:discover\"\r\n")
        payload.append("\r\n")
        let data = (payload as String).data(using: .utf8)
        return data!
    }
    
    static func parseMSearch(payload message: String, from IP: String) -> Node {
        let castModel = message.parseMessage(for: castModel)
        
        let nodePort = message.parseMessage(for: port)
        
        let deviceName = message.parseMessage(for: deviceName)
        
        let fwversion = message.parseMessage(for: firmwareVersion)

        let nodeID = deviceName + IP
        let node = Node(id: nodeID, friendlyName: deviceName, model: castModel, ipAddress: IP, port: UInt16(nodePort)!, firmwareVersion: fwversion)
        
        return node
    }
}
