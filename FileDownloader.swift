//
//  FileDownloader.swift
//  NetworkLayer-Cly
//
//  Created by Omar Ali on 19/12/2020.
//

import Foundation

public class FileDownloader: NSObject, URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    private lazy var urlSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        
        configuration.timeoutIntervalForRequest = 604800 // 7 days
        configuration.timeoutIntervalForResource = 604800 // 7 days
        let session = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return session
    }()
    
    
    var downloadTask: URLSessionDownloadTask?
    
    private let url: URL
    private let destinationDirectory: String
    private let fileName: String
    private var onSuccess: (() -> Void)?
    private var onFailure: ((Error) -> Void)?
    private var onProgressChange: ((Float) -> Void)?
    
    public init?(sourceUrlString: String, destinationDirectory: String, fileName: String) {
        if let url = URL(string: sourceUrlString) {
            self.url = url
            self.destinationDirectory = destinationDirectory
            self.fileName = fileName
            
        } else {
            return nil
        }
    }
    
    public func downloadFile(onSuccess: (() -> Void)?, onFailure: ((Error) -> Void)?, onProgressChange: ((Float) -> Void)?) {
        self.onSuccess = onSuccess
        self.onFailure = onFailure
        self.onProgressChange = onProgressChange
        let downloadTask = urlSession.downloadTask(with: url)
        downloadTask.resume()
        self.downloadTask = downloadTask
    }
    
    // MARK: - URLSession Delegate
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
         if downloadTask == self.downloadTask {
            let calculatedProgress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
            onProgressChange?(calculatedProgress)
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // check for and handle errors:
        // * downloadTask.response should be an HTTPURLResponse with statusCode in 200..<299

        do {
            let fileManager = FileManager.default
            let documentsURL = try
                fileManager.url(for: .documentDirectory,
                                        in: .userDomainMask,
                                        appropriateFor: nil,
                                        create: false)
            let destinationDirectory = documentsURL.appendingPathComponent(self.destinationDirectory)
            
            if !fileManager.fileExists(atPath: destinationDirectory.absoluteString) {
                try fileManager.createDirectory(at: destinationDirectory, withIntermediateDirectories: true, attributes: nil)
            }
            
            let savedURL = documentsURL.appendingPathComponent("\(self.destinationDirectory)/\(self.fileName)")
            
            try fileManager.moveItem(at: location, to: savedURL)
            onSuccess?()
        } catch {
            onFailure?(error)
        }
    }
    
    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            onFailure?(error)
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            onFailure?(error)
        }
    }
    
    
}
