//
//  LuciCommunication.swift
//  
//
//  Created by Guru on 14/03/24.
//

import UIKit
import CocoaAsyncSocket

public protocol LuciCommunicationDelegate: AnyObject {
    
    /// Indication of Message write success
    /// - Parameters:
    ///   - node: Node object
    ///   - messageBox: MessageBox type
    func writeMessageSuccess(to node: Node, on messageBox: MessageBox)
    
    /// Indication of response from Node
    /// - Parameters:
    ///   - node: Node object
    ///   - messageBox: MessageBox type
    func receivedMessage(message payload: Data, from node: Node, on messageBox: MessageBox)
}

public struct LuciMessage {
    let message: String
    let messageBox: MessageBox
    let messageType: MessageType
}

final public class LuciCommunication: NSObject {
    
    public weak var delegate: LuciCommunicationDelegate?
    private var nodesList: [Node] = []

    private override init() {
        super.init()
    }
    
    public init(delegate: LuciCommunicationDelegate) {
        self.delegate = delegate
        
        super.init()
    }
    
    private func appendNode(_ node: Node) {
        if (self.nodesList.contains(where: { $0.id == node.id })) {
            return
        }
        self.nodesList.append(node)
    }
    
    public func sendMessage(message: LuciMessage, to node: Node) {
        // Check to append node to list
        self.appendNode(node)
        //
        guard let data = message.message.data(using: .utf8) else { return }
        let packet = LuciPacketConstructor(with: data,
                                           messageSize: short(data.count),
                                           command: short(message.messageBox.rawValue),
                                           commandType: short(message.messageType.rawValue),
                                           remoteID: 0)
        let payload = packet.getMessage() as Data
        node.luciSocket?.delegate = self
        node.luciSocket?.delegateQueue = DispatchQueue(label: "LuciMessageQueue")
        node.luciSocket?.write(payload, withTimeout: -1, tag: message.messageBox.rawValue)
    }

}

extension LuciCommunication: GCDAsyncSocketDelegate {
    
    public func socket(_ sock: GCDAsyncSocket, didRead data: Data, withTag tag: Int) {
        guard let host = sock.connectedHost else { return }
        let port: UInt16 = sock.connectedPort

        if (port == 0 && data.count < 0) {
            print("❌ port & data is 0 in socket didRead data for MB no :\(tag)")
            return
        }
        guard let node = self.nodesList.first(where: { $0.ipAddress == host }) else {
            return
        }
        self.processLuciData(for: node, payload: data)
        
        sock.readData(withTimeout: -1, tag: tag)
    }
    
    public func socket(_ socket: GCDAsyncSocket, didWriteDataWithTag tag: Int) {
        print("✅ socket write success for MessageBox :\(tag)")
        guard let host = socket.connectedHost else { return }
        guard let node = self.nodesList.first(where: { $0.ipAddress == host }) else {
            return
        }
        self.delegate?.writeMessageSuccess(to: node, on: MessageBox(rawValue: tag)!)
        socket.readData(withTimeout: -1, tag: tag)
    }
    
}

extension LuciCommunication {
    
    private var headerSize: Int {
        get {
            return 10
        }
    }
    
    private func processLuciData(for node: Node, payload: Data) {
        let inputBuffer = NSMutableData()
        inputBuffer.append(payload)
        
        var array: [CUnsignedChar] = Array(repeating: 0, count: inputBuffer.count)
        inputBuffer.getBytes(&array, length: array.count)
        
        let completePayloadSize = inputBuffer.length
        
        var offset = 0

        while (completePayloadSize - offset) >= 10 {
            if offset > 0 {
                print("❌ Looks like theres additional data, running in while loop")
            }
            let messageBox = Int(UInt16(payload[offset+3]) << 8 | UInt16(payload[offset+4]))
            
            let messageSize = Int(UInt16(payload[offset+8]) << 8 | UInt16(payload[offset+9]))
            
            guard offset + headerSize + messageSize <= inputBuffer.length else {
                // Not enough data to read luciPayload
                break
            }
            
            if (messageSize >= 0) {
                let dataRange = NSRange(location: offset + headerSize, length: Int(messageSize))
                let luciPayload = inputBuffer.subdata(with: dataRange)

                guard let messageBox = MessageBox(rawValue: messageBox) else {
                    return
                }
                self.delegate?.receivedMessage(message: luciPayload,from: node, on: messageBox)
            }
            offset += (Int(messageSize) + headerSize)
        }
    }

}
