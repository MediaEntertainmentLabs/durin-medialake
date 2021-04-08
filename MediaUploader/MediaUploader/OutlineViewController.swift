//
//  OutlineViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa
import MSAL




class OutlineViewController: NSViewController,
                             NSTextFieldDelegate {
    // MARK: Constants

    struct NameConstants {
        static let untitled = NSLocalizedString("untitled string", comment: "")
        static let kShowsStr = NSLocalizedString("shows string", comment: "")
        static let kRetryStr = NSLocalizedString("retry string", comment: "")
        
        static let kFetchShowContentStr = NSLocalizedString("fetch show string", comment: "")
        static let kFetchListOfShowsStr = NSLocalizedString("fetch list shows string", comment: "")
        static let kFetchListOfShowsFailedStr = NSLocalizedString("fetch list shows fail string", comment: "")
        static let kFetchShowContentFailedStr = NSLocalizedString("fetch show content fail string", comment: "")
        static let kFetchListOfSeasonsFailedStr = NSLocalizedString("fetch seasons fail string", comment: "")
        static let kUploadShowFailedStr = NSLocalizedString("upload show fail string", comment: "")
        static let kInProgressStr = NSLocalizedString("in progress string", comment: "")
        static let kPausedStr = NSLocalizedString("paused string", comment: "")
        
        static let kGenerateOTPStr = NSLocalizedString("generate OTP  string", comment: "")
        static let kVerifyOTPStr = NSLocalizedString("verify OTP  string", comment: "")
        static let kGenerateOTPFailedStr = NSLocalizedString("generate OTP fail string", comment: "")
        static let kVerifyOTPFailedStr = NSLocalizedString("verify OTP fail string", comment: "")
        static let unableToFindUserToken = NSLocalizedString("unableToFindUserToken", comment: "")
        static let userToken = NSLocalizedString("userToken", comment: "")
        static let userAuthToken = NSLocalizedString("x-auth-token", comment: "")
        static let STRING_EMPTY = NSLocalizedString("", comment: "")
        static let otpLength = NSLocalizedString("otpLength", comment: "")
     }
        
    // The data source backing of the NSOutlineView.
    @IBOutlet weak var treeController: NSTreeController!
    private var iconViewController: IconViewController!
    
#if USE_AZURE_BLOBSTORAGE_API
    private var blobClient: StorageBlobClient?
#endif
    
    // Outline view content top-level content (backed by NSTreeController).
    @objc dynamic var contents: [AnyObject] = []
    
    var currentShowName:  String!
    var currentShowId: String!
    
    var savedSelection: [IndexPath] = []
    
    var rowToAdd = -1 // A flagged row being added (for later renaming after it was added).
    
    var xmlParser: XMLResponseParser?
    var root: TreeElement!
    
    var cancelTask: Bool = false

    var expireTimer: Timer!
    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSelectedShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onCancelPendingTasks(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onRefreshShowContent(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.RefreshShowContent),
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearContent(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.ClearShowContent),
            object: nil)
    }

    func addPathToTree(root: TreeElement, fullPath: inout [String]) {
        if(fullPath.isEmpty) {
            return
        }
        let dirName = fullPath.removeLast()
        if let newRoot = root.search(element: dirName) {
            addPathToTree(root: newRoot, fullPath: &fullPath)
        } else {
            let newRoot = TreeElement(value: dirName)
            root.add(newRoot)
            addPathToTree(root: newRoot, fullPath: &fullPath)
        }
    }
    
    @objc private func clearContent(_ notification: Notification) {
        treeController.content = nil
        contents.removeAll()
        currentShowName = nil
        currentShowId = nil
    }
    
    @objc private func onCancelPendingTasks(_ notification: Notification) {
        self.cancelTask = true
    }
    
    static let showID = "1001"
    @objc private func onSelectedShow(_ notification: Notification) {
        
        self.currentShowName = notification.userInfo?["showName"] as? String
        self.currentShowId = notification.userInfo?["showId"] as? String
        
        fetchShowContent(showName: self.currentShowName, showId: self.currentShowId)
    }
    
    @objc func onRefreshShowContent(_ sender: Any) {
        guard let currentShowName = self.currentShowName else { return }
        guard let currentShowId = self.currentShowId else { return }
        
        // update show content
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
            object: nil,
            userInfo: ["progressLabel" : OutlineViewController.NameConstants.kFetchShowContentStr])
        
        NotificationCenter.default.post(
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil,
            userInfo: ["showName" : currentShowName, "showId": currentShowId])
    }
    
    private func fetchShowContent(showName : String, showId : String) {
        
        var sasToken : String!
        
        fetchSASToken(showName: showName, showId: showId, synchronous: false) { (result,state) in
            switch state {
            case .pending:
                return
            case .cached:
                sasToken = result
            case .completed:
                NotificationCenter.default.post(
                    name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
                    object: nil,
                    userInfo: ["showName" : showName, "showId" : showId, "cdsUserId" : LoginViewController.cdsUserId!])
            }
        }
        
        // pending task completion
        if sasToken == nil {
            return
        }
        
        let fetchShowContentURI = sasToken + "&restype=container&comp=list"
        
        fetchShowContentTask(sasURI: fetchShowContentURI) { (result) in
            
            if let error = result["error"] as? String {
                fetchShowContentErrorAndNotify(error: error, showName: showName, showId: showId)
                return
            }
            guard let data = result["data"] as? Data else { fetchShowContentErrorAndNotify(error: "Failed to retrieve show content!", showName: showName, showId: showId); return }
            self.xmlParser = XMLResponseParser(data: data)
            
            guard let parser = self.xmlParser else {  fetchShowContentErrorAndNotify(error: "Failed to retrieve show content!", showName: showName, showId: showId); return }
            self.root = nil
            
            if parser.results == nil {
                fetchShowContentErrorAndNotify(error: "Failed to retrieve show content!", showName: showName, showId: showId)
                return
            }
            
            for item in parser.results! as [[String : String]] {
                let components = NSString(string: item["Name"]!).pathComponents
                var reversedComponents : [String] = Array(components.reversed())
                if self.root == nil {
                    //if reversedComponents.count == 1 {
                        self.root = TreeElement(value: showName)
                    //} else {
                    //    self.root = TreeElement(value: reversedComponents.removeLast())
                    //}
                }
                self.addPathToTree(root: self.root, fullPath: &reversedComponents)
            }
  
                // TODO: add cancelation logic
//            if self.cancelTask {
//                DispatchQueue.main.async {
//                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
//                                                    object: nil)
//                }
//                return
//            }
            DispatchQueue.main.async {
                self.addGroupNode(showName, identifier: OutlineViewController.showID)
            }
            if self.root != nil {
                
                let start = DispatchTime.now() // <<<<<<<<<< Start time
                self.addFileSystemObject(root: self.root, isFolder: self.root.hasChildren(), indexPath: IndexPath(indexes: [0, 0]))
                let end = DispatchTime.now()   // <<<<<<<<<<   end time
                let timeInterval_msec = Double(end.uptimeNanoseconds - start.uptimeNanoseconds) / 1_000_000
                
                print ("------------ update OutlineView Tree UI: ", timeInterval_msec, " ms")
                
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
                                                    object: nil)
                }
                
            } else {
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : "Show is empty!",
                                                               "disableProgress" : true])
                }
            }
        }
    }
    
    func addFileSystemObject(root: TreeElement, isFolder: Bool, indexPath: IndexPath) {
        if root.hasChildren() {
            let node = OutlineViewController.fileSystemNode(from: root.value, isFolder: true)
            DispatchQueue.main.async {
                if self.cancelTask {
                    //return
                }
                self.treeController.insert(node, atArrangedObjectIndexPath: indexPath)
            }
            
        } else {
            let node = OutlineViewController.leafNode(from: root.value)
            DispatchQueue.main.async {
                if self.cancelTask {
                    //return
                }
                self.treeController.insert(node, atArrangedObjectIndexPath: indexPath)
            }
        }
        
        for child in root.children() {
            let newIndexPath = indexPath
            let finalIndexPath = newIndexPath.appending(0)
            
            addFileSystemObject(root: child, isFolder: root.hasChildren(), indexPath: finalIndexPath)
        }
    }
    
    
    private func addGroupNode(_ folderName: String, identifier: String) {
        let node = Node()
        node.type = .container
        node.title = folderName
        node.identifier = identifier
        node.is_group_node = true
   
        var insertionIndexPath: IndexPath
        treeController.content = nil
        contents.removeAll()
        insertionIndexPath = IndexPath(index: contents.count)
        self.treeController.insert(node, atArrangedObjectIndexPath: insertionIndexPath)
    }
    
    // MARK: MSALInteractiveDelegate
    
    func didCompleteMSALRequest(withResult result: MSALResult) {
        LoginViewController.account = result.account
    }
    
    
    deinit {
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.CancelPendingURLTasks),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.RefreshShowContent),
            object: nil)
        
        NotificationCenter.default.removeObserver(
            self,
            name: Notification.Name(WindowViewController.NotificationNames.ClearShowContent),
            object: nil)
    }
}
    
#if USE_AZURE_BLOBSTORAGE_API
extension OutlineViewController: StorageBlobClientDelegate {
    func blobClient(_: StorageBlobClient, didUpdateTransfer transfer: BlobTransfer, withState transferState: TransferState, andProgress _: TransferProgress) {
        print("-------- blobClient didUpdateTransfer, transferType: ", transfer.transferType, "withState: ", transferState)
        if transfer.transferType == .upload {
            //collectionView.reloadData()
        }
    }

    func blobClient(_: StorageBlobClient, didCompleteTransfer transfer: BlobTransfer) {
        print("-------- blobClient didCompleteTransfer")
        if transfer.transferType == .upload {
            //collectionView.reloadData()
        }
    }

    func blobClient(_: StorageBlobClient, didFailTransfer _: BlobTransfer, withError error: Error) {
        print("-------- blobClient didFailTransfer")
        self.blobClient?.uploads.removeAll()
    }
}
#endif
