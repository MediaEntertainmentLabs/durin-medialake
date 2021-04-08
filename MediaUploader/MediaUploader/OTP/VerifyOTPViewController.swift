//
//  VerifyOTPViewController.swift
//  MediaUploader
//
//  Created by global on 09/03/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Cocoa

class VerifyOTPViewController: NSViewController, NSTextFieldDelegate {
    
    @IBOutlet weak var lblOTPMessage: NSTextField!
    @IBOutlet weak var txtOTP: NSTextField!
    @IBOutlet weak var btnSubmit: NSButton!
    let ACCEPTABLE_NUMBERS     = "0123456789"
    @IBOutlet weak var loadingIndicator: NSProgressIndicator!
    var strOTPMessage:String?
    var cdUserID:String?
    
    // reference to a window
    var window: NSWindow?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        txtOTP.delegate = self
        let onlyIntFormatter = OnlyIntegerValueFormatter()
        txtOTP.formatter = onlyIntFormatter
        self.hideIndicator()
    }
    
    @IBAction func btnSubmitClicked(_ sender: Any) {
        self.showIndicator()
        if  !txtOTP.stringValue.isEmpty {
            if txtOTP.stringValue.count < getOTPLength()! {
                hideIndicator()
                showPopoverMessage(positioningView: txtOTP, msg: "Kindly enter correct OTP ")
            }else {
                VerifyOtpStr(otpStr: txtOTP.stringValue)
            }
        } else {
            hideIndicator()
            showPopoverMessage(positioningView: txtOTP, msg: "Kindly enter OTP")
        }
    }
    
    func showIndicator(){
        loadingIndicator.isHidden = false
        loadingIndicator.startAnimation(self)
    }
    func hideIndicator(){
        loadingIndicator.isHidden = true
        loadingIndicator.stopAnimation(self)
    }
    
    private func VerifyOtpStr(otpStr: String) {
        print (" --------------- VerifyOtpStr ")
        
        verifyOTP(otp:otpStr, userID:cdUserID ?? "") { (result) in
            
            DispatchQueue.main.async {
                self.hideIndicator()
                if let error = result["error"] as? String {
                    _ = dialogOKCancel(question: error, text: OutlineViewController.NameConstants.STRING_EMPTY)
                    return
                }
                
                let userToken = result["token"] as! String
                
                // NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController), object: nil)
                print("userToken ::: \(userToken)")
                setUserToken(userToken: userToken)
                self.onLoginSuccessfull()
            }
        }
    }
    
    func onLoginSuccessfull()
    {
        guard let account = LoginViewController.account else { return }
        
        guard let identifier = account.identifier else { return }
        guard let username = account.username else { return }
        
        LoginViewController._azureUserId = identifier.components(separatedBy: ".")[0]
        
       // let storyboard = NSStoryboard(name:"Main", bundle: nil)
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        var windowController : NSWindowController! = appDelegate.mainWindowController
        if(windowController == nil) {
            windowController = storyboard!.instantiateController(withIdentifier: "WindowController") as? WindowController
        }
        windowController.contentViewController = storyboard!.instantiateController(withIdentifier: "WindowViewController") as? NSViewController
        windowController.showWindow(self)
        window?.performClose(self)
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.updateUserNameLabel),
                                        object: nil,
                                        userInfo: ["azureUserName": username])
        
        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
                                        object: nil)
        
        self.view.window?.close()
    }
    
    
//    @objc func passOTPMessage(_ notification: NSNotification) {
//
//        if let otpMessage = notification.userInfo?["otpMessage"] as? String {
//            lblOTPMessage.stringValue = otpMessage
//        }
//    }
    
}
