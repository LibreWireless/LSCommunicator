//
//  BLE+Constants.swift
//
//
//  Created by Guru on 11/03/24.
//

import Foundation
import CoreBluetooth
import UIKit

//MARK: - BLE UUID's

//let TRANSFER_SERVICE_UUID             =         "AAAA"
let BLE_LIBRE_ADV_SERVICE_DATA_UUID   =         CBUUID(string: "29320bdb-b9b4-53cd-aae9-b1da527728d1") //uuid.uuid5(uuid.NAMESPACE_DNS, 'Libre Wireless Technologies India Private Limited')
let BLE_SERVICE_UUID                  =         "b8313268-90dc-5a30-bfb1-a814e7c6dbba"
let TRANSFER_CHARACTERISTIC_UUID      =         "04b5d61d-7d20-5122-ae91-fdc306471497"
let TRANSFER_CHARACTERISTIC_Concept   =         "Friend"
let BLEHeadeR_ID                      =          171
let Device_UUID                       =         "2B3F9221-4183-46D5-84DC-6640F93BE072"


//MARK: - BLE Commands

public enum BLECommand: UInt16 {
    
    case BLE_SAC_APP2DEV_REQUEST_WIFI_SCANLIST      =        0
    case BLE_SAC_APP2DEV_SEND_CREDENTIALS           =        1
    case BLE_SAC_APP2DEV_SEND_STOPSAC               =        3
    case BLE_SAC_APP2DEV_REQUEST_TO_PLAYTONE        =        4
    case BLE_SAC_APP2DEV_REQUEST_FOR_FRIENDLYNAME   =        5
    
    case BLE_SAC_DEV2APP_STARTED                    =        16
    case BLE_SAC_DEV2APP_SCAN_LIST_START            =        17
    case BLE_SAC_DEV2APP_SCAN_LIST_DATA             =        18
    case BLE_SAC_DEV2APP_SCAN_LIST_END              =        19
    case BLE_SAC_DEV2APP_CRED_RECEIVED              =        20
    case BLE_SAC_DEV2APP_CRED_SUCCESS               =        21
    case BLE_SAC_DEV2APP_CRED_FAILURE               =        22
    case BLE_SAC_DEV2APP_WIFI_CONNECTING            =        23
    case BLE_SAC_DEV2APP_WIFI_CONNECTED             =        24
    case BLE_SAC_DEV2APP_WIFI_CONNECTING_FAILED     =        25
    case BLE_SAC_DEV2APP_WIFI_STATUS                =        26
    case BLE_SAC_SEND_DATA_WITH_ENCRYPTION          =        27
}
