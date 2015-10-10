//
//  BitcoinMainNetParameters.swift
//  BitcoinSwift
//
//  Created by Kevin Greene on 1/15/15.
//  Copyright (c) 2015 DoubleSha. All rights reserved.
//

import Foundation

public class BitcoinMainNetParameters: BitcoinParameters {

  public class func get() -> BitcoinMainNetParameters {
    // TODO: Remove this once Swift supports class vars.
    struct Static {
      static let instance = BitcoinMainNetParameters()
    }
    return Static.instance
  }

  // MARK: - TransactionParameters

  public var transactionVersion: UInt32 {
    return 1
  }

  // MARK: - AddressParameters

  public var supportedAddressHeaders: [UInt8] {
    return [publicKeyAddressHeader, P2SHAddressHeader]
  }

  public var publicKeyAddressHeader: UInt8 {
//  return 0		=> Bitcoin
//  return 0x47	=> Vertcoin
		return 0x47
  }

  public var P2SHAddressHeader: UInt8 {
//	return 5			=> Bitcoin
//	return 7			=> Vertcoin
    return 7
  }

  // MARK: - BlockHeaderParameters

  public var blockVersion: UInt32 {
//	return 1			=> Bitcoin
//	return 2			=> Vertcoin
		return 2
  }

  // MARK: - BlockChainStoreParameters

  public var blockChainStoreFileName: String {
    return "blockchain"
  }
}
