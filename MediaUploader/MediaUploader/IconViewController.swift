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
        fetchSASTokenURLTask(cdsUserId : self.cdsUserId, showId : self.showId, synchronous: true) { (result) in
            if (result["error"] as? String) != nil {
                // if error occured while fetching SAS Token in background just ignore this
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

class IconViewController: NSViewController {
    
    @objc private dynamic var icons: [Node] = []
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var fetchSASTokenQueue = OperationQueue()
    private var uploadQueue = OperationQueue()

    private var listShows : [String:Any] = [:]
    var cdsUserId : String!
    
    //var pendingFiles : [String: [[String:Any]]] = [:]
    //var pendingUploadDir : [String : String] = [:]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureCollectionView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onLoginSuccessfull(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onNewSASTokenReceived(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.NewSASToken),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onStartUploadShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
            object: nil)
    }
    
    func showId(showName: String) -> String {
        return (self.listShows[showName] as! [String:String])["showId"]!
    }
    
    @objc private func onNewSASTokenReceived(_ notification: Notification) {
        
        let showName  = notification.userInfo?["showName"] as! String
        let sasToken  = notification.userInfo?["sasToken"] as! String
        AppDelegate.cacheSASTokens[showName]=sasToken
    }
    
    @objc private func onLoginSuccessfull(_ notification: NSNotification) {

        cdsUserId  = (notification.userInfo?["cdsUserId"] as! String)
        fetchListShows(cdsUserId : cdsUserId)
    }
    
    private func fetchListShows(cdsUserId: String) {
        fetchListOfShowsTask(cdsUserId : cdsUserId) { (result) in
            
            DispatchQueue.main.async {
                if let error = result["error"] as? String {
                    AppDelegate.retryContext["cdsUserId"] = cdsUserId
                    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchListShows
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : error,
                                                               "disableProgress" : true,
                                                               "enableButton" : OutlineViewController.NameConstants.kRetryStr])
                    return
                }
                self.listShows = result["data"] as! [String : Any]
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
                                                object: nil)
                    
                var contentArray : [Node] = []
                for show in self.listShows {
                    
                    let node = OutlineViewController.fileSystemNode(from: show.key, isFolder: true)
                    node.identifier = self.showId(showName: show.key)
                    contentArray.append(node)
                    
                    /*
                    // disable background fetching of SAS Tokens, fetch SAS Token ONLY on demand
                     
                    let fetchSASTokenOperation = FetchSASTokenOperation(showName: show.key, cdsUserId: self.cdsUserId, showId: self.showId(showName: show.key))
                    self.fetchSASTokenQueue.addOperations([fetchSASTokenOperation], waitUntilFinished: false)
                    */
                }
                
                if contentArray.count != 0 {
                    self.updateIcons(contentArray)
                }
                
                if FileManager.default.fileExists(atPath: LoginViewController.kAzCopyCmdPath) == false {
                    _ = dialogOKCancel(question: "Warning", text: "AzCopy is not found by path \(LoginViewController.kAzCopyCmdPath).\r\nDownload here\r\n \(LoginViewController.kAzCopyCmdDownloadURL) and copy binary 'azcopy' to /Applications folder.")
                }
            }
        }
    }
    
    private func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 105.0, height: 100.0)
        flowLayout.sectionInset = NSEdgeInsets(top: 10.0, left: 10.0, bottom: 10.0, right: 10.0)
        flowLayout.minimumInteritemSpacing = 5.0
        //flowLayout.minimumLineSpacing = 10.0
        collectionView.collectionViewLayout = flowLayout
        // 2
        view.wantsLayer = true
        // 3
        collectionView.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    private func updateIcons(_ data: [Node]) {
        icons = data
        collectionView.reloadData()
    }
    
    
    @objc func onStartUploadShow(_ notification: NSNotification) throws {
        
        let showName = notification.userInfo?["showName"] as! String
        let season = notification.userInfo?["season"] as! (String,String) // name:Id
        let shootDay = notification.userInfo?["shootDay"] as! String
        let blockOrEpisode = notification.userInfo?["blockOrEpisode"] as! (String,String) // name:Id
        let isBlock = notification.userInfo?["isBlock"] as! Bool
        let batch = notification.userInfo?["batch"] as! String
        let unit = notification.userInfo?["unit"] as! String
        let team = notification.userInfo?["team"] as! String
        
        let info = notification.userInfo?["info"] as! String
        let notificationEmail = notification.userInfo?["notificationEmail"] as! String
        let checksum = notification.userInfo?["checksum"] as! String
        let type = notification.userInfo?["type"] as! String
        let files = notification.userInfo?["files"] as! [[String:Any]]
        let srcDir = notification.userInfo?["srcDir"] as! String
        
        
        // template for full path for upload:
        //      [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
        //
        // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW
  
        
        let metadatafolderLayout = "\(season.0)/\(blockOrEpisode.0 as String)/\(shootDay)/\(batch)/\(unit)/"
        let folderLayoutStr = metadatafolderLayout + "\(type)/"
        
        var jsonRecords : [Any] = []
        for item in files {
            for (_, rec) in item {
                var dict = rec as! [String:Any]
                dict["filePath"] = folderLayoutStr + (dict["filePath"]! as! String)
                jsonRecords.append(dict)
            }
        }
        let episodeId = isBlock ? "" : blockOrEpisode.1
        let blockId = isBlock ? blockOrEpisode.1 : ""
        
        let json : [String : Any] = [
            "showId": self.showId(showName: showName),
            "seasonId":season.1,
            "episodeId":episodeId,
            "blockId":blockId,
            "batch":batch,
            "unit":unit,
            "team":team,
            "shootDay":shootDay,
            "info":info,
            "notificationEmail":notificationEmail,
            "checksum":checksum, // TODO: remove checksum from common part
            "files":jsonRecords
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
        var metadataPath : URL!
        let metadataJsonFilename = showName + "_metadata.json"
        
        
        if let metadataJsonPath = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory,
                                                            in: FileManager.SearchPathDomainMask.allDomainsMask).first {
          
            metadataPath = metadataJsonPath.appendingPathComponent(metadataJsonFilename)
            print ("---------------------- ", metadataPath)
            do {
                try jsonData!.write(to: metadataPath)
            } catch let error as NSError {
                print(error)
                // TODO: show Alert
                return
            }
        }
  
        var sasToken : String!
        
        if let sas = AppDelegate.cacheSASTokens[showName] {
            // if SAS Token is already in cache just use it
            sasToken = sas;
        } else {
            fetchSASTokenURLTask(cdsUserId : cdsUserId, showId : self.showId(showName: showName), synchronous: false) { (result) in
                if let error = result["error"] as? String {
                    uploadShowErrorAndNotify(error: error, cdsUserId: self.cdsUserId, showId: self.showId(showName: showName))
                    return
                }
                
                sasToken = result["data"] as? String
                AppDelegate.cacheSASTokens[showName]=sasToken

                self.uploadMetadataJsonOperation(showName: showName,
                                       folderLayoutStr : folderLayoutStr,
                                       sasToken: sasToken,
                                       srcDataPath: srcDir,
                                       srcPath: metadataPath.path,
                                       dstPath:metadatafolderLayout + "metadata.json",
                                       step: FileUploadOperation.Step.kMetadataJsonUpload
                                       )
                }
        }
        
        if sasToken != nil {

            uploadMetadataJsonOperation(showName: showName,
                                   folderLayoutStr : folderLayoutStr,
                                   sasToken: sasToken,
                                   srcDataPath: srcDir,
                                   srcPath: metadataPath.path,
                                   dstPath:metadatafolderLayout + "metadata.json",
                                   step: FileUploadOperation.Step.kMetadataJsonUpload)
        }
    }
    
    func uploadMetadataJsonOperation(showName: String, folderLayoutStr: String, sasToken: String, srcDataPath: String, srcPath: String, dstPath: String, step: FileUploadOperation.Step) {
        
        let sasSplit = sasToken.components(separatedBy: "?")
        let sasTokenWithDestPath = sasSplit[0] + "/" + dstPath + "?" + sasSplit[1]
        
        let uploadRecord = UploadTableRecord(showName: showName, srcPath: srcDataPath, dstPath: folderLayoutStr)
        
        DispatchQueue.main.async {
            let uploadOperation = FileUploadOperation(showName: showName,
                                                      folderLayoutStr: folderLayoutStr,
                                                      sasToken: sasToken,
                                                      step: step,
                                                      uploadRecord : uploadRecord,
                                                      cmd: LoginViewController.kAzCopyCmdPath,
                                                      args: ["copy", srcPath, sasTokenWithDestPath])
            
            uploadOperation.completionBlock = {
                if uploadOperation.isCancelled {
                    return
                }
                
                DispatchQueue.main.async {
                    self.uploadDir(showName: showName, folderLayoutStr: folderLayoutStr, sasToken: sasToken,  uploadRecord: uploadOperation.uploadRecord)
                }
            }
        
            self.uploadQueue.addOperations([uploadOperation], waitUntilFinished: false)
            
            NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.AddUploadTask),
                                            object: nil,
                                            userInfo: ["uploadRecord" : uploadRecord])
        }
    }
    
    func uploadDir(showName: String, folderLayoutStr: String, sasToken: String, uploadRecord : UploadTableRecord) {
        print("------------ upload DIR:", sasToken)
        let dstPath = "/" + folderLayoutStr
        let sasSplit = sasToken.components(separatedBy: "?")
        let sasTokenWithDestPath = sasSplit[0] + dstPath+"?" + sasSplit[1]
        
        
        let uploadOperation = FileUploadOperation(showName: showName,
                                                  folderLayoutStr: folderLayoutStr,
                                                  sasToken: sasToken,
                                                  step: FileUploadOperation.Step.kDataUpload,
                                                  uploadRecord : uploadRecord,
                                                  cmd: LoginViewController.kAzCopyCmdPath,
                                                  args: ["copy", uploadRecord.srcPath, sasTokenWithDestPath, "--recursive"])
        
        self.uploadQueue.addOperations([uploadOperation], waitUntilFinished: false)
    }
    
    func uploadFiles(files: [[String:Any]], showName: String, folderLayoutStr: String, sasToken: String) {
        do {
            for item in files {
                for (filePath, rec) in item {
                    
         
                    let filenameToUpload = folderLayoutStr + (rec as! [String:String])["filePath"]!
                    
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
                    let uploadRecord = UploadTableRecord(showName: showName, srcPath: filePath, dstPath: filenameToUpload)
                    let uploadOperation = FileUploadOperation(showName: showName,
                                                              folderLayoutStr: folderLayoutStr,
                                                              sasToken: sasToken,
                                                              step: FileUploadOperation.Step.kDataUpload,
                                                              uploadRecord : uploadRecord,
                                                              cmd: LoginViewController.kAzCopyCmdPath,
                                                              args: ["copy", filePath, sasTokenWithDestPath])
                    self.uploadQueue.addOperations([uploadOperation], waitUntilFinished: false)
                }
            }
        } catch let error {
            uploadShowErrorAndNotify(error: error, cdsUserId: self.cdsUserId, showId: self.showId(showName: showName))
        }
    }
   
    deinit {
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.NewSASToken),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
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
        
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil,
            userInfo: ["showName" : showName, "showId" : showId, "cdsUserId" : self.cdsUserId!])
    }
    
    internal func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else {return}
        guard let item = collectionView.item(at: indexPath) else {return}
        (item as! CollectionViewItem).setHighlight(selected: false)
    }
    
}
