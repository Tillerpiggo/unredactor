//
//  ClassifiedText.swift
//  Unredactor
//
//  Created by tyler on 7/18/19.
//  Copyright © 2019 tyler. All rights reserved.
//

import Foundation
import UIKit

class ClassifiedText: NSCopying { // NSCopying is effectively for the unredactor
    var words: [ClassifiedString]
    
    var rawText: String { // Returns just the underlying original text, ignoring redactions/unredactions
        
        var rawText: String = ""
        for word in self.words {
            rawText.append(word.string)
            rawText.append(" ")
        }
        rawText.removeLast() // Remove the last space that was aded
        
        return rawText
    }
    
    var maskTokenText: String {
        // This is sent to unredactor.com. It uses the mask token ("unk")
        var maskTokenText: String = ""
        for word in self.words {
            if word.redactionState == .redacted {
                maskTokenText.append(Unredactor.maskToken)
            } else {
                maskTokenText.append(word.string)
            }
            maskTokenText.append(" ")
        }
        
        maskTokenText.removeLast() // Remove the last space that was added.
        
        return maskTokenText
    }
    
    func wordForCharacterIndex(_ characterIndex: Int) -> ClassifiedString? {
        var startIndex = 0
        var endIndex = 0 // Place we are at in the sequence currently
        for word in words {
            let wordLength = word.redactionState == .unredacted ? word.unredactorPrediction!.count : word.string.count
            
            endIndex += wordLength
            startIndex = endIndex - wordLength
            if characterIndex >= startIndex && characterIndex <= endIndex - 1 {
                return word
            }
            
            // Add a space
            startIndex += 1
            endIndex += 1
        }
        
        return nil
    }
    
    // Returns true if this classified text contains any redactions/unredactions
    var isNotRedacted: Bool {
        for word in words {
            if word.redactionState != .notRedacted {
                return false
            }
        }
        
        return true
    }
    
    var isRedacted: Bool {
        for word in words {
            if word.redactionState == .redacted {
                return true
            }
        }
        
        return false
    }
    
    var isUnredacted: Bool {
        for word in words {
            if word.redactionState == .unredacted {
                return true
            }
        }
        
        return false
    }
    
    // Returns the index of the first character of a word
    func characterIndexForWord(wordIndex: Int) -> Int? {
        var characterIndex = 0
        for (index, word) in words.enumerated() {
            characterIndex += word.string.count
            if index == wordIndex {
                //let numberOfSpaces = wordIndex
                return characterIndex// + numberOfSpaces
            }
        }
        
        return nil
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copy = ClassifiedText(withClassifiedWords: words)
        return copy
    }
    
    init(withWords words: [String]) {
        self.words = words.map { ClassifiedString($0) }
    }
    
    init(withText text: String) {
        let wordSubstrings = text.split(separator: " ")
        let words = wordSubstrings.map { String($0) }
        self.words = words.map { ClassifiedString($0) }
    }
    
    init(withClassifiedWords classifiedWords: [ClassifiedString]) {
        self.words = classifiedWords
    }
}

// A special string that knows whether or not is has been redacted or not
class ClassifiedString {
    var string: String
    var unredactorPrediction: String?
    var redactionState: RedactionState = .notRedacted
    var lastRedactionState: RedactionState?
    
    func toggleRedactionState() {
        switch redactionState {
        case .notRedacted:
            redactionState = lastRedactionState ?? .redacted
            lastRedactionState = .notRedacted
        case .redacted:
            redactionState = .notRedacted
            lastRedactionState = .redacted
        case .unredacted:
            redactionState = .notRedacted
            lastRedactionState = .unredacted
            // TODO: Make this also toggle the string to be it's predicted word version instead of the raw string
        }
    }
    
    init(_ string: String) {
        self.string = string
    }
}

enum RedactionState {
    case notRedacted, redacted, unredacted // Not redacted is normal, unredacted is when the model makes a prediction for it.
}

extension NSAttributedString {
    func height(withConstrainedWidth width: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.height)
    }
    
    func width(withConstrainedHeight height: CGFloat) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, context: nil)
        
        return ceil(boundingBox.width)
    }
}
