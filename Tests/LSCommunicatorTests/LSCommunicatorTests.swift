import XCTest
@testable import LSCommunicator

final class LSCommunicatorTests: XCTestCase {
    
//    func testExample() throws {
//        // XCTest Documentation
//        // https://developer.apple.com/documentation/xctest
//
//        // Defining Test Cases and Test Methods
//        // https://developer.apple.com/documentation/xctest/defining_test_cases_and_test_methods
//    }
    
    func testDiscovery() {
        LuciDiscovery.shared.delegate = self
        LuciDiscovery.shared.startDiscovery()
//        LuciDiscovery.shared.startDiscovery(timeout: 5, interval: 30, model: "RIVA")
    }
}

extension LSCommunicatorTests: DiscoveryDelegate {
    
    func luciDidDisover(nodes: [LSCommunicator.Node]) {
        print(nodes)
    }
    
}
