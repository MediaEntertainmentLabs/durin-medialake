//
//  OutlineViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa
import MSAL


func fetchListOfShowsTask(cdsUserId: String, completion: @escaping (_ shows: [String:Any]) -> Void) {

    let json: [String: String] = ["userId" : cdsUserId]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let url = URL(string: LoginViewController.kFetchShowsURL)!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            guard let data = data, error == nil else {
                throw "Failed to retrive list of shows!"
            }
            var shows : [String:Any] = [:]
            
            let responseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:Any]]
            if responseJSON == nil {
                throw "Failed to retrive list of shows!"
            }
            for item in responseJSON! {
                let media_AssetContainer = item["media_AssetContainer"] as? String
                if media_AssetContainer == nil {
                    continue
                }
                let asset = try JSONSerialization.jsonObject(with: Data(media_AssetContainer!.utf8), options: []) as? [String: Any]
                let showName = asset!["media_name"] as! String
                let showId = asset!["media_assetcontainerid"] as! String
                let media_AssetTemplate = asset!["media_AssetTemplate"] as! [String : Any]
                let media_AssetFolderLayout = media_AssetTemplate["media_AssetFolderLayout"] as! [String : Any]
                shows[showName] = ["showId":showId, "folderLayout":media_AssetFolderLayout["media_layout"]]
            }
            completion(["data": shows])
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}



class OutlineViewController: NSViewController,
                             NSTextFieldDelegate {
    // MARK: Constants

    struct NameConstants {
        static let untitled = NSLocalizedString("untitled string", comment: "")
        static let kShowsStr = NSLocalizedString("shows string", comment: "")
        static let kRetryStr = NSLocalizedString("retry string", comment: "")
        
    }
        
    // The data source backing of the NSOutlineView.
    @IBOutlet weak var treeController: NSTreeController!
    private var iconViewController: IconViewController!
    
#if USE_AZURE_BLOBSTORAGE_API
    private var blobClient: StorageBlobClient?
#endif
    
    // Outline view content top-level content (backed by NSTreeController).
    @objc dynamic var contents: [AnyObject] = []
    
    var sasToken : String!
    var currentShowName:  String!
    var currentShowId: String!
    var cdsUserId: String!
    
    var savedSelection: [IndexPath] = []
    
    var rowToAdd = -1 // A flagged row being added (for later renaming after it was added).
    
    // MARK: XMLParser variables
    let recordKey = "Blob"
    let dictionaryKeys = Set<String>(["Name", "Content-Length"])

    
    // a few variables to hold the results as we parse the XML
    var results: [[String: String]]?           // the whole array of dictionaries
    var currentDictionary: [String: String]? // the current dictionary
    var currentValue: String?                  // the current value for one of the keys in the dictionary
    var root : TreeElement!
    
    var cancelTask : Bool = false

    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupObservers()
    }
    
    private func fetchShowContentTask(sasURI : String, completion: @escaping (_ data: [String:Any]) -> Void) {
        
        let url = URL(string: sasURI)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            do {
                guard let data = data, error == nil else {
                    throw "Failed to retrieve show content!"
                }
                completion(["data" : data])
            } catch let error  {
                completion(["error": error])
            }
        }
        task.resume()
    }

    func addPathToTree(root: TreeElement, fullPath: inout [String])
    {
        if(fullPath.isEmpty) {
            return
        }
        let dirName = fullPath.removeLast()
        if let newRoot = root.search(element: dirName) {
            addPathToTree(root: newRoot, fullPath: &fullPath)
        } else {
            let newRoot = TreeElement(value: dirName)
            root.add(newRoot)
            addPathToTree(root: newRoot, fullPath: &fullPath)
        }
    }
    
    @objc private func onCancelPendingTasks(_ notification: Notification) {
        self.cancelTask = true
    }
    
    static let showID = "1001"
    @objc private func onSelectedShow(_ notification: Notification) {
        
        self.currentShowName = notification.userInfo?["showName"] as? String
        self.currentShowId = notification.userInfo?["showId"] as? String
        self.cdsUserId = notification.userInfo?["cdsUserId"] as? String
        
        fetchShowContent(showName: self.currentShowName, showId: self.currentShowId, cdsUserId: self.cdsUserId)
    }
    
    @IBAction func refreshShowContent(_ sender: Any) {
        if self.currentShowName == nil {
            return
        }
        // update show content
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
            object: nil,
            userInfo: ["progressLabel" : "Fetching show content..."])
        
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil,
            userInfo: ["showName" : self.currentShowName!, "showId": self.currentShowId!, "cdsUserId" : self.cdsUserId!])
    }
    
    
    private func fetchShowContent(showName : String, showId : String, cdsUserId : String) {
        
        var fetchShowContentURI : String!
        if let sasToken = AppDelegate.cacheSASTokens[showName] {
            fetchShowContentURI = sasToken + "&restype=container&comp=list"
        } else {
            fetchSASTokenURLTask(cdsUserId: cdsUserId, showId: showId, synchronous: false) { (result) in
                if let error = result["error"] as? String {
                    uploadShowErrorAndNotify(error: error, cdsUserId: cdsUserId, showId: showId)
                    return
                }
                
                let sasToken = result["data"] as? String
                fetchShowContentURI = sasToken! + "&restype=container&comp=list"
                AppDelegate.cacheSASTokens[showName]=sasToken
                
                NotificationCenter.default.post(
                    name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
                    object: nil,
                    userInfo: ["showName" : showName, "showId" : showId, "cdsUserId" : cdsUserId])
            }
        }
        
        // pending task completion
        if fetchShowContentURI == nil {
            return
        }
        
        self.fetchShowContentTask(sasURI: fetchShowContentURI) { (result) in
            
            if let error = result["error"] as? String {
                fetchShowContentErrorAndNotify(error: error, showName: showName, showId: showId, cdsUserId: cdsUserId)
                return
            }
            let parser = XMLParser(data: result["data"] as! Data)
            parser.delegate = self
            parser.parse()
            
            self.root = nil
            
            if self.results == nil {
                fetchShowContentErrorAndNotify(error: "Failed to retrieve show content!", showName: showName, showId: showId, cdsUserId: cdsUserId)
                return
            }
            
            for item in self.results! as [[String : String]] {
                let components = NSString(string: item["Name"]!).pathComponents
                var reversedComponents : [String] = Array(components.reversed())
                if self.root == nil {
                    //if reversedComponents.count == 1 {
                        self.root = TreeElement(value: showName)
                    //} else {
                    //    self.root = TreeElement(value: reversedComponents.removeLast())
                    //}
                }
                self.addPathToTree(root: self.root, fullPath: &reversedComponents)
            }
  
                // TODO: add cancelation logic
//            if self.cancelTask {
//                DispatchQueue.main.async {
//                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
//                                                    object: nil)
//                }
//                return
//            }
            DispatchQueue.main.async {
                self.addGroupNode(showName, identifier: OutlineViewController.showID)
            }
            if self.root != nil {
                
                let start = DispatchTime.now() // <<<<<<<<<< Start time
                self.addFileSystemObject(root: self.root, isFolder: self.root.hasChildren(), indexPath: IndexPath(indexes: [0, 0]))
                let end = DispatchTime.now()   // <<<<<<<<<<   end time
                let timeInterval_msec = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                
                print ("------------ update OutlineView Tree UI: ", timeInterval_msec, " ms")
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
                                                    object: nil)
                }
                
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : "Show is empty!",
                                                               "disableProgress" : true])
                }
            }
        }
    }
    
    func addFileSystemObject(root: TreeElement, isFolder: Bool, indexPath: IndexPath) {
        if root.hasChildren() {
            let node = OutlineViewController.fileSystemNode(from: root.value, isFolder: true)
            DispatchQueue.main.async {
                if self.cancelTask {
                    //return
                }
                self.treeController.insert(node, atArrangedObjectIndexPath: indexPath)
            }
            
        } else {
            let node = OutlineViewController.leafNode(from: root.value)
            DispatchQueue.main.async {
                if self.cancelTask {
                    //return
                }
                self.treeController.insert(node, atArrangedObjectIndexPath: indexPath)
            }
        }
        
        for child in root.children() {
            let newIndexPath = indexPath
            let finalIndexPath = newIndexPath.appending(0)
            
            addFileSystemObject(root: child, isFolder: root.hasChildren(), indexPath: finalIndexPath)
        }
    }
    
    
    private func addGroupNode(_ folderName: String, identifier: String) {
        let node = Node()
        node.type = .container
        node.title = folderName
        node.identifier = identifier
        node.is_group_node = true
   
        var insertionIndexPath: IndexPath
        treeController.content = nil
        contents.removeAll()
        insertionIndexPath = IndexPath(index: contents.count)
        self.treeController.insert(node, atArrangedObjectIndexPath: insertionIndexPath)
    }
    
    
    
    private func setupObservers() {
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSelectedShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCancelPendingTasks(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
            object: nil)
    }
    
    // MARK: MSALInteractiveDelegate
    
    func didCompleteMSALRequest(withResult result: MSALResult) {
        LoginViewController.account = result.account
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
            object: nil)
    }
}

extension OutlineViewController: XMLParserDelegate {
    
    // initialize results structure
    func parserDidStartDocument(_ parser: XMLParser) {
        results = []
    }
    
    // start element
    //
    // - If we're starting a "record" create the dictionary that will hold the results
    // - If we're starting one of our dictionary keys, initialize `currentValue` (otherwise leave `nil`)
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == recordKey {
            currentDictionary = [:]
        } else if dictionaryKeys.contains(elementName) {
            currentValue = ""
        }
    }
    
    // found characters
    //
    // - If this is an element we care about, append those characters.
    // - If `currentValue` still `nil`, then do nothing.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue? += string
    }
    
    // end element
    //
    // - If we're at the end of the whole dictionary, then save that dictionary in our array
    // - If we're at the end of an element that belongs in the dictionary, then save that value in the dictionary
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == recordKey {
            results!.append(currentDictionary!)
            currentDictionary = nil
        } else if dictionaryKeys.contains(elementName) {
            currentDictionary![elementName] = currentValue
            currentValue = nil
        }
    }
    
    // Just in case, if there an error, report it. (We don't want to fly blind here.)
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
        
        currentValue = nil
        currentDictionary = nil
        results = nil
    }
}
    
#if USE_AZURE_BLOBSTORAGE_API
extension OutlineViewController: StorageBlobClientDelegate {
    func blobClient(_: StorageBlobClient, didUpdateTransfer transfer: BlobTransfer, withState transferState: TransferState, andProgress _: TransferProgress) {
        print("-------- blobClient didUpdateTransfer, transferType: ", transfer.transferType, "withState: ", transferState)
        if transfer.transferType == .upload {
            //collectionView.reloadData()
        }
    }

    func blobClient(_: StorageBlobClient, didCompleteTransfer transfer: BlobTransfer) {
        print("-------- blobClient didCompleteTransfer")
        if transfer.transferType == .upload {
            //collectionView.reloadData()
        }
    }

    func blobClient(_: StorageBlobClient, didFailTransfer _: BlobTransfer, withError error: Error) {
        print("-------- blobClient didFailTransfer")
        self.blobClient?.uploads.removeAll()
    }
}
#endif
