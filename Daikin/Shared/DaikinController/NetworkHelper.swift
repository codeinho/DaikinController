//
//  NetworkHelper.swift
//  Daikin
//
//  Created by Lothar Heinrich on 09.01.22.
//

import Foundation
import Network




func getIFAddresses() -> [String] {
    var addresses = [String]()
    
    // Get list of all interfaces on the local machine:
    var ifaddr : UnsafeMutablePointer<ifaddrs>?
    guard getifaddrs(&ifaddr) == 0 else { return [] }
    guard let firstAddr = ifaddr else { return [] }
    
    // For each interface ...
    for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
        let flags = Int32(ptr.pointee.ifa_flags)
        var addr = ptr.pointee.ifa_addr.pointee
        
        // Check for running IPv4, IPv6 interfaces. Skip the loopback interface.
        if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
            if addr.sa_family == UInt8(AF_INET) || addr.sa_family == UInt8(AF_INET6) {
                
                // Convert interface address to a human readable string:
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                if (getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count),
                                nil, socklen_t(0), NI_NUMERICHOST) == 0) {
                    let address = String(cString: hostname)
                    addresses.append(address)
                }
            }
        }
    }
    
    freeifaddrs(ifaddr)
    return addresses

}

func isValidIP4(ip: String) -> Bool {
    let dotsCount = ip.filter { $0 == "." }.count
    if dotsCount != 3 {
        return false
    }
    if let _ = IPv4Address(ip) {
        return true
    }
    return false
}

func subnet(ofIp: String) -> String? {
    let dots = ofIp.filter ( { $0 == "." })
    guard dots.count == 3 else {
        return nil
    }
    
    if let index = ofIp.lastIndex(of: ".") {
        let str = ofIp[ofIp.startIndex..<index]
        return String(str)
    }
    return nil
}
/// works with some heuristics, e.g. we could be in an other wifi than the aircons but with the same subnet. In this case we get a false positiv
/// two main cases work reliable:
///     1.) we are on same ip4-network with the aircon -> true
///     2.) we are on a mobile network -> false
func isInOurWifi(acIP: String) -> Bool {
    guard let acSubnet = subnet(ofIp: acIP) else {
        return false
    }
    
    let myIPs = getIFAddresses()
    
    for myIP in myIPs {
        if isValidIP4(ip: myIP) {
            let mySubnet = subnet(ofIp: myIP)
            if mySubnet == acSubnet {
                return true
            }
        }
    }
    return false
}
