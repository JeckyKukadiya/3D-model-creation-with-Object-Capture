//
//  String+Extension.swift
//  ObjectCapture
//
//  Created by Eryus Tech on 05/09/24.
//

import Foundation

extension String: Error, LocalizedError {
    public var errorDescription: String? { self }
}
