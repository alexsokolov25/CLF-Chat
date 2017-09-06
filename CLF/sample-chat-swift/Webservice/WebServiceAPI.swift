//
//  READY
//
//  Created by Admin on 18/03/16.
//  Copyright © 2016 Andrei. All rights reserved.
//

import UIKit
import Alamofire

class WebServiceAPI: NSObject {
    
    static func postDataWithURL(_ url:String,
                                token: String?,
                                withoutHeader: Bool,
                                params:[String: Any]?,
                                completionBlock:((_ request:URLRequest?, _ response:HTTPURLResponse?, _ data:AnyObject)->Void)?,
                                errBlock:((_ errorString:String)->Void)? )-> Void {
        
        
        var headers:[String:String]? = nil
        if withoutHeader {
            headers = nil
        } else {
            headers = ["Authorization":"bearer " + token!]
        }
        
        let urlString = "\(Constants.WebServiceApi.ApiBaseUrl)\(url)"
        print("WebServiceAPI postDataWithURL: \(urlString)")
        
        Alamofire.request(urlString, method: .post, parameters: params, headers: headers).responseJSON {
            (response) in
            
            print(response)
            
            let json = response.result
            if json.isSuccess {
                if let data = json.value {
                    
                    let jsonObj = JSON(data)
                    
                    if jsonObj.error == nil {
                        completionBlock!(nil, nil, data as AnyObject)
                    } else {
                        errBlock!(jsonObj.error!.localizedDescription)
                    }
                    
                } else {
                    errBlock!("Could not get json.value")
                }
            } else {
                errBlock!("We're sorry, a network error occurred")
            }
            
        }
    }

    static func postDataWithURLWithResource(_ url:String,
                                token: String?,
                                withoutHeader: Bool,
                                resourceData:Data?,
                                fileName:String,
                                mimeType:String,
                                attachParamName:String,
                                params:Dictionary<String, AnyObject>?,
                                completionBlock:((_ request:URLRequest?, _ response:HTTPURLResponse?, _ json:AnyObject)->Void)?,
                                errBlock:((_ errorString:String)->Void)? )-> Void {
        var headers:[String:String]? = nil
        if withoutHeader {
            headers = nil
        } else {
            headers = ["Authorization":"bearer " + token!]
        }
        
        let m = SessionManager.default
        m.session.configuration.httpAdditionalHeaders = headers
        
        let urlString = "\(Constants.WebServiceApi.ApiBaseUrl)\(url)"

        print("urlString: \(urlString)")
        Alamofire.upload(multipartFormData: { (multipartFormData) in
            if let data = resourceData {
                multipartFormData.append(data, withName: attachParamName, fileName: fileName, mimeType: mimeType)
            }
            
            if let params = params {
                for (key, value) in params {
                    let d = String(describing: value).data(using: .utf8)
                    multipartFormData.append(d!, withName: key)
                }
            }
            
            }, usingThreshold: 10 * 1024 * 1024,
               to: urlString,
               method: .post,
               headers: headers) { (encodingResult) in
                
                switch encodingResult {
                case .success(let upload, _, _):
                    
                    upload.responseJSON(completionHandler: { response in
                        
                        debugPrint(response)
                        
                        let json = response.result
                        if let data = json.value {
                            let jsonObj = JSON(data)
                            
                            if jsonObj.error == nil {
                                completionBlock!(nil, nil, data as AnyObject)
                            } else {
                                errBlock!("")
                            }
                            
                        } else {
                            errBlock!("")
                        }
                    })
                    upload.responseString(completionHandler: { (response) in
                        debugPrint(response)
                    })
                case .failure(let encodingError):
                    print("Encoding Result was FAILURE")
                    print(encodingError)
                }

                
        }
        
        
    }

    static func getDataWithURL(_ url:String,
                               token: String?,
                               params:[String: Any]?,
                               withoutHeader: Bool,
                               cacheKey:String?,
                               completionBlock:((_ request:URLRequest?, _ response:HTTPURLResponse?, _ json:JSON, _ isFromCache:Bool)->Void)?,
                               errBlock:((_ errorString:String)->Void)? )-> Void {
            
        
        var headers:[String:String]? = nil
        if withoutHeader {
            headers = nil
        } else {
            headers = ["Authorization":"bearer " + token!]
        }
        
        let urlString = "\(Constants.WebServiceApi.ApiBaseUrl)\(url)"
        
        Alamofire.request(urlString, method: .get, parameters: params, headers: headers).responseJSON { (response) in
            let json = response.result
            if json.isSuccess {
                if let data = json.value {
                    
                    let jsonObj = JSON(data)
                    
                    if jsonObj.error == nil {
                         completionBlock!(nil, nil, jsonObj, false)
                    } else {
                        errBlock!(jsonObj.error!.localizedDescription)
                    }
                    
                } else {
                    errBlock!("")
                }
            } else {
                errBlock!("We're sorry, a network error occurred")
            }
            
        }
    }

    //MARK: converter
    static func dateFromString(_ dateString:String?, dateFormat:String) -> Date? {
        if let dateString = dateString {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "US_en")
            formatter.dateFormat = dateFormat
            return formatter.date(from: dateString)
        }
        
        return nil
    }

}
