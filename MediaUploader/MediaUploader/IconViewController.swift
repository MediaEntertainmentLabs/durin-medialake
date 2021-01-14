//
//  IconViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//
import Cocoa

class IconViewController: NSViewController {
    
    @objc private dynamic var icons: [Node] = []
    @IBOutlet weak var collectionView: NSCollectionView!
    
    private var fetchSASTokenQueue = OperationQueue()
    private var uploadQueue = OperationQueue()
    private var listShows : [String:Any] = [:]
    
    struct SectionAttributes {
        var name: String
        var offset: Int  // the index of the first image of this section in the imageFiles array
        var length: Int  // number of images in the section
    }
    
    private var iconSections : [Int:SectionAttributes] = [:]
    private var failedOperations = Set<FileUploadOperation>()
    
    
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
            selector: #selector(onUploadFailed(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.OnUploadFailed),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onStartUploadShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
            object: nil)
    }
    
    func showId(showName: String) -> String {
        guard let show = self.listShows[showName] as? [String:Any] else { return String() }
        return show["showId"] as! String
    }
    
    @objc private func onNewSASTokenReceived(_ notification: Notification) {
        
        let showName  = notification.userInfo?["showName"] as! String
        let sasToken  = notification.userInfo?["sasToken"] as! String
        AppDelegate.cacheSASTokens[showName]=SASToken(showId: self.showId(showName: showName), sasToken: sasToken)
    }
    
    @objc private func onLoginSuccessfull(_ notification: NSNotification) {

        LoginViewController.cdsUserId = LoginViewController.azureUserId!
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                        object: nil,
                                        userInfo: ["progressLabel" : OutlineViewController.NameConstants.kFetchListOfShowsStr])
        
        fetchListShows()
    }
    
    private func fetchApiURLs(apiURL : String) {
        print (" --------------- fetchApiURLs: ", apiURL)
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                        object: nil,
                                        userInfo: ["progressLabel" : OutlineViewController.NameConstants.kFetchListOfShowsStr])
        
        fetchListAPI_URLs(userApiURLs : apiURL) { (result) in
            
            DispatchQueue.main.async {
                if let error = result["error"] as? String {
                    AppDelegate.retryContext["cdsUserId"] = LoginViewController.cdsUserId
                    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchListShows
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : error,
                                                               "disableProgress" : true,
                                                               "enableButton" : OutlineViewController.NameConstants.kRetryStr])
                    return
                }
                for item in result["data"] as! [[String : String]] {
                    for (key,value) in item {
                        LoginViewController.apiUrls[key] = value
                    }
                }
                
                self.fetchListShows()
            }
        }
    }
    
    
    private func fetchListShows() {
        print (" --------------- fetchListShows ")
        
        fetchListOfShowsTask() { (result) in
            
            DispatchQueue.main.async {
                if let error = result["error"] as? String {
                    AppDelegate.retryContext["cdsUserId"] = LoginViewController.cdsUserId
                    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchListShows
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : error,
                                                               "disableProgress" : true,
                                                               "enableButton" : OutlineViewController.NameConstants.kRetryStr])
                    return
                }
                self.listShows = result["data"] as! [String : Any]
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController), object: nil)
                    
                var contentArray : [Node] = []
                var elems : Int = 0
                for show in self.listShows {
                    
                    let node = OutlineViewController.fileSystemNode(from: show.key, isFolder: true)
                    let value = show.value as! [String:Any]
                    node.identifier = value["showId"] as! String
                    node.is_upload_allowed = value["allowed"] as! Bool
                    contentArray.append(node)
                    let studioName = value["studio"] as! String
                    
                
                    var found : Bool = false
                    for (key,value) in self.iconSections {
                        if value.name == studioName {
                            self.iconSections[key]!.length += 1
                            found = true
                            break
                        }
                    }
                    
                    if !found {
                        let attr = SectionAttributes(name: studioName, offset: 0, length: 1)
                        self.iconSections[elems] = attr
                        elems += 1
                    }
                    
                    /*
                    // disable background fetching of SAS Tokens, fetch SAS Token ONLY on demand
                     
                    let fetchSASTokenOperation = FetchSASTokenOperation(showName: show.key, cdsUserId: self.cdsUserId, showId: self.showId(showName: show.key))
                    self.fetchSASTokenQueue.addOperations([fetchSASTokenOperation], waitUntilFinished: false)
                    */
                }
                
                if (self.iconSections.count != 0) {
                    for i in 1 ..< self.iconSections.count {
                        self.iconSections[i]!.offset = self.iconSections[i-1]!.offset + self.iconSections[i-1]!.length
                    }
                }
                
                if contentArray.count != 0 {
                    self.updateIcons(contentArray)
                }
                
                if FileManager.default.fileExists(atPath: LoginViewController.azcopyPath.path) == false {
                    _ = dialogOKCancel(question: "Warning", text: "AzCopy is not found by path \(LoginViewController.azcopyPath.path).")
                }
            }
        }
    }
    
    private func configureCollectionView() {
        // 1
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 105.0, height: 100.0)
        
        flowLayout.sectionInset = NSEdgeInsets(top: 30.0, left: 20.0, bottom: 30.0, right: 20.0)
        
        
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

    @objc func onUploadFailed(_ notification: NSNotification) throws {
        if let op = notification.userInfo?["failedOperation"] as? FileUploadOperation {
            failedOperations.insert(op)
        }
        
        // TODO: implement recovery logic
        
        // There are 3 cases:
        // 1. Fetch SAS Token failed -> No FileUploadOperation being created
        // 2. FileUploadOperation of metadata.json failed
        // 3. FileUploadOperation for data subtasks failed.
        
        // Solution 1 (fast) - All failed FileUploadOperations accumulate into single queue.
        //                     Click on button schedule to retry all items from failedOperations queue one by one.
        
        // Solution 2 - Per each row recovery:
        // case 1: restart upload from the very beginning.
        //         Prerequisites: all input data SHALL be saved to recovery_context object.
        //                        Shall be conncetion between UI row in table and recovery_context object.
        //         Actions: restart onStartUploadShow
        // case 2: restart metadata.json root task, which after completion trigger all its subtasks to run,
        //         so restart possible only for metadata.json and bunch of its subtasks as a whole.
        //         Prerequisites: SHALL be connection between each subtask and root metadata.json task.
        //                        SHALL be connection between UI row in table and each subtask.
        //         Actions: set state = -1.
        // case 3: restart possible for single subtask for individual UI row in table.
        //         Prerequisites: SHALL be connection between UI row in table and each subtask.
        //         Actions: set state = -2.
    }
    
    @objc func onStartUploadShow(_ notification: NSNotification) throws {
        
        let json_main = notification.userInfo?["json_main"] as! [String:String]
        let shootDay = json_main["shootDay"]!
        let batch = json_main["batch"]!
        let unit = json_main["unit"]!
     
        let showName = notification.userInfo?["showName"] as! String
        let season = notification.userInfo?["season"] as! (String,String) // name:Id
        let blockOrEpisode = notification.userInfo?["blockOrEpisode"] as! (String,String) // name:Id
        let isBlock = notification.userInfo?["isBlock"] as! Bool
        guard let files = notification.userInfo?["files"] as? [String:[[String:Any]]] else { return }
        guard let srcDirs = notification.userInfo?["srcDir"] as? [String:String] else { return }
        var pendingUploads = notification.userInfo?["pendingUploads"] as? [String:UploadTableRow]
        
        let keys = [UploadSettingsViewController.kCameraRAWFileType,
                    UploadSettingsViewController.kAudioFileType,
                    UploadSettingsViewController.kCDLFileType,
                    UploadSettingsViewController.kLUTFileType]
        
        // template for full path for upload:
        //      [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
        //
        let metadatafolderLayout = "\(season.0)/\(blockOrEpisode.0 as String)/\(shootDay)/\(batch)/\(unit)/"
        let metadataJsonFilename = NSUUID().uuidString + "_metadata.json"
        

        var sasToken : String!
        
        if (pendingUploads == nil) {
            pendingUploads = [:]
            for type in keys {
                if files[type]?.count == 0 {
                    continue
                }
                
                // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
                let folderLayoutStr = metadatafolderLayout + "\(type)/"
                
                // create UI rows in table before all upload tasks will be created
                let uploadRecord = UploadTableRow(showName: showName, uploadParams: json_main, srcPath: srcDirs[type]!, dstPath: folderLayoutStr)
                pendingUploads![type] = uploadRecord
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.AddUploadTask),
                                                object: nil,
                                                userInfo: ["uploadRecord" : uploadRecord])
            }
        }
        
        let recoveryContext : [String : Any] = ["json_main": json_main,
                                               "showName": showName,
                                               "season": season,
                                               "blockOrEpisode": blockOrEpisode,
                                               "isBlock": isBlock,
                                               "files": files,
                                               "srcDir": srcDirs,
                                               "pendingUploads": pendingUploads!]
        
        if let sas = AppDelegate.cacheSASTokens[showName]?.value() {
            // if SAS Token is already in cache just use it
            sasToken = sas
        } else {
            fetchSASTokenURLTask(showId : self.showId(showName: showName), synchronous: false) { (result) in
                
                if (result["error"] as? String) != nil {
                    uploadShowFetchSASTokenErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, recoveryContext: recoveryContext)
                    return
                }
                
                sasToken = result["data"] as? String
                AppDelegate.cacheSASTokens[showName]=SASToken(showId : self.showId(showName: showName), sasToken: sasToken)
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
                                                object: nil,
                                                userInfo: ["json_main": json_main,
                                                           "showName": showName,
                                                           "season": season,
                                                           "blockOrEpisode": blockOrEpisode,
                                                           "isBlock": isBlock,
                                                           "files": files,
                                                           "srcDir": srcDirs,
                                                           "pendingUploads": pendingUploads!])
            }
        }
        
        // wait for token to aquire in background task
        if sasToken == nil {
            return
        }
        
        var jsonRecords : [Any] = []
        var filesToUpload : [String:String] = [:]
        var dataSubTasks: [FileUploadOperation] = []
        
        for type in keys {
            if files[type]?.count == 0 {
                continue
            }
            
            // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
            let folderLayoutStr = metadatafolderLayout + "\(type)/"

            // metadata.json upload task is root task, all data tasks are subtasks
            // sasToken is unavailable here, will be filled in latter
            let op = self.createUploadDirTask(showName: showName, folderLayoutStr: folderLayoutStr, sasToken: sasToken, uploadRecord: pendingUploads![type]!)
            dataSubTasks.append(op)
          
            
            for item in files[type]! {
                for (key, rec) in item {
                    if let dict = rec as? [String:Any] {
                        if let filePathkey = dict["filePath"] as? String {
                            filesToUpload[filePathkey] = key
                            jsonRecords.append(rec)
                        }
                    }
                }
            }
        }
        
        var json : [String:Any] = json_main
        json["files"] = jsonRecords
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: [.sortedKeys, .prettyPrinted]) else { return }
        
        var metadataPath : URL!
        if let metadataJsonPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .allDomainsMask).first {
            
            metadataPath = metadataJsonPath.appendingPathComponent(metadataJsonFilename)
            print ("---------------------- metadataPath: ", metadataPath!)
            do {
                try jsonData.write(to: metadataPath)
            } catch let error as NSError {
                print(error)
                // TODO: show Alert
                return
            }
        }
        
        if metadataPath == nil { return }
        
        self.uploadMetadataJsonOperation(showName: showName,
                                         sasToken: sasToken,
                                         dataFiles: filesToUpload,
                                         metadataFilePath: metadataPath.path,
                                         dstPath: metadatafolderLayout + "metadata.json",
                                         dependens : dataSubTasks,
                                         recoveryContext : recoveryContext)
    }
    
    
    func uploadMetadataJsonOperation(showName: String,
                                     sasToken: String,
                                     dataFiles: [String:String],
                                     metadataFilePath: String,
                                     dstPath: String,
                                     dependens : [FileUploadOperation],
                                     recoveryContext : [String : Any]) {
        
        let sasSplit = sasToken.components(separatedBy: "?")
        let sasTokenWithDestPath = sasSplit[0] + "/" + dstPath + "?" + sasSplit[1]
        
        // calculate checksum per each file being upload
        let calcChecksumOperation = CalculateChecksumOperation(srcFiles: dataFiles, metadataFilePath : metadataFilePath)
        
        self.uploadQueue.addOperations([calcChecksumOperation], waitUntilFinished: false)
        
        calcChecksumOperation.completionBlock = {
            if calcChecksumOperation.isCancelled {
                return
            }
            if calcChecksumOperation.status != 0 {
                uploadShowFetchSASTokenErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, recoveryContext: recoveryContext)
                return
            }
            DispatchQueue.main.async {
                let uploadOperation = FileUploadOperation(showId: self.showId(showName: showName),
                                                          cdsUserId: LoginViewController.cdsUserId!,
                                                          sasToken: sasToken,
                                                          step: FileUploadOperation.UploadType.kMetadataJsonUpload,
                                                          uploadRecord : nil,
                                                          dependens : dependens,
                                                          args: ["copy", metadataFilePath, sasTokenWithDestPath])
                uploadOperation.completionBlock = {
                    if uploadOperation.isCancelled {
                        return
                    }
                    
                    if (uploadOperation.completionStatus != 0) {
                        uploadShowFetchSASTokenErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, recoveryContext: recoveryContext)
                        return
                    }
                    
                    // WARNING: delay after metadata JSON uploading completed successfully
                    DispatchQueue.main.asyncAfter(deadline: .now() + 20 /* delay 20 secs */) {
                        self.uploadQueue.addOperations(uploadOperation.dependens , waitUntilFinished: false)
                    }
                }
                
                self.uploadQueue.addOperations([uploadOperation], waitUntilFinished: false)
            }
        }
    }
    
    func createUploadDirTask(showName: String, folderLayoutStr: String, sasToken: String, uploadRecord : UploadTableRow) -> FileUploadOperation {
        print("------------ upload DIR:", sasToken)
        
        let dstPath = "/" + folderLayoutStr
        let sasSplit = sasToken.components(separatedBy: "?")
        let sasTokenWithDestPath = sasSplit[0] + dstPath+"?" + sasSplit[1]
        
        
        let uploadOperation = FileUploadOperation(showId: self.showId(showName: showName),
                                                  cdsUserId: LoginViewController.cdsUserId!,
                                                  sasToken: sasToken,
                                                  step: FileUploadOperation.UploadType.kDataUpload,
                                                  uploadRecord : uploadRecord,
                                                  dependens: [],
                                                  args: ["copy", uploadRecord.srcPath, sasTokenWithDestPath, "--recursive", "--put-md5"])
        return uploadOperation
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
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.OnUploadFailed),
            object: nil)
    }
}


extension IconViewController : NSCollectionViewDataSource {
    
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return self.iconSections.count
      }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if (self.iconSections.count == 0) {
            return 0
        }
        
        return self.iconSections[section]!.length
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("CollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? CollectionViewItem else {return item}
        
        let data = icons[self.iconSections[indexPath.section]!.offset + indexPath.item]
        collectionViewItem.node = data

        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader,
                                                        withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "IconViewSectionHeader"),
                                                        for: indexPath) as! IconViewSectionHeader
        view.sectionTitle.stringValue = self.iconSections[indexPath.section]!.name
        return view
    }
}

extension IconViewController : NSCollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> NSSize {
    return NSSize(width: 1000, height: 40)
  }
}




extension IconViewController : NSCollectionViewDelegate {
    
    internal func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else { return }
        guard let item = collectionView.item(at: indexPath) else { return }
        guard let selected = item as? CollectionViewItem else { return }
        selected.setHighlight(selected: true)
        
        guard let node = selected.node else { return }
        
        let showName = node.title
        let showId = self.showId(showName: node.title)
        
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
            object: nil,
            userInfo: ["progressLabel" : OutlineViewController.NameConstants.kFetchShowContentStr])
        
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil,
            userInfo: ["showName" : showName, "showId" : showId])
    }
    
    internal func collectionView(_ collectionView: NSCollectionView, didDeselectItemsAt indexPaths: Set<IndexPath>) {
        guard let indexPath = indexPaths.first else {return}
        guard let item = collectionView.item(at: indexPath) else { return }
        guard let selected = item as? CollectionViewItem else { return }
        selected.setHighlight(selected: false)
    }
    
}
