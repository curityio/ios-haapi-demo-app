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

import Foundation
import IdsvrHaapiSdk

/// A model representing an error container that has a title and an error.
struct ErrorInfo: Equatable, LocalizedError {

    /// A title for the Error. It is **not 100%** localized.
    let title: String
    let error: Error

    init(_ error: Error) {
        self.title = error.title
        self.error = error
    }

    init(title: String, error: Error) {
        self.title = title
        self.error = error
    }

    static func == (lhs: ErrorInfo, rhs: ErrorInfo) -> Bool {
        return lhs.title == rhs.title &&
            (lhs.error as NSError) == (rhs.error as NSError)
    }

    var errorDescription: String? {
        return error.localizedDescription
    }
}

private extension Error {

    var title: String {
        let result: String
        if self is HaapiError {
            result = "Communication error"
        }
        else if self is StorageError {
            result = "Storage error"
        }
        else if self is HaapiControllerError {
            result = "Haapi Demo error"
        }
        else {
            result = "System error"
        }
        return result
    }
}
