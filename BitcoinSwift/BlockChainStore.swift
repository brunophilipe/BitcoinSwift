//
//  BlockChainStore.swift
//  BitcoinSwift
//
//  Created by Kevin Greene on 11/29/14.
//  Copyright (c) 2014 DoubleSha. All rights reserved.
//

import Foundation

public protocol BlockChainStoreParameters {

  /// The filename to use for the persistent blockchain store.
  /// This filename should NOT have an extension. The BlockChainStore will append an appropriate
  /// extension based on the type of file (e.g. CoreDataBlockChainStore will append ".sqlite").
  var blockChainStoreFileName: String { get }
}

/// Persistent storage for blocks in a blockchain. Calls to all methods should be thread-safe.
/// TODO: Convert this to Swift 2 syntax.
public protocol BlockChainStore {

  /// The height of the current longest blockchain. If there is no head block, returns nil. If an
  /// error occurs, it will be thrown.
  func height() throws -> UInt32?

  /// The head block in the current longest blockchain. If there is no head block, returns nil.
  /// If an error occurs, it will be thrown.
  func head() throws -> BlockChainHeader?

  /// Adds blockChainHeader to the store and sets it as the head of the current longest chain.
  /// If an error occurs, it will be thrown.
  func addBlockChainHeaderAsNewHead(blockChainHeader: BlockChainHeader) throws

  // TODO: Make this operate like a stack - so you can only delete the head blockHeader. Otherise
  // this can easily get into a bad state where the head is not updated after deleting a block.
  //
  /// Deletes the blockChainheader with |hash| from the store.
  /// If not present, then this is just a NOP. If an error occurs, it will be thrown.
  func deleteBlockChainHeaderWithHash(hash: SHA256Hash) throws

  /// Returns the blockChainHeader with the given hash. If there is no block matching the given
  /// hash, returns nil. If an error occurs, it will be stored thrown.
  func blockChainHeaderWithHash(hash: SHA256Hash) throws -> BlockChainHeader?
}
