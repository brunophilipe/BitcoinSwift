//
//  Script.swift
//  BitcoinSwift
//
//  Created by Bruno Philipe on 11/11/15.
//  Copyright © 2015 DoubleSha. All rights reserved.
//

import Foundation

/// A Script token. Can be either an OPCode or a series of raw bytes (data).
public enum ScriptToken: Equatable {
  case Operation(OPCode)
  case Data(NSData)
}

public func ==(lhs: ScriptToken, rhs: ScriptToken) -> Bool {
  switch (lhs, rhs) {
  case (.Operation(let lOp), .Operation(let rOp)):
    return lOp == rOp
  case (.Data(let lData), .Data(let rData)):
    return lData == rData
  default:
    return false
  }
}

extension ScriptToken {
  public func description() -> String {
    switch self {
    case .Operation(let code):
      return String(code.rawValue)
    case .Data(let data):
      return data.description
    }
  }
}

/// A script is essentially a list of instructions recorded with each transaction that describe how the next person 
/// wanting to spend the Bitcoins being transferred can gain access to them.
/// Script is simple, stack-based, and processed from left to right. It is purposefully not Turing-complete, 
/// with no loops.
// https://en.bitcoin.it/wiki/Script
public class Script {
  private var tokenQueue = [ScriptToken]()
  
  /// Creates a new Script with the parameter tokens in the queue.
  init(withTokens tokens: [ScriptToken]) {
    tokenQueue.appendContentsOf(tokens)
  }
  
  /// Attempts to parse the data as a raw Script. Returns nil if the parse failed.
  init?(fromData data: NSData) {
    var bytesRead = 0
    var currByte: UInt8 = 0
    
    repeat {
      data.getBytes(&currByte, range: NSMakeRange(bytesRead, 1))
      bytesRead++
      
      if let opcode = OPCode(rawValue: currByte) {
        // This is an OPCode, so lets add it to the tokens list
        tokenQueue.append(ScriptToken.Operation(opcode))
      } else {
        // This indicates the amount of bytes that should be read as raw data, so let's do this
        let dataLength = Int(currByte)
        if bytesRead + dataLength <= data.length {
          let subData = data.subdataWithRange(NSMakeRange(bytesRead, dataLength))
          tokenQueue.append(ScriptToken.Data(subData))
          bytesRead += dataLength
        } else {
          // Bogus data found
          return nil
        }
      }
    } while (bytesRead < data.length)
  }
  
  /// Appends the parameter token at the bottom of the tokens queue.
  /// If the Script were to be executed after calling this method, the parameter token would be the last to
  /// be processed.
  public func appendToken(token: ScriptToken) {
    tokenQueue.append(token)
  }
  
  /// Inserts the parameter token at the top of the tokens queue.
  /// If the Script were to be executed after calling this method, the parameter token would be the first to 
  /// be processed.
  public func prependToken(token: ScriptToken) {
    tokenQueue.insert(token, atIndex: 0)
  }
  
  /// Executes the Script and returns the value present at the top of the stack after all tokens have been processed.
  public func execute() -> ScriptToken {
    // TODO: Executing the script and outputting the value at the top of the stack
    return .Operation(OPCode.Return)
  }
}

extension Script {
  /// The tokens present in this Script
  public var tokens: [ScriptToken] {
    return tokenQueue
  }
}