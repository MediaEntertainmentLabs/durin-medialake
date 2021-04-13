//
//  ErrorHandling.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

func uploadShowErrorAndNotify(error : Error, params : [String:Any], operation : FileUploadOperation?) {
    
    var tempParam:[String:Any]
    tempParam = params
    var subject = "Failed to Upload asset" //"Failed to Upload asset for shoot day day001"
    var emailBody = "Hi,\n Upload Failed for asset with below error- \n The operation couldn’t be completed.\n\nPlease check your source location directory and retry."
    if let strShootday = params["shootDay"] {
        subject = "Upload Failed for asset \(strShootday)"
        emailBody = "Hi,\n Upload Failed for asset \(strShootday) with below error-\n \(error.localizedDescription) \n\nPlease check your source location directory and retry."
    }
    
    if let strShootday = params["shootDay"] {
        subject = "Upload Failed for asset \(strShootday)"
    }
    
    tempParam["subject"] = subject
    tempParam["emailbody"] = emailBody
    
    postUploadFailureTask(params: params) { (result) in
        if !result {
            writeFile(strToWrite: "Unable to send error report!", className:"ErrorHandling", functionName: "uploadShowErrorAndNotify")
            //             DispatchQueue.main.async {
            //                _ = dialogOKCancel(question: "Warning", text: "Unable to send error report!")
            //            }
        }
    }
    
    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedUploadShowSASToken
    
    writeFile(strToWrite: error.localizedDescription, className: "iCONViewController", functionName: "uploadShowErrorAndNotify")
    
    if operation != nil {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnUploadFailed),
                                        object: nil,
                                        userInfo: ["failedOperation" : operation as Any])
    }
}

func uploadShowFetchSASTokenErrorAndNotify(error: Error, recoveryContext: [String : Any]) {
    print (" ------------ Failed to fetch SAS Token during show upload, error: ", error)
    
    // TODO: implement recovery logic
    let params = recoveryContext["json_main"] as! [String : String]
    let rows = recoveryContext["pendingUploads"] as! [String: UploadTableRow]
    for row in rows {
        row.value.completionStatusString = "Failed"
        row.value.uploadProgress = 100.0
    }
    
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.UpdateShowUploadProgress),
                                        object: nil)
    }
    
    var tempParam:[String:Any]
    tempParam = params
    var subject = "Failed to Upload asset" //"Failed to Upload asset for shoot day day001"
    var emailBody = "Hi,\n Upload Failed for asset with below error- \n The operation couldn’t be completed.\n\nPlease check your source location directory and retry."
    if let strShootday = params["shootDay"] {
        subject = "Upload Failed for asset \(strShootday)"
        emailBody = "Hi,\n Upload Failed for asset \(strShootday) with below error-\(error.localizedDescription).\n\nPlease check your source location directory and retry."
    }
    
    if let strShootday = params["shootDay"] {
        subject = "Upload Failed for asset \(strShootday)"
    }
    
    tempParam["subject"] = subject
    tempParam["emailbody"] = emailBody
    
    postUploadFailureTask(params: tempParam) { (result) in
        if !result {
            writeFile(strToWrite: "Unable to send error report!", className:"ErrorHandling", functionName: "uploadShowFetchSASTokenErrorAndNotify")
            //            DispatchQueue.main.async {
            //            _ = dialogOKCancel(question: "Warning", text: "Unable to send error report!")
            //            }
        }
    }
}

func fetchShowContentErrorAndNotify(error : Error, showName: String, showId : String) {
    AppDelegate.retryContext["showName"] = showName
    AppDelegate.retryContext["showId"] = showId
    AppDelegate.retryContext["cdsUserId"] = LoginViewController.cdsUserId!
    
    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchShowContent
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                        object: nil,
                                        userInfo: ["progressLabel" : error,
                                                   "disableProgress" : true,
                                                   "enableButton" : OutlineViewController.NameConstants.kRetryStr])
    }
}


func otpExpiredShowLoginScreen(error : Error, showName: String, showId : String) {
    AppDelegate.retryContext["showName"] = showName
    AppDelegate.retryContext["showId"] = showId
    AppDelegate.retryContext["cdsUserId"] = LoginViewController.cdsUserId!
    
    AppDelegate.lastError = AppDelegate.ErrorStatus.kOTPExpired
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                        object: nil,
                                        userInfo: ["progressLabel" : error,
                                                   "disableProgress" : true,
                                                   "TokenExpired" : OutlineViewController.NameConstants.kProceed])
    }
}
