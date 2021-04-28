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
    private var listShows : [[String:Any]] = [[:]]
    var currentSelectionIndex : IndexPath!
    var sortedKeys:[String]=[]
    
    struct SectionAttributes {
        var name: String
        var offset: Int  // the index of the first image of this section in the imageFiles array
        var length: Int  // number of images in the section
    }
    var studioDict:[String:[Node]] = [:]
    private var iconSections : [Int:SectionAttributes] = [:]
    private var failedOperations = Set<FileUploadOperation>()
    var uploadSettingsViewController : UploadSettingsViewController!
    
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
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onResumeUploadShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.OnResumeUploadShow),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onPauseUploadShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.OnPauseUploadShow),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onShowUploadSettings(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.ShowUploadSettings),
            object: nil)
 
    }
    
    func showId(showName: String) -> String {
        
        if let index = self.listShows.firstIndex(where: { ($0["showName"] as! String) == showName }) {
            return self.listShows[index]["showId"]as! String
        }
        return String()
    }
    
    @objc func onShowUploadSettings(_ notification: NSNotification) {
        
        let tableRecord = notification.userInfo?["record"] as? UploadTableRow
        
        if uploadSettingsViewController != nil {
            return
        }
        
        uploadSettingsViewController = UploadSettingsViewController()
        
        if currentSelectionIndex != nil {
            guard let item = collectionView.item(at: self.currentSelectionIndex) else { return }
            guard let selected = item as? CollectionViewItem else { return }
            guard let node = selected.node else { return }
            
            uploadSettingsViewController.showId = node.identifier // showId
            uploadSettingsViewController.showName = node.title // showName
        }
        
        if tableRecord != nil {
            uploadSettingsViewController.populated = tableRecord
            uploadSettingsViewController.showId = tableRecord?.uploadParams["showId"] as! String
            uploadSettingsViewController.showName = tableRecord?.showName
            uploadSettingsViewController.dataFromCoredata = true
        }
        
        if currentSelectionIndex == nil && tableRecord == nil {
            return
        }
        
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        guard let uploadSettingsWindowController = storyboard.instantiateController(withIdentifier: "UploadSettingsWindow") as? NSWindowController else { return }
        if let uploadSettingsWindow = uploadSettingsWindowController.window {
            //let application = NSApplication.shared
            //application.runModal(for: downloadWindow)
            uploadSettingsWindow.level = NSWindow.Level.modalPanel
            
            uploadSettingsWindow.contentMinSize = NSSize(width: 650, height: 680)
            uploadSettingsWindow.contentMaxSize = NSSize(width: 1115, height: 1115)
            
            let controller =  NSWindowController(window: uploadSettingsWindow)
            uploadSettingsWindow.contentViewController = uploadSettingsViewController
            controller.showWindow(self)
            
            NotificationCenter.default.addObserver(
                self,
                selector: #selector(resetViewController(_:)),
                name: Notification.Name(WindowViewController.NotificationNames.DismissUploadSettingsDialog),
                object: nil)
        }
    }
    
    @objc func resetViewController(_ sender: Any)
    {
        uploadSettingsViewController = nil
    }
    
    @objc private func onNewSASTokenReceived(_ notification: Notification) {
        
        let showName  = notification.userInfo?["showName"] as! String
        let sasToken  = notification.userInfo?["sasToken"] as! String
        AppDelegate.cacheSASTokens[showName]=SASToken(showId: self.showId(showName: showName), sasToken: sasToken)
    }
    
    @objc private func onLoginSuccessfull(_ notification: NSNotification) {
        
        collectionView.deselectAll(nil)
        icons.removeAll()
        listShows.removeAll()
        iconSections.removeAll()
        currentSelectionIndex = nil
        collectionView.reloadData()
        
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
                
                self.listShows = result["data"] as! [[String : Any]]
                
                self.iconSections.removeAll()
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController), object: nil)
                
                var contentArray : [Node] = []
                var elems : Int = 0
                for value in self.listShows {
                    let studioName = value["studio"] as! String
                    let node = OutlineViewController.fileSystemNode(from: value["showName"] as! String, isFolder: true)
                    node.identifier = value["showId"] as! String
                    node.is_upload_allowed = value["allowed"] as! Bool
                    node.studioName = studioName
                    contentArray.append(node)
                    
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
                
                self.studioDict = Dictionary(grouping: self.icons, by: { $0.studioName})
                var itemDict:[String:[Node]] = [:]
                
                var tempArr : [Node] = []
                
                for (key,value) in self.studioDict {
                    if !value.isEmpty{
                        tempArr = value.sorted(by: { (Obj1, Obj2) -> Bool in
                            let Obj1_Name = Obj1.title
                            let Obj2_Name = Obj2.title
                            return (Obj1_Name.localizedCaseInsensitiveCompare(Obj2_Name ) == .orderedAscending)
                        })
                    }
                    itemDict[key] = tempArr
                }
                // This merge is required to updated Dict w.r.t key sorting
                self.studioDict.merge(itemDict) { (oldValue, newValue) -> [Node] in
                    // This closure return what value to consider if repeated keys are found
                    return newValue
                }
                
                //   self.sortedKeys = Array(itemDict.keys).sorted(by: < )   // For case sensitive
                self.sortedKeys  = Array(itemDict.keys).sorted { $0.localizedStandardCompare($1) == .orderedAscending }   // For case Insensitive
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
        //        if (currentSelectionIndex != nil) {
        //            collectionView.selectItems(at: [currentSelectionIndex], scrollPosition: NSCollectionView.ScrollPosition.top)
        //            setHighlight(indexPath: currentSelectionIndex, select: true)
        //        }
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
        guard let srcDirs = notification.userInfo?["srcDir"] as? [String:[String]] else { return }
        var pendingUploads = notification.userInfo?["pendingUploads"] as? [String:[UploadTableRow]]
        
        // template for full path for upload:
        //      [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
        //
        let metadatafolderLayout = "\(season.0)/\(blockOrEpisode.0 as String)/\(shootDay)/\(batch)/\(unit)/"
        let metadataJsonFilename = NSUUID().uuidString + "_metadata.json"
        let metaDataJSONTime = notification.userInfo?["metaDataJSONTime"] as! String
        
        if (pendingUploads == nil) {
            pendingUploads = [:]
            for (type, value) in srcDirs {
                pendingUploads![type] = []
                for dir in value {
                    // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
                    var folderLayoutStr : String
                    if  type == StringConstant().reportNotesType{
                        folderLayoutStr = metadatafolderLayout + "\(StringConstant().reportNotesFilePath)/"
                    }else{
                        folderLayoutStr = metadatafolderLayout + "\(type)/"
                    }
                    
                    
                    // create UI row in TableView (one per each folder being upload) before all upload tasks will be created
                    let uploadRecord = UploadTableRow(showName: showName, uploadParams: json_main, srcPath: dir, dstPath: folderLayoutStr, isExistRemotely: false,isBlock: isBlock,seasonId: season.1,metaDataJSONTime: metaDataJSONTime)
                    pendingUploads![type]!.append(uploadRecord)
                    
                    writeFile(strToWrite: dir, className: "IconViewController", functionName: "OnstartUploadShow")
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.AddUploadTask),
                                                    object: nil,
                                                    userInfo: ["uploadRecord" : uploadRecord])
                }
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
        
        var sasToken : String!
        
        fetchSASToken(showName: showName, showId: self.showId(showName: showName), synchronous: false) { (result,state) in
            switch state {
            case .pending:
                return
            case .cached:
                sasToken = result
            case .completed:
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
                                                object: nil,
                                                userInfo: ["json_main": json_main,
                                                           "showName": showName,
                                                           "season": season,
                                                           "blockOrEpisode": blockOrEpisode,
                                                           "isBlock": isBlock,
                                                           "files": files,
                                                           "srcDir": srcDirs,
                                                           "pendingUploads": pendingUploads!,
                                                           "metaDataJSONTime":metaDataJSONTime])
            }
        }
        
        // wait for token to aquire in background task
        if sasToken == nil {
            return
        }
        
        var jsonRecords : [Any] = []
        var filesToUpload : [String:String] = [:]
        var dataSubTasks: [FileUploadOperation] = []
        
        for (type, value) in files {
            if value.isEmpty {
                continue
            }
            // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
            var folderLayoutStr : String
            
            if  type == StringConstant().reportNotesType{
                folderLayoutStr = metadatafolderLayout + "\(StringConstant().reportNotesFilePath)/"
            }else{
                folderLayoutStr = metadatafolderLayout + "\(type)/"
            }
            
            // metadata.json upload task is root task, all data tasks are subtasks
            // sasToken is unavailable here, will be filled in latter
            let op = self.createUploadDirTask(showName: showName, folderLayoutStr: folderLayoutStr, sasToken: sasToken, isResume: false, uploadRecords: pendingUploads![type]!)
            dataSubTasks.append(contentsOf: op)
            
            for item in value {    // Item is having array of dictionary
                for (key, rec) in item {
                    if let dict = rec as? [String:Any] {     //Updated by kush
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
        jsonFromDict(from: json)
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
        
        DispatchQueue.global(qos: .background).async {
            
            let checkPathQueue = OperationQueue()
            
            var dialogMessage : String = ""
            var isExistRemotely: Bool = false
            for (type, value) in files {
                if value.isEmpty {
                    continue
                }
                
                for v in pendingUploads![type]! {
                    let pathElements = v.srcPath.components(separatedBy: "/")
                    var tail : String = pathElements.last!
                    if tail.hasSuffix(".") {
                        let rmvDot:String  = removeDot(dirNameArray:pathElements)
                        let rmvDotLastDir = URL(fileURLWithPath: rmvDot).lastPathComponent
                        if(!rmvDotLastDir.isEmpty) {
                            tail = rmvDotLastDir
                        }
                    }
                    print("dst :\(String(describing: "\(v.dstPath)\(tail)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))")
                    if let dst = "\(v.dstPath)\(tail)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
                        let checkPathOperation = CheckPathExistsOperation(showName: showName, showId: self.showId(showName: showName), srcDir: dst) { (result) in
                            if result == true {
                                v.isExistRemotely = result
                                isExistRemotely = true
                                dialogMessage += "\r\n\(v.dstPath)\(tail)"
                            }
                        }
                        checkPathQueue.addOperations([checkPathOperation], waitUntilFinished: false)
                    }
                }
            }
            
            checkPathQueue.waitUntilAllOperationsAreFinished()
            
            // default just fallback to upload step
            var modalResult: NSApplication.ModalResponse = NSApplication.ModalResponse.alertSecondButtonReturn
            
            DispatchQueue.main.async {
                var appendOnly: Bool = false
                // show dilaog only if at least one remote directory exists
                if isExistRemotely {
                    dialogMessage += "\r\n\r\nPlease choose \"\(StringConstant().append)\" or \"\(StringConstant().replace)\" to proceed."
                    modalResult = dialogOverwrite(question:StringConstant().pathExist, text: dialogMessage)
                }
                
                DispatchQueue.global(qos: .background).async {
                    switch modalResult {
                    case NSApplication.ModalResponse.alertFirstButtonReturn:
                        for (type, value) in files {
                            if value.isEmpty {
                                continue
                            }
                            // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
                            let folderLayoutStr = metadatafolderLayout + "\(type)/"
                            
                            let result = self.removeDirTask(showName: showName, folderLayoutStr: folderLayoutStr, sasToken: sasToken, uploadRecords: pendingUploads![type]!)
                            if result == false {
                                uploadShowFetchSASTokenErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, recoveryContext: recoveryContext)
                                return
                            }
                        }
                        // trigger upload operation
                        fallthrough
                        
                    case NSApplication.ModalResponse.alertSecondButtonReturn:
                        appendOnly = true
                        fallthrough
                        
                    default:
                        //let metaDataJSONTime = String(format:"%2X", Int(Date().timeIntervalSince1970 * 1000)) // in millsecs  // updated by kush
                        self.uploadMetadataJsonOperation(showName: showName,
                                                         sasToken: sasToken,
                                                         dataFiles: filesToUpload,
                                                         metadataFilePath: metadataPath.path,
                                                         dstPath: metadatafolderLayout + "\(metaDataJSONTime)_metadata.json",
                                                         dependens : dataSubTasks,
                                                         appendOnly : appendOnly,
                                                         recoveryContext : recoveryContext,
                                                         metaDataTimeStamp:metaDataJSONTime)
                        break
                    }
                }
            }
        }
    }
    
    @objc func onResumeUploadShow(_ notification: NSNotification) throws {
        guard let resumeUpload = notification.userInfo?["resumeUpload"] as? UploadTableRow else { return }
        var sasToken : String!
        
        fetchSASToken(showName: resumeUpload.showName, showId: self.showId(showName: resumeUpload.showName), synchronous: false) { (result,state) in
            switch state {
            case .pending:
                return
            case .cached:
                sasToken = result
            case .completed:
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnResumeUploadShow),
                                                object: nil,
                                                userInfo: ["resumeUpload": resumeUpload])
            }
        }
        
        // async wait for token to aquire in background
        if sasToken == nil {
            return
        }
        
        let uploadOperation = self.createUploadDirTask(showName: resumeUpload.showName, folderLayoutStr: resumeUpload.dstPath, sasToken: sasToken, isResume: true, uploadRecords: [resumeUpload])
        self.uploadQueue.addOperations(uploadOperation, waitUntilFinished: false)
    }
    
    @objc func onPauseUploadShow(_ notification: NSNotification) throws {
        // TODO: not implemented yet
    }
    
    func uploadMetadataJsonOperation(showName: String,
                                     sasToken: String,
                                     dataFiles: [String:String],
                                     metadataFilePath: String,
                                     dstPath: String,
                                     dependens : [FileUploadOperation],
                                     appendOnly: Bool,
                                     recoveryContext : [String : Any],
                                     metaDataTimeStamp:String) {
        
        print("------------ uploadMetadataJsonOperation: metadataFilePath: \(metadataFilePath), dstPath: \(dstPath)")
        
        if appendOnly == true {
            for op in dependens {
                op.args.append("--overwrite=false")
            }
        }
        
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
                                                          args: ["copy", metadataFilePath, sasTokenWithDestPath,"--metadata","source=mac client;FileType=raw file"])
                uploadOperation.completionBlock = {
                    if uploadOperation.isCancelled {
                        return
                    }
                    
                    if (uploadOperation.completionStatus != 0) {
                        uploadShowFetchSASTokenErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, recoveryContext: recoveryContext)
                        return
                    }
                    updateMetaDataPresent(metaDataTimeStamp: metaDataTimeStamp)
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.reloadUploadTableView),
                                                    object: nil,
                                                    userInfo: ["metadataPresent":true,
                                                               "metaDataJSONTime": metaDataTimeStamp,
                                                    ])
                    
                    // WARNING: delay after metadata JSON uploading completed successfully
                    DispatchQueue.main.asyncAfter(deadline: .now() + 10 /* delay 10 secs */) {
                        self.uploadQueue.addOperations(uploadOperation.dependens , waitUntilFinished: false)
                    }
                }
                
                self.uploadQueue.addOperations([uploadOperation], waitUntilFinished: false)
            }
        }
    }
    
    func createUploadDirTask(showName: String, folderLayoutStr: String, sasToken: String, isResume: Bool, uploadRecords : [UploadTableRow]) -> [FileUploadOperation] {
        print("------------ upload DIR:", sasToken)
        
        let dstPath = "/" + folderLayoutStr
        let sasSplit = sasToken.components(separatedBy: "?")
        let sasTokenWithDestPath = sasSplit[0] + dstPath+"?" + sasSplit[1]
        
        var uploadOperations = [FileUploadOperation]()
        for uploadRecord in uploadRecords {
            writeFile(strToWrite: uploadRecord.srcPath, className: "iCONViewController", functionName: "createUploadDirTask")
            var args = ["copy", uploadRecord.srcPath, sasTokenWithDestPath, "--recursive", "--put-md5"]
            if isResume {
                args.append("--overwrite=false")
            }
            args.append("--metadata")
            args.append("source=mac client;FileType=raw file")
            uploadOperations.append(FileUploadOperation(showId: self.showId(showName: showName),
                                                        cdsUserId: LoginViewController.cdsUserId!,
                                                        sasToken: sasToken,
                                                        step: FileUploadOperation.UploadType.kDataUpload,
                                                        uploadRecord : uploadRecord,
                                                        dependens: [],
                                                        args: args))
        }
        return uploadOperations
    }
    
    func removeDirTask(showName: String, folderLayoutStr: String, sasToken: String, uploadRecords : [UploadTableRow]) -> Bool {
        
        let removeQueue = OperationQueue()
        var result: Bool = true
        for uploadRecord in uploadRecords {
            if uploadRecord.isExistRemotely == false {
                continue
            }
            let sasSplit = sasToken.components(separatedBy: "?")
            guard let dstPath = uploadRecord.dstPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)  else { return false }
            guard var srcPath = uploadRecord.srcPath.components(separatedBy: "/").last!.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else { return false }
            
            if srcPath.hasSuffix(".") {
                let rmvDot:String  = removeDot(dirNameArray:uploadRecord.srcPath.components(separatedBy: "/"))
                let rmvDotLastDir = URL(fileURLWithPath: rmvDot).lastPathComponent
                if(!rmvDotLastDir.isEmpty) {
                    srcPath = rmvDotLastDir
                }
            }
            
            let sasTokenWithDestPath = sasSplit[0] + "/\(dstPath)\(srcPath)" + "?" + sasSplit[1]
            
            print("------------ remove DIR:", sasTokenWithDestPath)
            
            writeFile(strToWrite: sasTokenWithDestPath, className: "iCOnViewController", functionName: "removeDirTask")
            
            let removeOperation = FileUploadOperation(showId: self.showId(showName: showName),
                                                      cdsUserId: LoginViewController.cdsUserId!,
                                                      sasToken: sasToken,
                                                      step: FileUploadOperation.UploadType.kDataRemove,
                                                      uploadRecord : uploadRecord,
                                                      dependens: [],
                                                      args: ["rm", sasTokenWithDestPath, "--recursive=true"])
            removeOperation.completionBlock = {
                if removeOperation.isCancelled {
                    return
                }
                
                if (removeOperation.completionStatus != 0) {
                    result = false
                    print("--------- Remove operation failed for ", uploadRecord.dstPath)
                    return
                }
            }
            
            removeQueue.addOperation(removeOperation)
            
        }
        removeQueue.waitUntilAllOperationsAreFinished()
        return result
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
            name: Notification.Name(WindowViewController.NotificationNames.OnResumeUploadShow),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.OnPauseUploadShow),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.OnUploadFailed),
            object: nil)
    }
    
    
    
    @IBAction func onRefreshListShowButtonClick(_ sender: Any) {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull), object: nil)
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ClearShowContent), object: nil)
    }
    
    
    func reUploadMetadataJSON(json_Main:[String:String])
    {
        /*
         let json_main = notification.userInfo?["json_main"] as! [String:String]
         let shootDay = json_main["shootDay"]!
         let batch = json_main["batch"]!
         let unit = json_main["unit"]!
         
         let showName = notification.userInfo?["showName"] as! String
         let season = notification.userInfo?["season"] as! (String,String) // name:Id
         let blockOrEpisode = notification.userInfo?["blockOrEpisode"] as! (String,String) // name:Id
         let isBlock = notification.userInfo?["isBlock"] as! Bool
         guard let files = notification.userInfo?["files"] as? [String:[[String:Any]]] else { return }
         guard let srcDirs = notification.userInfo?["srcDir"] as? [String:[String]] else { return }
         var pendingUploads = notification.userInfo?["pendingUploads"] as? [String:[UploadTableRow]]
         
         // template for full path for upload:
         //      [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
         //
         let metadatafolderLayout = "\(season.0)/\(blockOrEpisode.0 as String)/\(shootDay)/\(batch)/\(unit)/"
         let metadataJsonFilename = NSUUID().uuidString + "_metadata.json"
         let metaDataJSONTime = notification.userInfo?["metaDataJSONTime"] as! String
         
         if (pendingUploads == nil) {
         pendingUploads = [:]
         for (type, value) in srcDirs {
         pendingUploads![type] = []
         for dir in value {
         // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
         var folderLayoutStr : String
         if  type == StringConstant().reportNotesType{
         folderLayoutStr = metadatafolderLayout + "\(StringConstant().reportNotesFilePath)/"
         }else{
         folderLayoutStr = metadatafolderLayout + "\(type)/"
         }
         
         
         // create UI row in TableView (one per each folder being upload) before all upload tasks will be created
         let uploadRecord = UploadTableRow(showName: showName, uploadParams: json_main, srcPath: dir, dstPath: folderLayoutStr, isExistRemotely: false,isBlock: isBlock,seasonId: season.1,metaDataJSONTime: metaDataJSONTime)
         pendingUploads![type]!.append(uploadRecord)
         
         writeFile(strToWrite: dir, className: "IconViewController", functionName: "OnstartUploadShow")
         NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.AddUploadTask),
         object: nil,
         userInfo: ["uploadRecord" : uploadRecord])
         }
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
         
         var sasToken : String!
         
         fetchSASToken(showName: showName, showId: self.showId(showName: showName), synchronous: false) { (result,state) in
         switch state {
         case .pending:
         return
         case .cached:
         sasToken = result
         case .completed:
         NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
         object: nil,
         userInfo: ["json_main": json_main,
         "showName": showName,
         "season": season,
         "blockOrEpisode": blockOrEpisode,
         "isBlock": isBlock,
         "files": files,
         "srcDir": srcDirs,
         "pendingUploads": pendingUploads!,
         "metaDataJSONTime":metaDataJSONTime])
         }
         }
         
         // wait for token to aquire in background task
         if sasToken == nil {
         return
         }
         
         var jsonRecords : [Any] = []
         var filesToUpload : [String:String] = [:]
         var dataSubTasks: [FileUploadOperation] = []
         
         for (type, value) in files {
         if value.isEmpty {
         continue
         }
         // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
         var folderLayoutStr : String
         
         if  type == StringConstant().reportNotesType{
         folderLayoutStr = metadatafolderLayout + "\(StringConstant().reportNotesFilePath)/"
         }else{
         folderLayoutStr = metadatafolderLayout + "\(type)/"
         }
         
         // metadata.json upload task is root task, all data tasks are subtasks
         // sasToken is unavailable here, will be filled in latter
         let op = self.createUploadDirTask(showName: showName, folderLayoutStr: folderLayoutStr, sasToken: sasToken, isResume: false, uploadRecords: pendingUploads![type]!)
         dataSubTasks.append(contentsOf: op)
         
         for item in value {    // Item is having array of dictionary
         for (key, rec) in item {
         if let dict = rec as? [String:Any] {     //Updated by kush
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
         jsonFromDict(from: json)
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
         
         DispatchQueue.global(qos: .background).async {
         
         let checkPathQueue = OperationQueue()
         
         var dialogMessage : String = ""
         var isExistRemotely: Bool = false
         for (type, value) in files {
         if value.isEmpty {
         continue
         }
         
         for v in pendingUploads![type]! {
         let pathElements = v.srcPath.components(separatedBy: "/")
         var tail : String = pathElements.last!
         if tail.hasSuffix(".") {
         let rmvDot:String  = removeDot(dirNameArray:pathElements)
         let rmvDotLastDir = URL(fileURLWithPath: rmvDot).lastPathComponent
         if(!rmvDotLastDir.isEmpty) {
         tail = rmvDotLastDir
         }
         }
         print("dst :\(String(describing: "\(v.dstPath)\(tail)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)))")
         if let dst = "\(v.dstPath)\(tail)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) {
         let checkPathOperation = CheckPathExistsOperation(showName: showName, showId: self.showId(showName: showName), srcDir: dst) { (result) in
         if result == true {
         v.isExistRemotely = result
         isExistRemotely = true
         dialogMessage += "\r\n\(v.dstPath)\(tail)"
         }
         }
         checkPathQueue.addOperations([checkPathOperation], waitUntilFinished: false)
         }
         }
         }
         
         checkPathQueue.waitUntilAllOperationsAreFinished()
         
         // default just fallback to upload step
         var modalResult: NSApplication.ModalResponse = NSApplication.ModalResponse.alertSecondButtonReturn
         
         DispatchQueue.main.async {
         var appendOnly: Bool = false
         // show dilaog only if at least one remote directory exists
         if isExistRemotely {
         dialogMessage += "\r\n\r\nPlease choose \"\(StringConstant().append)\" or \"\(StringConstant().replace)\" to proceed."
         modalResult = dialogOverwrite(question:StringConstant().pathExist, text: dialogMessage)
         }
         
         DispatchQueue.global(qos: .background).async {
         switch modalResult {
         case NSApplication.ModalResponse.alertFirstButtonReturn:
         for (type, value) in files {
         if value.isEmpty {
         continue
         }
         // folderLayoutStr -> [season name]/[block name]/[shootday]/[batch]/[unit ]/[type]
         let folderLayoutStr = metadatafolderLayout + "\(type)/"
         
         let result = self.removeDirTask(showName: showName, folderLayoutStr: folderLayoutStr, sasToken: sasToken, uploadRecords: pendingUploads![type]!)
         if result == false {
         uploadShowFetchSASTokenErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, recoveryContext: recoveryContext)
         return
         }
         }
         // trigger upload operation
         fallthrough
         
         case NSApplication.ModalResponse.alertSecondButtonReturn:
         appendOnly = true
         fallthrough
         
         default:
         //let metaDataJSONTime = String(format:"%2X", Int(Date().timeIntervalSince1970 * 1000)) // in millsecs  // updated by kush
         self.uploadMetadataJsonOperation(showName: showName,
         sasToken: sasToken,
         dataFiles: filesToUpload,
         metadataFilePath: metadataPath.path,
         dstPath: metadatafolderLayout + "\(metaDataJSONTime)_metadata.json",
         dependens : dataSubTasks,
         appendOnly : appendOnly,
         recoveryContext : recoveryContext,
         metaDataTimeStamp:metaDataJSONTime)
         break
         }
         }
         }
         }
         */
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
        let key = sortedKeys[section]
        return self.studioDict[key]?.count ?? 0    // Updated due to Sorting w.r.t. Alphabetically
        //   return self.iconSections[section]!.length
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        
        let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier("CollectionViewItem"), for: indexPath)
        guard let collectionViewItem = item as? CollectionViewItem else {return item}
        //  let data = icons[self.iconSections[indexPath.section]!.offset + indexPath.item]  // Updated due to Sorting w.r.t. Alphabetically
        let key = sortedKeys[indexPath.section]
        let dataNode = self.studioDict[key]?[indexPath.item]
        collectionViewItem.node = dataNode
        
        return item
    }
    
    func collectionView(_ collectionView: NSCollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> NSView {
        
        let view = collectionView.makeSupplementaryView(ofKind: NSCollectionView.elementKindSectionHeader,
                                                        withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "IconViewSectionHeader"),
                                                        for: indexPath) as! IconViewSectionHeader
        //  view.sectionTitle.stringValue = self.iconSections[indexPath.section]!.name
        view.sectionTitle.stringValue = sortedKeys[indexPath.section]   // Updated due to Sorting w.r.t. Alphabetically
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
        setHighlight(indexPath: indexPath, select: true)
        self.currentSelectionIndex = indexPath
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
        
        setHighlight(indexPath: indexPath, select: false)
    }
    
    func setHighlight(indexPath : IndexPath, select: Bool) {
        guard let item = collectionView.item(at: indexPath) else { return }
        guard let selected = item as? CollectionViewItem else { return }
        selected.view.layer?.backgroundColor = select ? NSColor.gray.cgColor : NSColor.clear.cgColor
    }
}
