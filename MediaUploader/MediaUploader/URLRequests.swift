//
//  URLRequests.swift
//  MediaUploader
//
//  Created by codecs on 23.12.2020.
//  Copyright © 2020 Mykola Gerasymenko. All rights reserved.
//

import Cocoa


func postUploadFailureTask(params: [String:Any], completion: @escaping (_ result: Bool) -> Void) {
    
    let json = [
        "showId": params["showId"],
        "seasonId":params["seasonId"],
        "episodeId":params["episodeId"],
        "blockId":params["blockId"],
        "batch":params["batch"],
        "unit":params["unit"],
        "team":params["team"],
        "shootDay": params["shootDay"],
        "notificationEmail": params["notificationEmail"],
        "subject":params["subject"], // you can specify the subject.
        "emailbody":params["emailbody"] // body of email.
    ]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    guard let assetUploadFailureURI = LoginViewController.assetUploadFailureURI else { completion(false); return }
    guard let url = URL(string: assetUploadFailureURI) else { completion(false); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if error != nil {
            print("Error: \(String(describing: error))")
            writeFile(strToWrite: (String(describing: error)), className: "URLRequest", functionName: "postUploadFailureTask")
            completion(false)
            return
        }
        
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                if let data = data, let dataString = String(data: data, encoding: .utf8) {
                    print("Response: \(dataString)")
                    writeFile(strToWrite: dataString, className: "URLRequest", functionName: "postUploadFailureTask")
                }
                completion(false)
                return
            }
        }
        
        //            let responseJSON = try JSONSerialization.jsonObject(with: data!) as? [[String:String]]
        //            if responseJSON == nil {
        //                completion(false)
        //            }
        completion(true)
        return
    }
    task.resume()
}

func fetchListAPI_URLs(userApiURLs: String, completion: @escaping (_ shows: [String:Any]) -> Void) {
    guard let url = URL(string: userApiURLs) else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // Convert HTTP Response Data to a simple String
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Response: \(dataString)")
                        writeFile(strToWrite: dataString, className: "URLRequest", functionName: "fetchListAPI_URLs")
                    }
                    throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
                }
            }
            if let data = data {
                if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:String]] {
                    completion(["data": responseJSON])
                }
            }
            
        } catch let error as NSError {
            completion(["error" : OutlineViewController.NameConstants.kFetchListOfShowsFailedStr])
            writeFile(strToWrite: error.localizedDescription, className: "URLRequest", functionName: "fetchListAPI_URLs")
            print("\(error)")
        } catch let error  {
            writeFile(strToWrite: error.localizedDescription, className: "URLRequest", functionName: "fetchListAPI_URLs")
            completion(["error": error])
        }
    }
    task.resume()
}

func fetchShowContentTask(sasURI : String, completion: @escaping (_ data: [String:Any]) -> Void) {
    guard let url = URL(string: sasURI) else { completion(["error": OutlineViewController.NameConstants.kFetchShowContentFailedStr]); return }
    
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
                    if httpResponse.statusCode == 401 {
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response Code \(httpResponse.statusCode): Response : \(dataString)")
                        }
                        throw String(httpResponse.statusCode)
                    }else  {
                        
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response: \(dataString)")
                            writeFile(strToWrite: dataString, className: "URLRequest", functionName: "fetchShowContentTask")
                        }
                        throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                    }
                }
            }
            
            guard let data = data else { completion(["error": OutlineViewController.NameConstants.kFetchShowContentFailedStr]); return }
            completion(["data" : data])
            
        } catch let error as NSError {
            writeFile(strToWrite: error.localizedDescription, className: "URLRequest", functionName: "fetchShowContentTask")
            completion(["error" : OutlineViewController.NameConstants.kFetchShowContentFailedStr])
            print("\(error)")
        } catch let error  {
            writeFile(strToWrite: error.localizedDescription, className: "URLRequest", functionName: "fetchShowContentTask")
            completion(["error": error])
        }
    }
    task.resume()
}

func fetchSASTokenURLTask(showId: String, synchronous: Bool, completion: @escaping (_ result: [String:Any]) -> Void) {
    
    let json = ["showId":showId, "userId":LoginViewController.cdsUserId]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    guard let SASTokenURI = LoginViewController.generateSASTokenURI else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    guard let url = URL(string: SASTokenURI) else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    guard let userToken = getUserToken() else {
        writeFile(strToWrite: OutlineViewController.NameConstants.unableToFindUserToken, className: "URLRequest", functionName: "fetchSASTokenURLTask")
        return
    }
    request.setValue(userToken, forHTTPHeaderField: OutlineViewController.NameConstants.userAuthToken)
    
    request.httpBody = jsonData
    
    let semaphore = DispatchSemaphore(value: 0)
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if httpResponse.statusCode == 401 {
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response Code \(httpResponse.statusCode): Response : \(dataString)")
                            do {
                                let dict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
                                throw "\(String(httpResponse.statusCode))?\(dict?["message"] ?? OutlineViewController.NameConstants.kFetchShowContentFailedStr)"
                            }
                        }else{
                            throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                        }
                    }else {
                        // Convert HTTP Response Data to a simple String
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response: \(dataString)")
                        }
                        throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                    }
                }
            }
            
            if let data = data {
                let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]
                if let sasToken = responseJSON["weburi"] as? String {
                    completion(["data" : sasToken])
                }
            }
            if synchronous {
                semaphore.signal()
            }
            
        }
        catch let error as NSError {
            completion(["error" : OutlineViewController.NameConstants.kFetchShowContentFailedStr])
            print("\(error)")
            if synchronous {
                semaphore.signal()
            }
        }
        catch let error {
            completion(["error" : error])
            print(error)
            if synchronous {
                semaphore.signal()
            }
        }
    }
    
    task.resume()
    
    if synchronous {
        _ = semaphore.wait(timeout: .distantFuture)
    }
}

enum FetchSASTokenState {
    case pending, cached, completed
}
func fetchSASToken(showName : String, showId : String, synchronous: Bool, completion: @escaping (_ data: (String,FetchSASTokenState)) -> Void) {
    
    var sasToken : String!
    if let cachedSasToken = AppDelegate.cacheSASTokens[showName] {
        if let value = cachedSasToken.value() {
            completion((value, FetchSASTokenState.cached))
        }
    } else {
        fetchSASTokenURLTask(showId: showId, synchronous: synchronous) { (result) in
            if let error = result["error"] as? String {
                
                var strError = error
                if error.contains(OutlineViewController.NameConstants.OTPTokenExpired) {
                    let arrItem:[String]? = error.components(separatedBy: "?")
                    if arrItem != nil , arrItem!.count > 1 {
                        strError = arrItem![1]
                    }
                    otpExpiredShowLoginScreen(error: strError, showName: showName, showId: showId)
                    return
                }else {
                    fetchShowContentErrorAndNotify(error: strError, showName: showName, showId: showId)
                    return
                }
            }
            
            if let value = result["data"] as? String {
                sasToken = value
                AppDelegate.cacheSASTokens[showName]=SASToken(showId : showId, sasToken: value)
                
                completion((sasToken,FetchSASTokenState.completed))
            }
        }
    }
}

func fetchListOfShowsTask(completion: @escaping (_ shows: [String:Any]) -> Void) {
    
    let json: [String: String] = ["userId" : LoginViewController.cdsUserId!]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    guard let showForUserURI = LoginViewController.getShowForUserURI else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    guard let url = URL(string: showForUserURI) else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    guard let userToken = getUserToken() else {
        writeFile(strToWrite: OutlineViewController.NameConstants.unableToFindUserToken,className: "URLRequest", functionName: "fetchListOfShowsTask")
        return
    }
    request.setValue(userToken, forHTTPHeaderField: OutlineViewController.NameConstants.userAuthToken)
    
    request.httpBody = jsonData
    
    print("URL : \(showForUserURI)")
    print("BODY \n \(String(decoding: request.httpBody!, as: UTF8.self))")
    print("HEADERS \n \(String(describing: request.allHTTPHeaderFields))")
    
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    
                    if httpResponse.statusCode == 401 {
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response Code \(httpResponse.statusCode): Response : \(dataString)")
                        }
                        throw String(httpResponse.statusCode)
                    }else
                    {
                        // Convert HTTP Response Data to a simple String
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response Code \(httpResponse.statusCode): Response : \(dataString)")
                        }
                        throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
                    }
                }
            }
            
            var shows = [[String:Any]]()
            if let data = data {
                if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:Any]] {
                    for item in responseJSON {
                        let showName = item["media_name"] as! String
                        let showId = item["media_assetcontainerid"] as! String
                        let studio = item["media_Studio"] as! String
                        var studioName:String = "noname"
                        var studioId:String = ""
                        if let data = studio.data(using: String.Encoding.utf8) {
                            guard let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String:String] else { continue }
                            guard let name : String = json["media_name"]  else { continue }
                            guard let id : String = json["media_studioid"]  else { continue }
                            studioName = name
                            studioId = id
                        }
                        
                        // NOTE: as special request I need to reverse this bit deliberately!
                        let allowed = !(item["media_uploadallowed"] as! Bool)
                        
                        shows.append(["showName":showName, "showId":showId, "studio":studioName, "studioId":studioId, "allowed":allowed])
                    }
                    if (shows.count != 0) {
                        let sortedByStudio = shows.sorted(by: {
                                                            if $0["studio"] as! String != $1["studio"] as! String {
                                                                return ($0["studio"] as! String) < ($1["studio"] as! String)
                                                            } else {
                                                                return String(describing: $0["studio"] as! String) > String(describing: $1["studio"] as! String) } })
                        
                        completion(["data": sortedByStudio])
                    }
                } else {
                    if let string = String(bytes: data, encoding: .utf8) {
                        print (" ---------------- Response JSON \(string)")
                        throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
                    }
                }
            }
            
        } catch let error as NSError {
            completion(["error" : OutlineViewController.NameConstants.kFetchListOfShowsFailedStr])
            print("\(error)")
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}


func fetchSeasonsAndEpisodesTask(showId: String, completion: @escaping (_ shows: [String:Any]) -> Void) {
    
    let json: [String: String] = ["showid" : showId ,"userId" : LoginViewController.cdsUserId!]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    guard let seasonDetailsForShowURI = LoginViewController.getSeasonDetailsForShowURI else { completion(["error": OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr]); return }
    guard let url = URL(string: seasonDetailsForShowURI) else { completion(["error": OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr]); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    guard let userToken = getUserToken() else {
        writeFile(strToWrite: OutlineViewController.NameConstants.unableToFindUserToken, className: "URLRequest", functionName: "fetchSeasonsAndEpisodesTask")
        return
    }
    request.setValue(userToken, forHTTPHeaderField: OutlineViewController.NameConstants.userAuthToken)
    
    request.httpBody = jsonData
    
    print("BODY \n \(String(decoding: request.httpBody!, as: UTF8.self))")
    print("HEADERS \n \(String(describing: request.allHTTPHeaderFields))")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if httpResponse.statusCode == 401 {
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response Code \(httpResponse.statusCode): Response : \(dataString)")
                        }
                        throw String(httpResponse.statusCode)
                    }else {
                        // Convert HTTP Response Data to a simple String
                        if let data = data, let dataString = String(data: data, encoding: .utf8) {
                            print("Response Code \(httpResponse.statusCode): Response : \(dataString)")
                        }
                        throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
                    }
                }
            }
            
            // season_name -> (list_episode_name, list_block_name)
            var result = UploadSettingsViewController.SeasonsType()
            
            guard let data = data else { throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr }
            
            let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]
            jsonFromDict(from: responseJSON)
            
            guard let seasons = responseJSON["seasons"] as? [[String:Any]] else {
                throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
            }
            
            guard let episodes = responseJSON["episodes"] as? [[String:String]] else {
                throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
            }
            
            guard let blocks = responseJSON["blocks"] as? [[String:String]] else {
                throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
            }
            
            var lastShootDay = "day000"
            var shootDayFormat = "day001"
            // TO DO : waiting for lastShootDay,shootDayFormat from server , till than I am setting this default value, post response Actual value should be updated ; As per SONU on 06April2021
            
            if(responseJSON["lastShootDay"] as? String != nil){
                lastShootDay = responseJSON["lastShootDay"] as? String ?? "day000"
            }
            
            if(responseJSON["shootDayFormat"] as? String != nil){
                shootDayFormat = responseJSON["shootDayFormat"] as? String ?? "day001"
            }
            
            
            for season in seasons {
                var out_episodes = [(String,String)]()
                for episode in episodes {
                    if let name = episode["name"], episode["seasonid"] == (season["seasonId"] as! String) {
                        out_episodes.append((name,episode["id"]! as String))
                    }
                }
                var out_blocks = [(String,String)]()
                for block in blocks  {
                    if let name = block["name"], block["seasonid"] == (season["seasonId"] as! String) {
                        out_blocks.append((name,block["id"]! as String))
                    }
                }
                
                result[season["seasonName"] as! String] = (season["seasonId"] as! String, out_episodes, out_blocks, lastShootDay, shootDayFormat)
            }
            completion(["data": result])
            
        } catch let error as NSError {
            completion(["error" : OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr])
            print("\(error)")
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}
func generateOTP(completion: @escaping (_ optMessage: [String:Any]) -> Void) {
    
    guard let account = LoginViewController.account else { return }
    guard let identifier = account.identifier else { return }
    
    let json: [String: String] = ["userId" : identifier.components(separatedBy: ".")[0]]
    //let json: [String: String] = ["userId" :"5b1c464a-f96e-4228-bbe7-33d5ccd18b3c"]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    guard let generateOTPForUserURI = LoginViewController.generateOTPForUserURI else { completion(["error": OutlineViewController.NameConstants.kGenerateOTPFailedStr]); return }
    guard let url = URL(string: generateOTPForUserURI) else { completion(["error": OutlineViewController.NameConstants.kGenerateOTPFailedStr]); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kGenerateOTPFailedStr
            }
            print("Generate OTP Response : \(String(data: data!, encoding: .utf8) )")
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // Convert HTTP Response Data to a simple String
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Generate OTP Response Error: \(dataString)")
                        // Write a log file to catch OTP genration error
                    }
                    throw OutlineViewController.NameConstants.kGenerateOTPFailedStr
                }
            }
            
            guard let data = data else { throw OutlineViewController.NameConstants.kGenerateOTPFailedStr }
            if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String:Any] {
                completion(["message": responseJSON["message"] as Any])
            } else {
                if let string = String(bytes: data, encoding: .utf8) {
                    print (" ---------------- Response JSON \(string)")
                    throw OutlineViewController.NameConstants.kGenerateOTPFailedStr
                }
            }
        } catch let error as NSError {
            completion(["error" : OutlineViewController.NameConstants.kGenerateOTPFailedStr])
            print("\(error)")
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}

func verifyOTP(otp: String,userID:String,completion: @escaping (_ userToken: [String:Any]) -> Void) {
    
    //let json: [String: String] = ["userId" :userID,"otp":otp]
    
    let json: [String: String] = ["userId" :LoginViewController.azureUserId!,"otp":otp]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    
    guard let verifyOTPForUserURI = LoginViewController.verifyOTPForUserURI else { completion(["error": OutlineViewController.NameConstants.kVerifyOTPFailedStr]); return }
    guard let url = URL(string: verifyOTPForUserURI) else { completion(["error": OutlineViewController.NameConstants.kVerifyOTPFailedStr]); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    print("BODY \n \(String(decoding: request.httpBody!, as: UTF8.self))")
    print("HEADERS \n \(String(describing: request.allHTTPHeaderFields))")
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kVerifyOTPFailedStr
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // Convert HTTP Response Data to a simple String
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Verify OTP Response Error: \(dataString)")
                        // Write a log file to catch OTP genration error
                    }
                    throw OutlineViewController.NameConstants.kVerifyOTPFailedStr
                }
            }
            
            guard let data = data else { throw OutlineViewController.NameConstants.kVerifyOTPFailedStr }
            if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [String:Any] {
                
                if responseJSON["token"] != nil {
                    setUserToken(userToken: responseJSON["token"] as! String)
                    completion(["token": responseJSON["token"] as Any])
                }else{
                    throw OutlineViewController.NameConstants.kVerifyOTPFailedStr
                }
            } else {
                if let string = String(bytes: data, encoding: .utf8) {
                    print (" ---------------- Response JSON \(string)")
                    throw OutlineViewController.NameConstants.kVerifyOTPFailedStr
                }
            }
        } catch let error as NSError {
            completion(["error" : OutlineViewController.NameConstants.kVerifyOTPFailedStr])
            print("\(error)")
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}
