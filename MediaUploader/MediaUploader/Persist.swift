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
    guard let showEntity = NSEntityDescription.entity(forEntityName: "ShowEntity", in: managedContext) else { print(" ------ Could not createData."); return }
    
    let data = NSManagedObject(entity: showEntity, insertInto: managedContext)
    
    data.setValue(String(index), forKey: "sn")
    data.setValue(uploadTableRecord.showName, forKey: "showName")
    data.setValue(uploadTableRecord.srcPath, forKeyPath: "srcPath")
    data.setValue(uploadTableRecord.dstPath, forKey: "dstPath")
    data.setValue(uploadTableRecord.uploadProgress, forKey: "progress")
    data.setValue(uploadTableRecord.completionStatusString, forKey: "status")
    data.setValue(uploadTableRecord.dateModified, forKey: "dateModified")
    data.setValue(uploadTableRecord.isBlock, forKey: "isBlock")
    data.setValue(uploadTableRecord.seasonId, forKey: "seasonId")
    data.setValue(uploadTableRecord.metaDataJSONTime, forKey: "metaDataJSONTime")
    data.setValue(uploadTableRecord.metadataJSONPresent, forKey: "metadataJSONPresent")
    for key in storedKeys {
        data.setValue(uploadTableRecord.uploadParams[key], forKey: key)
    }
    
    do {
        try managedContext.save()
       
    } catch let error as NSError {
        print("------------ createData failed. \(error), \(error.userInfo)")
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
            record.pauseResumeStatus = .none
            record.dateModified = data.value(forKey: "dateModified") as! Date
            record.isBlock = data.value(forKey: "isBlock") as! Bool
            record.seasonId = data.value(forKey: "seasonId") as! String
            record.metaDataJSONTime = data.value(forKey: "metaDataJSONTime") as! String
            record.metadataJSONPresent = data.value(forKey: "metadataJSONPresent") as! Bool
            if equal(record.resumeProgress, 100.0) == false {
                record.pauseResumeStatus = .pause
                record.completionStatusString = OutlineViewController.NameConstants.kPausedStr
            }
            
            for key in storedKeys {
                if let v = data.value(forKey: key) as? String {
                    record.uploadParams[key] = v
                }
            }
            completion(record)
        }
        
    } catch let error as NSError {
        print("------------ retrieveData Failed. \(error), \(error.userInfo)")
        completion(UploadTableRow())
    }
}

func updateData(row: Int, progress : Int, status: String) {
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
            print(error)
        }
        
    } catch {
        print(error)
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

func updateMetaDataPresent(metaDataTimeStamp: String) {
    let managedContext = AppDelegate.appDelegate.persistentContainer.viewContext
    let fetchRequest: NSFetchRequest<NSFetchRequestResult> = NSFetchRequest.init(entityName: "ShowEntity")
    fetchRequest.predicate = NSPredicate(format: "metaDataJSONTime = %@", metaDataTimeStamp)
    
    do
    {
        let test = try managedContext.fetch(fetchRequest)
        if test.count > 0 {
            for item in test {
                let objectUpdate = item as! NSManagedObject
                objectUpdate.setValue(true, forKey: "metadataJSONPresent")
                do {
                    try managedContext.save()
                    
                } catch {
                    print(error)
                }
            }
        } else {
            print("Data Not Found")
        }
    } catch {
        print(error)
    }
}

