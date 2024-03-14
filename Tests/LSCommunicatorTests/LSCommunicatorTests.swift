import XCTest
@testable import LSCommunicator

class LSCommunicatorTests: XCTestCase {
    
    
    var discoveryExpectation: XCTestExpectation!
    var connectionExpectation: XCTestExpectation!
    var communicationExpectation: XCTestExpectation!
    var communication: LuciCommunication!
    var tcpTunnelingExpectation: XCTestExpectation!
    var tcpTunnel: TCPTunnelCommunication!
    
    var list: [Node] = []
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testDiscovery() {
        discoveryExpectation = XCTestExpectation()

        let discovery = LuciDiscovery(delegate: self)
        discovery.startDiscovery()
//        discovery.startDiscovery(interval: 10)
        
        wait(for: [discoveryExpectation], timeout: 20)
    }
    
    func testConnection() {
        connectionExpectation = XCTestExpectation()
        
        initNodeList()
        
        let connection = LuciConnection(delegate: self)
        for node in list {
            try? connection.connect(to: node)
        }
        
        wait(for: [connectionExpectation], timeout: 60)
    }
    
    private func initNodeList() {
        self.list = [Node(id: "RivaFestivalx23c185_192.168.1.35",
                               friendlyName: "RivaFestivalx23c185",
                               model: "festival x",
                               ipAddress: "192.168.1.35",
                               port: 7777, firmwareVersion: "eng.C4A.3197.0.1")]
    }
    
    func communicationTest(node: Node) {
        communicationExpectation = XCTestExpectation()
                
        communication = LuciCommunication(delegate: self)
        
        let json = ["id":"1.0", "version":"1.0", "ip":"192.168.1.155", "phone_model":"", "phone_os_version":""]
        let appInfo = ["app_info":json]
        let jsonData = try! JSONEncoder().encode(appInfo)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        let reg_message = LuciMessage(message: jsonString,
                                      messageBox: .REG_ASYNC_EVENTS,
                                      messageType: .WRITE)
        
        communication.sendMessage(message: reg_message, to: node)
        
        wait(for: [communicationExpectation], timeout: 20)
    }
    
    func testTCPTunneling() {
        tcpTunnelingExpectation = XCTestExpectation()
        
        tcpTunnel = TCPTunnelCommunication(ipAddress: "192.168.1.42",
                                               port: 50005,
                                               delegate: self)
                
        wait(for: [tcpTunnelingExpectation], timeout: 20)
    }
}

extension LSCommunicatorTests: LuciDiscoveryDelegate {
    
    func luciDidDisover(nodes: [LSCommunicator.Node]) {
        print(nodes)
        do {
            try XCTSkipIf(nodes.count > 1, "Nodes count = \(nodes.count)")
        } catch {
            print("Skipped as luciDidDisover Nodes, Overall Node count is \(nodes.count)")
            discoveryExpectation.fulfill()
        }
    }
    
}

extension LSCommunicatorTests: LuciConnectionDelegate {
    
    func luciDidEstablishConnection(for node: LSCommunicator.Node) {
        print("\(node.friendlyName) connected on \(node.ipAddress) at port \(node.port)")
        
        self.communicationTest(node: node)
    }
    
}

extension LSCommunicatorTests: LuciCommunicationDelegate {
    
    func writeMessageSuccess(to node: LSCommunicator.Node, on messageBox: LSCommunicator.MessageBox) {
        print("Message to \(node.friendlyName) node written successfully")
        
    }
    
    func receivedMessage(message payload: Data, from node: LSCommunicator.Node, on messageBox: LSCommunicator.MessageBox) {
        let payload = String(data: payload, encoding: .utf8)
        print("Received message \(payload ?? "-") from \(node.friendlyName) node on MB: \(messageBox)")
        
        if (messageBox == .REG_ASYNC_EVENTS) {
            let reg_message = LuciMessage(message: "",
                                          messageBox: .VOLUME,
                                          messageType: .READ)
            communication.sendMessage(message: reg_message, to: node)
        } else if (messageBox == .VOLUME) {
            communicationExpectation.fulfill()
            connectionExpectation.fulfill()
        }
    }
    
}

extension LSCommunicatorTests: TCPTunnelCommunicationDelegate {
    
    func tcpTunnelingConnectionDidEsatblish() {
        let data = tcpTunnel.getDataMode()
        tcpTunnel.sendTCPTunnelMessage(data: data)
    }
    
    func tcpTunnelingConnectionClosed() {
        // nothing to do
    }
    
    
    func sentTCPTunnelMessage(to host: String) {
        print("TCP Tunnel message sent to \(host)")
    }
    
    func receivedTCPTunnelMessage(message payload: Data, from host: String) {
        let payload = String(data: payload, encoding: .utf8)
        print("Received message \(payload ?? "-") from \(host)")
        tcpTunnelingExpectation.fulfill()
    }
    
}
