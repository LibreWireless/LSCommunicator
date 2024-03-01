//
//  File.swift
//  
//
//  Created by Guru on 27/02/24.
//

import Foundation
import CocoaAsyncSocket

public protocol DiscoveryDelegate: AnyObject {

    /// Function to notify updated nodes list
    func luciDidDisover(nodes: [Node])
    
}

public class LuciDiscovery: NSObject {
    
    public static let shared = LuciDiscovery()
    
    private var interface: String?
    
    private var msearchUDPSocket: GCDAsyncUdpSocket?
    private var msearchTCPSocket: GCDAsyncSocket?
    
    private var msearchTimeout: Int?
    private var msearchInterval: Int?
    private var model: String?
    
    private var discoveryTimer: Timer?
    private var msearchIntervalTimer: Timer?
    
    private var httpPort: UInt16!
    
    private var connectedSockets = [GCDAsyncSocket]()

    public weak var delegate: DiscoveryDelegate?
    
    private var nodesList: [Node] {
        didSet {
            self.nodesListUpdated()
        }
    }
    
    enum SceneName {
        case Active
        case Launch
        case AfterSAC
    }
    
    private override init() {
        self.nodesList = [Node]()
        
        super.init()
        
        self.httpPort = UInt16(arc4random_uniform(1600) + 49152)
        
        self.interface = NetworkHelper.shared.interfaceAddress
        
        guard self.interface != nil else { return }
    }
    
    public func startDiscovery() {
        self.initSocketSetup()
    }
    
    public func startDiscovery(timeout: Int = .max, interval: Int = 30, model: String?) {
        self.msearchTimeout = timeout
        self.msearchInterval = interval
        self.model = model
        
        self.startDiscovery()
    }
    
    /// Start UDP Connection on specified port and interface
    private func connectUDP() throws {
        if (msearchUDPSocket == nil) {
            let udpSocketQueue = DispatchQueue(label: "UDPSocketQueue")
            msearchUDPSocket = GCDAsyncUdpSocket(delegate: self, delegateQueue: udpSocketQueue)
        }

        try msearchUDPSocket?.bind(toPort: self.httpPort, interface: interface)
        
        try msearchUDPSocket?.beginReceiving()
        try msearchUDPSocket?.enableBroadcast(true)
                
        if (msearchTCPSocket != nil) {
            self.startScan(sceneName: .Active)
        }
    }
    
    /// Open TCP port for accepting sockets
    private func openTCPServer() throws {
        if (msearchTCPSocket == nil) {
            // TCP socket for accepting device as client
            let tcpServerSocketQueue = DispatchQueue(label: "TCPServerSocketQueue")
            msearchTCPSocket = GCDAsyncSocket(delegate: self, delegateQueue: tcpServerSocketQueue)
            try msearchTCPSocket!.accept(onPort: self.httpPort)
        }
    }
    
    private func initSocketSetup() {
        startIntervalTimer()
        
        startDiscoveryTimer()
        
        for i in 0..<200 {
            if i > 0 {
                self.httpPort += 1
            }
            if (self.didConnect) {
                self.startScan()
                break
            }
        }
    }
    
    /// Checks UDP TCP connection successfull
    var didConnect: Bool {
        do {
            // try to connect udp
            try self.connectUDP()
            
            do {
                // try to open tcp port
                try self.openTCPServer()
                return true
            } catch {
                // if failed to open tcp port, close the udp and retry on different port
                self.msearchUDPSocket?.close()
                self.msearchTCPSocket?.disconnect()
                return false
            }
        } catch {
            // catch the udp binding error
            self.msearchUDPSocket?.close()
            return false
        }
    }
    
    /// Tries to rebind UDP on the specified port recursively.
    /// Note: This method sleeps for 5 seconds before retrying.
    fileprivate func reconnectUDP() {
        usleep(5_000_000) //5 secs
        do {
            try connectUDP()
        } catch let bindError {
            print("Tried to reconnect UDP on \(self.httpPort!) but failed to bind with error \(bindError)")
        }
    }
    
    private func nodesListUpdated() {
        if self.nodesList.count > 0 {
            self.delegate?.luciDidDisover(nodes: self.nodesList)
        }
    }
    
    /// Starts timer for stopping discovery for specified timeout
    private func startDiscoveryTimer() {
        guard let msearchTimeout = msearchTimeout, Double(msearchTimeout) > 0 else {
            return
        }
        DispatchQueue.main.async {
            self.discoveryTimer = Timer.scheduledTimer(timeInterval: Double(msearchTimeout),
                                                             target: self,
                                                             selector: #selector(self.stopDiscovery),
                                                             userInfo: nil, repeats: false)
        }
    }
    
    /// Stops discovering new LS Modules
    @objc
    private func stopDiscovery() {
        DispatchQueue.main.async {
            self.discoveryTimer?.invalidate()
            self.discoveryTimer = nil
        }
        msearchUDPSocket?.setDelegate(nil)
        msearchTCPSocket?.delegate = nil
    }
    
    /// Send's MSearch in sepcified interval
    private func startIntervalTimer() {
        guard let msearchInterval = msearchInterval, Double(msearchInterval) > 0 else {
            return
        }
        DispatchQueue.main.async {
            self.msearchIntervalTimer = Timer.scheduledTimer(timeInterval: Double(msearchInterval),
                                                             target: self,
                                                             selector: #selector(self.triggerMSearch),
                                                             userInfo: nil, repeats: true)
        }
    }
    
    @objc
    private func triggerMSearch() {
        self.startScan(sceneName: .Active)
    }
    
    public func stop30SecMsearchTimer() {
        DispatchQueue.main.async {
            self.msearchIntervalTimer?.invalidate()
            self.msearchIntervalTimer = nil
        }
    }

}

extension LuciDiscovery {
    
    func startScan() {
        let payload = MSearchHelper.getPayload()
        msearchUDPSocket?.send(payload,
                               toHost: MSearchHelper.mCastAddress,
                               port: MSearchHelper.mSearchPort, withTimeout: -1, tag: 1)

        sendBroadCast()

        sendBroadCastForMeshNetwork()
    }
    
    func sendBroadCast() {
        let payload = MSearchHelper.getPayload()
        msearchUDPSocket?.send(payload,
                               toHost: MSearchHelper.UDPIPAddress,
                               port: MSearchHelper.mSearchPort, withTimeout: -1, tag: 1)
    }
    
    func sendBroadCastForMeshNetwork() {
        guard let availableInterfaces = NetworkHelper.shared.availableInterfaces else { return }
        for interface in availableInterfaces  {
            if(interface.name == "en0") {
                let networkIP = NSString(string: interface.ip)
                let length = networkIP.range(of: ".", options: .backwards).location + 1
                let ipAddress = networkIP.substring(with: NSRange(location: 0, length: length)) + "0"
                let payload = MSearchHelper.getPayload(for: ipAddress)
                msearchUDPSocket?.send(payload, toHost: ipAddress, port: 1800, withTimeout: -1, tag: 1)
            }
        }
    }
    
    func startScan(sceneName: SceneName) {
        if msearchUDPSocket == nil && msearchTCPSocket == nil {
            self.initSocketSetup()
        }
        
        if sceneName == .Launch || sceneName == .AfterSAC {
            sendBroadCast()
            
            sendBroadCastForMeshNetwork()
            
            let payload = MSearchHelper.getPayload()
            udpMSearch(currentHit: 0, totalHit: 1, data: payload)
        } else {
            startScan()
        }
    }
    
    func udpMSearch(currentHit: Int, totalHit: Int, data: Data) {
        msearchUDPSocket?.send(data, 
                               toHost: MSearchHelper.mCastAddress,
                               port: MSearchHelper.mSearchPort, withTimeout: -1, tag: 1)
        
        usleep(1_00_000)
        
        if(currentHit < totalHit) {
            udpMSearch(currentHit: currentHit+1, totalHit: totalHit, data: data)
        }
    }

}

//MARK: - GCDAsyncSocketDelegate

extension LuciDiscovery: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let message =  String(data: data, encoding: .utf8),
              let host = sock.connectedHost
        else {
            return
        }
        let port = Int(sock.connectedPort)
        print("Did receive data from \(host):\(port)")
        print(message)
        
        guard let startLine = message.parseFirstLine() else { return }
        if (startLine == "OK") {
            sock.readData(withTimeout: -1, tag: tag)
            return
        }
        
        let node = MSearchHelper.parseMSearch(payload: message, from: host)
        if self.nodesList.first(where: { $0.id == node.id }) == nil {
            self.nodesList.append(node)
        }
        print("Node with name \(node.friendlyName) exists")
        sock.readData(withTimeout: -1, tag: tag)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("✅\(self) Socket Did Connect to Host \(host) on Port \(port)")
    }
    
    public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        completionHandler(true)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didAcceptNewSocket newSocket: GCDAsyncSocket) {
        let host = newSocket.connectedHost
        let port = newSocket.connectedPort
        print("✅ \(self) Did accept a client with Host \(host as Any) & Port \(port)")
        self.connectedSockets.append(newSocket)
        newSocket.readData(withTimeout: -1, tag: 0)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?, ipAddress host: String?) {
        print("❌ \(self) server socket disconnect by \(host as Any) withError: \(err?.localizedDescription as Any)")
        self.msearchTCPSocket?.setDelegate(nil, delegateQueue: nil)
        self.msearchTCPSocket = nil
        if (host != nil) {
            self.connectedSockets.removeAll(where: { $0.connectedHost == host })
        } else {
            self.connectedSockets.removeAll()
        }
    }
    
}

//MARK: - UDPSockets Delegate

extension LuciDiscovery: GCDAsyncUdpSocketDelegate {
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didSendDataWithTag tag: Int) {
        print("✅ UDP socket did send data with tag:\(tag)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotSendDataWithTag tag: Int, dueToError error: Error?) {
        print("❌ \(self) UDP socket did not send data with tag:\(tag) due to error \(error?.localizedDescription as Any)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didReceive data: Data, fromAddress address: Data, withFilterContext filterContext: Any?) {
        guard let message = String(data: data, encoding: .utf8)
        else { return }
        var host: NSString? = ""
        var port: UInt16 = 0
        GCDAsyncUdpSocket.getHost(&host, port: &port, fromAddress: address)
        print("UDP did receive data from \(host!):\(port)")
        print(message)
        let node = MSearchHelper.parseMSearch(payload: message, from: host! as String)
        if self.nodesList.first(where: { $0.id == node.id }) == nil {
            self.nodesList.append(node)
        }
        print("Node with name \(node.friendlyName) exists")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didConnectToAddress address: Data) {
        let host = String(data: address, encoding: .utf8)
        print("✅  UDP did connect to address \(host as Any)")
    }
    
    public func udpSocket(_ sock: GCDAsyncUdpSocket, didNotConnect error: Error?) {
        print("❌ \(self) UDP socket did not connect \(error as Any)")
    }
    
    public func udpSocketDidClose(_ sock: GCDAsyncUdpSocket, withError error: Error?) {
        print("❌ \(self) UDP socket did close with error \(error as Any)")
        self.msearchUDPSocket?.setDelegate(nil, delegateQueue: nil)
        self.msearchUDPSocket = nil
        // code -> 65 "No route to host", code -> 64 "Host is down
        if (error != nil && ((error! as NSError).code == 65 || (error! as NSError).code == 64)) {
            self.reconnectUDP()
        }
    }
}
