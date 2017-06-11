//
//  XCRun.swift
//
//  Created by OTAKE Takayoshi on 2017/06/11.
//  Copyright © 2017 OTAKE Takayoshi. All rights reserved.
//

import Foundation

class XCRun {
    struct Runtime: Hashable {
        let identifier: String
        let name: String?
        let buildVersion: String?
        
        init(identifier: String) {
            self.init(identifier: identifier, name: nil, buildVersion: nil)
        }
        
        init(identifier: String, name: String?, buildVersion: String?) {
            self.identifier = identifier
            self.name = name
            self.buildVersion = buildVersion
        }
        
        var hashValue: Int {
            return identifier.hashValue
        }
        
        public static func ==(lhs: Runtime, rhs: Runtime) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
    
    struct Device: Hashable {
        let udid: String
        let name: String
        let runtime: Runtime
        
        var hashValue: Int {
            return udid.hashValue
        }
        
        public static func ==(lhs: Device, rhs: Device) -> Bool {
            return lhs.hashValue == rhs.hashValue
        }
    }
    
    let pathofxcrun: String
    
    init?() {
        guard let path = Process.which(program: "xcrun") else {
            return nil
        }
        pathofxcrun = path
    }
    
    func listSimRuntimes() -> [Runtime] {
        guard let output = Process.run(launchPath: pathofxcrun, arguments: ["simctl", "list", "-j", "runtimes"]) else {
            return []
        }
        guard let json = try? JSONSerialization.jsonObject(with: output.data(using: .utf8)!, options: [.mutableContainers]) as! [String:Any] else {
            return []
        }
        guard let runtimes = json["runtimes"] as? [[String : String]] else {
            return []
        }
        return runtimes.map { (runtime: [String : String]) -> Runtime? in
            guard let identifier = runtime["identifier"], let name = runtime["name"], let buildVersion = runtime["buildversion"] else {
                return nil
            }
            return Runtime.init(identifier: identifier, name: name, buildVersion: buildVersion)
            }.filter({ $0 != nil }) as! [Runtime]
    }
    
    func listSimDevices() -> [Device] {
        guard let output = Process.run(launchPath: pathofxcrun, arguments: ["simctl", "list", "-j", "devices"]) else {
            return []
        }
        guard let json = try? JSONSerialization.jsonObject(with: output.data(using: .utf8)!, options: [.mutableContainers]) as! [String:Any] else {
            return []
        }
        guard let allRuntimes = json["devices"] as? [String : [[String : String]]] else {
            return []
        }
        
        let availableRuntimes = listSimRuntimes()
        let devices = allRuntimes.reduce([]) { (accumulating, item: (key: String, value: [[String : String]])) -> [Device] in
            let runtime: Runtime = {
                if let index = availableRuntimes.index(where: { (runtime) -> Bool in
                    return runtime.name == item.key
                }) {
                    return availableRuntimes[index]
                }
                return Runtime.init(identifier: item.key)
            }()
            let devices = item.value.map({ (value: [String : String]) -> Device? in
                guard let udid = value["udid"], let name = value["name"] else {
                    return nil
                }
                return Device.init(udid: udid, name: name, runtime: runtime)
            }).filter({ $0 != nil }) as! [Device]
            
            var accumulated = accumulating
            accumulated.append(contentsOf: devices)
            return accumulated
        }
        return devices
    }
}

//fileprivate let userDevicesPath = "~/Library/Developer/CoreSimulator/Devices"
fileprivate let userDevicesPath = "Library/Developer/CoreSimulator/Devices"
fileprivate let metadataFileName = ".com.apple.mobile_container_manager.metadata.plist"

extension XCRun {
    struct App {
        let identifier: String
        let name: String
        let appContainerPath: String
        let dataContainerPath: String
        let device: Device
    }
    
    func listApps(of device: XCRun.Device) -> [App] {
        struct AppBundle {
            let name: String
            let containerPath: String
        }
        var appBundles: [String : AppBundle] = [:]
        var appDataContainerPaths: [String : String] = [:]
        
        let devicesPath = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(userDevicesPath).path
        do {
            let bundlePath = "\(devicesPath)/\(device.udid)/data/Containers/Bundle/Application"
            guard let bundleContents = try? FileManager.default.contentsOfDirectory(atPath: bundlePath) else {
                return []
            }
            for appContainerPath in bundleContents.map({ URL.init(string: bundlePath)!.appendingPathComponent($0).path
            }) {
                guard let appContents = try? FileManager.default.contentsOfDirectory(atPath: appContainerPath).filter({ $0.hasSuffix(".app") }), appContents.count == 1 else {
                    continue
                }
                let app = appContents[0]
                let appName = app.substring(to: app.index(app.endIndex, offsetBy: -4))
                
                let metadataFilePath = URL.init(string: appContainerPath)!.appendingPathComponent(metadataFileName).path
                guard let metadata = NSDictionary.init(contentsOfFile: metadataFilePath) as? Dictionary<String, Any> else {
                    continue
                }
                guard let identifier = metadata["MCMMetadataIdentifier"] as? String else {
                    continue
                }
                
                appBundles[identifier] = AppBundle.init(name: appName, containerPath: appContainerPath)
            }
        }
        do {
            let dataPath = "\(devicesPath)/\(device.udid)/data/Containers/Data/Application"
            for dataContainerPath in FileManager.default.contentsPathsOfDirectory(atPath: dataPath) {
                let metadataFilePath = URL.init(string: dataContainerPath)!.appendingPathComponent(metadataFileName).path
                guard let metadata = NSDictionary.init(contentsOfFile: metadataFilePath) as? Dictionary<String, Any> else {
                    continue
                }
                guard let identifier = metadata["MCMMetadataIdentifier"] as? String else {
                    continue
                }
                
                appDataContainerPaths[identifier] = dataContainerPath
            }
        }
        
        return appBundles.reduce([], { (accumulating, item: (identifier: String, appBundle: AppBundle)) -> [App] in
            var accumulated = accumulating
            if let dataContainerPath = appDataContainerPaths[item.identifier] {
                accumulated.append(App.init(identifier: item.identifier, name: item.appBundle.name, appContainerPath: item.appBundle.containerPath, dataContainerPath: dataContainerPath, device: device))
            }
            return accumulated
        })
    }
}
