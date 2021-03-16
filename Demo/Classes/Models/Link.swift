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
import UIKit

enum LinkHrefDataType {
    case data
    case url
    case unknown(string: String)
}

struct Link: Decodable, Hashable {
    let href: String
    let rel: String
    let title: String?
    let mimeType: String?

    private enum CodingKeys: String, CodingKey {
        case href = "href"
        case rel = "rel"
        case title = "title"
        case mimeType = "type"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.href = try container.decode(String.self, forKey: .href)
        self.rel = try container.decode(String.self, forKey: .rel)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.mimeType = try container.decodeIfPresent(String.self, forKey: .mimeType)
    }

    init(href: String, rel: String, title: String?, mimeType: String? = nil) {
        self.href = href
        self.rel = rel
        self.title = title
        self.mimeType = mimeType
    }

    func hrefDataType() -> LinkHrefDataType {
        let scheme = href.components(separatedBy: ":").first ?? ""
        if scheme == "data" {
            return .data
        } else if scheme == "https" {
            return .url
        } else {
            return .unknown(string: scheme)
        }
    }

    func dataImage() -> UIImage? {
        guard case .data = hrefDataType() else {
            return nil
        }
        let allButScheme = href.components(separatedBy: ":").dropFirst().joined(separator: ":")
        let allButScehemeAndMime = allButScheme.components(separatedBy: ";").dropFirst().joined(separator: ";")
        let isBase64 = allButScehemeAndMime.components(separatedBy: ",").first == "base64"
        guard let dataString = allButScehemeAndMime.components(separatedBy: ",").last else {
            return nil
        }
        if isBase64 {
            if let dataDecoded = Data(base64Encoded: dataString, options: []) {
                let decodedimage = UIImage(data: dataDecoded)
                return decodedimage
            } else {
                return nil
            }
        } else {
            return nil
        }
    }

    func imageUrl() -> URL? {
        guard case .url = hrefDataType() else {
            return nil
        }
        return URL(string: href)
    }
}
