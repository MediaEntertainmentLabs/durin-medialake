//
//  AppDelegate.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//
import Cocoa
import MSAL

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    enum ErrorStatus {
        case kNoError
        case kFailedFetchListShows
        case kFailedUploadShowSASToken
        case kFailedFetchShowContent
        case kFailedFetchSeasonsAndEpisodes
    }
    
    var mainWindowController : NSWindowController!
    var loginWindowController : NSWindowController!
    
    static var lastError : ErrorStatus = ErrorStatus.kNoError
    static var retryContext : [String:Any] = [:]
    static var cacheSASTokens : [String:SASToken] = [:]
  
    static let appDelegate = NSApplication.shared.delegate as! AppDelegate
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // The MSAL Logger should be set as early as possible in the app launch sequence, before any MSAL
        // requests are made.

        MSALGlobalConfig.loggerConfig.setLogCallback { (logLevel, message, containsPII) in
            
            // If PiiLoggingEnabled is set YES, this block will potentially contain sensitive information (Personally Identifiable Information), but not all messages will contain it.
            // containsPII == YES indicates if a particular message contains PII.
            // You might want to capture PII only in debug builds, or only if you take necessary actions to handle PII properly according to legal requirements of the region
            if let displayableMessage = message {
                if (!containsPII) {
                    #if DEBUG
                    // NB! This sample uses print just for testing purposes
                    // You should only ever log to NSLog in debug mode to prevent leaking potentially sensitive information
                    print(displayableMessage)
                    #endif
                }
            }
        }

    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication,
                                                hasVisibleWindows flag: Bool) -> Bool
    {
        if flag == false {
            if self.mainWindowController != nil {
                self.mainWindowController.window?.makeKeyAndOrderFront(self)
                return true
            }
            if self.loginWindowController != nil {
                self.loginWindowController.window?.makeKeyAndOrderFront(self)
                return true
            }
//            {
//                for window in sender.windows {
//
//                    if (window.delegate?.isKind(of: WindowController.self)) == true {
//                        window.makeKeyAndOrderFront(self)
//                    }
//                }
//            }
        }
        return true
    }
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {

        let container = NSPersistentContainer(name: "uploadsModelData")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

    // MARK: - Core Data Saving support

    func saveContext () {
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                fatalError("Unresolved error \(nserror), \(nserror.userInfo)")
            }
        }
    }

}
