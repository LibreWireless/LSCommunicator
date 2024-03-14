//
//  BLEMessageParser.swift
//  
//
//  Created by Guru on 11/03/24.
//

import UIKit
import CoreBluetooth

typealias BLEResult = (command: BLECommand, result: Any?)

/// Object class which is used to parse the Message received from device over BLE
class BLEMessageParser: NSObject {
    
    static let shared = BLEMessageParser()
    
    private var inputBuffer: NSMutableData?
    private var totalDataLength: Int?
        
    private override init() {
        super.init()
        
        inputBuffer = NSMutableData()
        totalDataLength = Int()
    }
    
    func processDeviceData(packet: Data,
                           forPeripheral peripheral: CBPeripheral) -> BLEResult? {
        
        print("🔵 BLE processDeviceData")
        print("🔵 BLE Process data of length: \(packet.count)")
                
        if (packet.count > 6) {
            let payloadString = String(data: packet.subdata(in: Range(NSRange(location: 4, length: packet.count - 5))!), encoding: .utf8)
            print("🔵 BLE payload : \(payloadString as Any)")
        }
        
        let headerVal = packet[0]
        var errorReason = ""
        
        guard headerVal == BLEHeadeR_ID else {
            print("❌ BLE REMOTE ID WRONG")
            inputBuffer!.length = 0
            return nil
        }
        
        print("🔵 BLE Command received = \(String(describing: BLECommand(rawValue: UInt16(packet[1]))))")
        
        switch BLECommand(rawValue: UInt16(packet[1])) {
            
        case .BLE_SAC_APP2DEV_REQUEST_FOR_FRIENDLYNAME:
            if let bleFriendlyName = String(data: packet.subdata(in: Range(NSRange(location: 4, length: packet.count - 5))!), encoding: .utf8) {
                print("🔵 BLE Got Friendly Name : \(bleFriendlyName)")
                return (.BLE_SAC_APP2DEV_REQUEST_FOR_FRIENDLYNAME, bleFriendlyName)
            }
            return (.BLE_SAC_APP2DEV_REQUEST_FOR_FRIENDLYNAME, "")
            
        case .BLE_SAC_DEV2APP_SCAN_LIST_START:
            inputBuffer = NSMutableData()
            totalDataLength = Int(packet[2]) + (Int(packet[3]) * 256)
            print("🔵 BLE Scan list start : \(totalDataLength!)")
            if (totalDataLength! < 10) {
                if let scanListLength = String(data: packet.subdata(in: Range(NSRange(location: 4, length: packet.count - 5))!), encoding: .utf8) {
                    totalDataLength = Int(scanListLength)!
                    print("🔵 BLE Scan list start : \(totalDataLength!)")
                }
            }
        case .BLE_SAC_DEV2APP_SCAN_LIST_DATA:
            inputBuffer!.append(packet.subdata(in: Range(NSRange(location: 4, length: packet.count - 5))!))
            print("🔵 BLE Scan list data : \(inputBuffer!.length)")
            
        case .BLE_SAC_DEV2APP_SCAN_LIST_END:
            print("🔵 BLE Scan list end -> input buffer length : \(inputBuffer!.length)")
            if(inputBuffer!.length == totalDataLength!) {
                let scanList = self.parseWiFiList(data: inputBuffer! as Data)
                let items = WiFiScanListItems(items: scanList)
                return (.BLE_SAC_DEV2APP_SCAN_LIST_END, items)
            } else {
                inputBuffer = NSMutableData()
                let error = NSError(domain: "Scan List Incomplete", code: 1000)
                return (.BLE_SAC_DEV2APP_SCAN_LIST_END, error)
            }
            
        case .BLE_SAC_DEV2APP_CRED_RECEIVED:
            return (.BLE_SAC_DEV2APP_CRED_RECEIVED, nil)
            
        case .BLE_SAC_DEV2APP_CRED_SUCCESS, .BLE_SAC_DEV2APP_CRED_FAILURE:
            break
            
        case .BLE_SAC_DEV2APP_WIFI_CONNECTING:
            return (.BLE_SAC_DEV2APP_WIFI_CONNECTING, nil)
            
        case .BLE_SAC_DEV2APP_WIFI_CONNECTED:
            return (.BLE_SAC_DEV2APP_WIFI_CONNECTED, nil)
            
        case .BLE_SAC_DEV2APP_WIFI_CONNECTING_FAILED:
            let reason = packet[4]
            switch (reason) {
            case 1:
                errorReason = "It seems that your device is currently out of Wi-Fi range. Please move closer to a Wi-Fi hotspot or ensure that your Wi-Fi is turned on."
            case 2:
                errorReason = "Incorrect password entered"
            default:
                errorReason = "Something went wrong"
                break
            }
            return (.BLE_SAC_DEV2APP_WIFI_CONNECTING_FAILED, errorReason)
            
            //            case .BLE_SAC_SEND_DATA_WITH_ENCRYPTION:
            //                print("❌ BLE is encryption enabled = \(packetBytes[4])")
            //                BLEMessageConstructor.shared.isEncryptionEnabled = Int(packetBytes[4])
            
        default:
            break
        }
        return nil
    }
    
    func parseWiFiList(data: Data) -> [WiFiScanListModel]?  {
        do {
            let json = try JSONDecoder().decode(WiFiScanListItems.self, from: data)
            if let scanResultArray = json.items {
                var result = [WiFiScanListModel]()
                // Append Other WiFi SSID for user to input hidden network
                for items in scanResultArray {
                    let model = WiFiScanListModel(ssid: items.ssid,
                                                  security: WiFiSecurity(rawValue: items.security?.rawValue ?? "NONE"), rssi: items.rssi)
                    result.append(model)
                }
                result.append(WiFiScanListModel(ssid: "Other", security: .WPA2_PSK))
                return result
            }
        } catch let parseError {
            var result = [WiFiScanListModel]()
            // Append Other WiFi SSID for user to input hidden network
            result.append(WiFiScanListModel(ssid: "Other", security: .WPA2_PSK))
            print("Could not decode BLE_SAC_DEV2APP_SCAN_LIST data to type BLESACDEV2APPModel, reason = \(parseError)")
            return result
        }
        return nil
    }

}

