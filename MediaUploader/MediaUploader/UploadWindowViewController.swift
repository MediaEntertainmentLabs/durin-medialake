//
//  ViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa


class UploadTableRow : NSObject {
    
    // there is cycle reference between async operation and UI row element
    var taskRef: FileUploadOperation?
    
    let showName: String
    let srcPath: String
    let dstPath: String
    var uploadProgress: Double
    var completionStatusString: String
    
    // metadata
    let uploadParams: [String:String] // we need to keep JSON params to send error report in case of failure occured
    
    init(showName: String, uploadParams: [String:String], srcPath: String, dstPath: String) {
        self.showName = showName
        self.srcPath = srcPath
        self.dstPath = dstPath
        self.uploadProgress = 0.0
        self.completionStatusString = "In progress"
        
        self.uploadParams = uploadParams
        
        super.init()
    }
    
    func restoreTask() {
        if let taskRef = taskRef {
            if let parent = taskRef.parent {
                // if retry operation has already started just return
                for dep in parent.dependens {
                    if dep.retry {
                        taskRef.retry = true
                        return
                    }
                }
                taskRef.retry = true
                
                let newParent = parent.copy() as! FileUploadOperation
                
                for dep in newParent.dependens {
                    dep.parent = newParent
                }
                //newParent.dependens.removeAll()
                //newParent.dependens.append(taskRef)

                // restart parent task
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.RestartTask),
                                                object: nil,
                                                userInfo: ["task" : newParent])
                
            } else {
                // restart data task
                let newTaskRef = taskRef.copy() as! FileUploadOperation
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.RestartTask),
                                                object: nil,
                                                userInfo: ["task" : newTaskRef])
            }
        }
    }
}

class UploadWindowViewController: NSViewController {

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
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "Retry", action: #selector(tableViewRetryItemClicked(_:)), keyEquivalent: ""))
        //menu.addItem(NSMenuItem(title: "Delete", action: #selector(tableViewDeleteItemClicked(_:)), keyEquivalent: ""))
        self.tableView.menu = menu
        
        var column_index : Int = 0
        tableView.tableColumns.forEach { (column) in
            switch(column_index) {
            case 0: column.title = "#"
            case 1: column.title = "Show"
            case 2: column.title = "Source"
            case 3: column.title = "Destination"
            case 4: column.title = "Progress"
            case 5: column.title = "Status"
            default: break
            }
            column_index += 1
            column.headerCell.attributedStringValue = NSAttributedString(string: column.title,
                                                                         attributes: [NSAttributedString.Key.font: NSFont.boldSystemFont(ofSize: 12),
                                                                                      NSAttributedString.Key.foregroundColor : NSColor.controlLightHighlightColor ])

//               // Optional: you can change title color also jsut by adding NSForegroundColorAttributeName
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

    @objc private func tableViewRetryItemClicked(_ sender: AnyObject) {

        guard tableView.clickedRow >= 0 else { return }

        let item = uploadTasks[tableView.clickedRow]
        item.restoreTask()
        //showDetailsViewController(with: item)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @objc private func onAddUploadTask(_ notification: Notification) {
        let uploadTableRecord  = notification.userInfo?["uploadRecord"] as! UploadTableRow
        DispatchQueue.main.async {
            self.uploadContent.addObject(uploadTableRecord)
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
}

