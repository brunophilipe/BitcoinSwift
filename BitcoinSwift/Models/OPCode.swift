//
//  OpCode.swift
//  BitcoinSwift
//
//  Created by Huang Yu on 8/24/15.
//  Copyright (c) 2015 DoubleSha. All rights reserved.
//

import Foundation

public func ==(left: OPCode, right: OPCode) -> Bool {
  return left.rawValue == right.rawValue
}

public func <(left: OPCode, right: OPCode) -> Bool {
  return left.rawValue < right.rawValue
}

public func <=(left: OPCode, right: OPCode) -> Bool {
  return left.rawValue <= right.rawValue
}

public func >(left: OPCode, right: OPCode) -> Bool {
  return left.rawValue > right.rawValue
}

public func >=(left: OPCode, right: OPCode) -> Bool {
  return left.rawValue >= right.rawValue
}

public enum OPCode: UInt8, Comparable {
  case _0 = 0
  
  case PushData1 = 76
  case PushData2 = 77
  case PushData4 = 78
  case _1Negate = 79
  case Reserved = 80
  case _1 = 81
  case _2 = 82
  case _3 = 83
  case _4 = 84
  case _5 = 85
  case _6 = 86
  case _7 = 87
  case _8 = 88
  case _9 = 89
  case _10 = 90
  case _11 = 91
  case _12 = 92
  case _13 = 93
  case _14 = 94
  case _15 = 95
  case _16 = 96
  
  case Nop = 97
  case Ver = 98
  case If = 99
  case NotIf = 100
  case VerIf = 101
  case VerNotIf = 102
  case Else = 103
  case EndIf = 104
  case Verify = 105
  case Return = 106
  
  case ToAltStack = 107
  case FromAltStack = 108
  case _2Drop = 109
  case _2Dup = 110
  case _3Dup = 111
  case _2Over = 112
  case _2Rot = 113
  case _2Swap = 114
  case IfDup = 115
  case Depth = 116
  case Drop = 117
  case Dup = 118
  case NIP = 119
  case Over = 120
  case Pick = 121
  case Roll = 122
  case Rot = 123
  case Swap = 124
  case Tuck = 125
  
  case Cat = 126
  case SubStr = 127
  case Left = 128
  case Right = 129
  case Size = 130
  
  case Invert = 131
  case And = 132
  case Or = 133
  case Xor = 134
  case Equal = 135
  case EqualVerify = 136
  case Reserved1 = 137
  case Reserved2 = 138
  
  case _1Add = 139
  case _1Sub = 140
  case _2Mul = 141
  case _2Div = 142
  case Negate = 143
  case Abs = 144
  case Not = 145
  case _0NotEqual = 146
  case Add = 147
  case Sub = 148
  case Mul = 149
  case Div = 150
  case Mod = 151
  case LShift = 152
  case RShift = 153
  
  case BoolAnd = 154
  case BoolOr = 155
  case NumEqual = 156
  case NumEqualVerify = 157
  case NumNotEqual = 158
  case LessThan = 159
  case GreaterThan = 160
  case LessThaNorEqual = 161
  case GreaterThaNorEqual = 162
  case Min = 163
  case Max = 164
  
  case Within = 165
  
  case Ripemd160 = 166
  case Sha1 = 167
  case Sha256 = 168
  case Hash160 = 169
  case Hash256 = 170
  case CodeSeparator = 171
  case CheckSig = 172
  case CheckSigVerify = 173
  case CheckMultiSig = 174
  case CheckMultiSigVerify = 175
  
  case Nop1 = 176
  case Nop2 = 177
  case Nop3 = 178
  case Nop4 = 179
  case Nop5 = 180
  case Nop6 = 181
  case Nop7 = 182
  case Nop8 = 183
  case Nop9 = 184
  case Nop10 = 185
  
  case PubKeyHash = 253
  case PubKey = 254
  
  case InvalidOpCode = 255
  
  public static var True: OPCode {
    return ._1
  }
  
  public static var False: OPCode {
    return ._0
  }
}
