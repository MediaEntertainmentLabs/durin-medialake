//
//  CalculateChecksumOperation.swift
//  MediaUploader
//
//  Copyright © 2020 Globallogic. All rights reserved.
//

import Cocoa
import CommonCrypto
import OSLog

final class CalculateChecksumOperation: AsyncOperation {

    private let srcFiles: [String:String]
    private let metadataFilePath : String
    var status = 0
    
    init(srcFiles: [String:String], metadataFilePath : String) {
        self.srcFiles = srcFiles
        self.metadataFilePath = metadataFilePath
    }

    override func main() {
        var md5_dict : [String:String] = [:]
        for (file,realPath) in srcFiles {
            guard let url = URL(fileURLWithPath: realPath) as URL? else { status = -1; self.finish(); return }
            let md5 = md5File(url: url)
            if md5 == nil {
                continue
            }
            md5_dict[file] = md5
        }

        do {
            let metadataJsonURL = URL(fileURLWithPath: metadataFilePath)
            let json = try String(contentsOfFile: metadataFilePath, encoding: .utf8)
            
            var lines = json.components(separatedBy: .newlines)
            
            for i in 0 ..< lines.count {
                let attributes: [String] =  lines[i].components(separatedBy: ":");
                if attributes.indices.contains(0) && attributes.indices.contains(1) {
                    if let attr0 = attributes[0].trimmingCharacters(in: .whitespacesAndNewlines) as String?,
                       let attr1 = attributes[1].trimmingCharacters(in: .whitespacesAndNewlines) as String? {
                        let filename = attr1.replacingOccurrences(of: "\"", with: "").replacingOccurrences(of: ",", with: "").replacingOccurrences(of: "\\", with: "")
                        if let md5 = md5_dict[filename] {
                            if attr0 == "\"checksum\"" {
                                let replaceLine: String = attributes[0] + " : \"" + md5 + "\","
                                lines[i]=replaceLine
                            }
                        }
                    }
                }
            }
            let result = lines.joined(separator: "\r\n")
            try result.write(to: metadataJsonURL, atomically: true, encoding: .utf8)
            
        } catch let error as NSError {
            os_log("An error took place during calculate checksum ", log: .default, type: .error,error)
        }
        
        self.finish()
    }

    override func cancel() {
        super.cancel()
    }
    
    internal func md5File(url: URL) -> String? {

        let bufferSize = 1024 * 1024

        do {
            let file = try FileHandle(forReadingFrom: url)
            defer {
                file.closeFile()
            }

            // Create and initialize MD5 context:
            var context = CC_MD5_CTX()
            CC_MD5_Init(&context)

            // Read up to `bufferSize` bytes, until EOF is reached, and update MD5 context:
            while autoreleasepool(invoking: {
                let data = file.readData(ofLength: bufferSize)
                if data.count > 0 {
                    data.withUnsafeBytes {
                        _ = CC_MD5_Update(&context, $0.baseAddress, numericCast(data.count))
                    }
                    return true
                } else {
                    return false // EOF
                }
            }) { }

            // Compute the MD5 digest:
            var digest: [UInt8] = Array(repeating: 0, count: Int(CC_MD5_DIGEST_LENGTH))
            _ = CC_MD5_Final(&digest, &context)
            
            let data = Data(digest)
            return data.hexEncodedString(options: .upperCase)

        } catch {
            print("Cannot open file:", error.localizedDescription)
            return nil
        }
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return map { String(format: format, $0) }.joined()
    }
}
