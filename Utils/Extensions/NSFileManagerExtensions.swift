/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

/* Created and contributed by Nikolai Ruhe and rewritten in Swift.
 * https://github.com/NikolaiRuhe/NRFoundation */

import Foundation

public let FileManagerExtensionsDomain = "org.mozilla.NSFileManagerExtensions"

public enum FileManagerExtensionsErrorCodes: Int {
    case enumeratorFailure = 0
    case enumeratorElementNotURL = 1
    case errorEnumeratingDirectory = 2
}

public extension FileManager {

    fileprivate func directoryEnumeratorForURL(_ url: URL) throws -> FileManager.DirectoryEnumerator {
        let prefetchedProperties = [
            URLResourceKey.isRegularFileKey,
            URLResourceKey.fileAllocatedSizeKey,
            URLResourceKey.totalFileAllocatedSizeKey
        ]

        // If we run into an issue getting an enumerator for the given URL, capture the error and bail out later.
        var enumeratorError: Error?
        let errorHandler: (URL, Error) -> Bool = { _, error in
            enumeratorError = error
            return false
        }

        guard let directoryEnumerator = FileManager.default.enumerator(at: url,
            includingPropertiesForKeys: prefetchedProperties,
            options: [],
            errorHandler: errorHandler) else {
            throw errorWithCode(.enumeratorFailure)
        }

        // Bail out if we encountered an issue getting the enumerator.
        if let _ = enumeratorError {
            throw errorWithCode(.errorEnumeratingDirectory, underlyingError: enumeratorError)
        }

        return directoryEnumerator
    }

    fileprivate func sizeForItemURL(_ url: AnyObject, withPrefix prefix: String) throws -> Int64 {
        guard let itemURL = url as? URL else {
            throw errorWithCode(.enumeratorElementNotURL)
        }

        // Skip files that are not regular and don't match our prefix
        guard itemURL.isRegularFile && itemURL.lastComponentIsPrefixedBy(prefix) else {
            return 0
        }

        return (url as? URL)?.allocatedFileSize() ?? 0
    }

    func allocatedSizeOfDirectoryAtURL(_ url: URL, forFilesPrefixedWith prefix: String, isLargerThanBytes threshold: Int64) throws -> Bool {
        let directoryEnumerator = try directoryEnumeratorForURL(url)
        var acc: Int64 = 0
        for item in directoryEnumerator {
            acc += try sizeForItemURL(item as AnyObject, withPrefix: prefix)
            if acc > threshold {
                return true
            }
        }
        return false
    }

    /**
     Returns the precise size of the given directory on disk.

     - parameter url:    Directory URL
     - parameter prefix: Prefix of files to check for size

     - throws: Error reading/operating on disk.
     */
    func getAllocatedSizeOfDirectoryAtURL(_ url: URL, forFilesPrefixedWith prefix: String) throws -> Int64 {
        let directoryEnumerator = try directoryEnumeratorForURL(url)
        return try directoryEnumerator.reduce(0) {
            let size = try sizeForItemURL($1 as AnyObject, withPrefix: prefix)
            return $0 + size
        }
    }

    func contentsOfDirectoryAtPath(_ path: String, withFilenamePrefix prefix: String) throws -> [String] {
        return try FileManager.default.contentsOfDirectory(atPath: path)
            .filter { $0.hasPrefix("\(prefix).") }
            .sorted { $0 < $1 }
    }

    func removeItemInDirectory(_ directory: String, named: String) throws {
        let file = URL(fileURLWithPath: directory).appendingPathComponent(named).path
		try self.removeItem(atPath: file)
    }

    fileprivate func errorWithCode(_ code: FileManagerExtensionsErrorCodes, underlyingError error: Error? = nil) -> NSError {
        var userInfo = [String: Any]()
        if let _ = error {
            userInfo[NSUnderlyingErrorKey] = error
        }

        return NSError(
            domain: FileManagerExtensionsDomain,
            code: code.rawValue,
            userInfo: userInfo)
    }
}
