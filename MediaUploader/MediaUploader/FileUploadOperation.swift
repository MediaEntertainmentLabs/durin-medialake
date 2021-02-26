//
//  FileUploadOperation.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa


final class FileUploadOperation: AsyncOperation {

    enum UploadType {
        case kMetadataJsonUpload
        case kDataUpload
        case kDataRemove
    }
    
    private let showId: String
    private let cdsUserId: String
    private let sasToken: String
    
    var uploadRecord : UploadTableRow?
    var completionStatus : Int
    var isCanceled: Bool
    
    var args: [String]
    private let step: FileUploadOperation.UploadType
    
    // upload being performed in two steps:
    // firstly we upload metadata.json -> dependens contains data tasks
    // second is actually data -> dependens is empty
    var dependens : [FileUploadOperation]!
    
    init(showId: String, cdsUserId: String, sasToken: String, step: FileUploadOperation.UploadType, uploadRecord : UploadTableRow?, dependens : [FileUploadOperation], args: [String]) {
        self.showId = showId
        self.cdsUserId = cdsUserId
        self.sasToken = sasToken
        self.uploadRecord = uploadRecord
        self.dependens = dependens
        self.completionStatus = 0
        self.isCanceled = false
        
        self.step = step
        self.args = args
    }

    override func main() {
        let (_, error, status) = runAzCopyCommand(cmd: LoginViewController.azcopyPath.path, args: self.args)
        if isCanceled {
            isCanceled = false
            print ("------------  Upload canceled!")
            uploadRecord?.completionStatusString = OutlineViewController.NameConstants.kPausedStr
            uploadRecord?.pauseResumeStatus = .pause
            self.finish()
            return
        }
        
        if status == 0 {
            if self.step == UploadType.kDataRemove {
                print ("------------  Remove of data completed successfully!")
            } else if self.step == UploadType.kMetadataJsonUpload {
                print ("------------  Completed successfully: \(sasToken) ")
                print ("------------  Cleanup of ", self.args[1])
                removeFile(path: self.args[1])
                

            } else if self.step == UploadType.kDataUpload {
                DispatchQueue.main.async {
                    
                    guard let uploadRecord = self.uploadRecord else { return }
                   
                    uploadRecord.uploadProgress = 100.0
                    uploadRecord.completionStatusString = "Completed"
                    print ("------------  Upload of data completed successfully!")
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowUploadCompleted),
                                                    object: nil,
                                                    userInfo: ["uploadRecord" : uploadRecord])
                }
            }
        } else {
            DispatchQueue.main.async {
                if self.step == UploadType.kMetadataJsonUpload {
                    for dep in self.dependens where dep.uploadRecord != nil {
                        dep.uploadRecord!.completionStatusString = "Failed"
                        print ("------------  Metadata.json upload failed, error: ", error)
                        
                        uploadShowErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, params: dep.uploadRecord!.uploadParams, operation: self)
                        
                        NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowUploadCompleted),
                                                        object: nil,
                                                        userInfo: ["uploadRecord" : dep.uploadRecord!])
                    }
                } else if self.step == UploadType.kDataUpload {
                    
                    guard let uploadRecord = self.uploadRecord else { return }
                    uploadRecord.completionStatusString = "Failed"
                    print ("------------  Data upload failed, error: ", error)
                    uploadShowErrorAndNotify(error: OutlineViewController.NameConstants.kUploadShowFailedStr, params: uploadRecord.uploadParams, operation: self)
                    
                    NotificationCenter.default.post(name: Notification.Name(WindowViewController.NotificationNames.ShowUploadCompleted),
                                                    object: nil,
                                                    userInfo: ["uploadRecord" : uploadRecord])
                }
            }
        }
        self.finish()
    }

    override func cancel() {
        super.cancel()
    }
    
    
    // WARNING: Sandboxed application fairly limited in what it can actually sub-launch
    //          So external programm need to be placed to /Applications folder
    internal func runAzCopyCommand(cmd : String, args : [String]) -> (output: [String], error: String, exitCode: Int32) {

        let output : [String] = []
        var error : String = ""

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
            if let observer = terminationObserver {
                NotificationCenter.default.removeObserver(observer)
            }
        }
        
        
        outpipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        var outpipeObserver : NSObjectProtocol!
        outpipeObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outpipe.fileHandleForReading , queue: nil) {
            notification in
            let output = outpipe.fileHandleForReading.availableData
            if (output.count > 0) {
                let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
                
                print(outputString)
                let (status, error_output) = self.parseResult(inputString: outputString)
                if status != 0 {
                    self.completionStatus = status
                    error = error_output
                    return
                }
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
  
            let (status, error_output) = self.parseResult(inputString: newOutput!)
            if status != 0 {
                self.completionStatus = status
                error = error_output
                return
            }
            
            if self.uploadRecord?.pauseResumeStatus == .pause {
                self.isCanceled = true
                task.terminate()
                return
            }
            
            // advance progress only for actually upload data stage
            if !result.isEmpty && self.step == FileUploadOperation.UploadType.kDataUpload {
                
                guard let uploadRecord = self.uploadRecord else { return }
                let progress = ceil(Double(result[0][0])! + 0.5)
                // normalize progress after resume
                let newRange = 100.0 - min(100.0, uploadRecord.resumeProgress)
                let oldRange = 100.0
                uploadRecord.uploadProgress = uploadRecord.resumeProgress + progress*(newRange/oldRange)
                print("------------ progress : ", uploadRecord.showName, " ", uploadRecord.uploadProgress, " >> ", result[0])
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
        
        if let observer = outpipeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        
        //NotificationCenter.default.removeObserver(errpipeObserver!)
        
        // AzCopy completed with return code 0 but operation failed
        if status == 0 && self.completionStatus != 0 {
            status = Int32(self.completionStatus)
        }
        
        return (output, error, status)
    }
    
    func parseResult(inputString: String) -> (Int,String) {
        var error: String = ""
        let resultString = getCompletionStatusString(inputString: inputString)
        if !resultString.isEmpty {
            
            // CompletedWithSkipped will occur if dir remotely exist but we choose Append mode at start of Upload
            if resultString != "Completed" && resultString != "CompletedWithSkipped" {
                if self.step == UploadType.kMetadataJsonUpload {
                    for dep in self.dependens {
                        guard let uploadRecord = dep.uploadRecord else { continue }
                        uploadRecord.completionStatusString = resultString
                    }
                    error = "Failed AzCopy metadata.json Upload!"
                } else {
                    if self.uploadRecord != nil {
                        self.uploadRecord!.completionStatusString = resultString
                    }
                    error = "Failed AzCopy data Upload!"
                }
                
                return (-1, error)
            }
        }
        return (0, error)
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
