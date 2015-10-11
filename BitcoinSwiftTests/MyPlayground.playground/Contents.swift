//: Playground - noun: a place where people can play

import UIKit
import BitcoinSwift

let keyBytes: [UInt8] = [
	0x06, 0xF5, 0xE8, 0x1E, 0x2F, 0x6D, 0x7A, 0x80,
	0x9E, 0xFA, 0xB0, 0x1F, 0x6A, 0xEE, 0xB6, 0x3E,
	0xFB, 0x69, 0x78, 0xF2, 0xBD, 0xCF, 0x1A, 0x12,
	0x27, 0x31, 0x42, 0xC3, 0xC6, 0x4E, 0x73, 0x44]

func base58EncodedKey(compressed pCompressed: Bool) -> String
{
	var WIF = [UInt8]()
	
	WIF.append(0xC7)
	WIF.appendContentsOf(keyBytes)
	
	if pCompressed
	{
		WIF.append(0x01)
	}
	
	let WIFData = NSData(bytes: WIF, length: WIF.count).mutableCopy() as! NSMutableData
	let checksum = WIFData.SHA256Hash().SHA256Hash().subdataWithRange(NSMakeRange(0, 4))
	
	WIFData.appendData(checksum)
	
	return WIFData.base58String
}

func __decodeBase58Key(pKey: String, compressed pCompressed: Bool) -> SecureData?
{
	if let lRawData = NSData.fromBase58String(pKey)
	{
		let lCompressedByte = lRawData.subdataWithRange(NSMakeRange(33, 1)).hexString
		
		if pCompressed
		{
			guard lCompressedByte == "01" else
			{
				NSLog("Malformed key: Compression byte does not match!!")
				return nil
			}
		}
		
		let lKeyData = lRawData.subdataWithRange(NSMakeRange(0, pCompressed ? 34 : 33))
		let lRawChecksum = lRawData.subdataWithRange(NSMakeRange(pCompressed ? 34 : 33, 4))
		let lKeyChecksum = lKeyData.SHA256Hash().SHA256Hash().subdataWithRange(NSMakeRange(0, 4))
		
		guard lRawChecksum == lKeyChecksum else
		{
			NSLog("Malformed key: Checksum does not match!!")
			return nil
		}
		
		let lKeyBytes = lRawData.subdataWithRange(NSMakeRange(1, 32))
		
		return SecureData(data: lKeyBytes)
	}
	
	NSLog("Malformed key: Bad base58 format!!")
	return nil
}

base58EncodedKey(compressed: true)
base58EncodedKey(compressed: false)

__decodeBase58Key("WSd1YXoFfTzu43nfiyRbb4LBu1TeEh1whEHa8sUaCtCyxVcNqYWH", compressed: true)?.data
__decodeBase58Key("7ftCuTTnv82LVnVUMPJMXNbhz6YQqsJS5api3EhghJVYUzE1VAM", compressed: false)?.data