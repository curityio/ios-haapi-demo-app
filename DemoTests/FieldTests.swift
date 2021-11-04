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

class FieldTests: XCTestCase {

//    enum TestFailed: Error {
//        case reason(String)
//    }
//
//    func testFieldValidJSON() {
//        do {
//            let data = try Data(jsonFileName: "fieldValid", inBundle: Bundle(for: FieldTests.self))
//            let field = try JSONDecoder().decode(Field.self, from: data)
//            XCTAssertEqual(field.name, "A field", "field.name is not equal")
//            XCTAssertEqual(field.type, .username, "field.type is not username")
//            XCTAssertNil(field.label, "field.label should be nil")
//            XCTAssertNil(field.value, "field.value should be nil")
//            XCTAssertNil(field.placeholder, "field.placeholder should be nil")
//        } catch {
//            XCTFail("Invalid flow: \(error.localizedDescription)")
//        }
//    }
//
//    func testFieldInvalidJSON() {
//        do {
//            let data = try Data(jsonFileName: "fieldInvalid", inBundle: Bundle(for: FieldTests.self))
//            _ = try JSONDecoder().decode(Field.self, from: data)
//            XCTFail("Expecting invalid JSON for Field")
//        } catch {
//            XCTAssertTrue(true, "Expecting JSONDecoder to fail")
//        }
//    }
//
//    func testFieldToDict() {
//        let field = Field(name: "A field",
//                          type: .username,
//                          label: nil,
//                          value: nil,
//                          placeholder: nil,
//                          checked: nil,
//                          readonly: nil)
//        do {
//            let data = try JSONEncoder().encode(field)
//            guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
//                throw TestFailed.reason("Invalid Dictionary")
//            }
//            XCTAssertEqual(json["name"] as? String, field.name, "field.name is not equal")
//            XCTAssertEqual(json["type"] as? String, "username", "field.username is not equal")
//            XCTAssertEqual(json["label"] as? String, field.label, "field.label is not equal")
//            XCTAssertEqual(json["value"] as? String, field.value, "field.value is not equal")
//            XCTAssertEqual(json["placeholder"] as? String, field.placeholder, "field.placeholder is not equal")
//            XCTAssertEqual(json["checked"] as? Bool, field.checked, "field.checked is not equal")
//            XCTAssertEqual(json["readonly"] as? Bool, field.readonly, "field.readonly is not equal")
//        } catch {
//            XCTFail("Invalid flow: \(error.localizedDescription)")
//        }
//    }

}
