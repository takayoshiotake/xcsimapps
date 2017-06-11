//
//  main.swift
//
//  Created by OTAKE Takayoshi on 2017/06/11.
//  Copyright © 2017 OTAKE Takayoshi. All rights reserved.
//

import Foundation

let CommandName = "xcsimapps"
let CommandVersion = "1.0"

extension Array where Element == XCRun.Device {
    func groupingByDeviceName() -> [String : [XCRun.Device]] {
        return self.reduce([:]) { (accumulating, device) -> [String : [XCRun.Device]] in
            var accumulated = accumulating
            if accumulated[device.name] == nil {
                accumulated[device.name] = []
            }
            accumulated[device.name]!.append(device)
            return accumulated
        }
    }
}

extension Array where Element == XCRun.App {
    func groupingByIdentifier() -> [String : [XCRun.App]] {
        return self.reduce([:]) { (accumulating, app) -> [String : [XCRun.App]] in
            var accumulated = accumulating
            if accumulated[app.identifier] == nil {
                accumulated[app.identifier] = []
            }
            accumulated[app.identifier]!.append(app)
            return accumulated
        }
    }
}


func showHelp() {
    let help = [
        "Usage: \(CommandName) [options] <subcommands> ...",
        "",
        "Options:",
        "   -h, --help  Show this help message and exit",
        "   --version   Show the \(CommandName) version",
        "",
        "Subcommands:",
        "   list        List available apps, devices, runtimes",
        "   data        Show the data container directory path of the app",
    ]
    print(help.joined(separator: "\n"))
}

func showVersion() {
    print("\(CommandName) version \(CommandVersion)")
}

func main(args: [String]) {
    var options = Array.init(args.dropFirst())
    if options.count == 0 {
        showHelp()
        return
    }
    if options[0] == "-h" || options[0] == "--help" {
        showHelp()
        return
    }
    else if options[0] == "--version" {
        showVersion()
        return
    }
    
    guard let xcrun = XCRun.init() else {
        return
    }
    
    let subcommand = options[0]
    options = Array(options.dropFirst())
    if subcommand == "list" {
        let usage = "Usage: \(CommandName) list [-h|--help] [apps|devices|runtimes] ..."
        if options.count == 0 || options[0] == "-h" || options[0] == "--help" {
            print(usage)
            return
        }
        else {
            let type = options[0]
            options = Array(options.dropFirst())
            if false {
            }
            else if type == "runtimes" {
                if options.count > 0 {
                    if options[0] != "-available" {
                        print("Usage: \(CommandName) list runtimes [-available]")
                        return
                    }
                    else {
                        for runtime in xcrun.listSimRuntimes().sorted(by: { $0.0.identifier < $0.1.identifier }) {
                            print("- \"\(runtime.identifier)\":")
                            if let name = runtime.name {
                                print("  - \"name\": \"\(name)\"")
                            }
                            if let buildVersion = runtime.buildVersion {
                                print("  - \"buildVersion\": \"\(buildVersion)\"")
                            }
                        }
                    }
                }
                else {
                    let devices = xcrun.listSimDevices()
                    for runtime in devices.reduce([], { (accumulatig, device) -> [XCRun.Runtime] in
                        var accumulated = accumulatig
                        if !accumulated.contains(device.runtime) {
                            accumulated.append(device.runtime)
                        }
                        return accumulated
                    }).sorted(by: { $0.0.identifier < $0.1.identifier }) {
                        print("- \"\(runtime.identifier)\":")
                        if let name = runtime.name {
                            print("  - \"name\": \"\(name)\"")
                        }
                        if let buildVersion = runtime.buildVersion {
                            print("  - \"buildVersion\": \"\(buildVersion)\"")
                        }
                    }
                }
            }
            else if type == "devices" {
                let usage = "Usage: \(CommandName) list devices [-available]"
                if options.count > 0 {
                    if options[0] != "-available" {
                        print(usage)
                        return
                    }
                }
                var availableOnly = false
                for option in options {
                    if option == "-available" {
                        availableOnly = true
                    }
                    else {
                        print(usage)
                        return
                    }
                }
                
                let groupedDevices = xcrun.listSimDevices().groupingByDeviceName()
                let names = groupedDevices.keys.sorted()
                if availableOnly {
                    let availableRuntimes = xcrun.listSimRuntimes()
                    for name in names {
                        let runtimes = groupedDevices[name]!.filter({ availableRuntimes.contains($0.runtime) }).map({ $0.runtime })
                        if runtimes.count > 0 {
                            print("\"\(name)\":")
                            for device in groupedDevices[name]!.sorted(by: { $0.0.runtime.identifier < $0.1.runtime.identifier }) {
                                guard runtimes.contains(device.runtime) else {
                                    continue
                                }
                                
                                print("  - \"\(device.runtime.name ?? device.runtime.identifier)\": \"\(device.udid)\"")
                            }
                        }
                    }
                }
                else {
                    for name in names {
                        print("\"\(name)\":")
                        for device in groupedDevices[name]!.sorted(by: { $0.0.runtime.identifier < $0.1.runtime.identifier }) {
                            print("  - \"\(device.runtime.name ?? device.runtime.identifier)\": \"\(device.udid)\"")
                        }
                    }
                }
            }
            else if type == "apps" {
                let usage = "Usage: \(CommandName) list apps [-h|--help] [-available] [-a|--app <app-identifier>] [-d|--device <device-name>] [-r|--runtime <runtime>]"
                if options.count > 0 {
                    if options[0] == "-h" || options[0] == "--help" {
                        print(usage)
                        return
                    }
                }
                var availableOnly = false
                var specifiedAppIdentifier: String? = nil
                var specifiedDeviceName: String? = nil
                var specifiedRuntime: String? = nil
                do {
                    var skips: Int = 0
                    for i in 0..<options.count {
                        if skips > 0 {
                            skips -= 1
                            continue
                        }
                        let option = options[i]
                        if option == "-available" {
                            availableOnly = true
                        }
                        else if option == "-a" || option == "--app" {
                            if i == options.count - 1 {
                                print(usage)
                                return
                            }
                            specifiedAppIdentifier = options[i + 1]
                            skips = 1
                        }
                        else if option == "-d" || option == "--device" {
                            if i == options.count - 1 {
                                print(usage)
                                return
                            }
                            specifiedDeviceName = options[i + 1]
                            skips = 1
                        }
                        else if option == "-r" || option == "--runtime" {
                            if i == options.count - 1 {
                                print(usage)
                                return
                            }
                            specifiedRuntime = options[i + 1]
                            skips = 1
                        }
                        else {
                            print(usage)
                            return
                        }
                    }
                }
                
                var apps: [XCRun.App] = []
                for device in xcrun.listSimDevices() {
                    apps.append(contentsOf: xcrun.listApps(of: device))
                }
                var groupedApps = apps.groupingByIdentifier()
                var identifiers = groupedApps.keys.sorted()
                if availableOnly {
                    let availableRuntime = xcrun.listSimRuntimes()
                    identifiers = identifiers.filter({
                        groupedApps[$0]!.filter({
                            availableRuntime.contains($0.device.runtime)
                        }).count > 0
                    })
                }
                if let specifiedAppIdentifier = specifiedAppIdentifier {
                    identifiers = identifiers.filter({ $0 == specifiedAppIdentifier })
                }
                if let specifiedDeviceName = specifiedDeviceName {
                    groupedApps = groupedApps.reduce([:], { (accumulating, item: (key: String, value: [XCRun.App])) -> [String : [XCRun.App]] in
                        var accumulated = accumulating
                        let apps = item.value.filter({ $0.device.name == specifiedDeviceName })
                        if apps.count > 0 {
                            accumulated[item.key] = apps
                        }
                        return accumulated
                    })
                    identifiers = identifiers.filter({ groupedApps[$0] != nil })
                }
                if let specifiedRuntime = specifiedRuntime {
                    groupedApps = groupedApps.reduce([:], { (accumulating, item: (key: String, value: [XCRun.App])) -> [String : [XCRun.App]] in
                        var accumulated = accumulating
                        let apps = item.value.filter({ $0.device.runtime.name == specifiedRuntime })
                        if apps.count > 0 {
                            accumulated[item.key] = apps
                        }
                        return accumulated
                    })
                    identifiers = identifiers.filter({ groupedApps[$0] != nil })
                }

                for identifier in identifiers {
                    print("\"\(identifier)\":")
                    for app in groupedApps[identifier]!.sorted(by: { $0.0.device.runtime.identifier < $0.1.device.runtime.identifier
                    }).sorted(by: { $0.0.device.name < $0.1.device.name
                    }) {
                        print("  - \"device\": \"\(app.device.name)\"")
                        print("    - \"runtime\": \"\(app.device.runtime.name ?? app.device.runtime.identifier)\"")
                        print("    - \"appName\": \"\(app.name)\"")
                        print("    - \"appContainerPath\": \"\(app.appContainerPath)\"")
                        print("    - \"dataContainerPath\": \"\(app.dataContainerPath)\"")
                    }
                }
            }
            else {
                print(usage)
                return
            }
        }
    }
    else if subcommand == "data" {
        let usage = "Usage: \(CommandName) data [-h|--help] -a|--app <app-identifier> -d|--device <device-name> -r|--runtime <runtime>"
        if options.count > 0 {
            if options[0] == "-h" || options[0] == "--help" {
                print(usage)
                return
            }
        }
        
        var specifiedAppIdentifier: String? = nil
        var specifiedDeviceName: String? = nil
        var specifiedRuntime: String? = nil
        do {
            var skips: Int = 0
            for i in 0..<options.count {
                if skips > 0 {
                    skips -= 1
                    continue
                }
                let option = options[i]
                if option == "-a" || option == "--app" {
                    if i == options.count - 1 {
                        print(usage)
                        return
                    }
                    specifiedAppIdentifier = options[i + 1]
                    skips = 1
                }
                else if option == "-d" || option == "--device" {
                    if i == options.count - 1 {
                        print(usage)
                        return
                    }
                    specifiedDeviceName = options[i + 1]
                    skips = 1
                }
                else if option == "-r" || option == "--runtime" {
                    if i == options.count - 1 {
                        print(usage)
                        return
                    }
                    specifiedRuntime = options[i + 1]
                    skips = 1
                }
                else {
                    print(usage)
                    return
                }
            }
        }
        guard let appIdentifier = specifiedAppIdentifier, let deviceName = specifiedDeviceName, let runtime = specifiedRuntime else {
            print(usage)
            return
        }
        
        var apps: [XCRun.App] = []
        for device in xcrun.listSimDevices() {
            apps.append(contentsOf: xcrun.listApps(of: device))
        }
        let filteredApps = apps.filter({ $0.identifier == appIdentifier && $0.device.name == deviceName && ($0.device.runtime.name == runtime || $0.device.runtime.identifier == runtime) })
        if filteredApps.count == 1 {
            print(filteredApps[0].dataContainerPath)
        }
    }
    else {
        showHelp()
        return
    }
}

main(args: CommandLine.arguments)

// TEST
//main(args: [CommandLine.arguments[0], "list"])
//main(args: [CommandLine.arguments[0], "list", "-h"])
//main(args: [CommandLine.arguments[0], "list", "--help"])
//main(args: [CommandLine.arguments[0], "list", "runtimes", "-"])
//main(args: [CommandLine.arguments[0], "list", "runtimes"])
//main(args: [CommandLine.arguments[0], "list", "runtimes", "-available"])
//main(args: [CommandLine.arguments[0], "list", "devices", "-h"])
//main(args: [CommandLine.arguments[0], "list", "devices", "--help"])
//main(args: [CommandLine.arguments[0], "list", "devices"])
//main(args: [CommandLine.arguments[0], "list", "devices", "-available"])
//main(args: [CommandLine.arguments[0], "list", "apps"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-available"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-a", "jp.bigbamboo.Soratama"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-app", "jp.bigbamboo.Soratama"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-d", "iPhone SE"])
//main(args: [CommandLine.arguments[0], "list", "apps", "--device", "iPhone SE"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-r", "iOS 10.3"])
//main(args: [CommandLine.arguments[0], "list", "apps", "--runtie", "iOS 10.3"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-a", "jp.bigbamboo.Soratama", "-d", "iPhone SE"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-a", "jp.bigbamboo.Soratama", "-r", "iOS 10.3"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-d", "iPhone SE", "-r", "iOS 10.3"])
//main(args: [CommandLine.arguments[0], "list", "apps", "-a", "jp.bigbamboo.Soratama", "-d", "iPhone SE", "-r", "iOS 10.3"])
//main(args: [CommandLine.arguments[0], "data", "-a", "jp.bigbamboo.Soratama", "-d", "iPhone SE", "-r", "iOS 10.3"])
//main(args: [CommandLine.arguments[0], "data", "-a", "jp.bigbamboo.Soratama", "-d", "iPhone SE", "-r", "iOS 10.3"])
