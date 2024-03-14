//
//  BLESetUpManager.swift
//
//
//  Created by Guru on 11/03/24.
//

import UIKit
import CoreBluetooth


@objc public enum BluetoothState: Int {
    case unknown = 0
    case resetting
    case unsupported
    case unauthorized
    case poweredOff
    case poweredOn
}

public typealias BLESetupDelegate = (BLEStateDelegate & BLEDiscoveryDelegate & BLEConnectionDelegate & BLEReadWriteDelegate)

public class BLESetUpManager: NSObject {
        
    private weak var delegate: BLESetupDelegate?
    
    private var centralManager: CBCentralManager?
    
    private var currentPeripheral: CBPeripheral?
    
    /// Array that contains nearby BLE devices peripheral instance
    private var bleDevicesList = [BLEDevice]()

    /// Array that contains nearby BLE devices name
    private var bleDevicesNameList = [String]()
    
    private var kBluetoothState: BluetoothState!
    
    private var scanResultArray: [WiFiScanListModel]?
    
    private override init() {
        super.init()
        
        self.appStateHandler()
    }
    
    public init(delegate: BLESetupDelegate) {
        super.init()
        
        self.delegate = delegate
        self.currentPeripheral = nil
    }
    
    private func appStateHandler() {
        AppStateManager.shared.didBecomeActiveHandler = {
            // Check bluetooth permission
            self.isBluetoothEnabled()
        }
    }
    
    /// Utility function to check whether bluetooth enabled
    public func isBluetoothEnabled() {
        print("🔵 Bluetooth enabled check")
        if self.centralManager == nil {
            let opts = [CBCentralManagerOptionShowPowerAlertKey: false]
            self.centralManager = CBCentralManager(delegate: self, queue: .main, options: opts)
        } else {
            self.centralManagerDidUpdateState(centralManager!)
        }
    }
    
    /// Starts to scan devices waiting for setup via BLE
    public func startScanning() {
        self.clearBLEDeviceList()
        self.centralManager?.scanForPeripherals(withServices: nil)
    }
    
    /// Clears BLE Devices list
    public func clearBLEDeviceList() {
        bleDevicesList.removeAll()
        bleDevicesNameList.removeAll()
    }
    
    /// Establish connection to the device
    /// - Parameter id: ID of the BLEDevice
    public func connectBLEDevice(with id: UUID) {
        guard let device = self.bleDevicesList.first(where: { $0.id == id}) else {
            return
        }
        if (self.currentPeripheral != device.peripheral) {
            self.currentPeripheral = device.peripheral
        }
        self.centralManager?.connect(device.peripheral)
    }
    
    /// Disconnect from the connected peripheral
    public func disconnectBLEDevice() {
        if (self.currentPeripheral != nil) {
            let peripheral = self.currentPeripheral
            self.currentPeripheral = nil
            self.centralManager?.cancelPeripheralConnection(peripheral!)
        }
    }
    
    public func stopScanning() {
        self.centralManager?.stopScan()
    }
    
    /// Utility function to cancel peripheral connection
    private func cleanup() {
        // Don't do anything if we're not connected
        guard let currentPeripheral = self.currentPeripheral,
              currentPeripheral.state == .connected,
              let services = currentPeripheral.services
        else { return }
        // See if we are subscribed to a characteristic on the peripheral
        for service in services {
            service.characteristics?.forEach({ characteristic in
                if (characteristic.isNotifying) {
                    currentPeripheral.setNotifyValue(false, for: characteristic)
                }
            })
        }
        self.centralManager?.cancelPeripheralConnection(currentPeripheral)
    }

    deinit {
        self.centralManager = nil
        self.currentPeripheral = nil
        self.kBluetoothState = .unknown
        self.scanResultArray = [WiFiScanListModel]()
    }
    
}

extension BLESetUpManager: CBCentralManagerDelegate {
    
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch(self.centralManager?.state) {
            case .poweredOff:
                print("🔵 Bluetooth is currently powered off.")
                kBluetoothState = .poweredOff
            case .poweredOn:
                print("🔵 Bluetooth is currently powered on and available to use.")
                kBluetoothState = .poweredOn
            case .unauthorized:
                print("🔵 The app is not authorized to use BLE")
                kBluetoothState = .unauthorized
            case .unsupported:
                print("🔵 The platform doesn't support BLE")
                kBluetoothState = .unsupported
            case .resetting:
                print("🔵 The connection with the system service was momentarily lost, update imminent.")
                kBluetoothState = .resetting
            default:
                print("🔵 BLE State unknown, update imminent")
                kBluetoothState = .unknown
        }
        
        self.delegate?.bluetoothStateDidUpdate(state: kBluetoothState)
    }
    
    public func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? ""
        if (!validateString(text: localName).isEmpty) {
            print("🔵 BLE advertisementData: \(advertisementData)")
            guard let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? NSDictionary, serviceData.allKeys.count > 0, serviceData.allValues.count > 0 else {
                return
            }
            print("🔵 BLE LocalName: \(serviceData.allKeys[0] as? CBUUID)")
            if ((serviceData.allKeys[0] as? CBUUID) == BLE_LIBRE_ADV_SERVICE_DATA_UUID) {
                if let data = serviceData.allValues[0] as? Data {
                    let brandModel = data.map ({ String(format: "%02X", $0) }).joined()
                    print("🔵 BLE LocalName: \(localName as Any)")
                    print("🔵 BLE brandModel: \(brandModel)")
                    var bleDevice: BLEDevice
                    if (!(bleDevicesList.contains(where: { $0.peripheral == peripheral})) &&
                         !(bleDevicesNameList.contains(validateString(text: localName)))) {
                        print("🔵 Appending \(localName as Any) to list")
                        bleDevice = BLEDevice(bleFriendlyName: validateString(text: localName),
                                                  peripheral: peripheral)
                        bleDevicesList.append(bleDevice)
                        bleDevicesNameList.append(validateString(text: localName))
                    } else {
                        print("🔵 \(localName as Any) exists in list")
                        let i: Int = bleDevicesList.firstIndex(where: { $0.peripheral == peripheral}) ?? 0
                        bleDevicesList.remove(at: i)
                        bleDevicesNameList.remove(at: i)
                        print("at index \(i)")
                        bleDevice = BLEDevice(bleFriendlyName: validateString(text: localName),
                                                  peripheral: peripheral)
                        bleDevicesList.append(bleDevice)
                        bleDevicesNameList.append(validateString(text: localName))
                        print("🔵 Re-Appending \(localName as Any) to list")
                    }
                    print("🔵 BLE Delegate = \(self.delegate as Any)")
                    self.delegate?.didDiscoverDevice(device: bleDevice)
                }
            }
        }
    }
    
    public func centralManager(_ central: CBCentralManager, 
                               didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("❌ Failed to connect to peripheral \(error?.localizedDescription as Any)")
        if let error = error {
            self.delegate?.failedToConnectTobluetoothDevice(withError: error)
        }
        self.cleanup()
    }
    
    public func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("✅ Peripheral Connected \(peripheral.name as Any)")
        self.currentPeripheral = peripheral
        // Stop scanning
        self.centralManager?.stopScan()
        print("🔵 Scanning stopped")
        // Make sure we get the discovery callbacks
        self.currentPeripheral?.delegate = self
        // Search only for services that match our UUID
        self.currentPeripheral?.discoverServices([CBUUID(string: BLE_SERVICE_UUID)])
    }
}

extension BLESetUpManager: CBPeripheralDelegate {
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("❌ Error discovering services: \(error.localizedDescription)")
            self.cleanup()
            return
        }
        print("🥳🥳🥳 services discovered")
        // Discover the characteristic we want...
        self.currentPeripheral = peripheral
        // Loop through the newly filled peripheral.services array, just in case there's more than one.
        peripheral.services?.forEach({ service in
            self.currentPeripheral?.discoverCharacteristics(
                [CBUUID(string: TRANSFER_CHARACTERISTIC_UUID)],
                for: service
            )
        })
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("❌ Error discovering characteristics: \(error.localizedDescription)")
            self.cleanup()
            return
        }
        service.characteristics?.forEach({ characteristic in
            self.currentPeripheral = peripheral
            self.currentPeripheral?.setNotifyValue(true, for: characteristic)
            self.delegate?.bluetoothConnectionSucceded()
        })
    }
    
    public func peripheral(_ peripheral: CBPeripheral, 
                           didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("✅ didWriteValueForCharacteristic")
        self.delegate?.didWriteMessage()
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error UpdateValueFor characteristics: \(error.localizedDescription)")
            return
        }
        print("🔵 characteristic value length \(characteristic.value?.count ?? 0)")
        
        let parsedData = BLEMessageParser.shared.processDeviceData(packet: characteristic.value ?? Data(),
                                                              forPeripheral: peripheral)
        self.bleParsedMessage(parsedData: parsedData)
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("❌ Error changing notification state: \(error.localizedDescription)")
        }
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("❌ Peripheral Disconnected name \(peripheral.name as Any), with error: \(error as Any)")
        if let error = error, self.currentPeripheral != nil {
            self.delegate?.failedToConnectTobluetoothDevice(withError: error)
        }
    }
    
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) { }
}

extension BLESetUpManager {
    
    func bleParsedMessage(parsedData: BLEResult?) {
        guard let data = parsedData, let result = data.result else { return }
        
        switch data.command {
        case .BLE_SAC_APP2DEV_REQUEST_FOR_FRIENDLYNAME:
            self.delegate?.didReadMessage(of: .friendlyName(result as? String))
            
        case .BLE_SAC_DEV2APP_SCAN_LIST_END:
            if ((result as? WiFiScanListItems) != nil) {
                self.delegate?.didReadMessage(of: .wifiScanList(.success(result as? WiFiScanListItems)))
            } else {
                self.delegate?.didReadMessage(of: .wifiScanList(.failure((result as! Error))))
            }

        case .BLE_SAC_DEV2APP_WIFI_CONNECTING:
            self.delegate?.didReadMessage(of: .connectingWiFi)

        case .BLE_SAC_DEV2APP_WIFI_CONNECTED:
            self.delegate?.didReadMessage(of: .wifiConnection(.success(0)))

        case .BLE_SAC_DEV2APP_WIFI_CONNECTING_FAILED:
            let error = NSError(domain: (result as! String), code: 1000)
            self.delegate?.didReadMessage(of: .wifiConnection(.failure(error)))
            
        default:
            break
        }
    }
    
}

extension BLESetUpManager: CBPeripheralManagerDelegate {
    
    public func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) { }
    
}

extension BLESetUpManager {
    
    /// Used to send BLE packet to the peripheral specified
    /// NOTE: Peripheral should be connected
    /// - Parameter dataToWrite: Data that is returned from constructBLEMessage function
    private func writeDataToBLEDevice(data: Data) {
        guard let peripheral = currentPeripheral else { return }
        if let services = peripheral.services {
            services.forEach({ service in
                service.characteristics?.forEach({ characteristic in
                    peripheral.writeValue(data, for: characteristic, type: .withResponse)
                })
            })
        }
    }
    
    /// Request Friendly Name of the device
    public func requestFriendlyName() {
        print("BLE Request Friendly Name")
        let data = BLEMessageConstructor.shared.constructBLEPacket(command: .BLE_SAC_APP2DEV_REQUEST_FOR_FRIENDLYNAME, withData: "".data(using: .utf8)!, length: 0)
        self.writeDataToBLEDevice(data: data)
    }
    
    /// Request WiFi scan list from device
    public func requestWiFiScanList() {
        print("Request WiFi Scan List")
        let data = BLEMessageConstructor.shared.constructBLEPacket(command: .BLE_SAC_APP2DEV_REQUEST_WIFI_SCANLIST, withData: "".data(using: .utf8)!, length: 0)
        self.writeDataToBLEDevice(data: data)
    }
    
    /// Send WiFi credentials for device to connect to network
    /// - Parameters:
    ///   - ssid: Network SSID
    ///   - password: Password to connect to the SSID
    ///   - security: Security type of the SSID
    ///   - deviceName: Existing / Updated Device Name
    public func postWiFiCredentials(ssid: String,
                                    password: String,
                                    security: WiFiSecurity,
                                    deviceName: String) {
        self.constuctBleCredentials(with: ssid,
                                    password: password,
                                    security: security.rawValue,
                                    deviceName: deviceName)
    }
    
    /// Converts string value to Data and UInt8 array
    /// - Parameter value: string to convert
    /// - Returns: Tuple of Array of UInt8 and Data
    private func getBytesData(from value: String) -> (bytes: [UInt8], data: Data) {
        let data = value.data(using: .utf8) ?? Data()
        let dataLength = data.count
        var dataBytes = Array<UInt8>.init(repeating: 0, count: 1)
        dataBytes[0]  = UInt8(dataLength)
        return (dataBytes, data)
    }
    
    private func constuctBleCredentials(with ssid: String,
                                        password: String,
                                        security: String,
                                        deviceName: String) {
        let ssid = getBytesData(from: ssid)
        let header = NSMutableData(bytes: ssid.bytes, length: ssid.bytes.count)
        header.append(ssid.data)
    
        let passPhrase = getBytesData(from: password)
        header.append(Data(bytes: passPhrase.bytes, count: passPhrase.bytes.count))
        header.append(passPhrase.data)
    
        let security = getBytesData(from: security)
        header.append(Data(bytes: security.bytes, count: security.bytes.count))
        header.append(security.data)
    
        let deviceName = getBytesData(from: deviceName)
        header.append(Data(bytes: deviceName.bytes, count: deviceName.bytes.count))
        header.append(deviceName.data)
    
        let data = BLEMessageConstructor.shared.constructBLEPacket(command: .BLE_SAC_APP2DEV_SEND_CREDENTIALS, withData: header as Data, length: header.count)
        self.writeDataToBLEDevice(data: data)
    }
    
    //MARK: - BLE Request for Tone
    
    ///Public function to Request Playtone to be played on a device
    public func requestForTone() {
        print("BLE Request For Tone data")
        let data = BLEMessageConstructor.shared.constructBLEPacket(command: .BLE_SAC_APP2DEV_REQUEST_TO_PLAYTONE, withData: "".data(using: .utf8)!, length: 0)
        self.writeDataToBLEDevice(data: data)
    }
    
    //MARK: - BLE Send Stop GATT Services
    
    /// Public function to send StopGATT command to device over BLE to stop device Gatt service and to end configuration mode on device
    public func sendStopGATTService() {
        print("BLE Send Stop SAC data")
        let data = BLEMessageConstructor.shared.constructBLEPacket(command: .BLE_SAC_APP2DEV_SEND_STOPSAC, withData: "".data(using: .utf8)!, length: 0)
        self.writeDataToBLEDevice(data: data)
    }

}
