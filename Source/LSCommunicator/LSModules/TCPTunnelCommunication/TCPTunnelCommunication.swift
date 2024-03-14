//
//  TCPTunnelCommunication.swift
//  
//
//  Created by Guru on 14/03/24.
//

import UIKit
import CocoaAsyncSocket

public protocol TCPTunnelCommunicationDelegate: AnyObject {

    func tcpTunnelingConnectionDidEsatblish()
    func sentTCPTunnelMessage(to host: String)
    func receivedTCPTunnelMessage(message payload: Data, from host: String)
    func tcpTunnelingConnectionClosed()
}

final public class TCPTunnelCommunication: NSObject {
    
    public weak var delegate: TCPTunnelCommunicationDelegate?
    
    private var tcpTunnelSocket: GCDAsyncSocket?
    
    private override init() {
        super.init()
    }
    
    public init(ipAddress: String, port: Int = 50005, delegate: TCPTunnelCommunicationDelegate) {
        self.delegate = delegate
        
        super.init()
        
        self.connectTCPSocket(on: ipAddress, port: port)
    }
    
    private func connectTCPSocket(on interface: String, port: Int) {
        let tcpTunnelSocketQueue = DispatchQueue(label: "tcpTunnelSocketQueue")
        let socket = GCDAsyncSocket(delegate: self, delegateQueue: tcpTunnelSocketQueue)
        do {
            try socket.connect(toHost: interface, onPort: UInt16(port))
        } catch {
            print("unable to create TCP tunneling socket:\(error.localizedDescription)")
        }
    }
    
    public func sendTCPTunnelMessage(data: Data) {
        self.tcpTunnelSocket?.write(data, withTimeout: -1, tag: 0)
        self.tcpTunnelSocket?.readData(withTimeout: -1, tag: 0)
    }
    
    private func retValueMemoryAllocation(no: Int)-> UnsafeMutablePointer<UInt8> {
        let retVal = malloc(MemoryLayout<UInt8>.size * no).assumingMemoryBound(to: UInt8.self)
        return retVal
    }
    
    public func getDataMode() -> Data {
        let retVal = retValueMemoryAllocation(no: 3)
        retVal[0] = 0x02
        retVal[1] = 0x02
        retVal[2] = 0x02
        let data = Data(bytes: retVal, count: 3)
        return data
    }
}

extension TCPTunnelCommunication: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        self.tcpTunnelSocket = sock
        print("✅ TCP Tunnel connection established")
        self.delegate?.tcpTunnelingConnectionDidEsatblish()
    }
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        print("✅ TCP Tunnel message recevied")
        if let host = sock.connectedHost {
            self.delegate?.receivedTCPTunnelMessage(message: data,
                                                    from: host)
        }
        sock.readData(withTimeout: -1, tag: tag)
    }
    
    public func socket(_ sock: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("✅ TCP Tunnel message did write")
        if let host = sock.connectedHost {
            self.delegate?.sentTCPTunnelMessage(to: host)
        }
        sock.readData(withTimeout: -1, tag: tag)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?, ipAddress host: String?) {
        print("❌ TCP Tunnel Socket Disconnected with error -> \(err as Any)")
        self.delegate?.tcpTunnelingConnectionClosed()
    }

}
