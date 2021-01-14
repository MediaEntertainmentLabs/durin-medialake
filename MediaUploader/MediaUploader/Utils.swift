//
//  Utils.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

extension String: Error {}

class TreeElement {
    var value: String
    var _children:[TreeElement] = []
    
    init (value: String) {
        self.value = value
    }
    
    init () {
        self.value = String()
    }
    
    func add(_ child: TreeElement) {
        self._children.append(child)
    }
    
    func search(element: String) -> TreeElement? {
        if "\(element)" == "\(self.value)"{
            return self
        }
        
        for child in _children {
            if let result = child.search(element: element){
                return result
            }
        }
        
        return nil
    }
    
    func hasChildren() -> Bool {
        return self._children.count > 0
    }
    
    func children() -> [TreeElement] {
        return self._children
    }
    
    func removeAll() ->Void {
        
    }
}


extension NSMutableAttributedString {

    public func setAsLink(textToFind:String, linkURL:String) -> Bool {

        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
}

func isDarkMode() -> Bool {
    let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
    return mode == "Dark"
}

func dialogOKCancel(question: String, text: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = NSAlert.Style.critical
    alert.addButton(withTitle: "OK")
    return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
}

func showPopoverMessage(positioningView: NSView, msg: String) {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateController(withIdentifier: "popover") as? PopoverViewController
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = vc
    popover.show(relativeTo: positioningView.bounds, of: positioningView, preferredEdge: NSRectEdge.maxY)
    vc?.popoverMessage.stringValue = msg
    return
}

func configURLPath() -> URL? {
    if let localConfigPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        
        do{
            try FileManager.default.createDirectory(atPath: localConfigPath.appendingPathComponent(Bundle.main.bundleIdentifier!).path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        return localConfigPath.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent("config.json")
    }
    return nil
}

extension Data {
    func appendToURL(fileURL: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

func appendConfig(item: [String:String]) {
    guard let configPath = configURLPath() else { return }
    
    do {
        if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys, .prettyPrinted]) {
            try jsonData.appendToURL(fileURL: configPath)
            if let str: Data = "\r\n".data(using: .utf8) {
                try str.appendToURL(fileURL: configPath)
            }
        }
    } catch let error as NSError {
        print(error)
        // TODO: show Alert
        return
    }
}

func writeConfig(item: [String:String]) {
    guard let configPath = configURLPath() else { return }
    
    do {
        if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys, .prettyPrinted]) {
            try jsonData.write(to: configPath)
        }
    } catch let error as NSError {
        print(error)
        // TODO: show Alert
        return
    }
}

func readConfig(key: String) -> String? {
    guard let configPath = configURLPath() else { return nil }
    
    do {
        let data = try Data(contentsOf: configPath, options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
            let apiURL = jsonResult[key] as? String
            return apiURL
        }
    } catch let error as NSError {
        print(error)
        // TODO: show Alert
        return nil
    }
    return nil
}


func removeFile(path: String) {
    do {
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        } else {
            print("File does not exist")
        }
        
    } catch let error as NSError {
        print("An error took place: \(error)")
    }
}
