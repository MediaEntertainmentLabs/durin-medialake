//
//  ErrorHandling.swift
//  MediaUploader
//
//  Created by codecs on 09.12.2020.
//  Copyright © 2020 Mykola Gerasymenko. All rights reserved.
//

import Cocoa

func uploadShowErrorAndNotify(error : Error, cdsUserId : String, showId : String) {
    
    AppDelegate.retryContext["cdsUserId"] = cdsUserId
    AppDelegate.retryContext["showId"] = showId
    
    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedUploadShowSASToken
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                        object: nil,
                                        userInfo: ["progressLabel" : error,
                                                   "disableProgress" : true,
                                                   "enableButton" : OutlineViewController.NameConstants.kRetryStr])
    }
}

func fetchShowContentErrorAndNotify(error : Error, showName: String, showId : String, cdsUserId : String) {
    AppDelegate.retryContext["showName"] = showName
    AppDelegate.retryContext["showId"] = showId
    AppDelegate.retryContext["cdsUserId"] = cdsUserId

    AppDelegate.lastError = AppDelegate.ErrorStatus.kFailedFetchShowContent
    DispatchQueue.main.async {
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                        object: nil,
                                        userInfo: ["progressLabel" : error,
                                                   "disableProgress" : true,
                                                   "enableButton" : OutlineViewController.NameConstants.kRetryStr])
    }
}
