//
//  ErrorHandling.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

func uploadShowErrorAndNotify(error : Error, params : [String:String], operation : FileUploadOperation?) {
    
    postUploadFailureTask(params: params) { (result) in
        if !result {
            _ = dialogOKCancel(question: "Warning", text: "Unable to send error report!")
        }
    }
    
    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedUploadShowSASToken
    
    if operation != nil {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.OnUploadFailed),
                                        object: nil,
                                        userInfo: ["failedOperation" : operation])
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
    
    postUploadFailureTask(params: params) { (result) in
        if !result {
            _ = dialogOKCancel(question: "Warning", text: "Unable to send error report!")
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
