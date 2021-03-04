/*
 * Copyright (C) 2021 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import Foundation

extension Encodable {
    func asJsonString(prettyPrinted: Bool = false) -> String? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = prettyPrinted ? [.prettyPrinted] : []
            let jsonData = try encoder.encode(self)
            let string = String(data: jsonData, encoding: .utf8)
            return string
        } catch {
            print("Error generating json: \(error.localizedDescription)")
            return nil
        }
    }
}

extension String {
    func decodedAsJson<T: Decodable>(as type: T.Type) -> T? {
        guard let data = self.data(using: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
