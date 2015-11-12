//
//  Script.swift
//  BitcoinSwift
//
//  Created by Bruno Philipe on 11/11/15.
//  Copyright © 2015 DoubleSha. All rights reserved.
//

import Foundation

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

public class Script {
  private var _tokens = [ScriptToken]()
  
  init?(fromData data: NSData) {
    var bytesRead = 0
    var currByte: UInt8 = 0
    
    repeat {
      data.getBytes(&currByte, range: NSMakeRange(bytesRead, 1))
      bytesRead++
      
      if let opcode = OPCode(rawValue: currByte) {
        // This is an OPCode, so lets add it to the tokens list
        _tokens.append(ScriptToken.Operation(opcode))
      } else {
        // This indicates the amount of bytes that should be read as raw data, so let's do this
        let dataLength = Int(currByte)
        if bytesRead + dataLength <= data.length {
          let subData = data.subdataWithRange(NSMakeRange(bytesRead, dataLength))
          _tokens.append(ScriptToken.Data(subData))
          bytesRead += dataLength
        } else {
          // Bogus data found
          return nil
        }
      }
    } while (bytesRead < data.length)
  }
}

extension Script {
  public var tokens: [ScriptToken] {
    return _tokens
  }
}