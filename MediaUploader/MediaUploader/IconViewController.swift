//
//  IconViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//
import Cocoa


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
        fetchSASTokenURLTask(cdsUserId : self.cdsUserId, showId : self.showId, synchronous: false) { (sasToken) in
            NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.NewSASToken),
                                            object: nil,
                                            userInfo: ["showName" : self.showName, "sasToken" : sasToken])
        }
        self.finish()
    }

    override func cancel() {
        super.cancel()
    }
}

private func fetchSASTokenURLTask(cdsUserId : String, showId: String, synchronous: Bool, completion: @escaping (_ sas: String) -> Void) {
    
    let json = ["showId":showId, "userId":cdsUserId]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    // create post request
    let url = URL(string: LoginViewController.kFetchSASTokenURL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    
    // insert json data to the request
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        var sasToken : String!
        
        do {
            
            let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]
            let WebUrl = responseJSON["sas"] as? String
            var data: NSData = WebUrl!.data(using: String.Encoding.utf8)! as NSData
            let WebUrlJSON = try JSONSerialization.jsonObject(with: data as Data) as! [String:Any]
            sasToken = WebUrlJSON["WebUrl"] as? String
            
            if synchronous {
                semaphore.signal()
            }
            
            completion(sasToken)
            
        } catch let error as NSError {
            print(error)
            completion("")
        }
    }
    
    task.resume()
    
    if synchronous {
        _ = semaphore.wait(timeout: .distantFuture)
    }
}

class IconViewController: NSViewController {
    
    @objc private dynamic var icons: [Node] = []
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var fetchSASTokenQueue = OperationQueue()
    private var uploadQueue = OperationQueue()

    private var listSASTokens : [String:String] = [:]
    private var listShows : [String:Any] = [:]
    var cdsUserId : String!
   
    #if ENABLE_UPLOAD_WINDOW
    
    struct IconViewKeys {
        static let keyName = "name"
        static let keyIcon = "icon"
    }
    
    var nodeContent: Node? {
        didSet {
            // Our base node has changed, notify ourselves to update our data source.
            gatherContents(nodeContent!)
        }
    }
    #endif
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fetchListOfShows(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
            object: nil)
        
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(gatherContents2(_:)),
//            name: Notification.Name(WindowViewController.NotificationNames.UpdateShowsIcons),
//            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onNewSASTokenReceived(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.NewSASToken),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(uploadShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.UploadShow),
            object: nil)
    }
    
    func showId(showName: String) -> String
    {
        return (self.listShows[showName] as! [String:String])["showId"]!
    }
    
    @objc private func onNewSASTokenReceived(_ notification: Notification) {
        
        let showName  = notification.userInfo?["showName"] as! String
        let sasToken  = notification.userInfo?["sasToken"] as! String
        self.listSASTokens[showName]=sasToken
    }
    
    @objc private func fetchListOfShows(_ notification: NSNotification) {

        cdsUserId  = (notification.userInfo?["cdsUserId"] as! String)
        
        fetchListOfShowsTask(cdsUserId : cdsUserId) { (shows) in
            
            DispatchQueue.main.async {
                self.listShows = shows
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
                                                object: nil)
                    
                var contentArray : [Node] = []
                for show in shows {
                    
                    let node = OutlineViewController.fileSystemNode(from: show.key, isFolder: true)
                    contentArray.append(node)
                    
                    let fetchSASTokenOperation = FetchSASTokenOperation(showName: show.key,
                                                                        cdsUserId: self.cdsUserId,
                                                                        showId: self.showId(showName: show.key))
                    self.fetchSASTokenQueue.addOperations([fetchSASTokenOperation], waitUntilFinished: false)
                }
                
                self.updateIcons(contentArray)
                
                
                if FileManager.default.fileExists(atPath: LoginViewController.kAzCopyCmdPath) == false {
                    _ = dialogOKCancel(question: "Warning", text: "AzCopy is not found by path \(LoginViewController.kAzCopyCmdPath).\r\nDownload here\r\n \(LoginViewController.kAzCopyCmdDownloadURL) and copy binary 'azcopy' to /Applications folder.")
                }
            }
        }
    }
    
    
    private func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 105.0, height: 60.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        flowLayout.minimumInteritemSpacing = 5.0
        //flowLayout.minimumLineSpacing = 10.0
        collectionView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
        collectionView.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    // The incoming object is the array of file system objects to display.
    private func updateIcons(_ data: [Node]) {
        icons = data
        collectionView.reloadData()
        print ("added" ,data[0].title)
    }
    
    
    @objc func uploadShow(_ notification: NSNotification) throws {
        
        let showName = notification.userInfo?["showName"] as! String
        let shootNumber = notification.userInfo?["shootNumber"] as! String
        let shootDate = notification.userInfo?["shootDate"] as! String
        let info = notification.userInfo?["info"] as! String
        let description = notification.userInfo?["description"] as! String
        let notificationEmail = notification.userInfo?["notificationEmail"] as! String
        let checksum = notification.userInfo?["checksum"] as! String
        let type = notification.userInfo?["type"] as! String
        var files = notification.userInfo?["files"] as! [[String:Any]]
        
        var folderLayoutStr : String
        let folderLayout = (self.listShows[showName] as! [String:String])["folderLayout"]
        if folderLayout == "Date/Type" {
            folderLayoutStr = shootDate + "/" + type + "/"
        } else if folderLayout == "Type/Date" {
            folderLayoutStr = type + "/" + shootDate + "/"
        } else {
            throw "Unsupported folderLayout!"
        }
        
        var jsonRecords : [Any] = []
        for item in files {
            for (fullPath, rec) in item {
                var dict = rec as! [String:String]
                dict["filePath"] = folderLayoutStr + dict["filePath"]!
                jsonRecords.append(dict)
            }
        }
        let json : [String : Any] = [
            "showId":(self.listShows[showName] as! [String:String])["showId"]!,
            "shootNumber":shootNumber,
            "shootDate":shootDate,
            "info":info,
            "description":description,
            "notificationEmail":notificationEmail,
            "checksum":checksum,
            "type":type,
            "files":jsonRecords
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        
        if let metadataJsonPath = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                                            in: FileManager.SearchPathDomainMask.allDomainsMask).first {
          
            let path = metadataJsonPath.appendingPathComponent("metadata.json")
            //metadataJsonPath = URL(fileURLWithPath: path)
            // upload metadata JSON first
            files.insert([path.path : ["jsonPath":"metadata.json", "name":"metadata.json"]], at: 0)
            do {
                try jsonData!.write(to: path)
            } catch let error as NSError {
                print(error)
            }
        }

        var sasToken : String!
        
        if let sas = self.listSASTokens[showName] {
            // now val is not nil and the Optional has been unwrapped, so use it
            sasToken = sas;
        }
        else {
            fetchSASTokenURLTask(cdsUserId : cdsUserId, showId : (self.listShows[showName] as! [String:String])["showId"]!, synchronous: true) { (sas) in
                
                sasToken = sas
            }
        }
        
        DispatchQueue.main.async { [self] in
            
            do {
                for item in files {
                    for (filePath, rec) in item {
                        
                        var filenameToUpload : String!
                        if let val = (rec as! [String:String])["jsonPath"] {
                            filenameToUpload = val
                        }
                        for item in jsonRecords {
                            let dict : [String:String] = item as! [String:String]
                            let toFind : [String:String] = (rec as! [String:String])
                            let isEqual = dict["name"] == toFind["name"]
                            if (isEqual) {
                                filenameToUpload = dict["filePath"]
                            }
                        }
                        let sasSplit = sasToken.components(separatedBy: "?")
                        
                        let sasTokenWithDestPath = sasSplit[0] + "/" + filenameToUpload + "?" + sasSplit[1]
                        print("------- upload SAS:", sasTokenWithDestPath)
                        
                        #if USE_AZURE_BLOBSTORAGE_API
                        let credential = MSALCredential(tenant: LoginViewController.kTenantID,
                                                        clientId: LoginViewController.kClientID,
                                                        authority: URL(string: LoginViewController.kAuthority)!,
                                                        redirectUri: LoginViewController.kRedirectUri,
                                                        account: LoginViewController.currentAccount)
                        
                        //let sasUri = "https://xxxx.blob.core.windows.net/container/path/to/blob?xxxx"
                        ///let sasCredential = StorageSASCredential(staticCredential: sasTokenWithDestPath)
                        //self.blobClient = try StorageBlobClient(endpoint: (URL(string: sasSplit[0])?.deletingLastPathComponent())!, credential: sasCredential)
                        
                        let options = StorageBlobClientOptions(
                            logger: ClientLoggers.none,
                            transportOptions: TransportOptions(timeout: 5.0),
                            restorationId: "MediaUploader"
                        )
                        
                        let properties = BlobProperties(
                            contentType: "application/json; charset=utf-8"
                        )
                        
                        let pathWithFilename = URL(fileURLWithPath: filePath)
                        let sourceUrl = LocalURL(fromAbsoluteUrl: pathWithFilename)
                        
                        //let containerName = "durinmediastorage"
                        let containerName = showName
                        
                        self.blobClient = try StorageBlobClient(endpoint: (URL(string: sasSplit[0])?.deletingLastPathComponent())!)
                        self.blobClient!.delegate = self
                        self.blobClient?.uploads.removeAll()
                        
                        let blobName = filenameToUpload + "?" + sasSplit[1]
                        // don't start a transfer if one has already started
                        guard self.blobClient!.uploads.firstWith(blobName: blobName) == nil else { return }
                        
                        //                    for item in files {
                        //                        for (filePath, rec) in item {
                        //                            let containerName = folderLayoutStr + type
                        //                            try self.blobClient!.upload(
                        //                                    file: sourceUrl,
                        //                                    toContainer: containerName,
                        //                                    asBlob: blobName,
                        //                                    properties: properties)
                        //
                        //                        }
                        //                    }
                        #endif
                        
                        let uploadOperation = FileUploadOperation(cmd: LoginViewController.kAzCopyCmdPath, args: ["copy", filePath, sasTokenWithDestPath])
                        uploadQueue.addOperations([uploadOperation], waitUntilFinished: false)
                    }
                }
            } catch let error as NSError {
                print(error)
            }
        }
    }
    
    #if ENABLE_UPLOAD_WINDOW
    private func gatherContents(_ inObject: Any) {
        autoreleasepool {
            
            var contentArray: [[String: Any]] = []
            
            if inObject is Node {
                // We are populating our collection view from a Node.
                for node in nodeContent!.children {
                    // The node's icon was set to a smaller size before, for this collection view we need to make it bigger.
                    var content: [String: Any] = [IconViewKeys.keyName: node.title]
                    
                    if let icon = node.nodeIcon.copy() as? NSImage {
                        content[IconViewKeys.keyIcon] = icon
                    }

                    contentArray.append(content)
                }
            } else {
                // We are populating our collection view from a file system directory URL.
                if let urlToDirectory = inObject as? URL {
                    do {
                        let fileURLs =
                            try FileManager.default.contentsOfDirectory(at: urlToDirectory,
                                                                        includingPropertiesForKeys: [],
                                                                        options: [])
                        for element in fileURLs {
                            // Only allow visible objects.
                            let isHidden = element.isHidden
                            if !isHidden {
                                let elementNameStr = element.localizedName
                                let elementIcon = element.icon
                                // File system object is visible so add to our content array.
                                contentArray.append([
                                    IconViewKeys.keyIcon: elementIcon,
                                    IconViewKeys.keyName: elementNameStr
                                ])
                            }
                        }
                    } catch _ {}
                }
            }
        }
    }
    #endif
    
    deinit {
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
            object: nil)
//
//        NotificationCenter.default.removeObserver(
//            self,
//            name: Notification.Name(WindowViewController.NotificationNames.UpdateShowsIcons),
//            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.NewSASToken),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.UploadShow),
            object: nil)
        
    }
}


extension IconViewController : NSCollectionViewDataSource {
    
    // 1
    //  func numberOfSectionsInCollectionView(collectionView: NSCollectionView) -> Int {
    //    return imageDirectoryLoader.numberOfSections
    //  }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        return icons.count//imageDirectoryLoader.numberOfItemsInSection(section)
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("CollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? CollectionViewItem else {return item}
        
        let data = icons[indexPath.item]
        collectionViewItem.node = data
        
        //let imageFile = imageDirectoryLoader.imageFileForIndexPath(indexPath)
        //collectionViewItem.imageFile = imageFile
        /*
        for node in icons {
            collectionViewItem.node = node
        }
         */
        return item
    }
}


extension IconViewController : NSCollectionViewDelegate {
    
    internal func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else {return}
        guard let item = collectionView.item(at: indexPath) else {return}
        let selected = item as! CollectionViewItem
        selected.setHighlight(selected: true)
        
        let showName = selected.node!.title
        let showId = self.showId(showName: selected.node!.title)
        
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
            object: nil,
            userInfo: ["progressLabel" : "Fetching show content..."])
        
        if let sasToken = self.listSASTokens[showName] {
            let fetchShowContentURI = sasToken + "&restype=container&comp=list"
            NotificationCenter.default.post(
                name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
                object: nil,
                userInfo: ["showName" : showName, "fetchShowContentURI": fetchShowContentURI])
    

        } else {
            fetchSASTokenURLTask(cdsUserId: self.cdsUserId, showId: showId, synchronous: false) { (sasToken) in
                let fetchShowContentURI = sasToken + "&restype=container&comp=list"
                print("------- fetch show content:", fetchShowContentURI)
                NotificationCenter.default.post(
                    name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
                    object: nil,
                    userInfo: ["showName" : showName, "fetchShowContentURI": fetchShowContentURI])
            }
        }
    }
    
    internal func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else {return}
        guard let item = collectionView.item(at: indexPath) else {return}
        (item as! CollectionViewItem).setHighlight(selected: false)
    }
    
}
