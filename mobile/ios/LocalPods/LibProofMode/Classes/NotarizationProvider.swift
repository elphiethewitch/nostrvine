//
//  NotarizationProvider.swift
//  LibProofMode
//
//  Created by N-Pex on 2022-07-21.
//

import Foundation


public protocol NotarizationProvider {
    func notarize(hash: String, media: Data, success: @escaping (String, String) -> Void, failure: @escaping (Int, String) -> Void )
    var fileExtension: String { get }
}
