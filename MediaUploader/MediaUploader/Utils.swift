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

func dialogOKCancel(question: String, text: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = NSAlert.Style.critical
    alert.addButton(withTitle: "OK")
    return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
}

func writeConfig(item: [String:String]) {
    let jsonData = try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys, .prettyPrinted])
    var configURLPath : URL!
    if let localConfigPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .allDomainsMask).first {
        
        configURLPath = localConfigPath.appendingPathComponent("config.json")
        do {
            try jsonData!.write(to: configURLPath)
        } catch let error as NSError {
            print(error)
            // TODO: show Alert
            return
        }
    }
}

func readConfig(key: String) -> String? {
    var configURLPath : URL!
    if let localConfigPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .allDomainsMask).first {
        configURLPath = localConfigPath.appendingPathComponent("config.json")
        do {
            let data = try Data(contentsOf: configURLPath, options: .mappedIfSafe)
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
    }
    return nil
}


func removeConfig(path: String) {
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