//
//  MediaItemProcessingOperation.swift
//  LibProofMode
//
//  Created by N-Pex on 2020-07-24.
//

import Foundation
import Photos

class MediaItemProcessingOperation: Operation {

    enum State: String {
        case isReady
        case isExecuting
        case isFinished
    }
    
    let mediaItem: MediaItem
    let options: ProofGenerationOptions
    
    init(mediaItem:MediaItem, options: ProofGenerationOptions) {
        self.mediaItem = mediaItem
        self.options = options
        super.init()
    }
        
    var state: State = .isReady {
        willSet(newValue) {
            willChangeValue(forKey: state.rawValue)
            willChangeValue(forKey: newValue.rawValue)
        }
        didSet {
            didChangeValue(forKey: oldValue.rawValue)
            didChangeValue(forKey: state.rawValue)
        }
    }
 
    override var isAsynchronous: Bool { true }
    override var isExecuting: Bool { state == .isExecuting }
    override var isFinished: Bool {
        if isCancelled && state != .isExecuting { return true }
        return state == .isFinished
    }

    override func start() {
        guard !isCancelled else { return }

        state = .isExecuting
        mediaItem.createProof(options: self.options) { success in
            self.state = .isFinished
        }
    }
}
