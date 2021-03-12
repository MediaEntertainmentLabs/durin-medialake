//
//  UploadSettingsViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

struct fileInfo {
    var dirPath: String
    var checksum: String
    var filePath: String
    var name: String
    var type: String
    var filesize: UInt64?
    var uniqueID: String
    var aleFileDetail : ALEFileDetails?
}

struct ALEFileDetails {
    var SourceFile: Bool
    var otherSourceFiles: [String]?
    var selectedSourceFilesIndex: Int?
    var selectedSourceFilesName: String?
    var optionExactContains: [String]?
    var optionExactName: String?
    var selectedOptionIndex: Int?
    var charecterFromLeft: Int?
    var charecterFromRight: Int?
}

var aleSelectionViewController : ALESelectionViewController!
class UploadSettingsViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource,FileBrowseDelegate, aleFileUpdatedDelegate {
    
    
    @IBOutlet weak var btnReloadSeason: NSButton!
    @IBOutlet weak var showNameField: NSTextField!
    @IBOutlet weak var shootDayField: NSTextField!
    //@IBOutlet weak var shootDate: NSDatePicker!
    @IBOutlet weak var infoField: NSTextField!
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var filePicker: NSButton!
    @IBOutlet weak var uploadButton: NSButton!
    
    @IBOutlet weak var progressFetch: NSProgressIndicator!
    
    @IBOutlet weak var byEpisodeRadio: NSButton!
    @IBOutlet weak var byBlockRadio: NSButton!
    
    @IBOutlet weak var seasonsCombo: NSComboBox!
    @IBOutlet weak var episodesCombo: NSComboBox!
    @IBOutlet weak var blocksCombo: NSComboBox!
    
    @IBOutlet weak var episodesComboLabel: NSTextField!
    @IBOutlet weak var blocksComboLabel: NSTextField!
    
    
    var radios:[(NSButton, NSComboBox, NSTextField)] = []
    
    @IBOutlet weak var teamPopup: NSPopUpButton!
    @IBOutlet weak var unitPopup: NSPopUpButton!
    @IBOutlet weak var batchPopup: NSPopUpButton!
    
    @IBOutlet weak var tblUploadFiles: NSTableView!
    
    @IBOutlet weak var lblShootDayHint: NSTextField!
    
    // season_name : (season_id, [(episode_name,episode_id)], [(block_name,block_id)], lastShootDay, shootDayFormat)
    typealias SeasonsType = [String:(String, [(String,String)],[(String,String)], String, String)]
    
    var seasons: SeasonsType!
    var lastShootDay: String!
    var shootDayFormat: String!
    
    // reference to a window
    var window: NSWindow?
    
    static let kCameraRAWFileType = "Camera RAW"
    static let kAudioFileType = "Audio"
    static let kLUTFileType = "LUTS"
    static let kCDLFileType = "CDL"
    static let kStillsFileType = "Stills"
    static let kReportsFileType = "Reports"
    static let kOthersFileType = "Others"
    
    static let kReportNotesType = "Reports/Notes"
    
    
    fileprivate let teamItems = ["Camera", "Sound","Scripts","Others"]
    
    fileprivate let unitItems = ["Main Unit", "Second Unit", "Splinter Unit",
                                 "Kelly's Unit & John's Unit", "\"1U\" & \"2U\" & \"3U\""]
    
    fileprivate let batchItems = ["1st Batch", "2nd Batch","Lunch and Wrap"]
    
    var selectedArray:[String] = [kCameraRAWFileType,kLUTFileType,kCDLFileType,kStillsFileType,kReportNotesType]
    var selectedFilePathsArray = [[String:[[String:Any]]]]()
    
    var selectedCameraFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count:5)
    var selectedSoundFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count: 2)
    var selectedScriptsFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count: 1)
    var selectedOthersFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count: 1)
    
    var isAllFileHaveSourceFile = true
    var showId : String!
    var showName : String!
    
    var populated : UploadTableRow! // if we restore from CoreData
    var dataFromCoredata = false
    
    var uploadedFileList: [fileInfo] = []
    var aleSouceFilesArray:[fileInfo] = []
    
    var totalFileStoUpload:[String:[[String:Any]]] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        selectedFilePathsArray = [[String:[[String:Any]]]](repeating:[:], count:selectedArray.count)
        
        radios = [(byEpisodeRadio,episodesCombo,episodesComboLabel),
                  (byBlockRadio,blocksCombo,blocksComboLabel)]
        
        episodesCombo.isHidden = false
        episodesComboLabel.isHidden = false
        byEpisodeRadio.state = NSControl.StateValue(rawValue: 1)
        
        blocksCombo.isHidden = true
        blocksComboLabel.isHidden = true
        
        teamPopup.removeAllItems()
        teamPopup.addItems(withTitles: teamItems)
        if teamPopup.numberOfItems > 0 {
            teamPopup.selectItem(at: 0)
        }
        
        unitPopup.removeAllItems()
        unitPopup.addItems(withTitles: unitItems)
        if unitPopup.numberOfItems > 0 {
            unitPopup.selectItem(at: 0)
        }
        batchPopup.removeAllItems()
        batchPopup.addItems(withTitles: batchItems)
        
        if batchPopup.numberOfItems > 0 {
            batchPopup.selectItem(at: 0)
        }
        
        seasonsCombo.removeAllItems()
        seasonsCombo.isEnabled = false
        progressFetch.isHidden = false
        progressFetch.startAnimation(self)
        
        episodesCombo.removeAllItems()
        episodesCombo.isEnabled = false
        blocksCombo.removeAllItems()
        blocksCombo.isEnabled = false
        
        //emailField.delegate = self
        seasonsCombo.delegate = self
        blocksCombo.delegate = self
        episodesCombo.delegate = self
        
        uploadButton.isEnabled = false
        
        fetchSeasonsAndEpisodes(showId: self.showId)
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
                                        object: nil)
        
        tblUploadFiles.sizeToFit()
        tblUploadFiles.selectionHighlightStyle = .none
        tblUploadFiles.backgroundColor = .clear
        
        shootDayField.delegate = self
        
        if showName != nil {
            showNameField.stringValue = showName
        }
        if(self.dataFromCoredata) {
            populateAfterRestore()
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSignOutClicked(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.logoutItem),
            object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.logoutItem),
            object: nil)
    }
    
    @objc func onSignOutClicked(_ sender: Any) {
        window?.performClose(nil) // nil because I'm not return a message
    }
    
    func populateAfterRestore() {
        
        self.uploadButton.isEnabled = false   // it will enable only fetchAPI success
        guard let populated = self.populated else { return }
        
        if let shootDay = populated.uploadParams["shootDay"] {
            shootDayField.stringValue = shootDay as! String
        }
        
        if let info = populated.uploadParams["info"] {
            infoField.stringValue = info as! String
        }
        
        if let notificationEmail = populated.uploadParams["notificationEmail"] {
            emailField.stringValue = notificationEmail as! String
        }
        
        if let batch = populated.uploadParams["batch"] {
            batchPopup.selectItem(withTitle: batch as! String)
        }
        
        if let unit = populated.uploadParams["unit"] {
            unitPopup.selectItem(withTitle: unit as! String)
        }
        
        if populated.isBlock {
            blocksCombo.isHidden = false
            blocksCombo.isEnabled = blocksCombo.numberOfItems > 0
            blocksComboLabel.isHidden = false
            episodesCombo.isHidden = true
            episodesComboLabel .isHidden = true
            byBlockRadio.state = NSControl.StateValue(rawValue: 1)
            
            if blocksCombo.numberOfItems > 0 {
                blocksCombo.selectItem(at: 0)
            }
            
        } else  {
            episodesCombo.isHidden = false
            episodesCombo.isEnabled = episodesCombo.numberOfItems > 0
            episodesComboLabel .isHidden = false
            blocksCombo.isHidden = true
            blocksComboLabel.isHidden = true
            byEpisodeRadio.state = NSControl.StateValue(rawValue: 1)
            if episodesCombo.numberOfItems > 0 {
                episodesCombo.selectItem(at: 0)
            }
            
        }
        
        if let team = populated.uploadParams["team"] {
            teamPopup.selectItem(withTitle: team as! String)
            popUpSelectionDidChange(teamPopup)
            var str = populated.dstPath
            if str.last == "/" {
                str = String(str.dropLast())
            }
            var selectedDir = str.components(separatedBy: "/").last
            if  selectedDir == StringConstant().reportNotesFilePath {
                selectedDir = StringConstant().reportNotesType
            }
            for i in 0 ..< selectedArray.count where selectedArray[i] == selectedDir {
                
                guard let fileType = deduceFileType(forRow: i) else { return }
                let urlString = populated.srcPath.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                guard let urlDir = URL(string: urlString!) else { return }
                let outputFiles = prepareUploadFiles(fileType: fileType, inputDirs: [urlDir])
                populateSelectedArray(forRow: i, files: outputFiles)
                break
            }
        }
        
    }
    
    override func viewDidAppear() {
        // After a window is displayed, get the handle to the new window.
        window = self.view.window!
        if window != nil {
            window?.center()
        }
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.DismissUploadSettingsDialog),
                                        object: nil)
    }
    
    func extractAllFile(atPath path: String, withExtension fileExtension:String) -> [String] {
        let pathURL = NSURL(fileURLWithPath: path, isDirectory: true)
        var allFiles: [String] = []
        let fileManager = FileManager.default
        let pathString = path.replacingOccurrences(of: "file:", with: "")
        if let enumerator = fileManager.enumerator(atPath: pathString) {
            for file in enumerator {
                if let path = NSURL(fileURLWithPath: file as! String, relativeTo: pathURL as URL).path, path.hasSuffix(".\(fileExtension)"){
                    let fileNameArray = (path as NSString).lastPathComponent.components(separatedBy: ".")
                    allFiles.append(fileNameArray.first!)
                }
            }
        }
        return allFiles
    }
    
    @IBAction func onCliskBlockRadio(_ sender: Any) {
        radios.forEach {
            $0.0.state =  NSControl.StateValue.off
            $0.1.isHidden = true
            $0.2.isHidden = true
        }
        
        (sender as! NSButton).state =  NSControl.StateValue.on
        
        if byEpisodeRadio.state == NSControl.StateValue.on {
            episodesCombo.isHidden = false
            episodesCombo.isEnabled = episodesCombo.numberOfItems > 0
            episodesComboLabel .isHidden = false
            blocksCombo.isHidden = true
            blocksComboLabel.isHidden = true
            byBlockRadio.state = NSControl.StateValue.off
            
        } else if byBlockRadio.state == NSControl.StateValue.on {
            blocksCombo.isHidden = false
            blocksCombo.isEnabled = blocksCombo.numberOfItems > 0
            blocksComboLabel.isHidden = false
            episodesCombo.isHidden = true
            episodesComboLabel .isHidden = true
            byEpisodeRadio.state = NSControl.StateValue.off
        }
    }
    
    // MARK: - FilePickerDialouge
    func filePickerDialog(fileType: String, completion: @escaping (_ result:[String:[[String:Any]]]) -> Void) {
        
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose single directory | Our Code World"
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseFiles          = false
        dialog.canChooseDirectories    = true
        dialog.allowsMultipleSelection = true
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let results = dialog.urls
            
            let outputFiles = prepareUploadFiles(fileType: fileType, inputDirs: results)
            completion(outputFiles)
            
        } else {
            completion([:]) // User clicked on "Cancel"
            return
        }
    }
    
    func prepareUploadFiles(fileType: String, inputDirs: [URL]) -> [String : [[String:Any]]] {
        var outputFiles: [String: [[String:Any]]] = [:]
        
        if fileType.isEmpty {
            return [:]
        }
        
        var fileDirPath = fileType
        if fileType == StringConstant().reportNotesType {
            fileDirPath = StringConstant().reportNotesFilePath
        }
        
        for result in inputDirs {
            
            let pathURL = NSURL(fileURLWithPath: result.path, isDirectory: true)
            var filePaths : [String : UInt64]    = [:]
            
            let enumerator = FileManager.default.enumerator(atPath: result.path)
            while let element = enumerator?.nextObject() as? String {
                let filename = URL(fileURLWithPath: element).lastPathComponent
                if filename == ".DS_Store" {
                    continue
                }
                if let fType = enumerator?.fileAttributes?[FileAttributeKey.type] as? FileAttributeType {
                    
                    switch fType{
                    case .typeRegular:
                        let path = NSURL(fileURLWithPath: element, relativeTo: pathURL as URL).path
                        if let fSize = enumerator?.fileAttributes?[FileAttributeKey.size] as? UInt64 {
                            filePaths[path!]=fSize
                        }
                    case .typeDirectory:
                        break
                    default:
                        continue
                    }
                }
                
            }
            
            let scanItems = filePaths
            var files = [[String:Any]]()
            for scanItem in scanItems {
                let filename = URL(fileURLWithPath: scanItem.key).lastPathComponent
                let filefolder = URL(fileURLWithPath: scanItem.key).deletingLastPathComponent()
                let rmvDot:String  = removeDot(dirNameArray:filefolder.relativeString.components(separatedBy: "/"))
                let rmvDotLastDir = URL(fileURLWithPath: rmvDot).lastPathComponent
                let filePath = rmvDotLastDir+"/"+filename
                let item : [String : Any] = ["name":filename,
                                             "filePath":fileDirPath + "/" + filePath,
                                             "filesize":scanItem.value,
                                             "checksum":fileDirPath + "/" + filePath, //randomString(length: 32),/* will be replaced latter by real checksum value */
                                             "type":fileType]
                files.append([scanItem.key : item])
                
            }
            outputFiles[result.path] = files
        }
        return outputFiles
    }
    
    func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    @IBAction func startUpload(_ sender: Any) {
        
        let dateformat: String = "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateformat
        //let strdate = dateFormatter.string(from: shootDate.dateValue)
        
        // [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
        let season = self.seasonsCombo.selectedCell()!.stringValue as String
        let block = self.blocksCombo.selectedCell()!.stringValue as String
        let episode = self.episodesCombo.selectedCell()!.stringValue as String
        
        var blockOrEpisode : (String,String)!
        
        if byBlockRadio.state == NSControl.StateValue.on {
            if block.isEmpty {
                if(self.blocksCombo.numberOfItems > 0) {
                    showPopoverMessage(positioningView: blocksCombo, msg: "Blocks are not associated with this season")
                    return
                }else{
                    showPopoverMessage(positioningView: blocksCombo, msg: "Blocks are not associated with this season")
                    return
                }
            }
            blockOrEpisode = getBlock(seasonName: season, blockName: block)
        } else {
            if episode.isEmpty {
                if(self.blocksCombo.numberOfItems > 0) {
                    showPopoverMessage(positioningView: episodesCombo, msg: "Episodes are not associated with this season")
                    return
                }else{
                    showPopoverMessage(positioningView: episodesCombo, msg: "Episodes are not associated with this season")
                    return
                }
            }
            blockOrEpisode = getEpisode(seasonName: season, episopeName: episode)
        }
        
        var isEmpty: Bool = true
        for item in selectedFilePathsArray {
            if !item.isEmpty {
                isEmpty = false
                break
            }
        }
        
        if shootDayField.stringValue.isEmpty {
            showPopoverMessage(positioningView: shootDayField, msg:StringConstant().specifyShootDay)
            return
        }
        
        if !shootDayField.stringValue.isStringPatternMatch(withstring: shootDayFormat ?? " ") {
            showPopoverMessage(positioningView: shootDayField, msg:StringConstant().invalidShootday )
            return
        }
        
        
        if !emailField.stringValue.isEmpty && !isValidEmail(emailField.stringValue){
            showPopoverMessage(positioningView: emailField, msg:StringConstant().wrongEmailFormat)
            return
        }
        
        if isEmpty {
            showPopoverMessage(positioningView: teamPopup, msg: StringConstant().specifyPathMedia)
            return
        }
        
        if !checkAllDirPathExist() {
            showPopoverMessage(positioningView: teamPopup, msg: StringConstant().dirPathNotExist)
            return
        }
        
        if blockOrEpisode == nil {
            return
        }
        
        checkAllFilesForSourceName()
        
        if aleSouceFilesArray.isEmpty || isAllFileHaveSourceFile {
            startUploadNonALEFile()
        } else {
            aleSelectionViewController = ALESelectionViewController()
            let storyboard = NSStoryboard(name: "Main", bundle: nil)
            guard let ALESelectionViewController = storyboard.instantiateController(withIdentifier: "ALESelectionWindow") as? NSWindowController else { return }
            if let aleSelectionViewWindow = ALESelectionViewController.window {
                //let application = NSApplication.shared
                //application.runModal(for: downloadWindow)
                aleSelectionViewWindow.level = NSWindow.Level.modalPanel
                
                aleSelectionViewWindow.contentMinSize = NSSize(width: 1200, height: 591)
                aleSelectionViewWindow.contentMaxSize = NSSize(width: 1200, height: 591)
                
                let controller =  NSWindowController(window: aleSelectionViewWindow)
                aleSelectionViewWindow.contentViewController = aleSelectionViewController
                aleSelectionViewController.aleFileDelegate = self
                aleSelectionViewController.setStructDataReference(structDataReference:aleSouceFilesArray)
                controller.showWindow(self)
                
                NotificationCenter.default.addObserver(
                    self,
                    selector: #selector(resetViewController(_:)),
                    name: Notification.Name(WindowViewController.NotificationNames.DismissUploadSettingsDialog),
                    object: nil)
            }
        }
    }
    
    func startUploadNonALEFile ()
    {
        // To DO : Go to Upload files   //KUSH 12 Feb 2021
        let dateformat: String = "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateformat
        //let strdate = dateFormatter.string(from: shootDate.dateValue)
        
        // [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
        let season = self.seasonsCombo.selectedCell()!.stringValue as String
        let block = self.blocksCombo.selectedCell()!.stringValue as String
        let episode = self.episodesCombo.selectedCell()!.stringValue as String
        
        var blockOrEpisode : (String,String)!
        let isBlock : Bool = byBlockRadio.state == NSControl.StateValue.on
        
        if byBlockRadio.state == NSControl.StateValue.on {
            if block.isEmpty {
                if(self.blocksCombo.numberOfItems > 0) {
                    return
                }else{
                    showPopoverMessage(positioningView: blocksCombo, msg: "Blocks are not associated with this season")
                    return
                }
            }
            blockOrEpisode = getBlock(seasonName: season, blockName: block)
        } else {
            if episode.isEmpty {
                if(self.episodesCombo.numberOfItems > 0) {
                    return
                }else{
                    showPopoverMessage(positioningView: episodesCombo, msg: "Episodes are not associated with this season")
                    return
                }
            }
            blockOrEpisode = getEpisode(seasonName: season, episopeName: episode)
        }
        
        if blockOrEpisode == nil {
            return
        }
        
        let episodeId = isBlock ? "" : blockOrEpisode.1
        let blockId = isBlock ? blockOrEpisode.1 : ""
        
        let json_main : [String:String] = [
            "showId": self.showId,
            "seasonId":getSeasonId(seasonName: season),
            "episodeId":episodeId,
            "blockId":blockId,
            "batch":batchPopup.titleOfSelectedItem!,
            "unit":unitPopup.titleOfSelectedItem!,
            "team":teamPopup.titleOfSelectedItem!,
            "shootDay":shootDayField.stringValue,
            "info":infoField.stringValue,
            "notificationEmail":emailField.stringValue,
            "checksum":"md5",
            "season":season,
            "blockOrEpisode":blockOrEpisode.0,
        ]
        
        
        var uploadFiles : [String:[[String:Any]]] = [:]
        var uploadDirs : [String:[String]] = [:]
        
        var miscDict = [String : Any]()
        
        miscDict = defaultMiscDict()
        
        for i in 0 ..< selectedArray.count {
            uploadDirs[selectedArray[i]] = []
            uploadFiles[selectedArray[i]] = []
            for (key, value) in selectedFilePathsArray[i] {
                uploadDirs[selectedArray[i]]?.append(key)
                for f in value {
                    var dictWithDirPath = [String:Any]()
                    for (key, value1) in f {  //key means dir path
                        var fDict:[String:Any]
                        fDict = value1 as! [String : Any]
                        
                        if let fileName = fDict["name"] {
                            let strArray = (fileName as AnyObject).components(separatedBy: ".")
                            if ( strArray.count > 1 ){
                                if(strArray[1] == "ale"){
                                    fDict["checksum"] = fDict["checksum"] as! String
                                    fDict["filePath"] = fDict["filePath"] as! String
                                    fDict["name"] = fDict["name"] as! String
                                    fDict["type"] = fDict["type"] as! String
                                    fDict["filesize"] = (fDict["filesize"] as! UInt64)
                                    fDict["miscInfo"] = miscDict
                                }
                            }
                        }
                        
                        dictWithDirPath[key] = fDict
                    }
                    uploadFiles[selectedArray[i]]?.append(dictWithDirPath)   // Kush
                    
                }
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
                                        object: nil,
                                        userInfo: ["json_main":json_main,
                                                   "showName": self.showNameField.stringValue,
                                                   "season": (season, getSeasonId(seasonName: season)),
                                                   "blockOrEpisode":blockOrEpisode!,
                                                   "isBlock":isBlock,
                                                   "files": uploadFiles,
                                                   "srcDir": uploadDirs,
                                        ])
        window?.performClose(nil) // nil because I'm not return a message
    }
    
    func getSeasonId(seasonName: String) -> String {
        guard let season = self.seasons[seasonName] else { return String("") }
        return season.0
    }
    
    // return array of (episopeName,episodeId)
    func getEpisode(seasonName: String, episopeName: String) -> (String,String) {
        
        for episode in getEpisodes(seasonName: seasonName) {
            if episode.0 == episopeName {
                return episode
            }
        }
        return ("","")
    }
    
    // return array of (episopeName,episodeId)
    func getEpisodes(seasonName: String) -> [(String,String)] {
        guard let episodes = self.seasons[seasonName] else { return [] }
        return episodes.1
    }
    
    // return array of (episopeName,episodeId)
    func getBlock(seasonName: String, blockName: String) -> (String,String) {
        
        for block in getBlocks(seasonName: seasonName) {
            if block.0 == blockName {
                return block
            }
        }
        return ("","")
    }
    
    // return array of (blockName,blockId)
    func getBlocks(seasonName: String) -> [(String,String)] {
        guard let block = self.seasons[seasonName] else { return [] }
        return block.2
    }
    
    private func fetchSeasonsAndEpisodes(showId: String) {
        
        fetchSeasonsAndEpisodesTask(showId : showId) { (result) in
            
            DispatchQueue.main.async { [self] in
                self.progressFetch.isHidden = true
                self.progressFetch.stopAnimation(self)
                self.btnReloadSeason.isHidden = true
                if let error = result["error"] as? String {
                    print(error)
                    self.btnReloadSeason.isHidden = false
                    /*
                     self.seasonsCombo.addItem(withObjectValue: "Failed to fetch seasons")
                     if self.populated != nil {
                     if let season = self.populated.uploadParams["season"] {
                     self.seasonsCombo.selectItem(withObjectValue: season)
                     }
                     } else {
                     self.seasonsCombo.selectItem(at: 0)
                     }
                     */
                    showPopoverMessage(positioningView: self.seasonsCombo, msg: "Failed to fetch seasons. Kindly retry to fetch")
                    AppDelegate.retryContext["showId"] = showId
                    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchSeasonsAndEpisodes
                    return
                }
                
                // "by default" insert first ket from dict
                self.seasons = result["data"] as? SeasonsType
                cleanCombobox(combo: seasonsCombo)
                var selectedSeasonIndex:Int = 0
                var tempIndex:Int = 0
                for (key,_) in self.seasons {
                    
                    if(self.dataFromCoredata){
                        guard let populated = self.populated else { return }
                        guard let seasonName = populated.uploadParams["season"] else { return }
                        if key == seasonName as! String {
                            selectedSeasonIndex = tempIndex
                        }else{
                            tempIndex = +1
                        }
                    }
                    self.seasonsCombo.addItem(withObjectValue: key)
                    self.seasonsCombo.isEnabled = true
                    self.uploadButton.isEnabled = true
                }
                
                if self.seasonsCombo.numberOfItems > 0 {
                    self.seasonsCombo.selectItem(at: selectedSeasonIndex)
                }
            }
        }
    }
    
    func cleanCombobox(combo : NSComboBox) {
        if (combo.numberOfItems != 0) {
            combo.removeAllItems()
            combo.deselectItem(at:0)
        }
    }
    
    func populateComoboxes(seasonName : String) {
        guard seasons != nil else { return }
        
        if let values = seasons[seasonName] {
            
            self.lastShootDay  = values.3
            self.shootDayFormat = values.4   // value.2 = Blocks array of dict ; value.1 = Episode array of dict
            
            if let myValue = shootDayFormat as NSString?  {
                lblShootDayHint.isHidden = false;
                if let strLastShootDay = lastShootDay as NSString? {
                    lblShootDayHint.stringValue = "Supported format: \(myValue), Last uploaded shoot day: \(strLastShootDay)"
                } else {
                    lblShootDayHint.stringValue = "Supported format: \(myValue)"
                }
            } else {
                lblShootDayHint.isHidden = true
            }
            
            cleanCombobox(combo: episodesCombo)
            cleanCombobox(combo: blocksCombo)
            var selectedEpisodeIndex :Int = 0
            var tempEpisodeIndex :Int = 0
            if (values.1.count != 0) {
                episodesCombo.isHidden = !(byEpisodeRadio.state == NSControl.StateValue.on)
                episodesCombo.isEnabled = !episodesCombo.isHidden
                for item in values.1 {
                    if(self.dataFromCoredata ){
                        guard let populated = self.populated else { return }
                        guard let blockOrEpisode = populated.uploadParams["blockOrEpisode"] else { return }
                        
                        if item.0 == blockOrEpisode as! String {
                            selectedEpisodeIndex =  tempEpisodeIndex
                        }else{
                            tempEpisodeIndex = +1
                        }
                    }
                    episodesCombo.addItem(withObjectValue: item.0)
                }
                
                if episodesCombo.numberOfItems > 0 {
                    episodesCombo.selectItem(at: selectedEpisodeIndex)
                }
            } else {
                episodesCombo.isEnabled = false
            }
            
            if (values.2.count != 0) {
                blocksCombo.isHidden = !(byBlockRadio.state == NSControl.StateValue.on)
                blocksCombo.isEnabled = !blocksCombo.isHidden
                var selectedBlockIndex :Int = 0
                var tempBlockIndex :Int = 0
                
                for item in values.2 {
                    
                    if(self.dataFromCoredata){
                        guard let populated = self.populated else { return }
                        guard let blockOrEpisode = populated.uploadParams["blockOrEpisode"] else { return }
                        if item.0 == blockOrEpisode as! String {
                            selectedBlockIndex =  tempBlockIndex
                        }else{
                            tempBlockIndex = +1
                        }
                    }
                    blocksCombo.addItem(withObjectValue: item.0)
                    
                }
                if blocksCombo.numberOfItems > 0 {
                    blocksCombo.selectItem(at: selectedBlockIndex)
                }
            } else {
                blocksCombo.isEnabled = false
            }
            
            if(dataFromCoredata){
                if populated.isBlock {
                    blocksCombo.isHidden = false
                    blocksCombo.isEnabled = blocksCombo.numberOfItems > 0
                    blocksComboLabel.isHidden = false
                    episodesCombo.isHidden = true
                    episodesComboLabel .isHidden = true
                } else  {
                    episodesCombo.isHidden = false
                    episodesCombo.isEnabled = episodesCombo.numberOfItems > 0
                    episodesComboLabel .isHidden = false
                    blocksCombo.isHidden = true
                    blocksComboLabel.isHidden = true
                    
                }
            }
        }
    }
    
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return selectedArray.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let uploadCell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "uploadCell"), owner: self) as? CustomUploadCell else { return nil }
        
        uploadCell.delegate = self
        uploadCell.lblTitle.stringValue = ("\(selectedArray[row]) :")
        uploadCell.txtFilePath.stringValue = ""
        if (!selectedFilePathsArray.isEmpty && row < selectedFilePathsArray.count) {
            var pathString = String()
            for (key, _) in selectedFilePathsArray[row] {
                pathString += ("\(key);")
            }
            
            uploadCell.txtFilePath.stringValue = pathString.trimmingCharacters(in: [";"])
        }
        uploadCell.btnBrowse.tag = row
        return uploadCell
    }
    
    // MARK:  File Browser
    func didFileBrowseTapped(_ sender: NSButton) {
        
        let row = sender.tag
        let fileType = deduceFileType(forRow: row)
        
        if (fileType == nil) { return }
        
        filePickerDialog(fileType: fileType!) { [self] (files) in
            if files.isEmpty {
                return
            }
            
            populateSelectedArray(forRow: row, files: files)
        }
    }
    
    func populateSelectedArray(forRow: Int, files: [String:[[String:Any]]]) {
        let index = teamPopup.indexOfSelectedItem
        
        if (index == 0) {
            self.selectedCameraFilePathsArray[forRow] = files
            self.selectedFilePathsArray = self.selectedCameraFilePathsArray
        } else if(index == 1) {
            self.selectedSoundFilePathsArray[forRow] = files
            self.selectedFilePathsArray = self.selectedSoundFilePathsArray
        } else if(index == 2) {
            self.selectedScriptsFilePathsArray[forRow] = files
            self.selectedFilePathsArray = self.selectedScriptsFilePathsArray
        } else if(index == 3) {
            self.selectedOthersFilePathsArray[forRow] = files
            self.selectedFilePathsArray = self.selectedOthersFilePathsArray
        }
        self.reloadTable()
    }
    
    func deduceFileType(forRow: Int) -> String? {
        let index = teamPopup.indexOfSelectedItem
        
        var fileType:String?
        
        if (index == 0) {
            switch forRow {
            case 0:
                fileType = UploadSettingsViewController.kCameraRAWFileType
            case 1:
                fileType = UploadSettingsViewController.kLUTFileType
            case 2:
                fileType = UploadSettingsViewController.kCDLFileType
            case 3:
                fileType = UploadSettingsViewController.kStillsFileType
            case 4:
                fileType = StringConstant().reportNotesType
            default:
                break
            }
        } else if (index == 1) {
            switch forRow {
            case 0:
                fileType = UploadSettingsViewController.kAudioFileType
            case 1:
                fileType = StringConstant().reportNotesType
            default:
                break
            }
        } else if (index == 2) {
            switch forRow {
            case 0:
                fileType = StringConstant().reportNotesType
            default:
                break
            }
        } else if (index == 3) {
            switch forRow {
            case 0:
                fileType = UploadSettingsViewController.kOthersFileType
            default:
                break
            }
        }
        
        return fileType
    }
    
    @IBAction func popUpSelectionDidChange(_ sender: NSPopUpButton) {
        
        let index = teamPopup.indexOfSelectedItem
        selectedArray.removeAll()
        
        if(index == 0) {
            selectedArray.append(UploadSettingsViewController.kCameraRAWFileType)
            selectedArray.append(UploadSettingsViewController.kLUTFileType)
            selectedArray.append(UploadSettingsViewController.kCDLFileType)
            selectedArray.append(UploadSettingsViewController.kStillsFileType)
            selectedArray.append(StringConstant().reportNotesType)
            selectedFilePathsArray = selectedCameraFilePathsArray
        } else if(index == 1) {
            selectedArray.append(UploadSettingsViewController.kAudioFileType)
            selectedArray.append(StringConstant().reportNotesType)
            selectedFilePathsArray = selectedSoundFilePathsArray
        } else if(index == 2) {
            selectedArray.append(StringConstant().reportNotesType)
            selectedFilePathsArray = selectedScriptsFilePathsArray
        } else if(index == 3) {
            selectedArray.append("Others")
            selectedFilePathsArray = selectedOthersFilePathsArray
        }
        
        reloadTable()
    }
    
    func reloadTable() {
        tblUploadFiles.reloadData()
    }
    
    func openTSV(fileName:String, fileType: String)-> String!{
        guard let filepath = Bundle.main.path(forResource: fileName, ofType: fileType)
        else {
            return nil
        }
        do {
            let contents = try String(contentsOfFile: filepath, encoding: .utf8)
            
            return contents
        } catch {
            print("File Read Error for file \(filepath)")
            return nil
        }
    }
    
    
    func parseALEFiles(dirPath : String)-> (sourceFileExist: Bool, ColumnArray:[String]?){
        
        var columnArrayList = [String]()
        var colArray = [String]()
        // TO DO : Check dirpath variavble existance
        let url = URL(fileURLWithPath: dirPath)
        
        do {
            let data = try Data(contentsOf: url)
            let tsvFile = String(decoding: data, as: UTF8.self)
            let subStr = tsvFile.slice(from: "Column", to: "Data")
            columnArrayList = (subStr?.components(separatedBy: "\t"))!
            
            colArray.removeAll()
            
            var strTitle:String
            for str in columnArrayList{
                strTitle = String(str.filter { !"\r".contains($0) })
                strTitle = strTitle.trimmingCharacters(in: .whitespacesAndNewlines)
                colArray.append(strTitle)
            }
            
            for columnName in colArray as [String]{
                if columnName.caseInsensitiveCompare(StringConstant().sourceFile) == ComparisonResult.orderedSame
                {
                    return (true,nil)
                }
            }
        } catch let error {
            print(error.localizedDescription)
        }
        return(false,colArray)
    }
    
    
    func controlTextDidEndEditing(_ obj: Notification) {
        if let sender = obj.object as? NSTextField {
            if sender.tag == 105 {
                if shootDayField.stringValue.isEmpty{
                    showPopoverMessage(positioningView: shootDayField, msg: StringConstant().specifyShootDay)
                }
                else  if shootDayField.stringValue.isStringPatternMatch(withstring: shootDayFormat ?? " ") {
                    //  print("shootDay string: \(shootDayField.stringValue)")
                } else {
                    showPopoverMessage(positioningView: shootDayField, msg: StringConstant().invalidShootday)
                }
            }
        }
    }
    
    @objc func resetViewController(_ sender: Any)
    {
        aleSelectionViewController = nil
    }
    
    // MARK:  ALE File Handling
    
    func checkAllFilesForSourceName() {
        
        aleSouceFilesArray.removeAll()
        uploadedFileList.removeAll()
        var uploadFiles : [String:[[String:Any]]] = [:]
        var uploadDirs : [String:[String]] = [:]
        var arrExactContains = [String]()
        
        arrExactContains.append(StringConstant().strMatchTypeExact)
        arrExactContains.append(StringConstant().strMatchTypeContains)
        
        for i in 0 ..< selectedArray.count {
            uploadDirs[selectedArray[i]] = []
            uploadFiles[selectedArray[i]] = []
            totalFileStoUpload[selectedArray[i]] = []
            for (keyMain, value) in selectedFilePathsArray[i] {
                uploadDirs[selectedArray[i]]?.append(keyMain)
                for f in value {
                    uploadFiles[selectedArray[i]]?.append(f)
                    var fUpdatedDict = [String:Any]()
                    var dictWithDirPath = [String:Any]()
                    for (key, value1) in f {  //key means dir path
                        var fDict:[String:Any]
                        fDict = value1 as! [String : Any]
                        let uniqueID = randomString(length: 32)
                        
                        uploadedFileList.append(fileInfo(dirPath: key,
                                                         checksum: fDict["checksum"] as! String,
                                                         filePath: fDict["filePath"] as! String,
                                                         name: fDict["name"] as! String ,
                                                         type: fDict["type"] as! String,
                                                         filesize:(fDict["filesize"] as! UInt64),
                                                         uniqueID: uniqueID,
                                                         aleFileDetail: nil
                        ))
                        
                        fUpdatedDict["checksum"] = fDict["checksum"] as! String
                        fUpdatedDict["filePath"] = fDict["filePath"] as! String
                        fUpdatedDict["name"] = fDict["name"] as! String
                        fUpdatedDict["type"] = fDict["type"] as! String
                        fUpdatedDict["filesize"] = (fDict["filesize"] as! UInt64)
                        fUpdatedDict["uniqueID"] = uniqueID
                        
                        dictWithDirPath[key] = fUpdatedDict
                    }
                    totalFileStoUpload[selectedArray[i]]?.append(dictWithDirPath)
                }
            }
        }
        
        for i in 0 ..< uploadedFileList.count {
            var fileStruct:fileInfo?
            fileStruct = uploadedFileList[i]
            
            if fileStruct?.name != nil{
                let strArray = fileStruct?.name.components(separatedBy: ".")
                if ( strArray!.count > 1 ){
                    if(strArray![1] == "ale"){
                        
                        let(sourceFile, columnArray) = parseALEFiles(dirPath: fileStruct!.dirPath)
                        
                        if sourceFile{
                            fileStruct?.aleFileDetail = ALEFileDetails(SourceFile: true,otherSourceFiles: nil,selectedSourceFilesIndex: nil,selectedSourceFilesName:nil,optionExactContains: nil,optionExactName:nil,selectedOptionIndex: 0,charecterFromLeft: nil,charecterFromRight: nil)
                            
                        }else{
                            isAllFileHaveSourceFile = false
                            fileStruct?.aleFileDetail = ALEFileDetails(SourceFile: false,otherSourceFiles: columnArray,selectedSourceFilesIndex: 0,selectedSourceFilesName: nil,optionExactContains: arrExactContains,optionExactName: nil,selectedOptionIndex: 0,charecterFromLeft: nil,charecterFromRight: nil)
                        }
                        aleSouceFilesArray.append(fileStruct!)
                    }
                }
            }
        }
    }
    
    func didALEFileUpdated(updatedALEFiles:[[String:Any]]){
        
        // Check ALE Files have source Name o/w goes to
        
        var updatedDict = [String: Any]()
        var keyDictArray = [[String: Any]]()
        for (key, value1) in totalFileStoUpload {
            //value1   =  Audio array , key  = Audio
            // to Get all updated value for key = Audio
            keyDictArray =  modifiedALEItem(sourceArray: value1, keyFileType: key, fromArray: updatedALEFiles)  //array of having all item related to this key
            updatedDict[key] = keyDictArray
        }
        
        startUploadWithALEParsing(uploadFilesWithALE: updatedDict)
    }
    
    func modifiedALEItem(sourceArray:[[String:Any]],keyFileType:String , fromArray:[[String:Any]]) -> [[String: Any]]{
        
        var retArray = [[String:Any]]()
        var retDict = [String: Any]()
        var tempDict = [String: Any]()
        var keyDict =  [String: Any]()
        var dirPath = String ()
        for itemDict in sourceArray {
            keyDict =  [String: Any]()
            for(key,valueItem) in itemDict {
                tempDict = valueItem as! [String : Any]
                
                if let fileName = tempDict["name"] {
                    let fileExtenssion = (fileName as! String).components(separatedBy: ".")
                    if fileExtenssion.count >= 2 {
                        retDict = [String: Any]()
                        dirPath = key
                        if fileExtenssion[1] == "ale" {
                            retDict = updatedALEFile(sourceCheckSum: tempDict["uniqueID"] as Any, fromDictArray: fromArray)
                        }else{
                            retDict["checksum"] = tempDict["checksum"]
                            retDict["filePath"] = tempDict["filePath"]
                            retDict["filesize"] = tempDict["filesize"]
                            retDict["name"] = tempDict["name"]
                            retDict["type"] = tempDict["type"]
                            // retDict["miscInfo"] = " "
                        }
                    }
                }
            }
            
            keyDict[dirPath] = retDict
            retArray.append(keyDict)
        }
        return retArray;
    }
    
    
    func updatedALEFile(sourceCheckSum:Any,fromDictArray:[[String:Any]]) -> [String : Any] {
        var retDict = [String: Any]()
        
        for item in fromDictArray {
            if let itemValue = item["uniqueID"] {
                if sourceCheckSum as? String == itemValue as? String {
                    
                    retDict["checksum"] = item["checksum"] as Any
                    retDict["filePath"] = item["filePath"]as Any
                    retDict["filesize"] = item["filesize"]as Any
                    retDict["name"] = item["name"] as Any
                    retDict["type"] = item["type"] as Any
                    retDict["miscInfo"] = item["miscInfo"] as Any
                    return retDict
                }
            }
        }
        
        return retDict
    }
    
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    
    func startUploadWithALEParsing(uploadFilesWithALE:[String: Any]) {
        
        let dateformat: String = "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateformat
        //let strdate = dateFormatter.string(from: shootDate.dateValue)
        
        // [show name]/[season name]/[block name]/[shootday]/[batch]/[unit ]/Camera RAW/browsed folder
        let season = self.seasonsCombo.selectedCell()!.stringValue as String
        let block = self.blocksCombo.selectedCell()!.stringValue as String
        let episode = self.episodesCombo.selectedCell()!.stringValue as String
        
        var blockOrEpisode : (String,String)!
        let isBlock : Bool = byBlockRadio.state == NSControl.StateValue.on
        
        if byBlockRadio.state == NSControl.StateValue.on {
            if block.isEmpty {
                if(self.blocksCombo.numberOfItems > 0) {
                    showPopoverMessage(positioningView: blocksCombo, msg: "Invalid params for Block")
                    return
                }else{
                    showPopoverMessage(positioningView: blocksCombo, msg: "Block are not associated with this season")
                    return
                }
            }
            blockOrEpisode = getBlock(seasonName: season, blockName: block)
        } else {
            if episode.isEmpty {
                if(self.episodesCombo.numberOfItems > 0) {
                    showPopoverMessage(positioningView: episodesCombo, msg: "Invalid params for Episode")
                    return
                }else{
                    showPopoverMessage(positioningView: episodesCombo, msg: "Episodes are not associated with this season")
                    return
                }
            }
            blockOrEpisode = getEpisode(seasonName: season, episopeName: episode)
        }
        
        var isEmpty: Bool = true
        for item in selectedFilePathsArray {
            if !item.isEmpty {
                isEmpty = false
                break
            }
        }
        
        if isEmpty {
            showPopoverMessage(positioningView: teamPopup, msg: StringConstant().specifyPathMedia)
            return
        }
        
        if shootDayField.stringValue.isEmpty {
            showPopoverMessage(positioningView: shootDayField, msg:StringConstant().specifyShootDay)
            return
        } else {
            if shootDayField.stringValue.isStringPatternMatch(withstring: shootDayFormat ?? " "){
                // print("shootDay string: \(shootDayField.stringValue)")
            } else {
                showPopoverMessage(positioningView: shootDayField, msg: StringConstant().invalidShootday)
                return
            }
        }
        
        if !emailField.stringValue.isEmpty && !isValidEmail(emailField.stringValue){
            showPopoverMessage(positioningView: emailField, msg:StringConstant().wrongEmailFormat)
            return
        }
        
        if blockOrEpisode == nil {
            return
        }
        
        let episodeId = isBlock ? "" : blockOrEpisode.1
        let blockId = isBlock ? blockOrEpisode.1 : ""
        
        let json_main : [String:String] = [
            "showId": self.showId,
            "seasonId":getSeasonId(seasonName: season),
            "episodeId":episodeId,
            "blockId":blockId,
            "batch":batchPopup.titleOfSelectedItem!,
            "unit":unitPopup.titleOfSelectedItem!,
            "team":teamPopup.titleOfSelectedItem!,
            "shootDay":shootDayField.stringValue,
            "info":infoField.stringValue,
            "notificationEmail":emailField.stringValue,
            "checksum":"md5",
            "season":season,
            "blockOrEpisode":blockOrEpisode.0,
        ]
        
        var uploadFiles : [String:[[String:Any]]] = [:]
        var uploadDirs : [String:[String]] = [:]
        
        for i in 0 ..< selectedArray.count {
            uploadDirs[selectedArray[i]] = []
            uploadFiles[selectedArray[i]] = []
            for (key, value) in selectedFilePathsArray[i] {
                uploadDirs[selectedArray[i]]?.append(key)
                for f in value {
                    uploadFiles[selectedArray[i]]?.append(f)
                }
            }
        }
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
                                        object: nil,
                                        userInfo: ["json_main":json_main,
                                                   "showName": self.showNameField.stringValue,
                                                   "season": (season, getSeasonId(seasonName: season)),
                                                   "blockOrEpisode":blockOrEpisode!,
                                                   "isBlock":isBlock,
                                                   "files": uploadFilesWithALE,
                                                   "srcDir": uploadDirs,
                                        ])
        window?.performClose(nil) // nil because I'm not return a message
        
        
        
    }
    
    func defaultMiscDict()-> [String : Any]{
        var retDict = [String: Any]()
        retDict["aleFileNameField"] = StringConstant().sourceFile
        retDict["matchType"] = StringConstant().strMatchTypeExact
        retDict["truncateCharFromStart"] = 0
        retDict["truncateCharFromEnd"] = 0
        return retDict;
    }
    
    @IBAction func btnReloadSesionClicked(_ sender: Any) {
        self.progressFetch.isHidden = false
        self.progressFetch.startAnimation(true)
        self.btnReloadSeason.isHidden = true
        fetchSeasonsAndEpisodes(showId: self.showId)
    }
    
    func checkAllDirPathExist() -> Bool {
        for item in selectedFilePathsArray {
            print("File Path item :\(item)")
            for (key,_) in item {
                if !isCheckDirExist(dirPath: key){
                    return false
                }
            }
        }
        return true
    }
}

extension NSComboBox {
    func selectedStringValue() -> String? {
        return self.itemObjectValue(at: self.indexOfSelectedItem) as? String
    }
}

extension UploadSettingsViewController: NSComboBoxDelegate {
    
    func comboBoxSelectionDidChange(_ notification: Notification) {
        
        if let comboBox = notification.object as? NSComboBox {
            if comboBox == self.seasonsCombo {
                if let seasonName = comboBox.selectedStringValue() {
                    populateComoboxes(seasonName: seasonName)
                }
            }
        }
    }
}


extension String{
    
    func isStringPatternMatch(withstring: String) -> Bool {
        var retVal:Bool = false
        let regex = try! NSRegularExpression(pattern: "\\d+", options: NSRegularExpression.Options.caseInsensitive)
        let range1 = NSMakeRange(0, self.count)
        let modPatternString = regex.stringByReplacingMatches(in: self, options: [], range: range1, withTemplate: "@")
        let range2 = NSMakeRange(0, withstring.count)
        let modActualString = regex.stringByReplacingMatches(in: withstring, options: [], range: range2, withTemplate: "@")
        
        retVal = modPatternString.elementsEqual(modActualString) == true
        
        return retVal
    }
    
    func slice(from: String, to: String) -> String? {
        
        return (range(of: from)?.upperBound).flatMap { substringFrom in
            (range(of: to, range: substringFrom..<endIndex)?.lowerBound).map { substringTo in
                String(self[substringFrom..<substringTo])
            }
        }
    }
}


extension StringProtocol {
    func index<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.lowerBound
    }
    func endIndex<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> Index? {
        range(of: string, options: options)?.upperBound
    }
    func indices<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Index] {
        ranges(of: string, options: options).map(\.lowerBound)
    }
    func ranges<S: StringProtocol>(of string: S, options: String.CompareOptions = []) -> [Range<Index>] {
        var result: [Range<Index>] = []
        var startIndex = self.startIndex
        while startIndex < endIndex,
              let range = self[startIndex...]
                .range(of: string, options: options) {
            result.append(range)
            startIndex = range.lowerBound < range.upperBound ? range.upperBound :
                index(range.lowerBound, offsetBy: 1, limitedBy: endIndex) ?? endIndex
        }
        return result
    }
}
/*
 extension UploadSettingsViewController: NSControlTextEditingDelegate {
 func controlTextDidChange(_ notification: Notification) {
 if let textField = notification.object as? NSTextField {
 print(textField.stringValue)
 //do what you need here
 }
 }
 }
 */
