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

import Combine
import SwiftUI

final class ImageLoader: ObservableObject {

    let session: URLSession

    init(with session: URLSession = .shared)
    {
        self.session = session
    }

    func loadImageFromURL(_ url: URL) -> AnyPublisher<UIImage?, Never> {
        return session.dataTaskPublisher(for: url)
            .map {
                UIImage(data: $0.data)
            }
            .replaceError(with: nil)
            .eraseToAnyPublisher()
    }
}
