//
//  ViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

enum pauseResumeStatus {
    case none
    case pause
    case resume
}

class UploadTableRow : NSObject {
    
    var showName: String
    var srcPath: String
    var dstPath: String
    var isExistRemotely: Bool
    var uploadProgress: Double
    var completionStatusString: String
    var pauseResumeStatus : pauseResumeStatus
    
    // metadata
    var uploadParams: [String:String] // we need to keep JSON params to send error report in case of failure occured
    
    override init() {
        self.showName = ""
        self.srcPath = ""
        self.dstPath = ""
        self.uploadProgress = 0.0
        self.completionStatusString = "In progress"
        
        self.uploadParams = [:]
        self.isExistRemotely = false
        self.pauseResumeStatus = .pause
        
        super.init()
    }
    
    init(showName: String, uploadParams: [String:String], srcPath: String, dstPath: String, isExistRemotely: Bool) {
        self.showName = showName
        self.srcPath = srcPath
        self.dstPath = dstPath
        self.uploadProgress = 0.0
        self.completionStatusString = "In progress"
        
        self.uploadParams = uploadParams
        self.isExistRemotely = isExistRemotely
        self.pauseResumeStatus = .none
        
        super.init()
    }
}

class UploadWindowViewController: NSViewController,PauseResumeDelegate {
    func didPauseResumeTapped(_ sender: NSButton) {
        print("did pause resume clicked ::: Row : \(sender.tag)")
        
    }
    

    // Key values for the icon view dictionary.
    struct IconViewKeys {
        static let keyName = "name"
        static let keyIcon = "icon"
    }
    
    @IBOutlet var uploadContent: NSArrayController!
    
    @objc dynamic var uploadTasks = [UploadTableRow]()
    
    
    @IBOutlet weak var tableView: NSTableView! {
        didSet {
            // As soon as we have our outline view loaded, we populate its content tree controller.
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        var column_index : Int = 0
        tableView.tableColumns.forEach { (column) in
            switch(column_index) {
            case 0: column.title = "S.N"
            case 1: column.title = "Show Name"
            case 2: column.title = "Source Location"
            case 3: column.title = "Destination Location"
            case 4: column.title = "Progress bar"
            case 5: column.title = "Status"
            default: break
            }
            column_index += 1
            column.headerCell.attributedStringValue = NSAttributedString(string: column.title,
                                                                         attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 12),
                                                                                      NSAttributedString.Key.foregroundColor : isDarkMode() ? NSColor.controlLightHighlightColor : NSColor.headerColor ])
            
            //               // Optional: you can change title color also jsut by adding NSForegroundColorAttributeName
        }
        
        retrieveData() { (record) in
            self.uploadContent.insert(record, atArrangedObjectIndex: 0)
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onAddUploadTask(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.AddUploadTask),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(updateProgress(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.UpdateShowUploadProgress),
            object: nil)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc private func onAddUploadTask(_ notification: Notification) {
        let uploadTableRecord  = notification.userInfo?["uploadRecord"] as! UploadTableRow
        DispatchQueue.main.async {
            createData(index: (self.uploadContent.arrangedObjects as! [Any]).count, uploadTableRecord: uploadTableRecord)
            self.uploadContent.insert(uploadTableRecord, atArrangedObjectIndex: 0)
        }
    }
    
    @objc private func updateProgress(_ notification: Notification) {
        tableView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.AddUploadTask),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.UpdateShowUploadProgress),
            object: nil)
        
    }
    
    override func rightMouseDown(with theEvent: NSEvent) {
        let point = tableView.convert(theEvent.locationInWindow, from: nil)
        let row = tableView.row(at: point)
        print("right click :\(row)")
        let theMenu = popupMenuForValue(selectedRow: row)
        NSMenu.popUpContextMenu(theMenu, with: theEvent, for: tableView) // returns a selected value
    }
    
    func popupMenuForValue(selectedRow:Int) -> NSMenu {
        
        let menu = NSMenu()
        menu.autoenablesItems = false
        let restart = NSMenuItem(title:StringConstant().restart,
                                 action: #selector(restartUpload(_:)), keyEquivalent: "")
        restart.representedObject = selectedRow
        
        //        let pause = NSMenuItem(title:StringConstant().pause,
        //                               action: #selector(restartUpload(_:)), keyEquivalent: "")
        //        let resume = NSMenuItem(title:StringConstant().resume,
        //                                action: #selector(restartUpload(_:)), keyEquivalent: "")
        
        menu.addItem(restart)
        //        menu.addItem(pause)
        //        menu.addItem(resume)
        return menu
    }
    
    @objc func restartUpload(_ item: NSMenuItem) {
        guard let selectedRow = item.representedObject as? Int else { return }
        
        print("selectedItem :\(item.title) , selectedRow :\(selectedRow)")
    }
}

