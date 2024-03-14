//
//  WiFiScanListModel.swift
//  
//
//  Created by Guru on 11/03/24.
//

import UIKit

/// Codable class for decoding BLESACDEV2APPModel which contains WiFi list received from BLE
public struct WiFiScanListItems: Codable {
    let items: [WiFiScanListModel]?
    
    enum CodingKeys: String, CodingKey {
        case items = "Items"
    }
}

/// Codable class for decoding WiFi list received from BLE
public struct WiFiScanListModel: Codable {
    public let ssid: String?
    public var security: WiFiSecurity?
    public let rssi: Int?
    
    public init(ssid: String?, security: WiFiSecurity?, rssi: Int? = nil) {
        self.ssid = ssid
        self.security = security
        self.rssi = rssi
    }
    
    enum CodingKeys: String, CodingKey {
        case ssid = "SSID"
        case security = "Security"
        case rssi = "rssi"
    }
}

public enum WiFiSecurity: String, CaseIterable, Codable {
    case WEP = "WEP"
    case WPA_PSK = "WPA-PSK"
    case WPA2_PSK = "WPA2-PSK"
    case WPA_WPA2 = "WPA/WPA2"
    case NONE = "NONE"
    case OPEN = "OPEN"
    case WPA = "WPA"
    case WPA2_WPA3 = "WPA2/WPA3"
    case WPA3 = "WPA3"
}
