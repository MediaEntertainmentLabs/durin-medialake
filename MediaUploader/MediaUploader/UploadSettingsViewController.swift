//
//  UploadSettingsViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class UploadSettingsViewController: NSViewController {

    @IBOutlet weak var showNameField: NSTextField!
    @IBOutlet weak var shootNoField: NSTextField!
    @IBOutlet weak var shootDate: NSDatePicker!
    @IBOutlet weak var infoField: NSTextField!
    @IBOutlet weak var descriptionField: NSTextField!
    @IBOutlet weak var emailField: NSTextField!
    @IBOutlet weak var filePicker: NSButton!
    @IBOutlet weak var uploadButton: NSButton!
    
    @IBOutlet weak var folderPathField: NSTextField!
    
    var files: [[String:Any]] = []
     
    // reference to a window
    var window: NSWindow?
    
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
    
    @IBAction func chooseShowFolder(_ sender: Any) {
        let dialog = NSOpenPanel();
        
        dialog.title                   = "Choose single directory | Our Code World";
        dialog.showsResizeIndicator    = true;
        dialog.showsHiddenFiles        = false;
        dialog.canChooseFiles = false;
        dialog.canChooseDirectories = true;
        
        if (dialog.runModal() ==  NSApplication.ModalResponse.OK) {
            let result = dialog.url
            
            if (result != nil) {
                folderPathField.stringValue = result!.path
                
                let pathURL = NSURL(fileURLWithPath: folderPathField.stringValue, isDirectory: true)
                var filePaths : [String] = []
                if let enumerator = FileManager.default.enumerator(atPath: folderPathField.stringValue) {
                    for file in enumerator {
                        let path = NSURL(fileURLWithPath: file as! String, relativeTo: pathURL as URL).path
                        filePaths.append(path!)
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
                    let filename = URL(fileURLWithPath: scanItem).lastPathComponent
                    let filefolder = URL(fileURLWithPath: scanItem).deletingLastPathComponent()

                    var parsed = filefolder.path.replacingOccurrences(of: pathURL.path!, with: "")
                    if parsed.hasPrefix("/") {
                        parsed = String(parsed.dropFirst())
                    }
                    let item = ["name": filename, "filePath" : parsed.isEmpty ? filename : parsed + "/" + filename, "checksum":"test2"]
                    files.append([scanItem : item])
                }
            }
        } else {
            // User clicked on "Cancel"
            return
        }
    }
    
    @IBAction func startUpload(_ sender: Any) {
               
        let dateformat: String = "yyyy-MM-dd"
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateformat
        let strdate = dateFormatter.string(from: shootDate.dateValue)
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.UploadShow),
                                        object: nil,
                                        userInfo: ["showName": self.showNameField.stringValue,
                                                   "shootNumber":shootNoField.stringValue,
                                                   "shootDate":strdate,
                                                   "info" :infoField.stringValue,
                                                   "description":descriptionField.stringValue,
                                                   "notificationEmail":emailField.stringValue,
                                                   "checksum":"md5",
                                                   "type":"video",
                                                   "files":files
                                                   ])
        window?.performClose(nil) // nil because I'm not return a message
    }
    
}
