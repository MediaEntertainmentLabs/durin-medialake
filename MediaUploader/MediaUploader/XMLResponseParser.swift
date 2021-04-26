//
//  XMLResponseParser.swift
//  MediaUploader
//
//  Created by codecs on 12.02.2021.
//  Copyright © 2021 GlobalLogic. All rights reserved.
//

import Cocoa

class XMLResponseParser : NSObject,XMLParserDelegate {
    
    // MARK: XMLParser variables
    var results: [[String: String]]?         // the whole array of dictionaries
    var currentDictionary: [String: String]? // the current dictionary
    var currentValue: String?                // the current value for one of the keys in the dictionary
    let recordKey = "Blob"
    let dictionaryKeys = Set<String>(["Name", "Content-Length"])
    
    init(data: Data) {
        super.init()
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
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
        if results != nil && elementName == recordKey {
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
