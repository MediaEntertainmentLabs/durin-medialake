//
//  Utils.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

extension String: Error {}

class TreeElement {
    var value: String
    var _children:[TreeElement] = []
    
    init (value: String) {
        self.value = value
    }
    
    init () {
        self.value = String()
    }
    
    func add(_ child: TreeElement) {
        self._children.append(child)
    }
    
    func search(element: String) -> TreeElement? {
        if "\(element)" == "\(self.value)"{
            return self
        }
        
        for child in _children {
            if let result = child.search(element: element){
                return result
            }
        }
        
        return nil
    }
    
    func hasChildren() -> Bool {
        return self._children.count > 0
    }
    
    func children() -> [TreeElement] {
        return self._children
    }
    
    func removeAll() ->Void {
        
    }
}


extension NSMutableAttributedString {
    
    public func setAsLink(textToFind:String, linkURL:String) -> Bool {
        
        let foundRange = self.mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            self.addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }
}

func isDarkMode() -> Bool {
    let mode = UserDefaults.standard.string(forKey: "AppleInterfaceStyle")
    return mode == "Dark"
}

func dialogOKCancel(question: String, text: String) -> Bool {
    let alert = NSAlert()
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = NSAlert.Style.critical
    alert.addButton(withTitle:StringConstant().strOk)
    return alert.runModal() == NSApplication.ModalResponse.alertFirstButtonReturn
}

func dialogOverwrite(question: String, text: String) -> NSApplication.ModalResponse {
    let alert = NSAlert()
    alert.accessoryView = NSView(frame: NSMakeRect(0, 0, 500.0, 0))
    
    alert.messageText = question
    alert.informativeText = text
    alert.alertStyle = NSAlert.Style.critical
    alert.addButton(withTitle:StringConstant().replace)
    alert.addButton(withTitle:StringConstant().append)
    let modalResult = alert.runModal()
    
    return modalResult
}

func showPopoverMessage(positioningView: NSView, msg: String) {
    let storyboard = NSStoryboard(name: "Main", bundle: nil)
    let vc = storyboard.instantiateController(withIdentifier: "popover") as? PopoverViewController
    let popover = NSPopover()
    popover.behavior = .transient
    popover.contentViewController = vc
    popover.show(relativeTo: positioningView.bounds, of: positioningView, preferredEdge: NSRectEdge.maxY)
    vc?.popoverMessage.stringValue = msg
    return
}

func configURLPath() -> URL? {
    if let localConfigPath = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
        do {
            try FileManager.default.createDirectory(atPath: localConfigPath.appendingPathComponent(Bundle.main.bundleIdentifier!).path, withIntermediateDirectories: true, attributes: nil)
        } catch {
            print("Error: \(error.localizedDescription)")
        }
        
        return localConfigPath.appendingPathComponent(Bundle.main.bundleIdentifier!).appendingPathComponent("config.json")
    }
    return nil
}

extension Data {
    func appendToURL(fileURL: URL) throws {
        if let fileHandle = try? FileHandle(forWritingTo: fileURL) {
            defer {
                fileHandle.closeFile()
            }
            fileHandle.seekToEndOfFile()
            fileHandle.write(self)
        }
        else {
            try write(to: fileURL, options: .atomic)
        }
    }
}

func appendConfig(item: [String:String]) {
    guard let configPath = configURLPath() else { return }
    
    do {
        if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys, .prettyPrinted]) {
            try jsonData.appendToURL(fileURL: configPath)
            if let str: Data = "\r\n".data(using: .utf8) {
                try str.appendToURL(fileURL: configPath)
            }
        }
    } catch let error as NSError {
        print(error)
        // TODO: show Alert
        return
    }
}

func writeConfig(item: [String:String]) {
    guard let configPath = configURLPath() else { return }
    
    do {
        if let jsonData = try? JSONSerialization.data(withJSONObject: item, options: [.sortedKeys, .prettyPrinted]) {
            try jsonData.write(to: configPath)
        }
    } catch let error as NSError {
        print(error)
        // TODO: show Alert
        return
    }
}

func readConfig(key: String) -> String? {
    guard let configPath = configURLPath() else { return nil }
    
    do {
        let data = try Data(contentsOf: configPath, options: .mappedIfSafe)
        let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)
        if let jsonResult = jsonResult as? Dictionary<String, AnyObject> {
            let apiURL = jsonResult[key] as? String
            return apiURL
        }
    } catch let error as NSError {
        print(error)
        // TODO: show Alert
        return nil
    }
    return nil
}


func removeFile(path: String) {
    do {
        if FileManager.default.fileExists(atPath: path) {
            try FileManager.default.removeItem(atPath: path)
        } else {
            print("File does not exist")
        }
        
    } catch let error as NSError {
        print("An error took place: \(error)")
    }
}


func jsonFromDict(from object:Any) -> String {
    
    let retString = ""
    do {
        let jsonData = try JSONSerialization.data(withJSONObject: object, options: .prettyPrinted)
        // here "jsonData" is the dictionary encoded in JSON data
        let decoded = try JSONSerialization.jsonObject(with: jsonData, options: [])
        // here "decoded" is of type `Any`, decoded from JSON data
        
        print("metadata::\(decoded)");
        
    } catch {
        print(error.localizedDescription)
    }
    
    return retString;
}

func equal(_ a: Double, _ b: Double) -> Bool {
    return fabs(a - b) < Double.ulpOfOne
}

func dateFromString(strDate :String)->Date{
    
    let dateFormatterGet = DateFormatter()
    dateFormatterGet.dateFormat = "MM-dd-yyyy hh:mm a"
    
    let date: Date? = dateFormatterGet.date(from:strDate)
    return date!
}

func stringFromDate(date :Date)->String{
    
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "MM-dd-yyyy hh:mm a"
    
    let strDate: String? = dateFormatter.string(from: date)
    return strDate!
}

func writeFile(strToWrite : String , className:String , functionName:String ) {
    let dir:NSURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).last! as NSURL
    let fileurl =  dir.appendingPathComponent("MediaUploader_log.txt")
    let urlString = fileurl!.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
    //_ = dialogOKCancel(question: "Warning", text: urlString!)
    let date = stringFromDate(date: Date()) //string.data(using: String.Encoding.utf8, allowLossyConversion: false)!
    
    let stringToWrite =  "\n \(date) : \(className) : \(functionName) : \(strToWrite)"
    if FileManager.default.fileExists(atPath: fileurl!.path) {
        var _:NSError?
        let urlString = fileurl!.path.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
        let file: FileHandle? = FileHandle(forUpdatingAtPath: urlString!)
        
        if file == nil {
            print("File open failed")
        } else {
            let data = (stringToWrite).data(using: String.Encoding(rawValue: String.Encoding.utf8.rawValue))
            file?.seekToEndOfFile()
            file?.write(data!)
            file?.closeFile()
        }
     }
    else {
        var _:NSError?
        do {
            try stringToWrite.write(to: fileurl!, atomically: false, encoding: .utf8)
        }
        catch {/* error handling here */}
    }
}

func isCheckDirExist(dirPath : String) -> Bool {
    
    let fileManager = FileManager.default
    var isDir : ObjCBool = true
    if fileManager.fileExists(atPath: dirPath, isDirectory:&isDir) {
        if isDir.boolValue {
            // file exists and is a directory
        } else {
            // file exists and is not a directory
            
        }
    } else {
        // file does not exist
        return false
    }
    
    return true
    
}

func removeDot(dirNameArray :[String]) -> String {
    var updatedArray = [String]()
    var retVal = String()
    for dirName in dirNameArray {
        if dirName.hasSuffix(".") {
            updatedArray.append((dirName.trimmingCharacters(in:CharacterSet(charactersIn: "."))))
        }else {
            updatedArray.append(dirName)
        }
    }
    if updatedArray.count > 0{
        retVal = updatedArray.joined(separator: "/")
    }
    return retVal;
}
func getUserToken() -> String? {
    
    guard let token =  UserDefaults.standard.value(forKey:OutlineViewController.NameConstants.userToken) as? String else {
   return OutlineViewController.NameConstants.STRING_EMPTY
    }
    return token
}

func setUserToken(userToken: String){
    let defaults = UserDefaults.standard
    defaults.set(userToken, forKey: OutlineViewController.NameConstants.userToken)
}

func deleteDataFromUserDefault(key :String) {
    UserDefaults.standard.removeObject(forKey:key)
    print("Key Value after remove \(String(describing: UserDefaults.standard.value(forKey: key)))")
}
func prepareUploadFiles(fileType: String, inputDirs: [URL]) -> [String : [[String:Any]]] {
    var outputFiles: [String: [[String:Any]]] = [:]
    
    if fileType.isEmpty {
        return [:]
    }
    
    var fileDirPath = fileType
    if fileType == StringConstant().reportNotesType {
        fileDirPath = StringConstant().reportNotesFilePath
    }
    
    for result in inputDirs {
        
        let pathURL = NSURL(fileURLWithPath: result.path, isDirectory: true)
        var filePaths : [String : UInt64]    = [:]
        
        let enumerator = FileManager.default.enumerator(atPath: result.path)
        while let element = enumerator?.nextObject() as? String {
            let filename = URL(fileURLWithPath: element).lastPathComponent
            if filename == ".DS_Store" {
                continue
            }
            if let fType = enumerator?.fileAttributes?[FileAttributeKey.type] as? FileAttributeType {
                
                switch fType{
                case .typeRegular:
                    let path = NSURL(fileURLWithPath: element, relativeTo: pathURL as URL).path
                    if let fSize = enumerator?.fileAttributes?[FileAttributeKey.size] as? UInt64 {
                        filePaths[path!]=fSize
                    }
                case .typeDirectory:
                    break
                default:
                    continue
                }
            }
            
        }
        
        let scanItems = filePaths
        var files = [[String:Any]]()
        for scanItem in scanItems {
            let filename = URL(fileURLWithPath: scanItem.key).lastPathComponent
            let filefolder = URL(fileURLWithPath: scanItem.key).deletingLastPathComponent()
            
            var parsed = filefolder.path.replacingOccurrences(of: pathURL.deletingLastPathComponent!.path, with: "")
            if parsed.hasPrefix("/") {
                parsed = String(parsed.dropFirst()) + "/"
            }
            // WARNING: special requirement to be compliant with backend we need to trim trailinig dot for each folder
            //          if folder name ends with dot.
            //   parsed = parsed.replacingOccurrences(of: "./", with: "/")
            //  let filePath = parsed.isEmpty ? filename : parsed + filename
            //   print("filePath : \(filePath)")
            
            let rmvDot:String  = removeDot(dirNameArray:parsed.components(separatedBy: "/"))
            let filePath = rmvDot+filename
            let item : [String : Any] = ["name":filename,
                                         "filePath":fileDirPath + "/" + filePath,
                                         "filesize":scanItem.value,
                                         "checksum":fileDirPath + "/" + filePath, //randomString(length: 32),/* will be replaced latter by real checksum value */
                                         "type":fileType]
            files.append([scanItem.key : item])
            
        }
        outputFiles[result.path] = files
    }
    return outputFiles
}

func defaultMiscDict()-> [String : Any]{
    var retDict = [String: Any]()
    retDict["aleFileNameField"] = StringConstant().sourceFile
    retDict["matchType"] = StringConstant().strMatchTypeExact
    retDict["truncateCharFromStart"] = 0
    retDict["truncateCharFromEnd"] = 0
    return retDict;
}


func setOTPLength(otpLength: Int){
    let defaults = UserDefaults.standard
    defaults.set(otpLength, forKey: OutlineViewController.NameConstants.otpLength)
}

func getOTPLength() -> Int? {
    return UserDefaults.standard.value(forKey:OutlineViewController.NameConstants.otpLength) as? Int
}



