//
//  UploadSettingsViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class UploadSettingsViewController: NSViewController,NSTableViewDelegate,NSTableViewDataSource,FileBrowseDelegate {

    @IBOutlet weak var showNameField: NSTextField!
    @IBOutlet weak var shootDayField: NSTextField!
    //@IBOutlet weak var shootDate: NSDatePicker!
    @IBOutlet weak var infoField: NSTextField!
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var filePicker: NSButton!
    @IBOutlet weak var uploadButton: NSButton!
    
    @IBOutlet weak var progressFetch: NSProgressIndicator!
    
    @IBOutlet weak var cameraRAWPathField: NSTextField!
    @IBOutlet weak var audioPathField: NSTextField!
    @IBOutlet weak var CDLPathField: NSTextField!
    @IBOutlet weak var LUTPathField: NSTextField!
    
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
    
    fileprivate let teamItems = ["Camera", "Sound","Scripts","Others"]
   
    fileprivate let unitItems = ["Main Unit", "Second Unit", "Splinter Unit",
                                 "Kelly's Unit & John's Unit", "\"1U\" & \"2U\" & \"3U\""]
    
    fileprivate let batchItems = ["1st Batch", "2nd Batch","Lunch and Wrap"]
  
    var selectedArray:[String] = ["Camera RAW","LUT","CDL","Stills","Reports/Notes"]
    var selectedFilePathsArray = [[String:[[String:Any]]]]()
    
    // [
    //     textField_0: [dir:[[filename:meta]],
    //     textField_1: [dir:[[filename:meta]],
    //     ...
    //     textField_n: [dir:[[filename:meta]]
    // ]
    var selectedCameraFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count:5)
    var selectedSoundFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count: 2)
    var selectedScriptsFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count: 1)
    var selectedOthersFilePathsArray = [[String:[[String:Any]]]](repeating: [:], count: 1)
    
    
    var showId : String!
    
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
        
        uploadButton.isEnabled = false
        
        fetchSeasonsAndEpisodes(showId: self.showId)
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
                                        object: nil)
        
        tblUploadFiles.sizeToFit()
        tblUploadFiles.selectionHighlightStyle = .none
        tblUploadFiles.backgroundColor = .clear
      
       
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
            
        } else if byBlockRadio.state == NSControl.StateValue.on {
            blocksCombo.isHidden = false
            blocksCombo.isEnabled = blocksCombo.numberOfItems > 0
            blocksComboLabel.isHidden = false
            episodesCombo.isHidden = true
            episodesComboLabel .isHidden = true
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
            
            var outputFiles: [String: [[String:Any]]] = [:]
            
            for result in results {
                
                let pathURL = NSURL(fileURLWithPath: result.path, isDirectory: true)
                var filePaths : [String : UInt64] = [:]
                
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
                            print("a dir")
                        default:
                            continue
                        }
                    }
                    
                }
                let scanItems = filePaths
                /*
                 let scanItems = filePaths.filter{ fileName in
                 let fileNameLower = fileName.lowercased()
                 for keyword in [".mp4", ".mov", ".mxf", ".ari", ".ale", ".xml"] {
                 if fileNameLower.contains(keyword) {
                 return true
                 }
                 }
                 return false
                 }
                 */
                var files = [[String:Any]]()
                for scanItem in scanItems {
                    let filename = URL(fileURLWithPath: scanItem.key).lastPathComponent
                    let filefolder = URL(fileURLWithPath: scanItem.key).deletingLastPathComponent()
                    
                    var parsed = filefolder.path.replacingOccurrences(of: pathURL.deletingLastPathComponent!.path, with: "")
                    if parsed.hasPrefix("/") {
                        parsed = String(parsed.dropFirst())
                    }
                    let filePath = parsed.isEmpty ? filename : parsed + "/" + filename
                    let item : [String : Any] = ["name": filename,
                                                 "filePath": fileType + "/" + filePath,
                                                 "filesize":scanItem.value,
                                                 "checksum":fileType + "/" + filePath, /* will be replaced latter by real checksum value */
                                                 "type":fileType]
                    files.append([scanItem.key : item])
                    
                }
                outputFiles[result.path] = files
            }
            completion(outputFiles)
        
        } else {
            completion([:]) // User clicked on "Cancel"
            return
        }
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
        let isBlock : Bool = byBlockRadio.state == NSControl.StateValue.on
        
        if byBlockRadio.state == NSControl.StateValue.on {
            
            if block.isEmpty {
                showPopoverMessage(positioningView: blocksCombo, msg: "Invalid params for Block")
                return
            }
  
            blockOrEpisode = getBlock(seasonName: season, blockName: block)
        } else {
            if episode.isEmpty {
                showPopoverMessage(positioningView: episodesCombo, msg: "Invalid params for Episode")
                return
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
            showPopoverMessage(positioningView: cameraRAWPathField, msg: "Please specify path to media")
            return
        }
        
        if shootDayField.stringValue.isEmpty {
            showPopoverMessage(positioningView: shootDayField, msg: "Please specify shoot Day")
            return
        }
        
        if !emailField.stringValue.isEmpty && !isValidEmail(emailField.stringValue){
            showPopoverMessage(positioningView: emailField, msg: "Wrong email format!")
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
            
            DispatchQueue.main.async {
                self.progressFetch.isHidden = true
                self.progressFetch.stopAnimation(self)

                if let error = result["error"] as? String {
                    print(error)
                    self.seasonsCombo.addItem(withObjectValue: "Failed to fetch seasons")
                    self.seasonsCombo.selectItem(at: 0)
                    
                    AppDelegate.retryContext["showId"] = showId
                    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchSeasonsAndEpisodes
                    return
                }
                
                // "by default" insert first ket from dict
                self.seasons = result["data"] as? SeasonsType
                
                for (key, _) in self.seasons {
                    self.seasonsCombo.addItem(withObjectValue: key)
                    self.seasonsCombo.isEnabled = true
                    self.uploadButton.isEnabled = true
                }
                
                if self.seasonsCombo.numberOfItems > 0 {
                    self.seasonsCombo.selectItem(at: 0)
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
            self.shootDayFormat = values.4
            
            cleanCombobox(combo: episodesCombo)
            cleanCombobox(combo: blocksCombo)
            if (values.1.count != 0) {
                episodesCombo.isHidden = !(byEpisodeRadio.state == NSControl.StateValue.on)
                episodesCombo.isEnabled = !episodesCombo.isHidden
                for item in values.1 {
                    episodesCombo.addItem(withObjectValue: item.0)
                }
                if episodesCombo.numberOfItems > 0 {
                    episodesCombo.selectItem(at: 0)
                }
            } else {
                episodesCombo.isEnabled = false
            }

            if (values.2.count != 0) {
                blocksCombo.isHidden = !(byBlockRadio.state == NSControl.StateValue.on)
                blocksCombo.isEnabled = !blocksCombo.isHidden
                for item in values.2 {
                    blocksCombo.addItem(withObjectValue: item.0)
                }
                if blocksCombo.numberOfItems > 0 {
                    blocksCombo.selectItem(at: 0)
                }
            } else {
                blocksCombo.isEnabled = false
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
        
        let index = teamPopup.indexOfSelectedItem
        
        var fileType:String?
        let btnTag = sender.tag
        
        if (index == 0) {
            switch btnTag {
            case 0:
                fileType = UploadSettingsViewController.kCameraRAWFileType
            case 1:
                fileType = UploadSettingsViewController.kLUTFileType
            case 2:
                fileType = UploadSettingsViewController.kCDLFileType
            case 3:
                fileType = UploadSettingsViewController.kStillsFileType
            case 4:
                fileType = UploadSettingsViewController.kReportsFileType
            default:
                break
            }
        } else if (index == 1) {
            switch btnTag {
            case 0:
                fileType = UploadSettingsViewController.kAudioFileType
            case 1:
                fileType = UploadSettingsViewController.kReportsFileType
            default:
                break
            }
        } else if (index == 2) {
            switch btnTag {
            case 0:
                fileType = UploadSettingsViewController.kReportsFileType
            default:
                break
            }
        } else if (index == 3) {
            switch btnTag {
            case 0:
                fileType = UploadSettingsViewController.kOthersFileType
            default:
                break
            }
        }
        
        if (fileType == nil) { return }
        
        filePickerDialog(fileType: fileType!) { (files) in
            if files.isEmpty {
                return
            }
            
            if (index == 0) {
                self.selectedCameraFilePathsArray[btnTag] = files
                self.selectedFilePathsArray = self.selectedCameraFilePathsArray
            } else if(index == 1) {
                self.selectedSoundFilePathsArray[btnTag] = files
                self.selectedFilePathsArray = self.selectedSoundFilePathsArray
            } else if(index == 2) {
                self.selectedScriptsFilePathsArray[btnTag] = files
                self.selectedFilePathsArray = self.selectedScriptsFilePathsArray
            } else if(index == 3) {
                self.selectedOthersFilePathsArray[btnTag] = files
                self.selectedFilePathsArray = self.selectedOthersFilePathsArray
            }
            
            self.reloadTable()
        }
    }
    
    @IBAction func popUpSelectionDidChange(_ sender: NSPopUpButton) {
       
        print("selected Item : ",teamPopup.titleOfSelectedItem!)
        
        let index = teamPopup.indexOfSelectedItem
        selectedArray.removeAll()
        if(index == 0) {
            selectedArray.append("Camera RAW")
            selectedArray.append("LUT")
            selectedArray.append("CDL")
            selectedArray.append("Stills")
            selectedArray.append("Reports/Notes")
            selectedFilePathsArray = selectedCameraFilePathsArray
        } else if(index == 1) {
            selectedArray.append("Audio")
            selectedArray.append("Reports/Notes")
            selectedFilePathsArray = selectedSoundFilePathsArray
        } else if(index == 2) {
            selectedArray.append("Reports/Notes")
            selectedFilePathsArray = selectedScriptsFilePathsArray
        } else if(index == 3) {
            selectedArray.append("Others")
            selectedFilePathsArray = selectedOthersFilePathsArray
        }
        
        reloadTable()
    }
    
    
    func reloadTable(){
         tblUploadFiles .reloadData()
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
