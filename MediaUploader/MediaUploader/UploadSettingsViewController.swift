//
//  UploadSettingsViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class UploadSettingsViewController: NSViewController {

    @IBOutlet weak var showNameField: NSTextField!
    @IBOutlet weak var shootDayField: NSTextField!
    //@IBOutlet weak var shootDate: NSDatePicker!
    @IBOutlet weak var infoField: NSTextField!
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var filePicker: NSButton!
    @IBOutlet weak var uploadButton: NSButton!
    
    @IBOutlet weak var progressFetch: NSProgressIndicator!
    @IBOutlet weak var folderPathField: NSTextField!
    
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
    
    var files: [[String:Any]] = []
    
    // season_name : (season_id, [(episode_name,episode_id)], [(block_name,block_id)])
    typealias SeasonsType = [String:(String, [(String,String)],[(String,String)])]

    
    var seasons: SeasonsType!
    
    // reference to a window
    var window: NSWindow?
    
    fileprivate let teamItems = ["Camera", "Sound","Scripts","Others"]
   
    fileprivate let unitItems = ["Main Unit", "Second Unit", "Splinter Unit",
                                 "Kelly's Unit & John's Unit", "\"1U\" & \"2U\" & \"3U\""]
    
    fileprivate let batchItems = ["1st Batch", "2nd Batch", "Lunch and Wrap"]
    
    var showId : String!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        radios = [(byEpisodeRadio,episodesCombo,episodesComboLabel),
                  (byBlockRadio,blocksCombo,blocksComboLabel)]
        
        episodesCombo.isHidden = false
        episodesComboLabel.isHidden = false
        byEpisodeRadio.state = NSControl.StateValue(rawValue: 1)
        
        blocksCombo.isHidden = true
        blocksComboLabel.isHidden = true
        
        teamPopup.removeAllItems()
        teamPopup.addItems(withTitles: teamItems)
        teamPopup.selectItem(at: 0)
        
        unitPopup.removeAllItems()
        unitPopup.addItems(withTitles: unitItems)
        unitPopup.selectItem(at: 0)
        
        batchPopup.removeAllItems()
        batchPopup.addItems(withTitles: batchItems)
        batchPopup.selectItem(at: 0)
        
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
        
        fetchSeandsAndEpisodes(showId: self.showId)
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
                                        object: nil)
    }
    
    func comboBoxWillDismiss(notification: NSNotification) {
        print("Woohoo, it changed")
    }
    
    override func viewDidAppear() {
        // After a window is displayed, get the handle to the new window.
        window = self.view.window!
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
            episodesComboLabel .isHidden = false
            blocksCombo.isHidden = true
            blocksComboLabel.isHidden = true
            
        } else if byBlockRadio.state == NSControl.StateValue.on {
            blocksCombo.isHidden = false
            blocksComboLabel.isHidden = false
            episodesCombo.isHidden = true
            episodesComboLabel .isHidden = true
        }
    }
    
    @IBAction func chooseShowFolder(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose single directory | Our Code World";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result == nil) {
                return
            }
            
            folderPathField.stringValue = result!.path
            
            let pathURL = NSURL(fileURLWithPath: folderPathField.stringValue, isDirectory: true)
            var filePaths : [String : UInt64] = [:]
            
            let enumerator = FileManager.default.enumerator(atPath: folderPathField.stringValue)
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
            for scanItem in scanItems {
                let filename = URL(fileURLWithPath: scanItem.key).lastPathComponent
                let filefolder = URL(fileURLWithPath: scanItem.key).deletingLastPathComponent()
                
                var parsed = filefolder.path.replacingOccurrences(of: pathURL.deletingLastPathComponent!.path, with: "")
                if parsed.hasPrefix("/") {
                    parsed = String(parsed.dropFirst())
                }
                let item = ["name": filename,
                            "filePath": parsed.isEmpty ? filename : parsed + "/" + filename,
                            "filesize":scanItem.value,
                            "checksum":"test2"] as [String : Any]
                files.append([scanItem.key : item])
            }
            
        } else {
            // User clicked on "Cancel"
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
        let team = self.teamPopup.titleOfSelectedItem
        let unit = self.unitPopup.titleOfSelectedItem
        let batch = self.batchPopup.titleOfSelectedItem
        
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
        
        if folderPathField.stringValue.isEmpty {
            showPopoverMessage(positioningView: folderPathField, msg: "Please specify path to media")
            return
        }
        
        if shootDayField.stringValue.isEmpty {
            showPopoverMessage(positioningView: shootDayField, msg: "Please specify shoot Day")
            return
        }
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnStartUploadShow),
                                        object: nil,
                                        userInfo: ["showName": self.showNameField.stringValue,
                                                   "season": (season, getSeasonId(seasonName: season)),
                                                   "shootDay":shootDayField.stringValue,
                                                   "blockOrEpisode":blockOrEpisode as Any,
                                                   "isBlock":isBlock,
                                                   "batch":batch!,
                                                   "unit":unit!,
                                                   "team":team!,
                                                   "type":"Camera RAW",
                                                   "info":infoField.stringValue,
                                                   "checksum":"md5",
                                                   //"description":descriptionField.stringValue,
                                                   "notificationEmail":emailField.stringValue,
                                                   "files":files,
                                                   "srcDir":folderPathField.stringValue
                                                   ])
        window?.performClose(nil) // nil because I'm not return a message
    }
    
    func getSeasonId(seasonName: String) -> String {
        return self.seasons[seasonName]!.0
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
        return self.seasons[seasonName]!.1
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
        return self.seasons[seasonName]!.2
    }
    
    private func showPopoverMessage(positioningView: NSView, msg: String) {
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let vc = storyboard.instantiateController(withIdentifier: "popover") as? PopoverViewController
        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentViewController = vc
        popover.show(relativeTo: positioningView.bounds, of: positioningView, preferredEdge: NSRectEdge.maxY)
        vc?.popoverMessage.stringValue = msg
        return
    }
        

    private func fetchSeandsAndEpisodes(showId: String) {
        
        fetchSeandsAndEpisodesTask(showId : showId) { (result) in
            
            DispatchQueue.main.async {
                self.progressFetch.isHidden = true
                self.progressFetch.stopAnimation(self)
                
                if let error = result["error"] as? String {
                    AppDelegate.retryContext["showId"] = showId
                    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchSeasonsAndEpisodes
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : error,
                                                               "disableProgress" : true,
                                                               "enableButton" : OutlineViewController.NameConstants.kRetryStr])
                    return
                }
                
                // "by default" insert first ket from dict
                var firstKey : String = ""
                self.seasons = result["data"] as! SeasonsType
                
                for (key, values) in self.seasons {
                    firstKey = key
                    self.seasonsCombo.addItem(withObjectValue: key)
                    self.seasonsCombo.isEnabled = true
                    self.uploadButton.isEnabled = true
                }
                self.seasonsCombo.selectItem(at: 0)
                
                //self.populateComoboxes(seasonName : firstKey)
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
        
        if let values = seasons[seasonName] {
            cleanCombobox(combo: episodesCombo)
            cleanCombobox(combo: blocksCombo)
            if (values.1.count != 0) {
                episodesCombo.isEnabled = true
                for item in values.1 {
                    episodesCombo.addItem(withObjectValue: item.0)
                }
                if (episodesCombo.numberOfItems != 0) {
                    episodesCombo.selectItem(at: 0)
                }
            } else {
                episodesCombo.isEnabled = false
            }
            
            if (values.2.count != 0) {
                blocksCombo.isEnabled = true
                for item in values.1 {
                    blocksCombo.addItem(withObjectValue: item.0)
                }
                if (blocksCombo.numberOfItems != 0) {
                    blocksCombo.selectItem(at: 0)
                }
            } else {
                blocksCombo.isEnabled = false
            }
        }
    }
}


private func fetchSeandsAndEpisodesTask(showId: String, completion: @escaping (_ shows: [String:Any]) -> Void) {

    let json: [String: String] = ["containerId" : showId]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let url = URL(string: LoginViewController.fetchSeasonsAndEpisodesURL)!
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            guard let data = data, error == nil else {
                throw "Failed to retrive list of shows!"
            }
            
            // season_name -> (list_episode_name, list_block_name)
            var result = UploadSettingsViewController.SeasonsType()
            
            let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]

            let seasons = responseJSON["season"] as? [[String:Any]]
            if seasons == nil {
                throw "Failed to retrive list of seasons!"
            }
            for season in seasons! {
                var episodes = [(String,String)]()
                for episode in season["episode"] as! [[String:String]]  {
                    if let name = episode["name"] {
                        episodes.append((name,episode["id"]! as String))
                    }
                }
                var blocks = [(String,String)]()
                for block in season["block"] as! [[String:String]]  {
                    if let name = block["name"] {
                        blocks.append((name,block["id"]! as String))
                    }
                }
            
                result[season["name"] as! String] = (season["id"] as! String, episodes, blocks)
            }
            completion(["data": result])
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}

extension NSComboBox {
    func selectedStringValue() -> String?
    {
        return self.itemObjectValue(at: self.indexOfSelectedItem) as? String
    }
    
}

extension UploadSettingsViewController: NSComboBoxDelegate {

    func comboBoxSelectionDidChange(_ notification: Notification) {
     
        if let comboBox = notification.object as? NSComboBox {
            if comboBox == self.seasonsCombo {
                let seasonName  = comboBox.selectedStringValue()
                populateComoboxes(seasonName: seasonName!)
            }
        }
     
    }

}

/*
extension UploadSettingsViewController: NSControlTextEditingDelegate {
    override func controlTextDidChange(_ obj: Notification) {
        if let textField = notification.object as? NSTextField {
            print(textField.stringValue)
            //do what you need here
        }
    }
}*/
