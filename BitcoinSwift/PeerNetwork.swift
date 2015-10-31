//
//  PeerNetwork.swift
//  BitcoinSwift
//
//  Created by Bruno Philipe on 10/27/15.
//  Copyright © 2015 Bruno Philipe. All rights reserved.
//

import UIKit
import BitcoinSwift

public struct PeerNetworkConfig {
  var genesisBlock: SHA256Hash
  var seedNodes: [IPAddress]
  var port: UInt16
  var minConnectedNodes: Int
  var network: Message.Network
  var versionMessage: VersionMessage
  var downloadBlockchain: Bool
  var blockChainStore: BlockChainStore?
  
  init(seedNodes: [IPAddress],
    port: UInt16,
    genesisBlock: SHA256Hash,
    network: Message.Network,
    versionMessage: VersionMessage,
    minConnectedNodes: Int = 3,
    downloadBlockchain: Bool = true,
    blockChainStore: BlockChainStore? = nil) {
      self.seedNodes = seedNodes
      self.port = port
      self.genesisBlock = genesisBlock
      self.network = network
      self.versionMessage = versionMessage
      self.minConnectedNodes = minConnectedNodes
      self.downloadBlockchain = downloadBlockchain && blockChainStore != nil
      self.blockChainStore = blockChainStore
  }
}

public protocol PeerNetworkDelegate {
  func peerNetwork(peerNetwork: PeerNetwork, receivedTransaction transaction: Transaction)
}

public class PeerNetwork {
  private var config: PeerNetworkConfig
  private var delegate: PeerNetworkDelegate?
  private var maintenanceTimer: NSTimer?
  private var maintenanceRun = 0
  
  private var peers = [PeerConnection]()
  private var knownPeerAddresses = [PeerAddress]()
  private var ignoredIPAddresses = [IPAddress]()
  private var sentPingMessages = [UInt64 : SentPingMessage]()
  private var pingTimes = [PeerConnection : NSTimeInterval]()
  
  init(config: PeerNetworkConfig) {
    self.config = config
    
    for ipAddress in config.seedNodes
    {
      let peerAddress = PeerAddress(services: PeerServices.None, IP: ipAddress, port: config.port)
      knownPeerAddresses.append(peerAddress)
    }
  }
  
  // MARK: - Public Methods
  
  public func start() {
    Logger.debug("Kicking off PeerNetwork")
    
    if maintenanceTimer == nil {
      maintenanceTimer = NSTimer.scheduledTimerWithTimeInterval(30.0,
        target: self,
        selector: "maintenanceTimerDidFire",
        userInfo: nil,
        repeats: true)
      maintenanceTimer?.fire()
    }
  }
  
  public func stop() {
    if maintenanceTimer != nil {
      maintenanceTimer?.invalidate()
      maintenanceTimer = nil
      
      for connectedPeer in connectedPeers() {
        connectedPeer.disconnect()
      }
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
  
  public func notifyConfirmationOfTransaction(transaction: Transaction) {

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
    Logger.debug("Starting PeerNetwork maintenance")
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
      Logger.info("Peer did not reply to ping message. Disconnecting: " + sentPing.peer.description)
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

extension PeerNetwork {
  func receivedBlockMessage(blockMessage: Block, fromPeer: PeerConnection) -> MessagePayload? {
    var responseMessage: MessagePayload? = nil
    
    // Process block
    if config.downloadBlockchain, let blockChainStore = config.blockChainStore {
      do {
        if let currentHeader = try blockChainStore.head() {
          let newWork = currentHeader.chainWork + blockMessage.header.work
          
          // Check if the new block matches the chain's head
          if currentHeader.blockHeader.hash == blockMessage.header.previousBlockHash, let height = try blockChainStore.height() {
            // Everything seems in place. We can add the new block to the chain.
            let chainHeader = BlockChainHeader(blockHeader: blockMessage.header, height: height+1, chainWork: newWork)
            try blockChainStore.addBlockChainHeaderAsNewHead(chainHeader)
          } else {
            // Check if the "previous block hash" block is in the chain
            if let parentHeader = try blockChainStore.blockChainHeaderWithHash(blockMessage.header.previousBlockHash) {
              let altWork = parentHeader.chainWork + blockMessage.header.work
              
              if altWork > newWork {
                // We received a block that makes the chain longer than it was, so we have to accept it as the new head
                // We start by removing all blocks after the new block's parent
                while let headHash = try blockChainStore.head()?.blockHeader.hash where headHash != parentHeader.blockHeader.hash {
                  try blockChainStore.deleteBlockChainHeaderWithHash(headHash)
                }
                // Now that the head points at the new block's parent, we can add the new block as the new head
                if let height = try blockChainStore.height() {
                  let chainHeader = BlockChainHeader(blockHeader: blockMessage.header, height: height+1, chainWork: altWork)
                  try blockChainStore.addBlockChainHeaderAsNewHead(chainHeader)
                }
              } else {
                // This is an orphan block. Let's reject it.
                responseMessage = RejectMessage(rejectedCommand: blockMessage.command,
                  code: .Invalid,
                  reason: "Orphan block",
                  hash: blockMessage.header.hash)
                
                Logger.info("Received orpah block.")
              }
            }
          }
        }
      } catch let error as NSError {
        Logger.warn("Failed adding block to chain: " + error.description)
      }
    }
    
    // Replay message to all other connected peers
    for peer in connectedPeers() {
      if peer !== fromPeer {
        peer.sendMessageWithPayload(blockMessage)
      }
    }
    
    return responseMessage
  }
  
  func receivedTransactionMessage(transactionMessage: Transaction, fromPeer: PeerConnection) {
    // Process transaction
    // Not implemented
    
    // Replay transaction to all other connected peers
    for peer in connectedPeers() {
      if peer !== fromPeer {
        peer.sendMessageWithPayload(transactionMessage)
      }
    }
  }
  
  func receivedPongMessageWithNonce(nonce: UInt64) {
    if let sentPingMessage = sentPingMessages[nonce] {
      sentPingMessages.removeValueForKey(nonce)
      
      let now = NSDate().timeIntervalSince1970
      pingTimes[sentPingMessage.peer] = now - sentPingMessage.time
    }
  }
  
  func receivedInventoryVectors(inventoryVectors: [InventoryVector]) -> GetDataMessage? {
    var inventoryVectorsToRequest = [InventoryVector]()
    
    for currentVector in inventoryVectors {
      switch currentVector.type
      {
      case .Block:
        // New block dicovered!
        if config.downloadBlockchain {
          inventoryVectorsToRequest.append(currentVector)
        }
        
      case .Transaction:
        // New transaction received!
        if config.downloadBlockchain || delegate != nil {
          inventoryVectorsToRequest.append(currentVector)
        }
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

extension PeerNetwork: PeerConnectionDelegate {
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
      responseMessage = receivedBlockMessage(blockMessage, fromPeer: peerConnection)
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

extension PeerNetwork {
  
  public var ErrorDomain: String { return "BitcoinSwift.PeerNetwork" }
  
  public enum ErrorCode: Int {
    case Unknown = 0,
    OrphanBlockReceived
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



















