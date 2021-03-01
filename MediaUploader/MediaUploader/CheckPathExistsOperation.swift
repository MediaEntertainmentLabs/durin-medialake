//
//  CheckPathExistsOperation.swift
//  MediaUploader
//
//  Copyright © 2021 Globallogic. All rights reserved.
//

import Cocoa
import OSLog

final class CheckPathExistsOperation: AsyncOperation {

    private let showName: String
    private let showId: String
    private let srcDir: String
    private var isDirExist: Bool?
    var aFunc: (Bool) -> Void
    
    var status = 0
    var xmlParser: XMLResponseParser?
    
    init(showName: String, showId: String, srcDir: String, completion: @escaping (_ isDirExist: Bool) -> Void) {
        self.showName = showName
        self.showId = showId
        self.srcDir = srcDir
        self.aFunc = completion
    }

    override func main() {

        var sasToken: String!
        
        fetchSASToken(showName: showName, showId: showId, synchronous: true) { (result,state) in
            switch state {
            case .pending:
                return
            case .cached, .completed:
                sasToken = result
            }
        }
        
        if sasToken == nil {
            return
        }
        
        checkPathExists(SASToken: sasToken, showName: self.showName, showId: self.showId, dir: self.srcDir) { (result) in
            guard let data = result["data"] as? Data else { return }
            self.xmlParser = XMLResponseParser(data: data)
            self.isDirExist = false
            if let parser = self.xmlParser {
                if parser.results == nil || (parser.results?.count == 0) {
                    return
                }
                self.isDirExist = true
            }
            self.aFunc(self.isDirExist!)
        }
    }
    
    private func checkPathExists(SASToken: String, showName: String, showId: String, dir: String, completion: @escaping (_ data: [String:Any]) -> Void) {
        
        let checkDirURI = SASToken + "&restype=container&comp=list&prefix="+dir
        print("checkPathExists :: \(checkDirURI)")
        //os_log("checkPathExists :: %@", log: .default, type: .debug,checkDirURI)
        guard let url = URL(string: checkDirURI) else { completion(["error": OutlineViewController.NameConstants.kFetchShowContentFailedStr]); return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            do {
                if error != nil {
                    throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode != 200 {
                        // Convert HTTP Response Data to a simple String
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("dataString :: \(dataString)")
                            // os_log("dataString :: %@", log: .default, type: .debug,dataString)
                        }
                        throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                    }
                }
                
                guard let data = data else { completion(["error": OutlineViewController.NameConstants.kFetchShowContentFailedStr]); return }
                completion(["data" : data])
                self.finish()
                
            } catch let error as NSError {
                completion(["error" : OutlineViewController.NameConstants.kFetchShowContentFailedStr])
                print("error :: \(error)")
                //os_log("error :: %@", log: .default, type: .error,error)
            } catch let error  {
                completion(["error": error])
            }
        }
        task.resume()
    }

    
    override func cancel() {
        super.cancel()
    }
}

