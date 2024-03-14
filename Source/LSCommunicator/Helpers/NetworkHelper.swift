//
//  File.swift
//  
//
//  Created by Guru on 28/02/24.
//

import Foundation

struct InterfaceInfo {
    var name: String
    var ip: String
}

class NetworkHelper: NSObject {
    
    static let shared = NetworkHelper()
    
    private var _interfaceAddress: String?
    private var _interfaces: [InterfaceInfo]?
    
    private override init() {
        super.init()
        
        self.getInterfaceAddress()
        
        self.getAvailableInterfaces()
    }
    
    var interfaceAddress: String? {
        get {
            return _interfaceAddress
        }
    }
    
    var availableInterfaces: [InterfaceInfo]? {
        get {
            return _interfaces
        }
    }
    
    private func getInterfaceAddress() {
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer {
                    ptr = ptr?.pointee.ifa_next
                }
                guard let interface = ptr?.pointee else {
                    return
                }
                let addrFamily = interface.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) {
                    let name: String = String(cString: (interface.ifa_name))
                    if  name == "en0" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                        _interfaceAddress = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
    }
    
    func getAvailableInterfaces() {
        _interfaces = [InterfaceInfo]()
        
        /* Get list of all interfaces on the local machine:*/
        var ifaddr : UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            /*For each interface ...*/
            var ptr = ifaddr
            while ptr != nil {
                defer {
                    ptr = ptr?.pointee.ifa_next
                }
                guard let interface = ptr?.pointee else { return }
                
                _ = Int32((ptr?.pointee.ifa_flags)!)
                let addrFamily = interface.ifa_addr.pointee.sa_family
                /* Check for running IPv4, IPv6 interfaces. Skip the loopback interface.*/
                //                if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
                /*AF_INET is the Internet address family for IPv4.
                 AF_INET6 is the Internet address family for IPv6.*/
                if addrFamily == UInt8(AF_INET) {
                    let name: String = String(cString: (interface.ifa_name))
                    var hostAddress = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostAddress, socklen_t(hostAddress.count), nil, socklen_t(0), NI_NUMERICHOST)
                    let address = String(cString: hostAddress)
                    
                    let interface = InterfaceInfo(name: name, ip: address)
                    _interfaces?.append(interface)
                }
            }
            freeifaddrs(ifaddr)
        }
    }
}
