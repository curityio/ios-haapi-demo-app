//
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

import XCTest
import Combine
@testable import IdsvrHaapiSdkDemo

class ImageLoaderTests: XCTestCase {

    func testLoadImage() throws {
        let imageLoader = ImageLoader(with: .shared)
        let url = URL(string: "https://curity.io/images/curity-logo-landscape.png")!

        let exp = expectation(description: "Expecting return value")
        var result: Result<UIImage?, Error>?
        let cancellable = imageLoader.loadImageFromURL(url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                exp.fulfill()
            }, receiveValue: { image in
                result = .success(image)
            })

        waitForExpectations(timeout: 10.0)
        cancellable.cancel()
        let value = try XCTUnwrap(result, "Awaited publisher did not produce an output UIImage?")

        XCTAssertNotNil(try value.get(), "Expecting an UIImage from \(url.absoluteString)")
    }

    func testInvalidURLLoadImage() throws {
        let imageLoader = ImageLoader(with: .shared)
        let url = URL(string: "https://curity.io")!

        let exp = expectation(description: "Expecting return value")
        var result: Result<UIImage?, Error>?
        let cancellable = imageLoader.loadImageFromURL(url)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in
                exp.fulfill()
            }, receiveValue: { image in
                result = .success(image)
            })

        waitForExpectations(timeout: 10.0)
        cancellable.cancel()
        let value = try XCTUnwrap(result, "Awaited publisher did not produce an output UIImage?")

        XCTAssertNil(try value.get(), "Expecting nil from \(url.absoluteString)")
    }
}
