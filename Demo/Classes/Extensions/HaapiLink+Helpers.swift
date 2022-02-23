//
// Copyright (C) 2021 Curity AB.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//   http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import IdsvrHaapiSdk

enum LinkHrefDataType: Equatable {
    case data
    case url
    case unknown(string: String)
}

extension Link {

    func imageUrl() -> URL? {
        guard true == type?.contains("image"),
              case .url = hrefDataType()
        else {
            return nil
        }
        return URL(string: href)
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
}
