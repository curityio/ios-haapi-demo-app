/*
 * Copyright (C) 2020 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import Foundation

func performBlock(_ block: @escaping () -> Void, afterDelay: Double) {
    let when = DispatchTime.now() + afterDelay
    DispatchQueue.main.asyncAfter(deadline: when) {
        block()
    }
}

extension URL {
    func withQuery(name: String, value: String) -> URL {
        return withQuery(parameters: [name: value])
    }
    
    func withQuery(parameters: [String: String]) -> URL {
        var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: true)!
        
        var queryItems = (urlComponents.queryItems ?? []) as [URLQueryItem]
        for (name, value) in parameters {
            queryItems.append(URLQueryItem(name: name, value: value))
        }
        
        urlComponents.queryItems = queryItems
        
        return urlComponents.url!
    }
}
