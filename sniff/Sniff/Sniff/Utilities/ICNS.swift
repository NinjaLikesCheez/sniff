//
//  ICNS.swift
//  Sniff
//
//  Created by ninji on 24/06/2025.
//
import BinaryParsing
import Foundation

struct ICNS {
	var header: Header
	var icons: [IconData]

	struct Header {
		var magic: UInt32
		var length: UInt32
	}

	struct IconData {
		var iconType: UInt32
		var length: UInt32
		var data: Data
	}
}

extension ICNS {
	static func parse(_ path: URL) throws -> ICNS {
		try ICNS(parsing: try Data(contentsOf: path))
	}
}

extension ICNS: ExpressibleByParsing {
	init(parsing input: inout BinaryParsing.ParserSpan) throws {
		var headerSlice = try input.sliceSpan(byteCount: 8)
		self.header = try Header(parsing: &headerSlice)

		// atm we only care about the first (high quality) image, so just parse the first icon data
		self.icons = [try IconData(parsing: &input)]
	}
}

extension ICNS.Header: ExpressibleByParsing {
	init(parsing input: inout BinaryParsing.ParserSpan) throws {
		self.magic = try UInt32(parsingBigEndian: &input)
		self.length = try UInt32(parsingBigEndian: &input)
	}
}

extension ICNS.IconData: ExpressibleByParsing {
	init(parsing input: inout BinaryParsing.ParserSpan) throws {
		self.iconType = try UInt32(parsingBigEndian: &input)
		self.length = try UInt32(parsingBigEndian: &input)

		let bytes = try Array<UInt8>(parsing: &input, byteCount: Int(length))
		self.data = Data(bytes)
	}
}
