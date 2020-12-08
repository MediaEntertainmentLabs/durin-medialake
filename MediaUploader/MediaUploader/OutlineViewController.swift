//
//  OutlineViewController.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa
import MSAL


// WARNING: Sandboxed application fairly limited in what it can actually sub-launch
//          So external programm need to be placed to /Applications folder
internal func runAzCopyCommand(cmd : String, args : [String]) -> (output: [String], error: [String], exitCode: Int32) {

    let output : [String] = []
    let error : [String] = []

    let task = Process()
    task.launchPath = cmd
    task.arguments = args
    
    let outpipe = Pipe()
    task.standardOutput = outpipe
    //let errpipe = Pipe()
    //task.standardError = errpipe

    var terminationObserver : NSObjectProtocol!
    terminationObserver = NotificationCenter.default.addObserver(forName: Process.didTerminateNotification,
                                                  object: task, queue: nil) { notification -> Void in
        NotificationCenter.default.removeObserver(terminationObserver!)
    }
    
    
    outpipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
    var outpipeObserver : NSObjectProtocol!
    outpipeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outpipe.fileHandleForReading , queue: nil) {
        notification in
        let output = outpipe.fileHandleForReading.availableData
        if (output.count > 0) {
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            DispatchQueue.main.async(execute: {
                print(outputString)
                
            })
        }
        outpipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
    }
    
    outpipe.fileHandleForReading.readabilityHandler = { (fileHandle) -> Void in
                 let availableData = fileHandle.availableData
                 let newOutput = String.init(data: availableData, encoding: .utf8)
                 print("\(newOutput!)")

             }
    
    
//    var errpipeObserver : NSObjectProtocol!
//    errpipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
//
//    errpipeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: errpipe.fileHandleForReading , queue: nil) {
//        notification in
//            let output = outpipe.fileHandleForReading.availableData
//            if (output.count > 0) {
//                let errorString = String(data: output, encoding: String.Encoding.utf8) ?? ""
//
//                DispatchQueue.main.async(execute: {
//                    print(errorString)
//
//                })
//                //output = nil
//            }
//        errpipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
//    }
//
//    errpipe.fileHandleForReading.readabilityHandler = { (fileHandle) -> Void in
//        autoreleasepool {
//            let availableData = fileHandle.availableData
//            let newOutput = String.init(data: availableData, encoding: .utf8)
//            print("\(newOutput!)")
//            // Display the new output appropriately in a NSTextView for example
//            //availableData = nil
//
//        }
//    }
    
    task.launch()
    
    task.waitUntilExit()
    let status = task.terminationStatus
    
    outpipe.fileHandleForReading.readabilityHandler = nil
    NotificationCenter.default.removeObserver(outpipeObserver!)
    //NotificationCenter.default.removeObserver(errpipeObserver!)

    return (output, error, status)
}



func fetchListOfShowsTask(cdsUserId: String, completion: @escaping (_ shows: [String:Any]) -> Void) {

    // prepare json data
    let json: [String: String] = ["userId" : cdsUserId]

    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)

    // create post request
    let url = URL(string: LoginViewController.kFetchShowsURL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"

    // insert json data to the request
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print(error?.localizedDescription ?? "No data")
            return
        }
        var shows : [String:Any] = [:]
        do {

            let responseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:Any]]
            for item in responseJSON! {
                let media_AssetContainer = item["media_AssetContainer"] as? String
                let asset = try JSONSerialization.jsonObject(with: Data(media_AssetContainer!.utf8), options: []) as? [String: Any]
                let showName = asset!["media_name"] as! String
                let showId = asset!["media_assetcontainerid"] as! String
                let media_AssetTemplate = asset!["media_AssetTemplate"] as! [String : Any]
                let media_AssetFolderLayout = media_AssetTemplate["media_AssetFolderLayout"] as! [String : Any]
                shows[showName] = ["showId":showId, "folderLayout":media_AssetFolderLayout["media_layout"]]
            }
            completion(shows)
            
        } catch let error as NSError {
            print(error)
            completion([:])
        }
    }

    task.resume()
}

final class FileUploadOperation: AsyncOperation {

    private let cmd: String
    private let args: [String]

    init(cmd: String, args: [String]) {
        self.cmd = cmd
        self.args = args
    }

    override func main() {
        let (output, error, status) = runAzCopyCommand(cmd: self.cmd, args: self.args)
        self.finish()
    }

    override func cancel() {
        super.cancel()
    }
}


class OutlineViewController: NSViewController,
                             NSTextFieldDelegate {
    // MARK: Constants
    
    struct NameConstants {
        // Default name for added folders and leafs.
        static let untitled = NSLocalizedString("untitled string", comment: "")
        // Places shows title.
        static let shows = NSLocalizedString("shows string", comment: "")
        // Pictures group title.
        static let pictures = NSLocalizedString("pictures string", comment: "")
    }
        
    // The data source backing of the NSOutlineView.
    @IBOutlet weak var treeController: NSTreeController!
    
    @IBOutlet weak var outlineView: OutlineView! {
        didSet {
            // As soon as we have our outline view loaded, we populate its content tree controller.
            //populateOutlineContents()
        }
    }
    
    private var treeControllerObserver: NSKeyValueObservation?
    //private var uploadViewController: UploadWindowViewController!
    private var iconViewController: IconViewController!
    
#if USE_AZURE_BLOBSTORAGE_API
    private var blobClient: StorageBlobClient?
#endif
    
    // Outline view content top-level content (backed by NSTreeController).
    @objc dynamic var contents: [AnyObject] = []
    
    var sasToken : String!
    
    var savedSelection: [IndexPath] = []
    
    var rowToAdd = -1 // A flagged row being added (for later renaming after it was added).
    
    // MARK: XMLParser variables
    let recordKey = "Blob"
    let dictionaryKeys = Set<String>(["Name", "Content-Length"])

    // a few variables to hold the results as we parse the XML

    var results: [[String: String]]?           // the whole array of dictionaries
    var currentDictionary: [String: String]? // the current dictionary
    var currentValue: String?                  // the current value for one of the keys in the dictionary
    var root : TreeElement!
    

    
    // MARK: View Controller Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        /*
        let defaults = UserDefaults.standard
        let initialDisclosure = defaults.string(forKey: "initialDisclosure")
        if initialDisclosure == nil {
            outlineView.expandItem(treeController.arrangedObjects.children![0])
            outlineView.expandItem(treeController.arrangedObjects.children![1])
            defaults.set("initialDisclosure", forKey: "initialDisclosure")
        }
        */
        setupObservers()
    }
    
    #if ENABLE_UPLOAD_WINDOW
    @objc private func showUploadWindow(_ notif: Notification) {
        
        let uploadWindowController = storyboard!.instantiateController(withIdentifier: "UploadWindowController") as! NSWindowController
        
        if let uploadWindow = uploadWindowController.window {
            //let application = NSApplication.shared
            //application.runModal(for: downloadWindow)
            let controller =  NSWindowController(window: uploadWindow)
            uploadWindow.contentViewController = uploadViewController
            controller.showWindow(self)
        }
    }
    #endif
    
    private func fetchShowContentTask(sasURI : String, completion: @escaping (_ data: Data) -> Void) {
        
        let url = URL(string: sasURI)!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print(error?.localizedDescription ?? "No data")
                return
            }
            completion(data)
        }
        
        task.resume()
    }

    func addPathToTree(root: TreeElement, fullPath: inout [String])
    {
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

    static let showID = "1001"
    @objc private func onSelectedShow(_ notification: Notification) {
        
        let showName = notification.userInfo?["showName"] as! String
        let fetchShowContentURI = notification.userInfo?["fetchShowContentURI"] as! String
        
        self.fetchShowContentTask(sasURI: fetchShowContentURI) { (data) in
            
            let parser = XMLParser(data: data)
            parser.delegate = self
            parser.parse()
            

            self.root = nil
            
            for item in self.results! as [[String : String]] {
                let components = NSString(string: item["Name"]!).pathComponents
                var reversedComponents : [String] = Array(components.reversed())
                if self.root == nil {
                    if reversedComponents.count == 1 {
                        self.root = TreeElement(value: "")
                    } else {
                        self.root = TreeElement(value: reversedComponents.removeLast())
                    }
                }
                self.addPathToTree(root: self.root, fullPath: &reversedComponents)
            }
    
            DispatchQueue.main.async {
                
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowOutlineViewController),
                                                object: nil)
                
                self.addGroupNode(showName, identifier: OutlineViewController.showID)
                if self.root != nil {
                    self.addFileSystemObject(root: self.root, isFolder: self.root.hasChildren(), indexPath: IndexPath(indexes: [0, 0]))
                } else {
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewControllerOnlyText),
                                                    object: nil,
                                                    userInfo: ["progressLabel" : "Show is empty!", "disableProgress" : true])
                    
                }
            }
        }
    }
    
    // Called by drag and drop from the Finder.
    func addFileSystemObject(root: TreeElement, isFolder: Bool, indexPath: IndexPath) {
        if root.hasChildren() {
                let node = OutlineViewController.fileSystemNode(from: root.value, isFolder: true)
                treeController.insert(node, atArrangedObjectIndexPath: indexPath)
        } else {
            let node = OutlineViewController.leafNode(from: root.value)
            treeController.insert(node, atArrangedObjectIndexPath: indexPath)
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
        treeController.insert(node, atArrangedObjectIndexPath: insertionIndexPath)
    }

  
  
    private func setupObservers() {
        
        #if ENABLE_UPLOAD_WINDOW
        // Notification to show Upload Window.
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showUploadWindow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.showUploadWindow),
            object: nil)
        #endif
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onSelectedShow(_:)),
            name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
            object: nil)
        
        
        #if ENABLE_UPLOAD_WINDOW
        uploadViewController = storyboard!.instantiateController(withIdentifier: "UploadWindowViewController") as? UploadWindowViewController
        #endif
        
        #if ENABLE_UPLOAD_WINDOW
        var aa = treeController.arrangedObjects.children![0].representedObject
        uploadViewController.nodeContent = aa as? Node
        #endif
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
    }
}

extension OutlineViewController: XMLParserDelegate {
    
    // initialize results structure
    func parserDidStartDocument(_ parser: XMLParser) {
        results = []
    }
    
    // start element
    //
    // - If we're starting a "record" create the dictionary that will hold the results
    // - If we're starting one of our dictionary keys, initialize `currentValue` (otherwise leave `nil`)
    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == recordKey {
            currentDictionary = [:]
        } else if dictionaryKeys.contains(elementName) {
            currentValue = ""
        }
    }
    
    // found characters
    //
    // - If this is an element we care about, append those characters.
    // - If `currentValue` still `nil`, then do nothing.
    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentValue? += string
    }
    
    // end element
    //
    // - If we're at the end of the whole dictionary, then save that dictionary in our array
    // - If we're at the end of an element that belongs in the dictionary, then save that value in the dictionary
    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == recordKey {
            results!.append(currentDictionary!)
            currentDictionary = nil
        } else if dictionaryKeys.contains(elementName) {
            currentDictionary![elementName] = currentValue
            currentValue = nil
        }
    }
    
    // Just in case, if there an error, report it. (We don't want to fly blind here.)
    
    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print(parseError)
        
        currentValue = nil
        currentDictionary = nil
        results = nil
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
