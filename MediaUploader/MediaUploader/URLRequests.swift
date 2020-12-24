//
//  URLRequests.swift
//  MediaUploader
//
//  Created by codecs on 23.12.2020.
//  Copyright © 2020 Mykola Gerasymenko. All rights reserved.
//

import Cocoa


func postUploadFailureTask(params: [String:String], completion: @escaping (_ result: Bool) -> Void) {

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
    let url = URL(string: LoginViewController.assetUploadFailureURI!)
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                completion(false)
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Response: \(dataString)")
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
            
        } catch let _  {
            completion(false)
            return
        }
    }
    task.resume()
}

func fetchListAPI_URLs(userApiURLs: String, completion: @escaping (_ shows: [String:Any]) -> Void) {

    let url = URL(string: userApiURLs)!
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
                    }
                    throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
                }
            }

            let responseJSON = try JSONSerialization.jsonObject(with: data!) as? [[String:String]]
            if responseJSON == nil {
                throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
            }
            completion(["data": responseJSON!])
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}

func fetchShowContentTask(sasURI : String, completion: @escaping (_ data: [String:Any]) -> Void) {
    
    let url = URL(string: sasURI)!
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
                        print("Response: \(dataString)")
                    }
                    throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                }
            }
            
            completion(["data" : data!])
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}

func fetchSASTokenURLTask(showId: String, synchronous: Bool, completion: @escaping (_ result: [String:Any]) -> Void) {
    
    let json = ["showId":showId, "userId":LoginViewController.cdsUserId]
    
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let url = URL(string: LoginViewController.generateSASTokenURI!)
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
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
                    // Convert HTTP Response Data to a simple String
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Response: \(dataString)")
                    }
                    throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                }
            }
            
            var sasToken : String!
            
            let responseJSON = try JSONSerialization.jsonObject(with: data!) as! [String:Any]
            sasToken = responseJSON["weburi"] as? String
            
            completion(["data" : sasToken!])
            
            if synchronous {
                semaphore.signal()
            }
            
        } catch let error {
            completion(["error" : error])
            
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

func fetchListOfShowsTask(completion: @escaping (_ shows: [String:Any]) -> Void) {

    let json: [String: String] = ["userId" : LoginViewController.cdsUserId!]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let url = URL(string: LoginViewController.getShowForUserURI!)
    
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
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
                    }
                    throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
                }
            }
            
            var shows : [String:Any] = [:]
            
            let responseJSON = try JSONSerialization.jsonObject(with: data!) as? [[String:Any]]
            if responseJSON == nil {
                throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
            }
            for item in responseJSON! {
                let showName = item["media_name"] as! String
                let showId = item["media_assetcontainerid"] as! String
                let allowed = item["media_uploadallowed"] as! Bool
                shows[showName] = ["showId":showId, "allowed":allowed]
            }
            completion(["data": shows])
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}


func fetchSeandsAndEpisodesTask(showId: String, completion: @escaping (_ shows: [String:Any]) -> Void) {

    let json: [String: String] = ["containerId" : showId]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    let url = URL(string: LoginViewController.getSeasonDetailsForShowURI!)
    
    var request = URLRequest(url: url!)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        do {
            if error != nil {
                print("Error: \(String(describing: error))")
                throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
            }
            
            if let httpResponse = response as? HTTPURLResponse {
                if httpResponse.statusCode != 200 {
                    // Convert HTTP Response Data to a simple String
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Response: \(dataString)")
                    }
                    throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
                }
            }
            
            // season_name -> (list_episode_name, list_block_name)
            var result = UploadSettingsViewController.SeasonsType()
            
            let responseJSON = try JSONSerialization.jsonObject(with: data!) as! [String:Any]

            let seasons = responseJSON["season"] as? [[String:Any]]
            if seasons == nil {
                throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
            }
            for season in seasons! {
                var episodes = [(String,String)]()
                for episode in season["episode"] as! [[String:String]]  {
                    if let name = episode["name"] {
                        episodes.append((name,episode["id"]! as String))
                    }
                }
                var blocks = [(String,String)]()
                for block in season["block"] as! [[String:String]]  {
                    if let name = block["name"] {
                        blocks.append((name,block["id"]! as String))
                    }
                }
            
                result[season["name"] as! String] = (season["id"] as! String, episodes, blocks)
            }
            completion(["data": result])
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}
