//
//  NetworkMonitor.swift
//  SamplTestApp
//
//  Created by mac2 on 15/10/25.
//


//
//  NetworkMonitor.swift
//  SamplTestApp
//
//  Optional: Monitor network connectivity status
//

import Foundation
import Network
import Combine
import SwiftUI

class NetworkMonitor: ObservableObject {
    static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
    }
    
    private init() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(path) ?? .unknown
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getConnectionType(_ path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        }
        return .unknown
    }
    
    deinit {
        monitor.cancel()
    }
}

// MARK: - Network Status Banner View
struct NetworkStatusBanner: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared
    
    var body: some View {
        if !networkMonitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                Text("Offline - Showing cached images")
                    .font(.caption)
            }
            .foregroundColor(.white)
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.orange)
        }
    }
}

// MARK: - Usage in GalleryView
// Add this to your GalleryView body:
/*
VStack(spacing: 0) {
    NetworkStatusBanner()
    
    ScrollView {
        // Your existing content
    }
}
*/
