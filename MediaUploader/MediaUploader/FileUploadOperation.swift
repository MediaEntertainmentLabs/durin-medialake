//
//  FileUploadOperation.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa


final class FileUploadOperation: AsyncOperation {

    enum Step {
        case kMetadataJsonUpload
        case kDataUpload
    }
    
    private let showName: String
    private let showId: String
    private let cdsUserId: String
    
    var sasToken: String
    var uploadRecord : UploadTableRecord?
    var completionStatus : Int

    private let cmd: String
    private let args: [String]
    private let step: FileUploadOperation.Step
    var dependens : [FileUploadOperation]!
    
    init(showName: String, showId: String, cdsUserId: String, sasToken: String, step: FileUploadOperation.Step, uploadRecord : UploadTableRecord?, dependens : [FileUploadOperation], cmd: String, args: [String]) {
        self.showName = showName
        self.showId = showId
        self.cdsUserId = cdsUserId
        self.sasToken = sasToken
        self.uploadRecord = uploadRecord
        self.dependens = dependens
        self.completionStatus = 0
        
        self.step = step
        self.cmd = cmd
        self.args = args
    }

    override func main() {
        let (_, error, status) = runAzCopyCommand(cmd: self.cmd, args: self.args)
        
        if status == 0 {
            if self.step == Step.kMetadataJsonUpload {
                print ("------------  Completed successfully: \(sasToken) ")
                print ("------------  Cleanup of ", self.args[1])
                do {
                    if FileManager.default.fileExists(atPath: self.args[1]) {
                        try FileManager.default.removeItem(atPath: self.args[1])
                    } else {
                        print("File does not exist")
                    }
                    
                } catch let error as NSError {
                    print("An error took place: \(error)")
                }
                
            } else if self.step == Step.kDataUpload {
                DispatchQueue.main.async {
                    self.uploadRecord!.uploadProgress = 100.0
                    self.uploadRecord!.completionStatusString = "Completed"
                    print ("------------  Upload of data completed successfully!")
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.UpdateShowUploadProgress),
                                                    object: nil,
                                                    userInfo: ["showName" : self.showName,
                                                               "progress" : self.uploadRecord!.uploadProgress])
                    // update show content
//                    NotificationCenter.default.post(
//                        name: Notification.Name(WindowViewController.NotificationNames.ShowProgressViewController),
//                        object: nil,
//                        userInfo: ["progressLabel" : "Fetching show content..."])
//
//                    NotificationCenter.default.post(
//                        name: Notification.Name(WindowViewController.NotificationNames.IconSelectionChanged),
//                        object: nil,
//                        userInfo: ["showName" : self.showName, "showId": self.showId, "cdsUserId" : self.cdsUserId])
                    
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.step == Step.kMetadataJsonUpload {
                    for dep in self.dependens {
                        print(dep.uploadRecord!.completionStatusString)
                        dep.uploadRecord!.uploadProgress = 100.0
                        dep.uploadRecord!.completionStatusString = "CompletedWithErrors"
                        print ("------------  Upload of data FAILED!")
                    }
                } else if self.step == Step.kDataUpload {
                    print(self.uploadRecord!.completionStatusString)
                    self.uploadRecord!.uploadProgress = 100.0
                    self.uploadRecord!.completionStatusString = "CompletedWithErrors"
                    print ("------------  Upload of metadata.json FAILED!")

                }
                NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.UpdateShowUploadProgress),
                                                object: nil)
            }
        }
        self.finish()
    }

    override func cancel() {
        super.cancel()
    }
    
    
    // WARNING: Sandboxed application fairly limited in what it can actually sub-launch
    //          So external programm need to be placed to /Applications folder
    internal func runAzCopyCommand(cmd : String, args : [String]) -> (output: [String], error: [String], exitCode: Int32) {

        let output : [String] = []
        var error : [String] = []

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
                
                print(outputString)
            }
            outpipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
            
        }
        
        outpipe.fileHandleForReading.readabilityHandler = { (fileHandle) -> Void in
            let availableData = fileHandle.availableData
            let newOutput = String.init(data: availableData, encoding: .utf8)
            
            print("\(newOutput!)")
            
            
            var result: [[String]] = []
            
            let pattern = #"(\d+.\d+) %"#
            let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
            let testString = newOutput
            
            let stringRange = NSRange(location: 0, length: (testString?.utf8.count)!)
            let matches = regex.matches(in: testString!, range: stringRange)
            
            for match in matches {
                var groups: [String] = []
                for rangeIndex in 1 ..< match.numberOfRanges {
                    groups.append((testString! as NSString).substring(with: match.range(at: rangeIndex)))
                }
                if !groups.isEmpty {
                    result.append(groups)
                }
            }
            
            let resultString = getCompletionStatusString(inputString: newOutput!)
            if !resultString.isEmpty {
                if resultString != "Completed" {
                    error.append("Failed AzCopy Upload!")
                    if self.step == Step.kMetadataJsonUpload {
                        self.uploadRecord!.completionStatusString = resultString
                    }
                    self.completionStatus = -1
                    return
                }
            }
   
            // advance progress only for actually upload data stage
            if !result.isEmpty && self.step == FileUploadOperation.Step.kDataUpload {
                self.uploadRecord!.uploadProgress = ceil(Double(result[0][0])! + 0.5)
                print("------------ progress : ", self.showName, " ", self.uploadRecord!.uploadProgress, " >> ", result[0])
            }
            
            DispatchQueue.main.async {
                if !result.isEmpty {
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.UpdateShowUploadProgress),
                                                    object: nil)
                }
            }
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
        
        task.launch()
        
        task.waitUntilExit()
        var status = task.terminationStatus
        
        outpipe.fileHandleForReading.readabilityHandler = nil
        NotificationCenter.default.removeObserver(outpipeObserver!)
        //NotificationCenter.default.removeObserver(errpipeObserver!)
        
        // AzCopy completed with return code 0 but operation failed
        if status == 0 && self.completionStatus != 0 {
            status = Int32(self.completionStatus)
        }
        
        if status != 0 {
            error.append("Failed AzCopy Upload!")
        }
        
        return (output, error, status)
    }
}


func getCompletionStatusString(inputString : String) -> String {
    let pattern = #"Final Job Status:(\s+\w+)\n"#
    let regex = try! NSRegularExpression(pattern: pattern, options: .anchorsMatchLines)
    let stringRange = NSRange(location: 0, length: inputString.utf8.count)
    let matches = regex.matches(in: inputString, range: stringRange)
    var result: [[String]] = []
    for match in matches {
        var groups: [String] = []
        for rangeIndex in 1 ..< match.numberOfRanges {
            groups.append((inputString as NSString).substring(with: match.range(at: rangeIndex)))
        }
        if !groups.isEmpty {
            result.append(groups)
        }
    }
    if (result.count != 0) {
        print ("----------------- getCompletionStatusString: ", result[0][0])
        return result[0][0].trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return ""
}
