//
//  TLVNode.swift
//  SwiftTLV
//
//  Created by Bruno Philipe on 11/2/15.
//  SwiftTLV is a simple TLV (X.690 ASN.1) parser written in pure Swift.
//  Copyright (C) 2015 – Bruno Philipe
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//

import UIKit

public enum TLVClass: UInt8
{
	case EOC = 0x00
	case Boolean = 0x01
	case Integer = 0x02
	case BitString = 0x03
	case OctetString = 0x04
	case Null = 0x05
	case ObjectIdentifier = 0x06
	case ObjectDescriptor = 0x07
	case External = 0x08
	case Real = 0x09
	case Enumerated = 0x0A
	case EmbeddedPDV = 0x0B
	case UTF8String = 0x0C
	case RelativeOID = 0x0D
	case Reserved1 = 0x0E
	case Reserved2 = 0x0F
	case Sequence = 0x10
	case Set = 0x11
	case NumericString = 0x12
	case PrintableString = 0x13
	case T61String = 0x14
	case VideotexString = 0x15
	case IA5String = 0x16
	case UTCTime = 0x17
	case GeneralizedTime = 0x18
	case GraphicString = 0x19
	case VisibleString = 0x1A
	case GeneralString = 0x1B
	case UniversalString = 0x1C
	case CharacterString = 0x1D
	case BMPString = 0x1E
	case LongTag = 0x1F
}

public class TLVNode
{
	var length: Int = 0
	var tag: TLVClass.RawValue = TLVClass.EOC.rawValue
	var tagString: String? = nil
	var data: NSData? = nil
	var nodeData: NSData? = nil
	var children = [TLVNode]()
	
	public static func nodeWithData(data: NSData) -> TLVNode?
	{
		let (result, _) = TLVNode.constructFromData(data)
		return result
	}
	
	private static func constructFromData(data: NSData) -> (node: TLVNode?, bytesRead: Int)
	{
		if data.length > 2
		{
			let node = TLVNode()
			var bytesRead = Int(0)
			var length = Int(0)
			var byteTag = UInt8(0)
			var byteLength = UInt8(0)
			
			data.getBytes(&byteTag, length: 1)
			bytesRead++
			
			node.tag = TLVClass(rawValue: byteTag)?.rawValue ?? byteTag
			var string_tag = String(format: "%02X", byteTag)
			
			if (byteTag & TLVClass.LongTag.rawValue) == TLVClass.LongTag.rawValue
			{
				repeat
				{
					data.getBytes(&byteTag, range: NSMakeRange(bytesRead, 1))
					bytesRead++
					string_tag += String(format: "%02X", byteTag)
				}
				while (byteTag & 1<<7 > 0)
			}
			
			node.tagString = string_tag
			
			data.getBytes(&byteLength, range: NSMakeRange(bytesRead, 1))
			bytesRead++
			
			let isLong = byteLength & 1<<7 > 0
			let isConstructed = byteTag & 1<<5 > 0
			
			if isLong
			{
				let lengthBytesCount = Int(byteLength & 0x7F)
				var lengthBytes = [Int8](count: Int(lengthBytesCount), repeatedValue: 0)
				
				if bytesRead + lengthBytesCount > data.length
				{
					return (nil, 0)
				}
				
				data.getBytes(&lengthBytes, range: NSMakeRange(bytesRead, lengthBytesCount))
				bytesRead += lengthBytesCount
				
				for i in 0..<lengthBytesCount
				{
					let byte = lengthBytes[i] << Int8(8 * (lengthBytesCount - i - 1))
					length |= Int(byte)
				}
			}
			else
			{
				length = Int(byteLength)
			}
			
			node.length = length
			
			if data.length == bytesRead
			{
				return (node, bytesRead)
			}
			else if data.length < bytesRead + Int(length)
			{
				return (nil, bytesRead)
			}
			
			if !isConstructed
			{
				node.data = data.subdataWithRange(NSMakeRange(bytesRead, Int(length)))
				bytesRead += Int(length)
			}
			else
			{
				var children = [TLVNode]()
				var bytesReadChildren = 0
				var failedParse = false
				
				while (bytesReadChildren < length) && !failedParse
				{
					let range = NSMakeRange(bytesRead + bytesReadChildren, length - bytesReadChildren)
					let (childNode, bytesReadChild) = TLVNode.constructFromData(data.subdataWithRange(range))
					
					if childNode == nil
					{
						failedParse = true
					}
					else
					{
						children.append(childNode!)
					}
					
					bytesReadChildren += bytesReadChild
				}
				
				if failedParse
				{
					node.data = data.subdataWithRange(NSMakeRange(bytesRead, length))
					bytesRead += length
				}
				else
				{
					bytesRead += bytesReadChildren
					node.children = children
				}
			}
			
			node.nodeData = data
			return (node, bytesRead)
		}
		else
		{
			return (nil, 0)
		}
	}
	
	public func rootNodesWithData(data: NSData) -> [TLVNode]
	{
		var nodes = [TLVNode]()
		var bytesReadTotal = 0
		
		while bytesReadTotal < data.length
		{
			let range = NSMakeRange(bytesReadTotal, data.length - bytesReadTotal)
			let (node, bytesRead) = TLVNode.constructFromData(data.subdataWithRange(range))
			
			if let sNode = node where sNode.tag != TLVClass.EOC.rawValue
			{
				nodes.append(sNode)
			}
			else
			{
				break
			}
			
			bytesReadTotal += bytesRead
		}
		
		return nodes
	}
	
	public func findChildWithTag(tag: TLVClass.RawValue, recursive: Bool = false) -> TLVNode?
	{
		return findChildWithTagString(String(format: "%02X", tag), recursive: recursive)
	}
	
	public func findChildWithTagString(var tag: String, recursive: Bool = false) -> TLVNode?
	{
		var node: TLVNode? = nil
		
		tag = tag.uppercaseString
		
		for child in children
		{
			if let childTag = child.tagString where childTag == tag
			{
				node = child
				break
			}
		}
		
		if node == nil && recursive
		{
			for child in children
			{
				if let grandchild = child.findChildWithTagString(tag, recursive: recursive) where grandchild.tagString == tag
				{
					node = child
					break
				}
			}
		}
		
		return node
	}
	
	func descriptionWithRecursionLevel(level: UInt) -> String
	{
		var childrenDescription = ""
		
		if self.children.count > 0
		{
			childrenDescription = "\n\(NSString.stringWithTabCharacters(level))(\n"
			for child in self.children
			{
				childrenDescription += String(format: "%@%@,\n",
					NSString.stringWithTabCharacters(level + 1),
					child.descriptionWithRecursionLevel(level + 1)
				)
			}
			childrenDescription.replaceRange(childrenDescription.rangefromNSRange(NSMakeRange(childrenDescription.characters.count - 2, 2)), with: "\n")
			childrenDescription += String(format: "%@)", NSString.stringWithTabCharacters(level))
		}
		else
		{
			childrenDescription = "(null)"
		}
		
		let pointerAddress = String(format: "0x%p", unsafeAddressOf(self))
		return "<TLVNode:\(pointerAddress) tag:\(self.tagString) length:\(self.length) bytes:\(self.data ?? "null")) children:\(childrenDescription)>"
	}
}

extension TLVNode : CustomStringConvertible
{
	public var description: String
	{
		return self.descriptionWithRecursionLevel(0)
	}
}

private extension NSString
{
	class func stringWithTabCharacters(tabs: UInt) -> NSString {
		let string = NSMutableString()
		for var i: UInt = 0; i < tabs; i++ {
			string.appendString("\t")
		}
		return string
	}
}

private extension String
{
	func rangefromNSRange(range: NSRange) -> Range<String.Index>
	{
		let startIndex = self.startIndex.advancedBy(range.location)
		let endIndex = startIndex.advancedBy(range.length)
		return Range(start: startIndex, end: endIndex)
	}
}
