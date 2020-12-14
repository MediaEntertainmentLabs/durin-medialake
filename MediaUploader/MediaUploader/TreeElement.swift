//
//  TreeElement.swift
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


func fetchSASTokenURLTask(cdsUserId : String, showId: String, synchronous: Bool, completion: @escaping (_ result: [String:Any]) -> Void) {
    
    let json = ["showId":showId, "userId":cdsUserId]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let url = URL(string: LoginViewController.kFetchSASTokenURL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            guard let data = data, error == nil else {
                throw "Failed to retrieve SAS Token"
            }
            var sasToken : String!
            
            let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]
            let WebUrl = responseJSON["sas"] as? String
            let webUrlData: Data = (WebUrl!.data(using: String.Encoding.utf8)! as NSData) as Data
            let WebUrlJSON = try JSONSerialization.jsonObject(with: webUrlData) as! [String:Any]
            sasToken = WebUrlJSON["WebUrl"] as? String
            
            completion(["data" : sasToken!])
            
            if synchronous {
                semaphore.signal()
            }
            
        } catch let error {
            completion(["error" : error])
            
            if synchronous {
                semaphore.signal()
            }
        }
    }
    
    task.resume()
    
    if synchronous {
        _ = semaphore.wait(timeout: .distantFuture)
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
