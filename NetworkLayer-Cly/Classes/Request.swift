//
//  HTTPRequest.swift
//  DataAccessLayerDemo
//
//  Created by Omar Ali on 8/28/18.
//  Copyright © 2018 Omar Ali. All rights reserved.
//

import Foundation
import ObjectMapper
import Alamofire

class Request<T> {
    
    let httpMedthod: HTTPMethod
    let url: String
    let urlParameters: [String: Any]?
    let bodyParameters: [String: Any]?
    let headers: [String: String]?
    
    init(url: String, method: HTTPMethod, headers: [String: String]?, urlParameters: [String: String]?, bodyParameters: [String: Any]?) {
//        self.url = "\(APIConstants.BASE_URL)\(url)"
        self.url = url
        self.httpMedthod = method
        self.headers = headers
        self.urlParameters = urlParameters
        self.bodyParameters = bodyParameters
    }
    
    init(customUrl: String, method: HTTPMethod, headers: [String: String]?, urlParameters: [String: String]?, bodyParameters: [String: Any]?) {
        self.url = customUrl
        self.httpMedthod = method
        self.headers = headers
        self.urlParameters = urlParameters
        self.bodyParameters = bodyParameters
    }
    
    func execute(onSuccess: @escaping ((T) -> Void), onFailure: ((APIError) -> Void)? = nil) {
        fatalError("This method must be overriden")
    }
    
    func executeHelper(onSuccess: @escaping ((Any) -> Void), onFailure: ((APIError) -> Void)? = nil) {
        
        switch httpMedthod {
        case .GET:
            executeGetRequest(onSuccess: {
                response in
                onSuccess(response)
            }, onFailure: {
                error in
                onFailure?(error)
            })
            break
        case .POST:
            executePostRequest(onSuccess: {
                response in
                onSuccess(response)
            }, onFailure: {
                error in
                onFailure?(error)
            })
            break
        }
        
    }
    
    private var urlWithParameters: String {
        
        guard let parameters = self.urlParameters, !parameters.isEmpty else {
            return url
        }
        
        var newUrl = "\(url)?"
        
        for (key, value) in parameters {
            newUrl = "\(newUrl)\(key)=\(value)&"
        }
        
        newUrl.removeLast()
        return newUrl
        
    }
    
    private func executeGetRequest(onSuccess: @escaping ((Any) -> Void), onFailure: ((APIError) -> Void)? = nil) {
        
        guard let url = URL(string: urlWithParameters) else {
            onFailure?(.invalidUrl)
            return
        }
        
        Alamofire.request(url, method: .get, parameters: nil, encoding: JSONEncoding.default, headers: headers).responseJSON(completionHandler: {
            response in

            if let _ = response.error {
                onFailure?(.unknown)
            }
            else {
                if let response = response.result.value {
                    onSuccess(response)
                }
                else {
                     onFailure?(.unknown)
                }
            }
        })
        
    }
    
    
    private func executePostRequest(onSuccess: @escaping ((Any) -> Void), onFailure: ((APIError) -> Void)? = nil) {
    
        Alamofire.upload(multipartFormData: {
            multipartData in
            for (key, value) in self.bodyParameters ?? [:] {
                if let data = value as? Data {
                    multipartData.append(data, withName: key,fileName: "file.jpg", mimeType: "image/jpg")
                }
                else if let fileInfo = value as? FileInfo<Data> {
                    switch fileInfo.type {
                    case .image:
                        multipartData.append(fileInfo.data, withName: key,fileName: "file.jpg", mimeType: "image/jpg")
                        break
                    case .video:
                        multipartData.append(fileInfo.data, withName: key,fileName: "video.mp4", mimeType: "video/mp4")
                        break
                    default:
                        break
                    }
                }
                else if let fileInfo = value as? FileInfo<[Data]> {
                    if fileInfo.type == .images {
                        for image in fileInfo.data {
                            multipartData.append(image, withName: key,fileName: "file.jpg", mimeType: "image/jpg")
                        }
                    }
                }
                else {
                    multipartData.append("\(value)".data(using: String.Encoding.utf8)!, withName: key)
                }
                

            }
            
        }, to: urlWithParameters, encodingCompletion: {
            result in
            
            switch result{
            case .success(let upload, _, _):
                upload.responseJSON { response in
                    if let data = response.data {
                        if let jsonResponse = try? JSONSerialization.jsonObject(with: data, options: []) {
                            if let errorMessage = (jsonResponse as? [String: Any])?["error"] as? String {
                                onFailure?(APIError.responseError(status: nil, message: errorMessage))
                            }
                            else {
                                onSuccess(jsonResponse as Any)
                            }
                            
                        }
                        else {
                            onFailure?(.notJson)
                        }
                    }
                    else {
                        onFailure?(.unknown)
                    }
                }
            case .failure(let error):
                onFailure?(APIError.unknown)
            }
        })
        
    }
    
    
    
}

enum HTTPMethod: Error {
    case GET
    case POST
}

enum APIError: Error {
    case invalidUrl
    case notJson
    case responseError(status: Int?, message: String)
    case unknown
}




struct FileInfo<T> {
    let type: FileType
    let data: T
}


enum FileType {
    case image
    case images
    case video
}
