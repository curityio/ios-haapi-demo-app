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

import XCTest
@testable import IdsvrHaapiSdkDemo

class RepresentationTests: XCTestCase {
    func testRedirectionStepRepresentationDeserialization() throws {
        let json = """
{
  "metadata": {
    "viewName": "/templates/redirect"
  },
  "type": "redirection-step",
  "actions": [
    {
      "template": "form",
      "kind": "redirect",
      "model": {
        "href": "https://785e77548e1e.ngrok.io/dev/authn/authenticate?serviceProviderId=oauth-dev&client_id=haapi-ios-dev-client&resumePath=%2Fdev%2Foauth%2Fauthorize&state=R_yNuXYI1Tpa3tuqquNRsSXQR5UJ1SPn8o",
        "method": "GET"
      }
    }
  ]
}
"""
        
        let representation = try Representation.fromJson(json)
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
        let json = """
{
  "metadata": {
    "viewName": "views/select-authenticator/index"
  },
  "type": "authentication-step",
  "actions": [
    {
      "template": "selector",
      "kind": "authenticator-selector",
      "title": "Select Authentication Method",
      "model": {
        "options": [
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "google1",
            "properties": {
              "authenticatorType": "google"
            },
            "model": {
              "href": "/dev/authn/authenticate/google1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "username",
            "properties": {
              "authenticatorType": "username"
            },
            "model": {
              "href": "/dev/authn/authenticate/username",
              "method": "GET"
            }
          }
        ]
      }
    }
  ]
}
"""
        let representation = try Representation.fromJson(json)
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
        let json = """
{
  "links": [
    {
      "href": "/dev/authn/authenticate/htmlSql/forgot-password",
      "rel": "forgot-password",
      "title": "Forgot your password?"
    },
    {
      "href": "/dev/authn/authenticate/htmlSql/forgot-account-id",
      "rel": "forgot-account-id",
      "title": "Forgot your username?"
    },
    {
      "href": "/dev/authn/register/create/htmlSql",
      "rel": "register-create",
      "title": "Create account"
    }
  ],
  "metadata": {
    "templateArea": "html1",
    "viewName": "authenticator/html-form/authenticate/get"
  },
  "type": "authentication-step",
  "actions": [
    {
      "template": "form",
      "kind": "login",
      "model": {
        "href": "/dev/authn/authenticate/htmlSql",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
        "title": "Login",
        "actionTitle": "Login",
        "fields": [
          {
            "name": "userName",
            "type": "username",
            "label": "Username"
          },
          {
            "name": "password",
            "type": "password",
            "label": "Password"
          }
        ]
      }
    }
  ]
}
"""
        
        let representation = try Representation.fromJson(json)
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
        let json = """
{
  "links": [
    {
      "href": "https://localhost:7777?code=fDsT5NDxwx80tx5zUTEL0HxCu6UUT5yB",
      "rel": "authorization-response"
    }
  ],
  "metadata": {
    "viewName": "templates/oauth/success-authorization-response"
  },
  "type": "oauth-authorization-response",
  "properties": {
    "code": "fDsT5NDxwx80tx5zUTEL0HxCu6UUT5yB"
  }
}
"""
        
        let representation = try Representation.fromJson(json)
        XCTAssertEqual(representation.type, .oauthAuthorizationResponse)
        
        XCTAssertNotNil(representation.properties)
        XCTAssertEqual(representation.properties.count, 1)
        
        XCTAssertEqual(representation.properties["code"], "fDsT5NDxwx80tx5zUTEL0HxCu6UUT5yB")
    }
}
