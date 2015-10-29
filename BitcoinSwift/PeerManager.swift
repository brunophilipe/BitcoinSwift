//
//  PeerManager.swift
//  BitcoinSwift
//
//  Created by Bruno Philipe on 10/27/15.
//  Copyright © 2015 Bruno Philipe. All rights reserved.
//

import UIKit

public struct PeerManagerConfig {
  var genesisBlock: SHA256Hash
  var seedNodes: [IPAddress]
  var port: UInt16
  var minConnectedNodes: Int
  var network: Message.Network
  var versionMessage: VersionMessage
  var downloadBlockchain: Bool
  var delegate: PeerManagerDelegate?
  var blockChainStore: BlockChainStore?
  
  init(seedNodes: [IPAddress],
    port: UInt16,
    genesisBlock: SHA256Hash,
    network: Message.Network,
    versionMessage: VersionMessage,
    minConnectedNodes: Int = 3,
    downloadBlockchain: Bool = true,
    blockChainStore: BlockChainStore? = nil,
    delegate: PeerManagerDelegate? = nil) {
      self.seedNodes = seedNodes
      self.port = port
      self.genesisBlock = genesisBlock
      self.network = network
      self.versionMessage = versionMessage
      self.minConnectedNodes = minConnectedNodes
      self.downloadBlockchain = downloadBlockchain && blockChainStore != nil
      self.blockChainStore = blockChainStore
      self.delegate = delegate
  }
}

public protocol PeerManagerDelegate {
  func peerManager(peerManager: PeerManager, receivedTransaction transaction: Transaction)
}

public class PeerManager {
  private var config: PeerManagerConfig
  private var maintenanceTimer: NSTimer?
  private var maintenanceRun = 0
  
  private var peers = [PeerConnection]()
  private var knownPeerAddresses = [PeerAddress]()
  private var ignoredIPAddresses = [IPAddress]()
  private var sentPingMessages = [UInt64 : SentPingMessage]()
  private var pingTimes = [PeerConnection : NSTimeInterval]()
  
  init(config: PeerManagerConfig) {
    self.config = config
    
    for ipAddress in config.seedNodes
    {
      let peerAddress = PeerAddress(services: PeerServices.None, IP: ipAddress, port: config.port)
      knownPeerAddresses.append(peerAddress)
    }
  }
  
  // MARK: - Public Methods
  
  public func kickoff() {
    Logger.debug("Kicking off PeerManager")
    
    if maintenanceTimer == nil {
      maintenanceTimer = NSTimer.scheduledTimerWithTimeInterval(30.0,
        target: self,
        selector: "maintenanceTimerDidFire",
        userInfo: nil,
        repeats: true)
      maintenanceTimer?.fire()
    }
  }
  
  public func broadcastTransaction(transaction: Transaction) -> Bool {
    let peers = connectedPeers()
    
    if peers.count > 0 {
      peers.forEach({ (peer) -> () in
        peer.sendMessageWithPayload(transaction)
      })
      
      return true
    } else {
      return false
    }
  }
  
  public func numberOfConnectedPeers() -> Int {
    return connectedPeers().count
  }
  
  // MARK: - Peers
  
  private func connectedPeers() -> [PeerConnection] {
    return peersWithStatus(.Connected)
  }
  
  private func peersWithStatus(status: PeerConnection.Status) -> [PeerConnection] {
    return peers.filter { (peerConnection) -> Bool in
      return peerConnection.status == status
    }
  }
  
  // MARK: - Maintenance
  
  private func runMaintenance() {
    Logger.debug("Starting PeerManager maintenance")
    maintenanceRun++
    
    // If we are connected to less than the configured minimum nodes, contact another one
    if connectedPeers().count < config.minConnectedNodes {
      if !connectToNewNode() {
        Logger.alert("No more known nodes available to connect...")
        requestAddressesToRandomPeer()
      }
    } else {
      Logger.debug("Enough peers are connected. Resting...")
    }
    
    // Disconnect to any peers that did not repond to the previous Ping message
    for (_, sentPing) in sentPingMessages {
      sentPing.peer.disconnect()
    }
    sentPingMessages.removeAll()
    
    // Send ping message to all connected peers, but only once every 4 maintenance runs
    if maintenanceRun == 4 {
      for connectedPeer in connectedPeers() {
        let pingMessage = PingMessage()
        let now = NSDate().timeIntervalSince1970
        connectedPeer.sendMessageWithPayload(pingMessage)
        sentPingMessages[pingMessage.nonce] = SentPingMessage(peer: connectedPeer, time: now)
      }
    }
    
    // Cleanup any disconnected peers
    for peer in peersWithStatus(.NotConnected) {
      peers.removeObject(peer)
    }
    
    // Reset maintenance run counter
    if maintenanceRun >= 4 {
      maintenanceRun = 0
    }
  }
  
  /// Returns the knownPeerAddresses array sorted by timestamp
  private func sortedKnownPeerAddresses() -> [PeerAddress]
  {
    return knownPeerAddresses.sort({ (peer1, peer2) -> Bool in
      let stamp1 = peer1.timestamp
      let stamp2 = peer2.timestamp
      
      if stamp1 != nil && stamp2 != nil {
        return stamp1!.timeIntervalSinceDate(stamp2!) > 0
      } else if stamp1 != nil {
        return true
      } else {
        return false
      }
    })
  }
  
  private func connectToNewNode() -> Bool {
    var success = false
    
    let sortedKnownPeers = sortedKnownPeerAddresses().filter { (peerAddress) -> Bool in
      return !ignoredIPAddresses.contains(peerAddress.IP)
    }
    
    for peerAddress in sortedKnownPeers
    {
      if let newHostname = peerAddress.IP.asHostname {
        let connection = PeerConnection(hostname: newHostname,
          port: config.port,
          network: config.network,
          delegate: self)
        
        connection.connectWithVersionMessage(config.versionMessage)
        ignoredIPAddresses.append(peerAddress.IP)
        peers.append(connection)
        
        knownPeerAddresses.removeObject(peerAddress)
        
        success = true
        break
      }
    }
    
    return success
  }
  
  private func requestAddressesToRandomPeer() {
    let peers = connectedPeers(), count = peers.count
    
    if count > 0 {
      let randomIndex = Int(arc4random() % UInt32(count))
      let randomNode = peers[randomIndex]
      randomNode.sendMessageWithPayload(GetPeerAddressMessage())
    } else {
      Logger.warn("No known nodes to connect, no connected nodes. Left in stalled place.")
    }
  }
  
  @objc
  private func maintenanceTimerDidFire() {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
      self.runMaintenance()
    }
  }
}

extension PeerManager {
  func receivedPongMessageWithNonce(nonce: UInt64) {
    if let sentPingMessage = sentPingMessages[nonce] {
      sentPingMessages.removeValueForKey(nonce)
      
      let now = NSDate().timeIntervalSince1970
      pingTimes[sentPingMessage.peer] = now - sentPingMessage.time
    }
  }
  
  func receivedInventoryVectors(inventoryVectors: [InventoryVector]) -> GetDataMessage? {
    var inventoryVectorsToRequest = [InventoryVector]()
    
    for inventoryVector in inventoryVectors {
      switch inventoryVector.type
      {
      case .Block:
        // New block dicovered!
        if config.downloadBlockchain {
          inventoryVectorsToRequest.append(inventoryVector)
        }
        
      case .Transaction:
        // New transaction received!
        // Not implemented
        break
        
      case .Error:
        // Not implemented
        break
      }
    }
    
    if inventoryVectorsToRequest.count > 0
    {
      return GetDataMessage(inventoryVectors: inventoryVectorsToRequest)
    }
    else
    {
      return nil
    }
  }
}

extension PeerManager: PeerConnectionDelegate {
  public func peerConnection(peerConnection: PeerConnection, didConnectWithPeerVersion peerVersion: VersionMessage) {
    let getHeadersMessage = GetHeadersMessage(protocolVersion: 70002, blockLocatorHashes: [self.config.genesisBlock])
    peerConnection.sendMessageWithPayload(getHeadersMessage)
  }
  
  public func peerConnection(peerConnection: PeerConnection, didDisconnectWithError error: NSError?) {
    peers.removeObject(peerConnection)
  }
  
  public func peerConnection(peerConnection: PeerConnection, didReceiveMessage message: PeerConnectionMessage) {
    var responseMessage: MessagePayload? = nil
    
    switch message {
      
    case .AlertMessage(let alertMessage):
      Logger.alert("Received alert message: " + alertMessage.alert.message)
      
    case .Block(let blockMessage):
      // Not implemented
      break
      
    case .FilterAddMessage(let filterAddMessage):
      // Not implemented
      break
      
    case .FilterClearMessage(let filterClearMessage):
      // Not implemented
      break
      
    case .FilteredBlock(let filteredBlockMessage):
      // Not implemented
      break
      
    case .FilterLoadMessage(let filterLoadMessage):
      // Not implemented
      break
      
    case .GetBlocksMessage(let getBlocksMessage):
      // Not implemented
      break
      
    case .GetDataMessage(let getDataMessage):
      // Not implemented
      break
      
    case .GetHeadersMessage(let getHeadersMessage):
      // Not implemented
      break
      
    case .GetPeerAddressMessage(let getPeerAddressMessage):
      responseMessage = PeerAddressMessage(peerAddresses: sortedKnownPeerAddresses())
      
    case .HeadersMessage(let headersMessage):
      // Not implemented
      break
      
    case .InventoryMessage(let inventoryMessage):
      responseMessage = receivedInventoryVectors(inventoryMessage.inventoryVectors)
      
    case .MemPoolMessage(let memPoolMessage):
      // Not implemented
      break
      
    case .NotFoundMessage(let notFoundMessage):
      // Not implemented
      break
      
    case .PeerAddressMessage(let peerAddressMessage):
      knownPeerAddresses.appendContentsOf(peerAddressMessage.peerAddresses)
      
    case .PingMessage(let pingMessage):
      responseMessage = PongMessage(nonce: pingMessage.nonce)
      
    case .PongMessage(let pongMessage):
      receivedPongMessageWithNonce(pongMessage.nonce)
      
    case .RejectMessage(let rejectMessage):
      // Not implemented
      break
      
    case .Transaction(let transactionMessage):
      // Not implemented
      break
    }
    
    if let concreteResponseMessage = responseMessage {
      peerConnection.sendMessageWithPayload(concreteResponseMessage)
    }
  }
}

extension Array where Element : Equatable {
  mutating func removeObject(object : Generator.Element) {
    if let index = self.indexOf(object) {
      self.removeAtIndex(index)
    }
  }
}

internal struct SentPingMessage {
  let peer: PeerConnection
  let time: NSTimeInterval
  
  init(peer: PeerConnection, time: NSTimeInterval) {
    self.peer = peer
    self.time = time
  }
}



















