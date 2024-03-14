//
//  LuciConnection.swift
//  
//
//  Created by Guru on 07/03/24.
//

import Foundation
import CocoaAsyncSocket

public protocol LuciConnectionDelegate: AnyObject {
    
    /// Connection to Node success
    /// - Parameters:
    ///   - node: Connected Node
    func luciDidEstablishConnection(for node: Node)

}

public enum LuciConnectionError: Error {
    /// No valid timer is set to invalidate timer
    case multipleRetries
}

final public class LuciConnection: NSObject {
    
    public weak var delegate: LuciConnectionDelegate?
    
    private var nodesList: [Node] = []

    public init(delegate: LuciConnectionDelegate) {
        self.delegate = delegate
        
        TLSHelper.initTLSSocketSettings()
        
        super.init()
    }
    
    public func connect(to node: Node) throws {
        guard appendNode(node) else {
            throw LuciConnectionError.multipleRetries
        }
        do {
            let tcpSocketQueue = DispatchQueue(label: "LuciConnection")
            let tcpSocket = GCDAsyncSocket(delegate: self, delegateQueue: tcpSocketQueue)
            try tcpSocket.connect(toHost: node.ipAddress, onPort: node.port)
            usleep(5_000_000)
            tcpSocket.startTLS(TLSHelper.tlsSetting)
        } catch {
            print("❌ Error connecting \(error)")
            throw error
        }
    }
    
    private func appendNode(_ node: Node) -> Bool {
        if (self.nodesList.contains(where: { $0.id == node.id })) {
            return false
        }
        self.nodesList.append(node)
        return true
    }
    
    private var credentialsFileURL: URL? {
        let fileName = "server"
        let fileExtension = "der"
        let thisSourceFile = URL(fileURLWithPath: #file)
        var thisSourceDirectory = thisSourceFile.deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        thisSourceDirectory = thisSourceDirectory.appendingPathComponent("Resources")
        return thisSourceDirectory.appendingPathComponent("\(fileName).\(fileExtension)")
    }
}

extension LuciConnection: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didReceive trust: SecTrust, completionHandler: @escaping (Bool) -> Void) {
        print("🟣 Did Receive Trust")
        //server certificate
        let serverCertificate: SecCertificate = SecTrustGetCertificateAtIndex(trust, 0)!
        let serverCertificateData: CFData = SecCertificateCopyData(serverCertificate)
        
        let serverData:UnsafePointer<UInt8> = CFDataGetBytePtr(serverCertificateData)
        let serverDataSize: CFIndex = CFDataGetLength(serverCertificateData)
        
        let serverCer = NSData(bytes: serverData, length: serverDataSize)
        
        //local certificate
        guard let url = credentialsFileURL else {
            fatalError("Missing the server der resource from the bundle")
        }
        
        let localCert = try! Data(contentsOf: url)
        let localCertData: CFData = localCert as CFData
        
        let localData:UnsafePointer<UInt8>  = CFDataGetBytePtr(localCertData)
        let localDataSize:CFIndex = CFDataGetLength(localCertData)
        
        let localCer = NSData(bytes: localData, length: localDataSize)
        
        if (localCer.count <= 0 && serverCer.count <= 0) {
            completionHandler(false)
        }
        
        var status: OSStatus = -1
        var result: SecTrustResultType = .deny
        
        let secServerCert = SecCertificateCreateWithData(nil, serverCertificateData)
        let secLocalCert = SecCertificateCreateWithData(nil, localCertData)
        
        let ref = [secServerCert, secLocalCert] as CFArray //,
        //        let ary = CFArrayCreate(nil, &ref, CFIndex(2), nil)
        
        SecTrustSetAnchorCertificates(trust, ref)
        
        status = SecTrustEvaluate(trust, &result)
        
        if (status == noErr) {
            completionHandler(true)
        } else {
            let arrayRefTrust = SecTrustCopyProperties(trust)
            print("❌ error in connection occured\n \(arrayRefTrust as Any)")
            let trustProperties = SecTrustCopyProperties(trust)
            print("❌ error in connection occured\n \(trustProperties as Any)")
            completionHandler(false)
        }
    }
        
    public func socket(_ sock: GCDAsyncSocket, didConnectToHost host: String, port: UInt16) {
        print("✅ socket connected to host \(host) on port \(port)")
        
        guard sock.connectedHost != nil,
        var node = self.nodesList.first(where: { $0.ipAddress == host })
        else {
            print("❌ connectedHost is nil in didConnectToHost")
            return
        }
        node.luciSocket = sock
//        print(TLSHelper.tlsSetting)
        sock.startTLS(TLSHelper.tlsSetting)
    }
    
    public func socketDidSecure(_ sock: GCDAsyncSocket) {
        print("✅ socket DidSecure \(sock.connectedHost as Any)")
        guard let host = sock.connectedHost,
              var node = self.nodesList.first(where: { $0.ipAddress == host })
        else {
            print("❌ connectedHost or node is nil in Did Secure")
            return
        }
        node.luciSocket = sock
        self.delegate?.luciDidEstablishConnection(for: node)
    }
    
    public func socketDidDisconnect(_ sock: GCDAsyncSocket, withError err: Error?, ipAddress host: String?) {
        print("❌ socket disconnected for IP -> \(host as Any) -- with error -> \(err as Any)")
        
        guard host != nil else { return }
        
        if let err = err as? NSError, err.code == -9806 {
            print("❌ socket \(err as Any)")
            return
        }
    }
}
