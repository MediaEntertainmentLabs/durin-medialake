//
//  Persist.swift
//  MediaUploader
//
//  Copyright © 2021 GlobalLogic. All rights reserved.
//

import Cocoa

let storedKeys = ["shootDay", "batch", "unit", "team", "season", "blockOrEpisode", "blockId", "episodeId", "showId", "info", "notificationEmail"]

func createData(index : Int, uploadTableRecord: UploadTableRow) {
    
    let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
    
    guard let showEntity = NSEntityDescription.entity(forEntityName: "ShowEntity", in: managedContext) else {
        print("------------  Could not createData.")
        // os_log("------------  Could not createData.", log: .default, type: .default)
        return }
    
    let data = NSManagedObject(entity: showEntity, insertInto: managedContext)
    
    data.setValue(String(index), forKey: "sn")
    data.setValue(uploadTableRecord.showName, forKey: "showName")
    data.setValue(uploadTableRecord.srcPath, forKeyPath: "srcPath")
    data.setValue(uploadTableRecord.dstPath, forKey: "dstPath")
    data.setValue(uploadTableRecord.uploadProgress, forKey: "progress")
    data.setValue(uploadTableRecord.completionStatusString, forKey: "status")
    data.setValue(uploadTableRecord.dateModified, forKey: "dateModified")
    for key in storedKeys {
        data.setValue(uploadTableRecord.uploadParams[key], forKey: key)
    }
    
    do {
        try managedContext.save()
        
    } catch let error as NSError {
        print("------------ Could not save. \(error)")
        //os_log("------------ Could not save. %@", log: .default, type: .error,error)
    }
}

func retrieveData(completion: @escaping (_ record: UploadTableRow) -> Void) {
    let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
    let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "ShowEntity")
    
    do {
        let result = try managedContext.fetch(fetchRequest)
        for data in result as! [NSManagedObject] {
            let record = UploadTableRow()
            record.uniqueIndex = Int(data.value(forKey: "sn") as! String)!
            record.showName = data.value(forKey: "showName") as! String
            record.srcPath = data.value(forKey: "srcPath") as! String
            record.dstPath = data.value(forKey: "dstPath") as! String
            record.resumeProgress = data.value(forKey: "progress") as! Double
            record.uploadProgress = record.resumeProgress
            record.completionStatusString = data.value(forKey: "status") as! String
            record.dateModified = data.value(forKey: "dateModified") as!Date
            record.pauseResumeStatus = .none
            if equal(record.resumeProgress, 100.0) == false {
                record.pauseResumeStatus = .pause
                record.completionStatusString = "Paused"
            }
            
            for key in storedKeys {
                if let v = data.value(forKey: key) as? String {
                    record.uploadParams[key] = v
                }
            }
            completion(record)
        }
        
    } catch {
        
        print("------------ failed durinf retrieve Data from coredata. ")
        //os_log("------------ failed durinf retrieve Data from coredata. %@", log: .default, type: .default)
        completion(UploadTableRow())
    }
}

func updateData(row: Int, progress : Int, status: String) {
    print(" ------- updateData for row:\(row) , status :\(status)")
    // os_log(" ------- updateData for row:%d , status :%@", log: .default, type: .default,row,status)
    
    let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "ShowEntity")
    fetchRequest.predicate = NSPredicate(format: "sn = %@", String(row))
    
    do
    {
        let test = try managedContext.fetch(fetchRequest)
        
        let objectUpdate = test[0] as! NSManagedObject
        objectUpdate.setValue(progress, forKey: "progress")
        objectUpdate.setValue(status, forKey: "status")
        objectUpdate.setValue(Date(), forKey: "dateModified")
        do {
            try managedContext.save()
            
        } catch {
            //     os_log(" ------- Error during update data %@", log: .default, type: .error,error as CVarArg)
            print(" ------- Error during update data :\(error)")
        }
        
    } catch {
        // os_log(" -----Catch  Error during update data %@", log: .default, type: .error,error as CVarArg)
        print(" -----Catch  Error during update data :\(error)")
    }
}

func deleteAllData() {
    let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
    let deleteAll = NSBatchDeleteRequest(fetchRequest: NSFetchRequest<NSFetchRequestResult>(entityName: "ShowEntity"))
    do {
        try managedContext.execute(deleteAll)
    }
    catch {
        print(error)
    }
}
