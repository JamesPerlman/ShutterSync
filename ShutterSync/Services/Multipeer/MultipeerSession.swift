//
//  MultiPeerSession.swift
//  ShutterSync
//
//  Created by James Perlman on 7/21/22.
//

import Foundation
import MultipeerConnectivity
import os
import SwiftUI

enum NamedColor: String, CaseIterable {
    case red, green, blue
}

extension NamedColor {
    var color: Color {
        let map:[NamedColor: Color] = [
            .red: .red,
            .green: .green,
            .blue: .blue,
        ]
        return map[self] ?? .blue
    }
}

class MultipeerSession: NSObject, ObservableObject {
    private let serviceType = "shuttersync"
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    private let serviceAdvertiser: MCNearbyServiceAdvertiser
    private let serviceBrowser: MCNearbyServiceBrowser
    private let session: MCSession
    
    private let log = Logger()
    
    @Published var connectedPeers: [MCPeerID] = []
    @Published var currentColor: NamedColor? = nil
    
    override init() {
        session = MCSession(peer: myPeerID)
        serviceAdvertiser = MCNearbyServiceAdvertiser(peer: myPeerID, discoveryInfo: nil, serviceType: serviceType)
        serviceBrowser = MCNearbyServiceBrowser(peer: myPeerID, serviceType: serviceType)
        
        super.init()
        
        session.delegate = self
        serviceAdvertiser.delegate = self
        serviceBrowser.delegate = self
        
        serviceAdvertiser.startAdvertisingPeer()
        serviceBrowser.startBrowsingForPeers()
    }
    
    deinit {
        serviceAdvertiser.stopAdvertisingPeer()
        serviceBrowser.stopBrowsingForPeers()
    }
    
    func send(color: NamedColor) {
        print("Sending \(String(describing: color)) to \(session.connectedPeers.count)")
        currentColor = color
        
        guard !session.connectedPeers.isEmpty else {
            return
        }
        
        guard let messageData = color.rawValue.data(using: .utf8) else {
            return
        }
        
        do {
            try session.send(messageData, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            log.error("There was an error sending the color: \(String(describing: error))")
        }
    }
    
}

extension MultipeerSession: MCNearbyServiceAdvertiserDelegate {
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        log.error("ServiceAdvertiser didNotStartAdvertisingPeer \(String(describing: error))")
    }
    
    func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        log.info("didReceiveInvitationFromPeer \(peerID)")
        invitationHandler(true, session)
    }
}

extension MultipeerSession: MCNearbyServiceBrowserDelegate {
    func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        log.error("ServiceBrowser didNotStartBrowsingForPeers: \(String(describing: error))")
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        log.info("ServiceBrowser found a peer! \(peerID)")
        browser.invitePeer(peerID, to: session, withContext: nil, timeout: 120)
    }
    
    func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        log.info("ServiceBrowser lost a peer :( \(peerID)")
    }
}

extension MultipeerSession: MCSessionDelegate {
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        log.info("peer \(peerID) didChangeState: \(state.rawValue)")
        DispatchQueue.main.async {
            self.connectedPeers = session.connectedPeers
        }
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        log.info("didReceive data \(data.count) from peer \(peerID)")
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        log.info("didReceive stream \(stream) withName \(streamName) from peer \(peerID)")
    }
    
    func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
        log.info("didReceive certificate fromPeer \(peerID)")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        log.info("didStart receiving resource with name \(resourceName) fromPeer \(peerID)")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        log.info("didFinish receiving resourceName \(resourceName) fromPeer \(peerID)")
    }
}
