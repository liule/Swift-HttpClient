Swift-HttpClient
================

Swift Http 访问

<code>
        var httpClient:HttpClient = HttpClient()
        
        let url:NSURL = NSURL(string:"http://www.baidu.com/")

        httpClient.request(URL: url,post: nil){
            html,error in
            if let err = error {
                println("HTTP Error:\(err.localizedDescription)")
            } else {
                println("HTTP Success:\(html)")
            }
        }
</code>
