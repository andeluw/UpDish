//
//  NetworkMonitorService.swift
//  UpDish
//
//  Created by Andrew Wallace on 28/07/26.
//

import Network
import Dispatch

@MainActor
final class NetworkMonitorService {
    // nil -> status is unknown or establishing a connection may activate the path
    private(set) var isConnected: Bool?
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(
        label: "com.andeluw.UpDish.network-monitor"
    )
    
    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            let isConnected: Bool?
            
            switch path.status {
            case .satisfied:
                isConnected = true
            case .unsatisfied:
                isConnected = false
            case .requiresConnection:
                isConnected = nil
            @unknown default:
                isConnected = nil
            }
            
            Task { @MainActor [weak self] in
                self?.isConnected = isConnected
            }
        }
        
        monitor.start(queue: queue)
    }
    
    deinit {
        monitor.cancel()
    }
}
