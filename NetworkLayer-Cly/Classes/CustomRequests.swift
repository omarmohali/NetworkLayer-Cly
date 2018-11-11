//
//  Request.swift
//  DataAccessLayerDemo
//
//  Created by Omar Ali on 9/15/18.
//  Copyright © 2018 Omar Ali. All rights reserved.
//

import Foundation
import ObjectMapper

open class RequestWithObjectResponse<T: Mappable>: Request<T> {
    
    override open func execute(onSuccess: @escaping ((T) -> Void), onFailure: ((APIError) -> Void)?) {
        super.executeHelper(onSuccess: {
            responseObject in
            
            if let responseDic = responseObject as? [String : Any], let object = Mapper<T>().map(JSON: responseDic) {
                onSuccess(object)
            }
            else {
                onFailure?(.unknown)
            }
            
        }, onFailure: {
            error in
            onFailure?(error)
        })
    }
}


open class RequestWithArrayResponse<T: Mappable>: Request<[T]> {
    
    override open func execute(onSuccess: @escaping (([T]) -> Void), onFailure: ((APIError) -> Void)?) {
        
        super.executeHelper(onSuccess: {
            responseObject in
            
            if let arrayOfObjects = Mapper<T>().mapArray(JSONObject: responseObject) {
                onSuccess(arrayOfObjects)
                return
            }
            else {
                onFailure?(APIError.notJson)
            }
            
        }, onFailure: {
            error in
            onFailure?(error)
        })
        
    }
}

open class RequestWithAnyResponse: Request<Any> {


    override open func execute(onSuccess: @escaping ((Any) -> Void), onFailure: ((APIError) -> Void)?) {

        super.executeHelper(onSuccess: {
            responseObject in

            onSuccess(responseObject)

        }, onFailure: {
            error in
            onFailure?(error)
        })

    }
}


