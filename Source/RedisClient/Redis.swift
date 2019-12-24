//
//  Redis.swift
//  Redis Client
//
//  Created by Ilya Trikoz on 07/09/2019.
//  Copyright © 2019 Ilya Trikoz. All rights reserved.
//
import Foundation
import Redis

class RC {
    static let shared = RC()
    init() {}
    
    func getClient(host: String?, port: Int?) -> RedisClient {
        let client = Redis.createClient()
        if (host != nil) {
            client.options.hostname = host
        }
        if (port != nil) {
            client.options.port = port!
        }
        return client
    }
    
    func test(host: String?, port: Int?, completion: @escaping (_ result: Bool)->()) {
        var tested = false
        let client = getClient(host: host, port: port)
    
        client.ping("check") { err, res in
            if (tested == false) {
                tested = true
                if (err == nil) {
                    completion(true)
                } else {
                    completion(false)
                }
                client.quit()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if (tested == false) {
                tested = true
                completion(false)
                client.quit()
            }
        }
    }
    
}
