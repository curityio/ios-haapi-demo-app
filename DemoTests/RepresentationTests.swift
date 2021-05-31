//
// Copyright (C) 2020 Curity AB.
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

class RepresentationTests: XCTestCase {
    func testRedirectionStepRepresentationDeserialization() throws {
        let representation = try Representation(try! Data(jsonFileName: "redirectionStepRepresentation", inBundle: Bundle(for: RepresentationTests.self)))
        XCTAssertEqual(representation.type, .redirectionStep)
        XCTAssertEqual(representation.actions.count, 1)
        
        let action = representation.actions.first!
        XCTAssertEqual(action.template, .form)
        XCTAssertEqual(action.kind, "redirect")
        
        XCTAssert(action.model is FormModel)
        
        let form = action.model as! FormModel
        XCTAssertEqual(form.href, "https://785e77548e1e.ngrok.io/dev/authn/authenticate?serviceProviderId=oauth-dev&client_id=haapi-ios-dev-client&resumePath=%2Fdev%2Foauth%2Fauthorize&state=R_yNuXYI1Tpa3tuqquNRsSXQR5UJ1SPn8o")
        XCTAssertEqual(form.method, "GET")
    }
    
    func testAuthenticationStepSelectorRepresentationDeserialization() throws {
        let representation = try Representation(try! Data(jsonFileName: "authenticationStepSelectorRepresentation", inBundle: Bundle(for: RepresentationTests.self)))
        XCTAssertEqual(representation.type, .authenticationStep)
        
        XCTAssertEqual(representation.metadata.count, 1)
        XCTAssertEqual(representation.metadata["viewName"], "views/select-authenticator/index")
        XCTAssertEqual(representation.actions.count, 1)
        
        let action = representation.actions.first!
        XCTAssertEqual(action.template, .selector)
        XCTAssertEqual(action.kind, "authenticator-selector")
        XCTAssertEqual(action.title, "Select Authentication Method")

        guard let selector = action.model as? IdsvrHaapiSdkDemo.SelectorModel else {
            XCTFail("action.model was not Selector type")
            return
        }

        let options = selector.options
        
        XCTAssertEqual(options.count, 2)

        XCTAssertEqual(options[0].template, .form)
        XCTAssertEqual(options[0].kind, "select-authenticator")
        XCTAssertEqual(options[0].title, "google1")
        XCTAssertEqual(options[0].properties.count, 1)
        XCTAssertEqual(options[0].properties["authenticatorType"], "google")
        XCTAssert(options[0].model is FormModel)
        XCTAssertEqual(options[0].form?.href, "/dev/authn/authenticate/google1")
        XCTAssertEqual(options[0].form?.method, "GET")

        XCTAssertEqual(options[1].template, .form)
        XCTAssertEqual(options[1].kind, "select-authenticator")
        XCTAssertEqual(options[1].title, "username")
        XCTAssertEqual(options[1].properties.count, 1)
        XCTAssertEqual(options[1].properties["authenticatorType"], "username")
        XCTAssert(options[1].model is FormModel)
        XCTAssertEqual(options[1].form?.href, "/dev/authn/authenticate/username")
        XCTAssertEqual(options[1].form?.method, "GET")
    }
    
    func testAuthenticationStepFormRepresentationDeserialization() throws {
        let representation = try Representation(Data(jsonFileName: "authenticationStepFormRepresentation", inBundle: Bundle(for: RepresentationTests.self)))
        XCTAssertEqual(representation.type, .authenticationStep)
        XCTAssertEqual(representation.actions.count, 1)
        
        let action = representation.actions.first!
        XCTAssertEqual(action.template, .form)
        XCTAssertEqual(action.kind, "login")
        
        XCTAssert(action.model is FormModel)
        
        let form = action.model as! FormModel
        XCTAssertEqual(form.href, "/dev/authn/authenticate/htmlSql")
        XCTAssertEqual(form.method, "POST")
        XCTAssertEqual(form.type, "application/x-www-form-urlencoded")
        XCTAssertEqual(form.title, "Login")
        XCTAssertEqual(form.actionTitle, "Login")
        
        let fields = form.fields
        XCTAssertEqual(fields.count, 2)
            
        XCTAssertEqual(fields[0].name, "userName")
        XCTAssertEqual(fields[0].type, .username)
        XCTAssertEqual(fields[0].label, "Username")

        XCTAssertEqual(fields[1].name, "password")
        XCTAssertEqual(fields[1].type, .password)
        XCTAssertEqual(fields[1].label, "Password")
    }
    
    func testOauthAuthorizationResponseRepresentationDeserialization() throws {
        let representation = try Representation(Data(jsonFileName: "oauthAuthorizationResponseRepresentation", inBundle: Bundle(for: RepresentationTests.self)))
        XCTAssertEqual(representation.type, .oauthAuthorizationResponse)
        
        XCTAssertNotNil(representation.properties)
        XCTAssertEqual(representation.properties.count, 1)
        
        XCTAssertEqual(representation.properties["code"], "fDsT5NDxwx80tx5zUTEL0HxCu6UUT5yB")
    }
}
