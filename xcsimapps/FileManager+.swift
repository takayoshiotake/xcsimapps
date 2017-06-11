//
//  FileManager+.swift
//
//  Created by OTAKE Takayoshi on 2017/06/11.
//  Copyright © 2017 OTAKE Takayoshi. All rights reserved.
//

import Foundation

extension FileManager {
    func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        self.fileExists(atPath: path, isDirectory: &isDirectory)
        return isDirectory.boolValue
    }
    
    func contentsPathsOfDirectory(atPath path: String) -> [String] {
        guard let contents = try? FileManager.default.contentsOfDirectory(atPath: path) else {
            return []
        }
        return contents.map({ URL.init(string: path)!.appendingPathComponent($0).path })
    }
}
