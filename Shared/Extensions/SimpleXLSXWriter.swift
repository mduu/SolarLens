internal import Foundation

/// Minimal XLSX file generator. XLSX is a ZIP archive containing XML files.
/// Uses Store (no compression) for simplicity since the files are small.
enum SimpleXLSXWriter {

    struct Cell {
        let column: Int
        let row: Int
        let value: String
        let isNumber: Bool
    }

    /// Creates an XLSX file at the given URL from a grid of cells.
    static func write(cells: [Cell], to url: URL) throws {
        // Collect shared strings (text cells only)
        var sharedStrings: [String] = []
        var stringIndex: [String: Int] = [:]
        for cell in cells where !cell.isNumber {
            if stringIndex[cell.value] == nil {
                stringIndex[cell.value] = sharedStrings.count
                sharedStrings.append(cell.value)
            }
        }

        // Build sheet XML
        let sheetXML = buildSheetXML(cells: cells, stringIndex: stringIndex)
        let sharedStringsXML = buildSharedStringsXML(strings: sharedStrings)

        let files: [(String, Data)] = [
            ("[Content_Types].xml", contentTypesXML.data(using: .utf8)!),
            ("_rels/.rels", relsXML.data(using: .utf8)!),
            ("xl/workbook.xml", workbookXML.data(using: .utf8)!),
            ("xl/_rels/workbook.xml.rels", workbookRelsXML.data(using: .utf8)!),
            ("xl/styles.xml", stylesXML.data(using: .utf8)!),
            ("xl/sharedStrings.xml", sharedStringsXML.data(using: .utf8)!),
            ("xl/worksheets/sheet1.xml", sheetXML.data(using: .utf8)!),
        ]

        let zipData = createZIP(files: files)
        try zipData.write(to: url)
    }

    // MARK: - XML Templates

    private static let contentTypesXML = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
<Default Extension="xml" ContentType="application/xml"/>
<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
<Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>
</Types>
"""

    private static let relsXML = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>
"""

    private static let workbookXML = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
<sheets><sheet name="Data" sheetId="1" r:id="rId1"/></sheets>
</workbook>
"""

    private static let workbookRelsXML = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
<Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>
</Relationships>
"""

    private static let stylesXML = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<fonts count="2">
<font><sz val="11"/><name val="Calibri"/></font>
<font><b/><sz val="11"/><name val="Calibri"/></font>
</fonts>
<fills count="2">
<fill><patternFill patternType="none"/></fill>
<fill><patternFill patternType="gray125"/></fill>
</fills>
<borders count="1"><border/></borders>
<cellStyleXfs count="1"><xf/></cellStyleXfs>
<cellXfs count="2">
<xf fontId="0" fillId="0" borderId="0"/>
<xf fontId="1" fillId="0" borderId="0" applyFont="1"/>
</cellXfs>
</styleSheet>
"""

    // MARK: - Dynamic XML builders

    private static func columnLetter(_ col: Int) -> String {
        var result = ""
        var c = col
        while c >= 0 {
            result = String(UnicodeScalar(65 + c % 26)!) + result
            c = c / 26 - 1
        }
        return result
    }

    private static func buildSheetXML(cells: [Cell], stringIndex: [String: Int]) -> String {
        var rows: [Int: [Cell]] = [:]
        for cell in cells {
            rows[cell.row, default: []].append(cell)
        }

        var xml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
<sheetData>
"""

        for rowNum in rows.keys.sorted() {
            let isHeader = rowNum == 0
            xml += "<row r=\"\(rowNum + 1)\">"
            for cell in rows[rowNum]!.sorted(by: { $0.column < $1.column }) {
                let ref = "\(columnLetter(cell.column))\(cell.row + 1)"
                let style = isHeader ? " s=\"1\"" : ""
                if cell.isNumber {
                    xml += "<c r=\"\(ref)\"\(style)><v>\(cell.value)</v></c>"
                } else {
                    let idx = stringIndex[cell.value]!
                    xml += "<c r=\"\(ref)\" t=\"s\"\(style)><v>\(idx)</v></c>"
                }
            }
            xml += "</row>"
        }

        xml += "</sheetData></worksheet>"
        return xml
    }

    private static func buildSharedStringsXML(strings: [String]) -> String {
        var xml = """
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="\(strings.count)" uniqueCount="\(strings.count)">
"""
        for s in strings {
            let escaped = s
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
            xml += "<si><t>\(escaped)</t></si>"
        }
        xml += "</sst>"
        return xml
    }

    // MARK: - Minimal ZIP writer (Store method, no compression)

    private static func createZIP(files: [(String, Data)]) -> Data {
        var zipData = Data()
        var centralDirectory = Data()

        for (name, content) in files {
            let nameData = name.data(using: .utf8)!
            let crc = crc32(content)
            let offset = UInt32(zipData.count)

            // Local file header
            zipData.appendUInt32(0x04034b50)       // signature
            zipData.appendUInt16(20)                // version needed
            zipData.appendUInt16(0)                 // flags
            zipData.appendUInt16(0)                 // compression: store
            zipData.appendUInt16(0)                 // mod time
            zipData.appendUInt16(0)                 // mod date
            zipData.appendUInt32(crc)               // crc32
            zipData.appendUInt32(UInt32(content.count)) // compressed size
            zipData.appendUInt32(UInt32(content.count)) // uncompressed size
            zipData.appendUInt16(UInt16(nameData.count)) // name length
            zipData.appendUInt16(0)                 // extra length
            zipData.append(nameData)
            zipData.append(content)

            // Central directory entry
            centralDirectory.appendUInt32(0x02014b50) // signature
            centralDirectory.appendUInt16(20)       // version made by
            centralDirectory.appendUInt16(20)       // version needed
            centralDirectory.appendUInt16(0)        // flags
            centralDirectory.appendUInt16(0)        // compression
            centralDirectory.appendUInt16(0)        // mod time
            centralDirectory.appendUInt16(0)        // mod date
            centralDirectory.appendUInt32(crc)
            centralDirectory.appendUInt32(UInt32(content.count))
            centralDirectory.appendUInt32(UInt32(content.count))
            centralDirectory.appendUInt16(UInt16(nameData.count))
            centralDirectory.appendUInt16(0)        // extra length
            centralDirectory.appendUInt16(0)        // comment length
            centralDirectory.appendUInt16(0)        // disk number
            centralDirectory.appendUInt16(0)        // internal attrs
            centralDirectory.appendUInt32(0)        // external attrs
            centralDirectory.appendUInt32(offset)   // offset to local header
            centralDirectory.append(nameData)       // file name
        }

        let centralDirOffset = UInt32(zipData.count)
        zipData.append(centralDirectory)

        // End of central directory
        zipData.appendUInt32(0x06054b50)
        zipData.appendUInt16(0)                     // disk number
        zipData.appendUInt16(0)                     // disk of central dir
        zipData.appendUInt16(UInt16(files.count))   // entries on disk
        zipData.appendUInt16(UInt16(files.count))   // total entries
        zipData.appendUInt32(UInt32(centralDirectory.count))
        zipData.appendUInt32(centralDirOffset)
        zipData.appendUInt16(0)                     // comment length

        return zipData
    }

    private static func crc32(_ data: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFFFFFF
        for byte in data {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ (crc & 1 == 1 ? 0xEDB88320 : 0)
            }
        }
        return crc ^ 0xFFFFFFFF
    }
}

// MARK: - Data helpers for little-endian writes

private extension Data {
    mutating func appendUInt16(_ value: UInt16) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 2))
    }

    mutating func appendUInt32(_ value: UInt32) {
        var v = value.littleEndian
        append(Data(bytes: &v, count: 4))
    }
}
