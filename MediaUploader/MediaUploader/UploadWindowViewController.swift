//
//  ViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa


class UploadTableRow : NSObject {
    
    var showName: String
    var srcPath: String
    var dstPath: String
    var isExistRemotely: Bool
    var uploadProgress: Double
    var completionStatusString: String
    
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
        
        super.init()
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
        
        retrieveData()
        
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
            self.createData(index: (self.uploadContent.arrangedObjects as! [Any]).count, uploadTableRecord: uploadTableRecord)
            self.uploadContent.insert(uploadTableRecord, atArrangedObjectIndex: 0)
        }
    }
    
    @objc private func updateProgress(_ notification: Notification) {
        tableView.reloadData()
    }
    
    static let storedKeys = ["shootDay", "batch", "unit", "team", "seasonId", "blockId", "info", "notificationEmail"]
    
    func createData(index : Int, uploadTableRecord: UploadTableRow) {
        
        let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
        
        guard let showEntity = NSEntityDescription.entity(forEntityName: "ShowEntity", in: managedContext) else { print(" ------ Could not createData."); return }
        
        let data = NSManagedObject(entity: showEntity, insertInto: managedContext)
        
        data.setValue(index, forKey: "sn")
        data.setValue(uploadTableRecord.showName, forKey: "showName")
        data.setValue(uploadTableRecord.srcPath, forKeyPath: "srcPath")
        data.setValue(uploadTableRecord.dstPath, forKey: "dstPath")
        data.setValue(uploadTableRecord.uploadProgress, forKey: "progress")
        data.setValue(uploadTableRecord.completionStatusString, forKey: "status")
        for key in UploadWindowViewController.storedKeys {
            data.setValue(uploadTableRecord.uploadParams[key], forKey: key)
        }
        
        do {
            try managedContext.save()
           
        } catch let error as NSError {
            print("Could not save. \(error), \(error.userInfo)")
        }
    }
    
    func retrieveData() {
        let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
        
        //Prepare the request of type NSFetchRequest  for the entity
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ShowEntity")
        
//        fetchRequest.fetchLimit = 1
//        fetchRequest.predicate = NSPredicate(format: "username = %@", "Ankur")
//        fetchRequest.sortDescriptors = [NSSortDescriptor.init(key: "email", ascending: false)]
//
        do {
            let result = try managedContext.fetch(fetchRequest)
            for data in result as! [NSManagedObject] {
                let record = UploadTableRow()
                print("S/N\(data.value(forKey: "sn") as! Int)")
                record.showName = data.value(forKey: "showName") as! String
                record.srcPath = data.value(forKey: "srcPath") as! String
                record.dstPath = data.value(forKey: "dstPath") as! String
                record.uploadProgress = data.value(forKey: "progress") as! Double
                record.completionStatusString = data.value(forKey: "status") as! String
                
                for key in UploadWindowViewController.storedKeys {
                    print(data.value(forKey: key) as! String)
                    record.uploadParams[key] = key
                }
                self.uploadContent.insert(record, atArrangedObjectIndex: 0)
            }
            
        } catch {
            
            print("Failed")
        }
    }
    
    func updateData(row: Int, progress : Int, status: String) {
    
        //We need to create a context from this container
        let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
        
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "ShowEntity")
        fetchRequest.predicate = NSPredicate(format: "sn = %@", row)
        do
        {
            let test = try managedContext.fetch(fetchRequest)
   
                let objectUpdate = test[0] as! NSManagedObject
                objectUpdate.setValue(progress, forKey: "progress")
                objectUpdate.setValue(status, forKey: "status")
                do{
                    try managedContext.save()
                }
                catch
                {
                    print(error)
                }
            }
        catch
        {
            print(error)
        }
   
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

