//
//  TLVNodeTests.swift
//  TLVNodeTests
//
//  Created by Bruno Philipe on 11/2/15.
//  Copyright © 2015 Bruno Philipe. All rights reserved.
//

import XCTest

class TLVNodeTests: XCTestCase {
  func testParseSimpleNode() {
    let tlvBytes: [UInt8] = [0x0C, 0x05, 0x42, 0x52, 0x55, 0x4E, 0x4F]
    if let node = TLVNode.nodeWithData(NSData(bytes: tlvBytes, length: tlvBytes.count)) {
      XCTAssertEqual(node.tag, 0x0C);
      XCTAssertEqual(node.tagString, "0C");
      XCTAssertEqual(node.length, 0x05);
      XCTAssertNotNil(node.data);
      XCTAssertEqual(node.children.count, 0);
      XCTAssertEqual(node.data, "BRUNO".dataUsingEncoding(NSUTF8StringEncoding));
    } else {
      XCTFail("Node is nil")
    }
  }
  
  func testLongTags() {
    let tlvBytes: [UInt8] = [0x3F, 0xFF, 0x43, 0x02, 0x00, 0xA0]
    let testDataBytes: [UInt8] = [0x00, 0xA0]
    
    let testData = NSData(bytes: testDataBytes, length: testDataBytes.count)
    
    if let node = TLVNode.nodeWithData(NSData(bytes: tlvBytes, length: tlvBytes.count)) {
      XCTAssertEqual(node.tag, 0x3F);
      XCTAssertEqual(node.tagString, "3FFF43");
      XCTAssertEqual(node.length, 0x02);
      XCTAssertNotNil(node.data);
      XCTAssertEqual(node.data, testData);
      XCTAssertEqual(node.children.count, 0);
    } else {
      XCTFail("Node is nil")
    }
  }
  
  func testChildSearchSimple() {
    let tlvBytes: [UInt8] = [0x6F, 0x07, 0x80, 0x02, 0x08, 0x00, 0x82, 0x01, 0x01]
    
    if let node = TLVNode.nodeWithData(NSData(bytes: tlvBytes, length: tlvBytes.count)) {
      XCTAssertEqual(node.tag, 0x6F)
      XCTAssertEqual(node.tagString, "6F")
      XCTAssertEqual(node.length, 0x07)
      XCTAssertNotNil(node.children)
      
      if let child = node.findChildWithTag(0x80, recursive: false) {
        XCTAssertEqual(child.tag, 0x80)
        XCTAssertEqual(child.tagString, "80")
        XCTAssertEqual(child.length, 0x02)
        XCTAssertEqual(child.children.count, 0)
      } else {
        XCTFail("Child node is nil")
      }
      
      if let child = node.findChildWithTag(0x82, recursive: false) {
        XCTAssertEqual(child.tag, 0x82)
        XCTAssertEqual(child.tagString, "82")
        XCTAssertEqual(child.length, 0x01)
        XCTAssertEqual(child.children.count, 0)
      } else {
        XCTFail("Child node is nil")
      }
    } else {
      XCTFail("Node is nil")
    }
  }
}
