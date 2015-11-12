//
//  ScriptTests.swift
//  BitcoinSwift
//
//  Created by Bruno Philipe on 11/12/15.
//  Copyright © 2015 DoubleSha. All rights reserved.
//

import XCTest

class ScriptTests: XCTestCase {
  func testParseSimpleScript() {
    let scriptBytes: [UInt8] = [
      0x76,                       // DUP
      0xA9,                       // HASH160
      0x14,                       // Bytes count = 20
        0x89, 0xAB, 0xCD, 0xEF,   // Bytes
        0xAB, 0xBA, 0xAB, 0xBA,
        0xAB, 0xBA, 0xAB, 0xBA,
        0xAB, 0xBA, 0xAB, 0xBA,
        0xAB, 0xBA, 0xAB, 0xBA,
      0x88,                       // EQUALVERIFY
      0xAC                        // CHEKCSIG
    ]
    
    let expectedBytes: [UInt8] = [
      0x89, 0xAB, 0xCD, 0xEF,
      0xAB, 0xBA, 0xAB, 0xBA,
      0xAB, 0xBA, 0xAB, 0xBA,
      0xAB, 0xBA, 0xAB, 0xBA,
      0xAB, 0xBA, 0xAB, 0xBA
    ]
    
    let expectedTokens: [ScriptToken] = [
      .Operation(.Dup),
      .Operation(.Hash160),
      .Data(NSData(bytes: expectedBytes, length: expectedBytes.count)),
      .Operation(OPCode.EqualVerify),
      .Operation(OPCode.CheckSig)
    ]
    
    let scriptData = NSData(bytes: scriptBytes, length: scriptBytes.count)
    
    if let script = Script(fromData: scriptData) {
      let tokens = script.tokens
      
      XCTAssertEqual(tokens, expectedTokens, "Script tokens are not as expected")
    } else {
      XCTFail("Could not create Script object")
    }
  }
}