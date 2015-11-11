//
//  OPCodeTests.swift
//  BitcoinSwift
//
//  Created by Huang Yu on 8/26/15.
//  Copyright (c) 2015 DoubleSha. All rights reserved.
//

import BitcoinSwift
import XCTest

class OPCodeTests: XCTestCase {
  
  func testNil() {
    XCTAssertTrue(OPCode(rawValue: 50) == nil)
    XCTAssertTrue(OPCode(rawValue: 0) != nil)
    XCTAssertTrue(OPCode(rawValue: 50) != OPCode(rawValue: 0))
  }
  
  func testEqual() {
    XCTAssertEqual(OPCode._0, OPCode.False)
    XCTAssertNotEqual(OPCode._2, OPCode._14)
    XCTAssertEqual(OPCode(rawValue: 81)!, OPCode.True)
  }
  
  func testGreaterThan() {
    XCTAssertGreaterThan(OPCode(rawValue: 81)!, OPCode(rawValue: 0)!)
    XCTAssertFalse(OPCode(rawValue: 81)! > OPCode(rawValue: 82)!)
  }
  
  func testGreaterThanOrEqual() {
    XCTAssertGreaterThanOrEqual(OPCode(rawValue: 81)!, OPCode(rawValue: 0)!)
    XCTAssertFalse(OPCode(rawValue: 0)! >= OPCode(rawValue: 81)!)
  }
  
  func testLessThan() {
    XCTAssertLessThan(OPCode(rawValue: 0)!, OPCode(rawValue: 81)!)
    XCTAssertFalse(OPCode(rawValue: 82)! < OPCode(rawValue: 81)!)
  }
  
  func testLessThanOrEqual() {
    XCTAssertLessThanOrEqual(OPCode(rawValue: 0)!, OPCode(rawValue: 81)!)
    XCTAssertLessThanOrEqual(OPCode(rawValue: 81)!, OPCode(rawValue: 81)!)
    XCTAssertFalse(OPCode(rawValue: 82)! <= OPCode(rawValue: 81)!)
  }
  
  func testDataWithRawValue() {
    let opcode: OPCode = OPCode(rawValue: 81)!
    XCTAssertEqual(opcode.rawValue, 81)
  }
}
