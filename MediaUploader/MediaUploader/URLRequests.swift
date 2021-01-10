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
    
    guard let assetUploadFailureURI = LoginViewController.assetUploadFailureURI else { completion(false); return }
    guard let url = URL(string: assetUploadFailureURI) else { completion(false); return }
    
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.httpBody = jsonData
    
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
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
                    }
                    throw OutlineViewController.NameConstants.kFetchListOfShowsFailedStr
                }
            }
            if let data = data {
                if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:String]] {
                    completion(["data": responseJSON])
                }
            }
            
        } catch let error  {
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
                    if let data = data, let dataString = String(data: data, encoding: .utf8) {
                        print("Response: \(dataString)")
                    }
                    throw OutlineViewController.NameConstants.kFetchShowContentFailedStr
                }
            }
            
            guard let data = data else { completion(["error": OutlineViewController.NameConstants.kFetchShowContentFailedStr]); return }
            completion(["data" : data])
            
        } catch let error  {
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
            
            if let data = data {
                let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]
                if let sasToken = responseJSON["weburi"] as? String {
                    completion(["data" : sasToken])
                }
            }
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
    
    guard let showForUserURI = LoginViewController.getShowForUserURI else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    guard let url = URL(string: showForUserURI) else { completion(["error": OutlineViewController.NameConstants.kFetchListOfShowsFailedStr]); return }
    
    var request = URLRequest(url: url)
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
            if let data = data {
                if let responseJSON = try JSONSerialization.jsonObject(with: data) as? [[String:Any]] {
                    for item in responseJSON {
                        let showName = item["media_name"] as! String
                        let showId = item["media_assetcontainerid"] as! String
                        
                        // NOTE: as special request I need to reverse this bit deliberately!
                        let allowed = !(item["media_uploadallowed"] as! Bool)

                        shows[showName] = ["showId":showId, "allowed":allowed]
                    }
                }
                completion(["data": shows])
            }
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}


func fetchSeasonsAndEpisodesTask(showId: String, completion: @escaping (_ shows: [String:Any]) -> Void) {

    let json: [String: String] = ["showid" : showId]
    let jsonData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
    guard let seasonDetailsForShowURI = LoginViewController.getSeasonDetailsForShowURI else { completion(["error": OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr]); return }
    guard let url = URL(string: seasonDetailsForShowURI) else { completion(["error": OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr]); return }
    
    var request = URLRequest(url: url)
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
                        print("Response \(httpResponse.statusCode): \(dataString)")
                    }
                    throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr
                }
            }
            
            // season_name -> (list_episode_name, list_block_name)
            var result = UploadSettingsViewController.SeasonsType()
            
            guard let data = data else { throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr }
            
            let responseJSON = try JSONSerialization.jsonObject(with: data) as! [String:Any]

            guard let seasons = responseJSON["seasons"] as? [[String:Any]] else { throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr }
            guard let episodes = responseJSON["episodes"] as? [[String:String]] else { throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr }
            guard let blocks = responseJSON["blocks"] as? [[String:String]] else { throw OutlineViewController.NameConstants.kFetchListOfSeasonsFailedStr }
            
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
            
                result[season["seasonName"] as! String] = (season["seasonId"] as! String, out_episodes, out_blocks)
            }
            completion(["data": result])
            
        } catch let error  {
            completion(["error": error])
        }
    }
    task.resume()
}