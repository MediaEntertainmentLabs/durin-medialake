//
//  AsyncOperation.swift
//  MediaUploader
//
//  Copyright © 2020 GlobalLogic. All rights reserved.
//

import Cocoa

class AsyncOperation: Operation {
    private let lockQueue = DispatchQueue(label: "durin.mediauploader.asyncoperation", attributes: .concurrent)

    override var isAsynchronous: Bool {
        return true
    }

    private var is_executing: Bool = false
    
    override private(set) var isExecuting: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return is_executing
            }
        }
        set {
            willChangeValue(forKey: "isExecuting")
            lockQueue.sync(flags: [.barrier]) {
                is_executing = newValue
            }
            didChangeValue(forKey: "isExecuting")
        }
    }

    private var is_finished: Bool = false
    override private(set) var isFinished: Bool {
        get {
            return lockQueue.sync { () -> Bool in
                return is_finished
            }
        }
        set {
            willChangeValue(forKey: "isFinished")
            lockQueue.sync(flags: [.barrier]) {
                is_finished = newValue
            }
            didChangeValue(forKey: "isFinished")
        }
    }

    override func start() {
        guard !isCancelled else {
            finish()
            return
        }

        isFinished = false
        isExecuting = true
        main()
    }

    override func main() {
        fatalError("Subclasses must implement `main` without overriding super.")
    }

    func finish() {
        isExecuting = false
        isFinished = true
    }
}
