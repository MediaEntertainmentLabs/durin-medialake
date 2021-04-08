//
//  OnlyIntegerValueFormatter.swift
//  MediaUploader
//
//  Created by global on 08/04/21.
//  Copyright © 2021 Mykola Gerasymenko. All rights reserved.
//

import Foundation
class OnlyIntegerValueFormatter: NumberFormatter {

    override func isPartialStringValid(_ partialString: String, newEditingString newString: AutoreleasingUnsafeMutablePointer<NSString?>?, errorDescription error: AutoreleasingUnsafeMutablePointer<NSString?>?) -> Bool {

        // Ability to reset your field (otherwise you can't delete the content)
        // You can check if the field is empty later
        if partialString.isEmpty {
            return true
        }

        guard let otpLength = getOTPLength() else {
            writeFile(strToWrite: OutlineViewController.NameConstants.unableToFindUserToken, className: "URLRequest", functionName: "fetchSASTokenURLTask")
            return true
        }
        
        // Optional: limit input length
        
        if otpLength > 0 && partialString.count > otpLength {
            //  if partialString.characters.count>3 {
            return false
        }
        

        // Actual check
        return Int(partialString) != nil
    }
    
}
