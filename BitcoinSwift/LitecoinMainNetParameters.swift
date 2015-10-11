//
//  LitecoinMainNetParameters.swift
//  BitcoinSwift
//
//  Created by Kevin Greene on 1/15/15.
//  Copyright (c) 2015 DoubleSha. All rights reserved.
//

import Foundation

public class LitecoinMainNetParameters: BitcoinParameters {

  public class func get() -> LitecoinMainNetParameters {
    // TODO: Remove this once Swift supports class vars.
    struct Static {
      static let instance = LitecoinMainNetParameters()
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
		return 0x30
  }

  public var P2SHAddressHeader: UInt8 {
    return 6
  }

  // MARK: - BlockHeaderParameters

  public var blockVersion: UInt32 {
		return 2 // Not sure
  }

  // MARK: - BlockChainStoreParameters

  public var blockChainStoreFileName: String {
    return "blockchain"
  }
	
	// MARK: - KeyParameters
	
	public var privateKeyHeader: UInt8 {
		return 0xB0
	}
	
	/// Regex parameter
	public var compressedWIFHeader: String {
		return "^T"
	}
	
	/// Regex parameter
	public var WIFHeader: String {
		return "^6"
	}

}
