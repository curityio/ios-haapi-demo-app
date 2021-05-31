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
@testable import IdsvrHaapiSdkDemo

class TemplateTests: XCTestCase {

    func testTemplateClientOperation() {
        let clientOperation = Template.clientOperation
        do {
            let data = try JSONEncoder().encode(clientOperation)
            let string = try JSONDecoder().decode(String.self, from: data)
            XCTAssertEqual(string, clientOperation.rawValue)
        } catch {
            XCTFail("Template.clientOperation should conform to Data -> String: \(error.localizedDescription)")
        }
    }

    func testTemplateUnsupported() {
        let template = Template.unsupported(value: "Awesome value")
        do {
            let data = try JSONEncoder().encode(template)
            let string = try JSONDecoder().decode(String.self, from: data)
            XCTAssertEqual(string, template.rawValue)
        } catch {
            XCTFail("Template.unsupported should conform to Data -> String: \(error.localizedDescription)")
        }
    }

}
