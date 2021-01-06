//
//  LoginViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa
import MSAL

class ConfigurationTextField : NSTextField {
    
    override var intrinsicContentSize: NSSize {
        var minSize: NSSize {
            var size = super.intrinsicContentSize
            size.width = 0
            return size
        }

        var newSize = super.intrinsicContentSize
        newSize.width = 200
        newSize.height = 300
        return newSize
    }
}


@IBDesignable
class HyperlinkTextField: NSTextField {

    var parent: LoginViewController!
    
    @IBInspectable var href: String = ""

    override func resetCursorRects() {
        discardCursorRects()
        addCursorRect(self.bounds, cursor: NSCursor.pointingHand)
    }

    override func awakeFromNib() {
        super.awakeFromNib()

        // TODO:  Fix this and get the hover click to work.

        let attributes: [NSAttributedString.Key: Any] = [
            NSAttributedString.Key.foregroundColor: NSColor.linkColor,
            NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue as AnyObject,
        ]
        attributedStringValue = NSAttributedString(string: self.stringValue, attributes: attributes)
    }
    
    func setParent(parent: LoginViewController) {
        self.parent = parent
    }
    
    override func mouseDown(with theEvent: NSEvent) {
        if (self.parent != nil) {
            self.parent.newUserButtonClicked(self)
        }
    }
    
    override func becomeFirstResponder() -> Bool {
        addTrackingAreaIfNeeded()
        return super.becomeFirstResponder()
    }
    override func mouseMoved(with event: NSEvent) {
        super.mouseMoved(with: event)
        NSCursor.pointingHand.set()
    }
    private func addTrackingAreaIfNeeded() {
        if trackingAreas.isEmpty {
            let area = NSTrackingArea(rect: bounds, options: [.mouseEnteredAndExited, .activeAlways], owner: self, userInfo: nil)
            addTrackingArea(area)
        }
    }
}


class LoginViewController: NSViewController {

    //static let kAzCopyCmdPath = "/Applications/azcopy"
    static let kAzCopyCmdDownloadURL = "https://aka.ms/downloadazcopy-v10-mac";
    static let kGraphEndpoint = "https://graph.microsoft.com/"
    static let kAuthority = "https://login.microsoftonline.com/common"
    
    static let keyTenantId = "kTenantId"
    static let keyClientId = "kClientId"
    static let keyRedirectURI = "kRedirectURI"
    
    static let keyLogicGetShowForUser: String = "Logic-GetShowForUser"
    static let keyLogicSendEmail: String = "Logic-SendEmail"
    static let keyLogicAssetUploadFailure: String = "Logic-AssetUploadFailure"
    static let keyLogicGenerateSASToken: String = "Logic-GenerateSASToken"
    static let keyLogicGetAssetsAndFiles: String = "Logic-GetAssetsAndFiles"
    static let keyLogicGetSeasonEpisodeForShow: String = "Logic-GetSeasonEpisodeForShow"
 
    
    static var kTenantID: String!
    static var kClientID: String!
    static var kRedirectUri: String!
    static var kConfigJson: [String:String]!
    
    @IBOutlet weak var usernameTextField: NSTextField!
    @IBOutlet weak var passwordTextField: NSSecureTextField!
    @IBOutlet weak var loginButton: NSButton!
    
    @IBOutlet weak var backButton: NSButton!
    @IBOutlet weak var loginProgress: NSProgressIndicator!
    
    @IBOutlet weak var clientIdStackView: NSStackView!
    @IBOutlet weak var tenantIdStackView: NSStackView!
    @IBOutlet weak var redirectURIStackView: NSStackView!
    @IBOutlet weak var configStackView: NSStackView!
    
    @IBOutlet weak var configLabel: NSTextField!
    @IBOutlet weak var configurationTextField: NSTextField!
    
    @IBOutlet weak var clientIdTextField: NSTextField!
    @IBOutlet weak var tenantIdTextField: NSTextField!
    @IBOutlet weak var redirectURITextField: NSTextField!
    
    @IBOutlet weak var versionLabel: NSTextField!
    
    @IBOutlet weak var newUserLabel: HyperlinkTextField!
    
    //"https://storage.azure.com/.default"
    let kScopes: [String] = ["user.read"]
 
    static var azcopyPath = Bundle.main.bundleURL.appendingPathComponent("Contents")
                                                 .appendingPathComponent("Resources")
                                                 .appendingPathComponent("azcopy")
    
    
    var isConfigInitialized : Bool = false
    var isConfigScreen : Bool = false
    var accessToken = String()
    static var application : MSALPublicClientApplication?
    var webViewParamaters : MSALWebviewParameters?
    static var account: MSALAccount?
    static var _azureUserId : String?
    static var cdsUserId: String? //= "fd895b30-1016-eb11-a812-000d3a530323" // TODO: fetch from portal
   
    static var apiUrls: [String:String] = [:]
    
    static var getShowForUserURI : String? {
        return LoginViewController.apiUrls[keyLogicGetShowForUser]
    }
    
    static var assetUploadFailureURI : String? {
        return LoginViewController.apiUrls[keyLogicAssetUploadFailure]
    }
    
    static var generateSASTokenURI : String? {
        return LoginViewController.apiUrls[keyLogicGenerateSASToken]
    }
    
    static var getAssetsAndFilesURI : String? {
        return LoginViewController.apiUrls[keyLogicGetAssetsAndFiles]
    }
    
    static var getSeasonDetailsForShowURI : String? {
        return LoginViewController.apiUrls[keyLogicGetSeasonEpisodeForShow]
    }
    
    static var sendEmailURI : String? {
        return LoginViewController.apiUrls[keyLogicSendEmail]
    }
    
    typealias AccountCompletion = (MSALAccount?) -> Void
    
    // reference to a window
    var window: NSWindow?
    
    override func viewDidAppear() {
        // After a window is displayed, get the handle to the new window.
        window = self.view.window!
        self.hideProgress()
        
        AppDelegate.appDelegate.loginWindowController = window!.windowController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.isConfigInitialized = checkConfigInitialized()
        self.isConfigScreen = !self.isConfigInitialized
        
        hideConfiguration(hide: self.isConfigInitialized)
        
        self.backButton.isHidden = true
        self.newUserLabel.isHidden = !self.isConfigInitialized
        self.newUserLabel.setParent(parent: self)
        
        if let ver = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            if let build_number = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                versionLabel.stringValue = "ver.\(ver).\(build_number)"
                print ("------------ ", versionLabel.stringValue)
            }
        }
        
        tryLogin()
    
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(signOut(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.logoutItem),
            object: nil)
    }
    
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        var width :Int = 600
        var height :Int = 800
        
        if !isConfigInitialized {
            self.backButton.isHidden = true
        } else {
            self.backButton.isHidden = !isConfigScreen
        }
        
        self.newUserLabel.isHidden = isConfigScreen
        
        if isConfigScreen == false {
            width  = 300
            height = 450
            hideConfiguration(hide: true)
        }
        if let w = self.view.window {
            var frame = w.frame
            frame.size = NSSize(width: width, height: height)
            w.setFrame(frame, display: true, animate: true)
            
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.logoutItem),
            object: nil)
    }
    
    func tryLogin(){
        if (LoginViewController.kClientID != nil) && (LoginViewController.kRedirectUri != nil) {
            do {
                try self.initMSAL()
            } catch let error {
                self.updateLogging(text: "Unable to create Application Context \(error)")
            }
            
            self.loadCurrentAccount()
        }
    }
    
    
    /**
     
     Initialize a MSALPublicClientApplication with a given clientID and authority
     
     - clientId:            The clientID of your application, you should get this from the app portal.
     - redirectUri:         A redirect URI of your application, you should get this from the app portal.
     If nil, MSAL will create one by default. i.e./ msauth.<bundleID>://auth
     - authority:           A URL indicating a directory that MSAL can use to obtain tokens. In Azure AD
     it is of the form https://<instance/<tenant>, where <instance> is the
     directory host (e.g. https://login.microsoftonline.com) and <tenant> is a
     identifier within the directory itself (e.g. a domain associated to the
     tenant, such as contoso.onmicrosoft.com, or the GUID representing the
     TenantID property of the directory)
     - error                The error that occurred creating the application object, if any, if you're
     not interested in the specific error pass in nil.
     */
    func initMSAL() throws {
        print(" ------------------ initMSAL")
        guard let authorityURL = URL(string: LoginViewController.kAuthority) else {
            self.updateLogging(text: "Unable to create authority URL")
            self.hideProgress()
            return
        }
        
        let authority = try MSALAADAuthority(url: authorityURL)
        
        let msalConfiguration = MSALPublicClientApplicationConfig(clientId: LoginViewController.kClientID,
                                                                  redirectUri: LoginViewController.kRedirectUri,
                                                                  authority: authority)
        
        if let bundleIdentifier = Bundle.main.bundleIdentifier {
            msalConfiguration.cacheConfig.keychainSharingGroup = bundleIdentifier
        }
        
        LoginViewController.application = try MSALPublicClientApplication(configuration: msalConfiguration)
        self.webViewParamaters = MSALWebviewParameters()
    }
    
    static var azureUserId: String? {
        if let userId = _azureUserId {
            return userId
        }
        return nil
    }
    
    static var currentAccount: MSALAccount? {
        if let acc = account {
            return acc
        }
        guard let application = application else { return nil }
        // We retrieve our current account by getting the first account from cache
        // In multi-account applications, account should be retrieved by home account identifier or username instead
        do {
            let cachedAccounts = try application.allAccounts()

            if !cachedAccounts.isEmpty {
                return cachedAccounts.first
            }
        } catch let error as NSError {
            print("Didn't find any accounts in cache: \(error)")
        }
        return nil
    }
    
    func loadCurrentAccount(completion: AccountCompletion? = nil) {
        
        guard let applicationContext = LoginViewController.application else { return }
        
        let msalParameters = MSALParameters()
        msalParameters.completionBlockQueue = DispatchQueue.main
                
        // Note that this sample showcases an app that signs in a single account at a time
        // If you're building a more complex app that signs in multiple accounts at the same time, you'll need to use a different account retrieval API that specifies account identifier
        // For example, see "accountsFromDeviceForParameters:completionBlock:" - https://azuread.github.io/microsoft-authentication-library-for-objc/Classes/MSALPublicClientApplication.html#/c:objc(cs)MSALPublicClientApplication(im)accountsFromDeviceForParameters:completionBlock:
        applicationContext.getCurrentAccount(with: msalParameters, completionBlock: { (currentAccount, previousAccount, error) in
            
            if let error = error {
                self.updateLogging(text: "Couldn't query current account with error: \(error)")
                if let completion = completion {
                    completion(nil)
                }
                return
            }
            
            if let current = currentAccount {
                
                self.updateLogging(text: "Found a signed in account \(String(describing: current.username)). Updating data for that account...")
                
                self.updateCurrentAccount(acc: current)
                
                if let completion = completion {
                    completion(current)
                }
                
                return
            }
            
            self.updateLogging(text: "Account signed out. Updating UX")
            self.accessToken = ""
            self.updateCurrentAccount(acc: nil)
            
            if let completion = completion {
                completion(nil)
            }
        })
    }
    
    func updateCurrentAccount(acc: MSALAccount?) {
   
        LoginViewController.account = acc
        
        if (LoginViewController.account != nil)
        {
            self.showProgress()
            self.acquireTokenSilently(LoginViewController.account)
        }
        let signInStr = self.isConfigScreen ? "Save & Sign In" : "Sign In"
        self.loginButton.title = acc != nil ? "Sign Out" : signInStr
   
        /*
        if (account != nil)
        {
            self.acquireTokenSilently(self.currentAccount)
            
            self.azureUserId = self.currentAccount!.identifier!.components(separatedBy: ".")[0]
            
            windowViewController = storyboard!.instantiateController(withIdentifier: "WindowViewController") as? WindowViewController
        
            let windowController = storyboard!.instantiateController(withIdentifier: "WindowController") as! NSWindowController
            
            if let mainWindow = windowController.window {
                let controller =  NSWindowController(window: mainWindow)
                windowController.contentViewController = windowViewController
                controller.showWindow(self)
                window?.performClose(nil) // nil because I'm not return a message
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.updateUserNameLabel),
                                                object: nil,
                                                userInfo: ["azureUserName": self.currentAccount?.username])
            }
        }*/
    }
    
    func updateLogging(text : String) {
        
        if Thread.isMainThread {
            print(text)
        } else {
            DispatchQueue.main.async {
                print(text)
            }
        }
    }

    private func checkConfigInitialized() -> Bool {

        if let url = readConfig(key: LoginViewController.keyLogicGetShowForUser) {
            LoginViewController.apiUrls[LoginViewController.keyLogicGetShowForUser] = url
        } else {
            print("-------- failed to read \(LoginViewController.keyLogicGetShowForUser) from config.json")
            return false
        }

        if let url = readConfig(key: LoginViewController.keyLogicAssetUploadFailure) {
            LoginViewController.apiUrls[LoginViewController.keyLogicAssetUploadFailure] = url
        } else {
            print("-------- failed to read \(LoginViewController.keyLogicAssetUploadFailure) from config.json")
            return false
        }

        if let url = readConfig(key: LoginViewController.keyLogicGenerateSASToken) {
            LoginViewController.apiUrls[LoginViewController.keyLogicGenerateSASToken] = url
        } else {
            print("-------- failed to read \(LoginViewController.keyLogicGenerateSASToken) from config.json")
            return false
        }

        if let url = readConfig(key: LoginViewController.keyLogicGetSeasonEpisodeForShow) {
            LoginViewController.apiUrls[LoginViewController.keyLogicGetSeasonEpisodeForShow] = url
        }
        else {
            print("-------- failed to read \(LoginViewController.keyLogicGetSeasonEpisodeForShow) from config.json")
            return false
        }

        if let url = readConfig(key: LoginViewController.keyLogicSendEmail) {
            LoginViewController.apiUrls[LoginViewController.keyLogicSendEmail] = url
        } else {
            print("-------- failed to read \(LoginViewController.keyLogicSendEmail) from config.json")
            return false
        }

        if let clientId = readConfig(key: LoginViewController.keyClientId) {
            LoginViewController.kClientID = clientId
        } else {
            print("-------- failed to read \(LoginViewController.keyClientId) from config.json")
            return false
        }

//        if let tenantId = readConfig(key: LoginViewController.keyTenantId) {
//            LoginViewController.kTenantID = tenantId
//        } else {
//            print("-------- failed to read \(LoginViewController.keyTenantId) from config.json")
//            return false
//        }

        if let redirectURI = readConfig(key: LoginViewController.keyRedirectURI) {
            LoginViewController.kRedirectUri = redirectURI
        } else {
            print("-------- failed to read \(LoginViewController.keyRedirectURI) from config.json")
            return false
        }

        return true
    }
    
    func saveCredentials () -> Bool {
        
        var dict:[String:String] = [:]
        if isConfigScreen {
            dict[LoginViewController.keyClientId] = LoginViewController.kClientID
            //dict[LoginViewController.keyTenantId] = LoginViewController.kTenantID
            dict[LoginViewController.keyRedirectURI] = LoginViewController.kRedirectUri
            
            for (key,value) in LoginViewController.kConfigJson {
                LoginViewController.apiUrls[key] = value
                dict[key] = value
            }
            
            writeConfig(item: dict)
        }
        self.isConfigInitialized = true
        
        return true
    }
    
    @IBAction func loginButtonClicked(_ sender: Any) {
        
        if self.isConfigScreen {
                        
            if clientIdTextField.stringValue.isEmpty ||
                redirectURITextField.stringValue.isEmpty ||
                configurationTextField.stringValue.isEmpty {
                showPopoverMessage(positioningView: clientIdTextField, msg: "Please, fill in all the fields!")
                return
            }
            
            LoginViewController.kClientID = clientIdTextField.stringValue
            LoginViewController.kRedirectUri = redirectURITextField.stringValue
            
            do {
                let data = Data(configurationTextField.stringValue.utf8)
                if let json = try JSONSerialization.jsonObject(with: data) as? [String:String] {
                    LoginViewController.kConfigJson = json
                }
            } catch {
                _ = dialogOKCancel(question: "Warning", text: "Wrong configuration string!")
                return
            }
            
            self.tryLogin()
        }
        
        self.loadCurrentAccount { (account) in
            guard account != nil else {
                
                // We check to see if we have a current logged in account.
                // If we don't, then we need to sign someone in.
                self.acquireTokenInteractively()
                return
            }
            self.signOut(self)
            return
        }
    }
    
    func updateLoginButtonTitle() {
        let signInStr = self.isConfigScreen ? "Save & Sign In" : "Sign In"
        self.loginButton.title = LoginViewController.account != nil ? "Sign Out" : signInStr
    }
    
    func newUserButtonClicked(_ sender: Any) {
        let state = self.isConfigInitialized
        self.isConfigInitialized = false
        self.isConfigScreen = true
        
        DispatchQueue.main.async {
            self.updateLoginButtonTitle()
            self.viewWillAppear()
            self.hideConfiguration(hide: false)
            self.enableConfiguration(enable: true)
        }
        
        self.newUserLabel.isHidden = true
        self.backButton.isHidden = false
        
        self.isConfigInitialized = state
    }
    
    @IBAction func backButtonClicked(_ sender: Any) {
        self.isConfigScreen = false
        
        DispatchQueue.main.async {
            self.updateLoginButtonTitle()
            self.hideConfiguration(hide: true)
            self.viewWillAppear()
        }
        
        self.backButton.isHidden = true
        self.newUserLabel.isHidden = false
    }
    
    @objc func signOut(_ sender: Any) {
        
        guard let applicationContext = LoginViewController.application else { return }
        guard let account = LoginViewController.currentAccount else { return }
        guard let webViewParamaters = self.webViewParamaters else { return }
        
        do {
            /**
             Removes all tokens from the cache for this application for the provided account
             
             - account:    The account to remove from the cache
             */
            
            let signoutParameters = MSALSignoutParameters(webviewParameters: webViewParamaters)
            signoutParameters.signoutFromBrowser = true
            
            applicationContext.signout(with: account, signoutParameters: signoutParameters, completionBlock: {(success, error) in
                
                if let error = error {
                    self.updateLogging(text: "Couldn't sign out account with error: \(error)")
                } else {
                    self.updateLogging(text: "Sign out completed successfully")
                }
                self.accessToken = ""
                self.updateCurrentAccount(acc: nil)
                
                if (self.window != nil) {
                    self.window?.makeKeyAndOrderFront(self)
                }
                
                if (AppDelegate.appDelegate.mainWindowController.contentViewController != nil) {
                    AppDelegate.appDelegate.mainWindowController.contentViewController?.removeFromParent()
                    AppDelegate.appDelegate.mainWindowController.contentViewController = nil
                }
                AppDelegate.appDelegate.mainWindowController = nil
            })
        }
    }
    
    func acquireTokenInteractively() {
        
        guard let applicationContext = LoginViewController.application else { return }
        guard let webViewParameters = self.webViewParamaters else { return }
        
        let parameters = MSALInteractiveTokenParameters(scopes: kScopes, webviewParameters: webViewParameters)
        parameters.promptType = .selectAccount
        
        self.showProgress()

        applicationContext.acquireToken(with: parameters) { (result, error) in
            
            if let error = error {
                
                self.updateLogging(text: "------------ Could not acquire token: \(error)")
                self.hideProgress()
                if !self.isConfigInitialized {
                    self.hideConfiguration(hide: false)
                }
                showPopoverMessage(positioningView: self.clientIdTextField, msg: "Invalid credentials!")
                return
            }
            
            guard let result = result else {
                
                self.updateLogging(text: "------------ Could not acquire token: No result returned")
                self.hideProgress()
                if !self.isConfigInitialized {
                    self.hideConfiguration(hide: false)
                }
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "----------- Access token is \(self.accessToken)")
            
            self.getContentWithToken() { isValid in
                
                self.hideProgress()
                
                if isValid {
                    LoginViewController.account = result.account
                  
                    DispatchQueue.main.async {
                        
                        if !self.saveCredentials() {
                            return
                        }
                        self.isConfigScreen = false
                        
                        self.clientIdTextField.stringValue = ""
                        self.redirectURITextField.stringValue = ""
                        self.configurationTextField.stringValue = ""
                        
                        self.onLoginSuccessfull(self)
                    }
                } else {
                    LoginViewController.account = nil
                    self.hideProgress()
                    // TODO: token is invalid print message
                }
            }
        }
    }
    
    func hideProgress() {
        DispatchQueue.main.async {
            self.loginProgress.isHidden = true
            self.loginProgress.stopAnimation(self)
            self.loginButton.isEnabled = true
            self.newUserLabel.isEnabled = true
            self.backButton.isEnabled = true
            self.enableConfiguration(enable: true)
        }
    }
    
    func showProgress() {
        DispatchQueue.main.async {
            self.loginProgress.isHidden = false
            self.loginProgress.startAnimation(self)
            self.loginButton.isEnabled = false
            self.newUserLabel.isEnabled = false
            self.backButton.isEnabled = false
            self.enableConfiguration(enable: false)
        }
    }
    
    func hideConfiguration(hide: Bool) {
        DispatchQueue.main.async {
            self.clientIdStackView.isHidden = hide
            //self.tenantIdStackView.isHidden = hide
            self.redirectURIStackView.isHidden = hide
            self.configStackView.isHidden = hide
            self.configLabel.isHidden = hide
            self.configurationTextField.isHidden = hide
        }
    }
    
    func enableConfiguration(enable: Bool) {
        
        // looks like a bug, during hidding of text fields text dissapears
        // so we save and restore text again
        let clientIdTextField = self.clientIdTextField.stringValue
        let redirectURITextField = self.redirectURITextField.stringValue
        let configurationTextField = self.configurationTextField.stringValue

        if self.isConfigScreen {
            print (" ----------------- enableConfiguration ", enable )
            self.clientIdTextField.isEnabled = enable
            //self.tenantIdTextField.isEnabled = enable
            self.redirectURITextField.isEnabled = enable
            self.configurationTextField.isEnabled = enable
        } else {
            print (" ----------------- enableConfiguration isConfigScreen == false" )
            self.clientIdTextField.isEnabled = false
            //self.tenantIdTextField.isEnabled = false
            self.redirectURITextField.isEnabled = false
            self.configurationTextField.isEnabled = false
        }
        self.clientIdTextField.stringValue = clientIdTextField
        self.redirectURITextField.stringValue = redirectURITextField
        self.configurationTextField.stringValue = configurationTextField
    }
    
    func acquireTokenSilently(_ account : MSALAccount!) {
        
        guard let applicationContext = LoginViewController.application else { return }
        
        /**
         
         Acquire a token for an existing account silently
         
         - forScopes:           Permissions you want included in the access token received
         in the result in the completionBlock. Not all scopes are
         guaranteed to be included in the access token returned.
         - account:             An account object that we retrieved from the application object before that the
         authentication flow will be locked down to.
         - completionBlock:     The completion block that will be called when the authentication
         flow completes, or encounters an error.
         */
        
        let parameters = MSALSilentTokenParameters(scopes: kScopes, account: account)
        
        applicationContext.acquireTokenSilent(with: parameters) { (result, error) in
            
            if let error = error {
                
                let nsError = error as NSError
                
                // interactionRequired means we need to ask the user to sign-in. This usually happens
                // when the user's Refresh Token is expired or if the user has changed their password
                // among other possible reasons.
                
                if (nsError.domain == MSALErrorDomain) {
                    
                    if (nsError.code == MSALError.interactionRequired.rawValue) {
                        
                        DispatchQueue.main.async {
                            self.acquireTokenInteractively()
                        }
                        return
                    }
                }
                
                self.updateLogging(text: "Could not acquire token silently: \(error)")
                self.hideProgress()
                return
            }
            
            guard let result = result else {
                self.updateLogging(text: "Could not acquire token: No result returned")
                self.hideProgress()
                return
            }
            
            self.accessToken = result.accessToken
            self.updateLogging(text: "Refreshed Access token is \(self.accessToken)")
            self.getContentWithToken() { isValid in
                // do something with the returned Bool
                DispatchQueue.main.async {
                    if isValid {
                        self.onLoginSuccessfull(self)
                    } else {
                        self.hideProgress()
                    }
                    
                }
            }
        }
    }
    
    func getGraphEndpoint() -> String {
        return LoginViewController.kGraphEndpoint.hasSuffix("/") ? (LoginViewController.kGraphEndpoint + "v1.0/me/") : (LoginViewController.kGraphEndpoint + "/v1.0/me/");
    }
    
    
    /**
     This will invoke the call to the Microsoft Graph API. It uses the
     built in URLSession to create a connection.
     */
    
    func getContentWithToken(completion: @escaping (Bool)->() ) {
        
        // Specify the Graph API endpoint
        let graphURI = getGraphEndpoint()
        guard let url = URL(string: graphURI) else { self.updateLogging(text: "Couldn't deserialize result JSON"); completion(false); return }
        var request = URLRequest(url: url)
        
        // Set the Authorization header for the request. We use Bearer tokens, so we specify Bearer + the token we got from the result
        request.setValue("Bearer \(self.accessToken)", forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            
            if let error = error {
                self.updateLogging(text: "Couldn't get graph result: \(error)")
                completion(false)
                return
            }
            
            guard let data = data else { completion(false); return }
            
            guard (try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]) != nil else {
                
                self.updateLogging(text: "Couldn't deserialize result JSON")
                completion(false)
                return
            }
            completion(true)

        }.resume()
    }   
    
    @objc private func onLoginSuccessfull(_ sender: Any)
    {
        guard let account = LoginViewController.account else { return }
        
        guard let identifier = account.identifier else { return }
        guard let username = account.username else { return }
        
        LoginViewController._azureUserId = identifier.components(separatedBy: ".")[0]
        
        
        //NSApplication.shared.mainWindow?.windowController!.showWindow(self)
        let appDelegate = NSApplication.shared.delegate as! AppDelegate
        var windowController : NSWindowController! = appDelegate.mainWindowController
        if(windowController == nil) {
            windowController = storyboard!.instantiateController(withIdentifier: "WindowController") as? WindowController
        }

        if let mainWindow = windowController!.window {
            let controller =  NSWindowController(window: mainWindow)
            controller.showWindow(self)
            window?.performClose(nil) // nil because I'm not return a message
            
            NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.updateUserNameLabel),
                                            object: nil,
                                            userInfo: ["azureUserName": username])
            
            NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.LoginSuccessfull),
                                            object: nil)
        }
    }
}
