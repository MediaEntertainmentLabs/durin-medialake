//
//  SASToken.swift
//  MediaUploader
//
//  Copyright © 2020 Globallogic. All rights reserved.
//

import Cocoa

class SASToken {
    var sasToken : String?
    let showId : String
    var expireTimer: Timer?
    
    init(showId : String, sasToken: String) {
        self.sasToken = sasToken
        self.showId = showId
        
        DispatchQueue.main.async {
            self.expireTimer = Timer.scheduledTimer(withTimeInterval: 5 * 60 * 60, repeats: true) { timer in
                self.sasToken = nil
                fetchSASTokenURLTask(showId : self.showId, synchronous: false) { (result) in
                    if (result["error"] as? String) != nil {
                        self.sasToken = nil
                        return
                    }
                    
                    self.sasToken = result["data"] as? String
                }
            }
        }
    }
    
    deinit {
        expireTimer!.invalidate()
    }
    
    func valid() -> Bool {
        return sasToken != nil
    }
    
    func value() -> String? {
        return sasToken
    }
}

final class FetchSASTokenOperation: AsyncOperation {

    private let showName: String
    private let cdsUserId: String
    private let showId: String
    
    init(showName: String, cdsUserId: String, showId : String) {
        self.showName = showName
        self.cdsUserId =  cdsUserId
        self.showId = showId
    }

    override func main() {
        fetchSASTokenURLTask(showId : self.showId, synchronous: true) { (result) in
            if (result["error"] as? String) != nil {
                // if error occured while fetching SAS Token in background just ignore it
                return
            }
            
            DispatchQueue.main.async {
                let sasToken = result["data"] as! String
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.NewSASToken),
                                                object: nil,
                                                userInfo: ["showName" : self.showName, "sasToken" : sasToken])
            }
        }
        self.finish()
    }

    override func cancel() {
        super.cancel()
    }
}
