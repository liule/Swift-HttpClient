//
//  HttpClient.swift
//  SwiftFrameworkTesting
//
//  Created by 招利 李 on 14-6-24.
//  Copyright (c) 2014年 慧趣工作室. All rights reserved.
//

import Foundation

class HttpClient: NSObject {
/*
    class func urlEncode(value:String) {
        NSString
        let str: CFString = Unmanaged.fromOpaque(value.toOpaque()).takeUnretainedValue()
        let result = CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault,
            originalString: value as CFStringRef,
            charactersToLeaveUnescaped: nil,
            legalURLCharactersToBeEscaped: "!*'();:@&=+$,/?%#[]" as CFStringRef,
            encoding: kUnicodeUTF8Format)
        
        
    }
*/
    class func arrayFromJSON(json:String!) -> Array<AnyObject>! {
        return objectFromJSON(json) as Array<AnyObject>
    }
    class func dictionaryFromJSON(json:String!) -> Dictionary<String,AnyObject>! {
        return objectFromJSON(json) as Dictionary<String,AnyObject>
    }
    
    //把 JSON 转成 Array 或 Dictionary
    class func objectFromJSON(json:String!) -> AnyObject! {
        let string:NSString = json
        let data = string.dataUsingEncoding(NSUTF8StringEncoding)
        var error:NSError?
        let object : AnyObject! = NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions(0), error: &error)
        if let err = error {
            println("JSON to object error:\(err.localizedDescription)")
            return nil
        } else {
            return object;
        }
    }
    //把 Array 或 Dictionary 转 JSON
    class func JSONFromObject(object:AnyObject!) -> String!{
        if !NSJSONSerialization.isValidJSONObject(object) {
            return nil
        }
        var error:NSError?
        let data = NSJSONSerialization.dataWithJSONObject(object, options: NSJSONWritingOptions(0), error: &error)
        if let err = error {
            println("object to JSON error:\(err.localizedDescription)")
            return nil
        } else {
            return NSString(data: data, encoding: NSUTF8StringEncoding)
        }
    }

    var timeoutInterval: NSTimeInterval
    init(timeoutInterval: NSTimeInterval){
        self.timeoutInterval = timeoutInterval
    }
    init() {
        timeoutInterval = 10;
    }
    
    func request(#URLString: String, post: Dictionary<String, String>?, onComplete: ((html: String, error: NSError?) -> ())?) {
        self.request(URL: NSURL(string: URLString), post: post, onComplete: onComplete)
    }
    
    var onComplete:((html:String, error:NSError?)->())?
    func request(URL url:NSURL, post:Dictionary<String,String>?, onComplete:((html:String, error:NSError?)->())?) {
        self.cancel();
        //设置回掉函数
        self.onComplete = onComplete
        
        var request:NSMutableURLRequest = NSMutableURLRequest(URL: url, cachePolicy: .UseProtocolCachePolicy, timeoutInterval: timeoutInterval)
        
        request.HTTPMethod = "GET"
        if let datas = post {
            if datas.count > 0 {
                request.HTTPMethod = "POST"
                var postString:NSMutableString = ""
                for (key,value) in datas {
                    if postString.length > 0 {
                        postString.appendString("&")
                    }
                    postString.appendString("\(key)=\(value)")
                }
                let data:NSData = postString.dataUsingEncoding(NSUTF8StringEncoding)
                request.HTTPBody = data;
                request.setValue("\(data.length)", forHTTPHeaderField: "Content-Length")
                
            }
        }
        //连接服务器
        
        connection = NSURLConnection(request: request, delegate: self)
    }
    
    var connection:NSURLConnection? = nil
    func cancel() {
        if let conn = connection {
            conn.cancel()
        }
        if let complete = onComplete {
            complete(html: "",error: NSError(domain: "用户取消了HTTP发送", code: 500, userInfo: nil))
            onComplete = nil
        }
    }
    
    var receiveData:NSMutableData? = nil
}

extension HttpClient:NSURLConnectionDelegate {
    
    //接收到服务器回应的时候调用此方法
    func connection(connection: NSURLConnection!, didReceiveResponse response: NSURLResponse!) {
        receiveData = NSMutableData()
    }
    
    //接收到服务器传输数据的时候调用，此方法根据数据大小执行若干次
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!) {
        if var receive = receiveData {
            receive.appendData(data)
        } else {
            receiveData = NSMutableData()
            receiveData!.appendData(data)
        }
    }
    
    //数据传完之后调用此方法
    func connectionDidFinishLoading(connection: NSURLConnection!) {
        var html:String = NSString(data: receiveData, encoding: NSUTF8StringEncoding)
        if let complete = onComplete {
            complete(html: html,error: nil)
            onComplete = nil
        }
    }
    
    //网络请求过程中，出现任何错误（断网，连接超时等）会进入此方法
    func connection(connection: NSURLConnection!, didFailWithError error: NSError!) {
        if let complete = onComplete {
            complete(html: "",error: error)
            onComplete = nil
        }
    }
}
