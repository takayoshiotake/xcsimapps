//
//  Process+.swift
//
//  Created by OTAKE Takayoshi on 2017/06/11.
//  Copyright © 2017 OTAKE Takayoshi. All rights reserved.
//

import Foundation

extension Process {
    static func run(launchPath: String, arguments: [String]?) -> String? {
        let process = Process.init()
        process.launchPath = launchPath
        process.arguments = arguments
        let pipe = Pipe()
        process.standardOutput = pipe
        process.launch()
        guard let output = String.init(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) else {
            return nil
        }
        return output.trimmingCharacters(in: ["\n"])
    }
    
    static func which(program: String) -> String? {
        return run(launchPath: "/usr/bin/which", arguments: [program])
    }
}
