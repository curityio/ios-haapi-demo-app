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

import Foundation

enum RepresentationSamples {
    static let redirect = """
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
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate?serviceProviderId=oauth-dev&client_id=haapi-public-client&resumePath=%2Fdev%2Foauth%2Fauthorize&state=R_93L2ZIITQP95bbCqQyDPho1WM23I84Gu",
        "method": "GET"
      }
    }
  ]
}
"""
    
    static let selectAuthentication = """
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
            "title": "totp",
            "properties": {
              "authenticatorType": "totp"
            },
            "model": {
              "href": "/dev/authn/authenticate/totp",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "phpass",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/phpass",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "sms2fa",
            "properties": {
              "authenticatorType": "sms"
            },
            "model": {
              "href": "/dev/authn/authenticate/sms2fa",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "twitter1",
            "properties": {
              "authenticatorType": "twitter"
            },
            "model": {
              "href": "/dev/authn/authenticate/twitter1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "sms1",
            "properties": {
              "authenticatorType": "sms"
            },
            "model": {
              "href": "/dev/authn/authenticate/sms1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "smsScim2",
            "properties": {
              "authenticatorType": "sms"
            },
            "model": {
              "href": "/dev/authn/authenticate/smsScim2",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "A Test 2fa authenticator",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/html2fa",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "sms3",
            "properties": {
              "authenticatorType": "sms"
            },
            "model": {
              "href": "/dev/authn/authenticate/sms3",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "A standard SQL backed authenticator",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlSql",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "A standard LDAP backed authenticator",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlLdap",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "email2",
            "properties": {
              "authenticatorType": "email"
            },
            "model": {
              "href": "/dev/authn/authenticate/email2",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "email1",
            "properties": {
              "authenticatorType": "email"
            },
            "model": {
              "href": "/dev/authn/authenticate/email1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "bankid1",
            "properties": {
              "authenticatorType": "bankid"
            },
            "model": {
              "href": "/dev/authn/authenticate/bankid1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "testAuth1",
            "properties": {
              "authenticatorType": "test"
            },
            "model": {
              "href": "/dev/authn/authenticate/testAuth1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "testAuth-janedoe",
            "properties": {
              "authenticatorType": "test"
            },
            "model": {
              "href": "/dev/authn/authenticate/testAuth-janedoe",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "A standard JSON-DataSource backed authenticator",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlFormJson",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "duo1",
            "properties": {
              "authenticatorType": "duo"
            },
            "model": {
              "href": "/dev/authn/authenticate/duo1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "social1",
            "properties": {
              "authenticatorType": "group"
            },
            "model": {
              "href": "/dev/authn/authenticate/social1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "encap1",
            "properties": {
              "authenticatorType": "encap"
            },
            "model": {
              "href": "/dev/authn/authenticate/encap1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "htmlFormJsonOAuth",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlFormJsonOAuth",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "2-factor authentiction",
            "properties": {
              "authenticatorType": "encap"
            },
            "model": {
              "href": "/dev/authn/authenticate/encap2",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "ping-idp-adapter",
            "properties": {
              "authenticatorType": "ping-idp-adapter"
            },
            "model": {
              "href": "/dev/authn/authenticate/ping-idp-adapter",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "win1",
            "properties": {
              "authenticatorType": "windows"
            },
            "model": {
              "href": "/dev/authn/authenticate/win1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "htmlScimBisnode",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlScimBisnode",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "A standard Active Directory backed authenticator",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlAd",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "ping1",
            "properties": {
              "authenticatorType": "pingfederate"
            },
            "model": {
              "href": "/dev/authn/authenticate/ping1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "htmlScimMock",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlScimMock",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "Virtual SAML",
            "properties": {
              "authenticatorType": "saml"
            },
            "model": {
              "href": "/dev/authn/authenticate/saml1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "NetIdAccess",
            "properties": {
              "authenticatorType": "netidaccess"
            },
            "model": {
              "href": "/dev/authn/authenticate/NetIdAccess",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "ping2bo",
            "properties": {
              "authenticatorType": "pingfederate"
            },
            "model": {
              "href": "/dev/authn/authenticate/ping2bo",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "htmlOpenLdap",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlOpenLdap",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "ping-fs01",
            "properties": {
              "authenticatorType": "pingfederate"
            },
            "model": {
              "href": "/dev/authn/authenticate/ping-fs01",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "htmlScim2Curity",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlScim2Curity",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "group1",
            "properties": {
              "authenticatorType": "group"
            },
            "model": {
              "href": "/dev/authn/authenticate/group1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "bcrypt",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/bcrypt",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "oidc1",
            "properties": {
              "authenticatorType": "oidc"
            },
            "model": {
              "href": "/dev/authn/authenticate/oidc1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "facebook1",
            "properties": {
              "authenticatorType": "facebook"
            },
            "model": {
              "href": "/dev/authn/authenticate/facebook1",
              "method": "GET"
            }
          },
          {
            "template": "form",
            "kind": "select-authenticator",
            "title": "htmlScim2Osiam",
            "properties": {
              "authenticatorType": "html-form"
            },
            "model": {
              "href": "/dev/authn/authenticate/htmlScim2Osiam",
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
    
    static let selectAuthenticationWithLinks = """
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
    
    static let bankidSelectSameOrOtherDevice = """
{
  "metadata": {
    "viewName": "authenticator/bankid/enter-personalnumber/index"
  },
  "type": "authentication-step",
  "actions": [
    {
      "template": "form",
      "kind": "bankid-same-device",
      "title": "Login with BankID installed on this device",
      "model": {
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/bankid1/index",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
        "actionTitle": "Login",
        "fields": [
          {
            "name": "usesamedevice",
            "type": "hidden",
            "value": "true"
          }
        ]
      }
    },
    {
      "template": "form",
      "kind": "bankid-other-device",
      "title": "Login with BankID installed on a different device",
      "model": {
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/bankid1/index",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
        "actionTitle": "Login",
        "fields": [
          {
            "name": "personalnumber",
            "type": "username",
            "label": "Personal number",
            "placeholder": "yyyymmddnnnn"
          },
          {
            "name": "usesamedevice",
            "type": "hidden",
            "value": "false"
          }
        ]
      }
    }
  ]
}
"""
    
    static let bankidSameDeviceClientOperation = """
{
  "metadata": {
    "viewName": "authenticator/bankid/launch/index"
  },
  "type": "authentication-step",
  "actions": [
    {
      "template": "client-operation",
      "kind": "login",
      "title": "Login with BankID",
      "model": {
        "name": "bankid",
        "arguments": {
          "href": "bankid:///?autostarttoken=04b7c1bd-6d7b-46c0-b8ed-00f5cf39688c&redirect=null",
          "autoStartToken": "04b7c1bd-6d7b-46c0-b8ed-00f5cf39688c",
          "redirect": "https%3A%2F%2Fdafe6dff0c1c.ngrok.io%2Fdev%2Fauthn%2Fauthenticate%2Fbankid1%2Flaunch"
        },
        "continueActions": [
          {
            "template": "form",
            "kind": "redirect",
            "title": "If you are not redirected automatically, click here to continue authenticating",
            "model": {
              "href": "https://dafe6dff0c1c.ngrok.io/dev/authn/authenticate/bankid1/poller",
              "method": "GET"
            }
          }
        ],
        "errorActions": [
          {
            "template": "form",
            "kind": "bankid-other-device",
            "title": "Login with BankID installed on a different device",
            "model": {
              "href": "/dev/authn/authenticate/bankid1/launch",
              "method": "POST",
              "type": "application/x-www-form-urlencoded",
              "actionTitle": "Login",
              "fields": [
                {
                  "name": "personalnumber",
                  "type": "username",
                  "label": "Personal number",
                  "placeholder": "yyyymmddnnnn"
                },
                {
                  "name": "usesamedevice",
                  "type": "hidden",
                  "value": "false"
                }
              ]
            }
          }
        ]
      }
    },
    {
      "template": "form",
      "kind": "continue",
      "title": "Start the BankID security app",
      "model": {
        "href": "https://dafe6dff0c1c.ngrok.io/dev/authn/authenticate/bankid1/poller",
        "method": "GET",
        "type": "application/x-www-form-urlencoded",
        "actionTitle": "Start the BankID security app"
      }
    },
    {
      "template": "form",
      "kind": "cancel",
      "title": "Cancel this operation",
      "model": {
        "href": "https://dafe6dff0c1c.ngrok.io/dev/authn/authenticate/bankid1/cancel",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
        "actionTitle": "Cancel"
      }
    }
  ]
}
"""
    
    static let usernamePassword = """
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
      "title": "Login",
      "model": {
        "href": "/dev/authn/authenticate/htmlSql",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
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
    
    static let usernamePasswordFormErrors = """
{
  "metadata": {
    "templateArea": "html1"
  },
  "invalidFields": [
    {
      "name": "password",
      "reason": "invalidValue",
      "detail": "You have to enter your password"
    },
    {
      "name": "userName",
      "reason": "invalidValue",
      "detail": "You have to enter your username"
    }
  ],
  "type": "https://curity.se/problems/invalid-input",
  "title": "Form Errors"
}
"""
    
    static let duo = """
{
  "links": [
    {
      "href": "/dev/authn/anonymous/duo1/info",
      "rel": "register-create",
      "title": "Register new device"
    }
  ],
  "metadata": {
    "viewName": "authenticator/duo/authenticate/select-device"
  },
  "type": "authentication-step",
  "actions": [
    {
      "template": "selector",
      "kind": "device-selector",
      "title": "Device selection",
      "model": {
        "options": [
          {
            "template": "selector",
            "kind": "device-option",
            "title": "Fake (+XXX XXX XXX 789)",
            "model": {
              "options": [
                {
                  "template": "form",
                  "kind": "login",
                  "title": "auto",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DP5N54VPVTYII32TIANH"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "auto"
                      }
                    ]
                  }
                },
                {
                  "template": "form",
                  "kind": "login",
                  "title": "push",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DP5N54VPVTYII32TIANH"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "push"
                      }
                    ]
                  }
                },
                {
                  "template": "form",
                  "kind": "login",
                  "title": "sms",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DP5N54VPVTYII32TIANH"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "sms"
                      }
                    ],
                    "continueActions": [
                      {
                        "template": "form",
                        "kind": "login",
                        "title": "passcode",
                        "model": {
                          "href": "/dev/authn/authenticate/duo1/select-device",
                          "method": "POST",
                          "type": "application/x-www-form-urlencoded",
                          "fields": [
                            {
                              "name": "device",
                              "type": "hidden",
                              "value": "DP5N54VPVTYII32TIANH"
                            },
                            {
                              "name": "factor",
                              "type": "hidden",
                              "value": "passcode"
                            },
                            {
                              "name": "passcode",
                              "type": "text",
                              "label": "Passcode"
                            }
                          ]
                        }
                      }
                    ]
                  }
                },
                {
                  "template": "form",
                  "kind": "login",
                  "title": "passcode",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DP5N54VPVTYII32TIANH"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "passcode"
                      },
                      {
                        "name": "passcode",
                        "type": "text",
                        "label": "Passcode"
                      }
                    ]
                  }
                }
              ]
            }
          },
          {
            "template": "selector",
            "kind": "device-option",
            "title": "Galaxy (+XXX XXX XXX 815)",
            "model": {
              "options": [
                {
                  "template": "form",
                  "kind": "login",
                  "title": "auto",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DPS31IX8I1NUQIY9EMC6"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "auto"
                      }
                    ]
                  }
                },
                {
                  "template": "form",
                  "kind": "login",
                  "title": "push",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DPS31IX8I1NUQIY9EMC6"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "push"
                      }
                    ]
                  }
                },
                {
                  "template": "form",
                  "kind": "login",
                  "title": "sms",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DPS31IX8I1NUQIY9EMC6"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "sms"
                      }
                    ],
                    "continueActions": [
                      {
                        "template": "form",
                        "kind": "login",
                        "title": "passcode",
                        "model": {
                          "href": "/dev/authn/authenticate/duo1/select-device",
                          "method": "POST",
                          "type": "application/x-www-form-urlencoded",
                          "fields": [
                            {
                              "name": "device",
                              "type": "hidden",
                              "value": "DPS31IX8I1NUQIY9EMC6"
                            },
                            {
                              "name": "factor",
                              "type": "hidden",
                              "value": "passcode"
                            },
                            {
                              "name": "passcode",
                              "type": "text",
                              "label": "Passcode"
                            }
                          ]
                        }
                      }
                    ]
                  }
                },
                {
                  "template": "form",
                  "kind": "login",
                  "title": "passcode",
                  "model": {
                    "href": "/dev/authn/authenticate/duo1/select-device",
                    "method": "POST",
                    "type": "application/x-www-form-urlencoded",
                    "fields": [
                      {
                        "name": "device",
                        "type": "hidden",
                        "value": "DPS31IX8I1NUQIY9EMC6"
                      },
                      {
                        "name": "factor",
                        "type": "hidden",
                        "value": "passcode"
                      },
                      {
                        "name": "passcode",
                        "type": "text",
                        "label": "Passcode"
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  ]
}
"""
    
    static let oauthAuthorizationResponse = """
{
  "links": [
    {
      "href": "https://localhost:7777/client-callback?code=OZxymZHVjkEhf9fajYz0jNPOaJaQpXTg&state=foo",
      "rel": "authorization-response"
    }
  ],
  "metadata": {
    "viewName": "templates/oauth/success-authorization-response"
  },
  "type": "oauth-authorization-response",
  "properties": {
    "code": "OZxymZHVjkEhf9fajYz0jNPOaJaQpXTg",
    "state": "foo"
  }
}
"""
    
    static let launchExternalBrowser = """
{
  "metadata": {
    "viewName": "authenticator/external-browser/launch"
  },
  "type": "authentication-step",
  "actions": [
    {
      "template": "launch",
      "kind": "external-browser",
      "title": "The authentication process needs to use an external browser",
      "model": {
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/username?_launch_nonce=hpGzxOf7BgXE3dbftd7NFXHatPyD9Z2m",
        "actionTitle": "The authentication process needs to use an external browser",
        "continueActions": [
          {
            "template": "form",
            "kind": "continue",
            "title": "If you are not redirected automatically, click here to continue authenticating",
            "model": {
              "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/username",
              "method": "GET",
              "type": "application/x-www-form-urlencoded",
              "fields": [
                {
                  "name": "_resume_nonce",
                  "type": "context"
                }
              ]
            }
          }
        ]
      }
    }
  ]
}
"""
    
    static let incorrectCredentialsProblem = """
{
  "metadata": {
    "templateArea": "html1"
  },
  "type": "https://curity.se/problems/incorrect-credentials",
  "title": "Incorrect credentials"
}
"""
    
    static let incorrectCredentialsProblemWithMessages = """
{
  "messages": [
    {
      "text": "Foo",
      "classList": [
        "info"
      ]
    }, {
      "text": "Bar",
      "classList": [
        "info"
      ]
    }
  ],
  "metadata": {
    "templateArea": "html1"
  },
  "type": "https://curity.se/problems/incorrect-credentials",
  "title": "Incorrect credentials"
}
"""
    
    static let pollingStep = """
{
  "metadata": {
    "viewName": "authenticator/duo/authenticate/device-poller"
  },
  "type": "polling-step",
  "properties": {
    "status": "pending"
  },
  "actions": [
    {
      "template": "form",
      "kind": "poll",
      "model": {
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/duo1/device-poller",
        "method": "GET"
      }
    },
    {
      "template": "form",
      "kind": "cancel",
      "title": "Cancel",
      "model": {
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/duo1",
        "method": "GET",
        "type": "application/x-www-form-urlencoded",
        "actionTitle": "Cancel"
      }
    }
  ]
}
"""
    
    static let pollingStepDone = """
{
  "metadata": {
    "viewName": "authenticator/duo/authenticate/device-poller"
  },
  "type": "polling-step",
  "properties": {
    "status": "done"
  },
  "actions": [
    {
      "template": "form",
      "kind": "redirect",
      "model": {
        "href": "https://d3dd92f30197.ngrok.io/dev/authn/authenticate/duo1/device-poller",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
        "fields": [
          {
            "name": "moveOn",
            "type": "hidden",
            "value": "true"
          }
        ]
      }
    }
  ]
}
"""
    
    static let continueSameStep = """
{
  "messages": [
    {
      "text": "SMS sent",
      "classList": [
        "info"
      ]
    }
  ],
  "metadata": {
    "viewName": "authenticator/duo/authenticate/passcode-sent"
  },
  "type": "continue-same-step"
}
"""

    static let messagesWithTextAndImageLinks = """
{
  "messages": [
    {
      "text": "Pair device",
      "classList": [
        "info",
        "heading"
      ]
    },
    {
      "text": "To activate a new device, enter the code into your mobile authentication application or use that app to scan the following QR code. Also, enter an alias, phone number or asset number, and select the type of device, so that you can more easily identify it later when logging in.",
      "classList": [
        "info"
      ]
    },
    {
      "text": "459120",
      "classList": [
        "info",
        "activationCode"
      ]
    }
  ],
  "links": [
    {
      "href": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPoAAAD6AQAAAACgl2eQAAAA00lEQVR42u3YSw7DMAgEUG4OR+vNXAUzELWxVXXpwYson5cNMuM4MvbjJQ0aNGjQ4Adg4kOHqYnmFR/QONpUdY8NXE+iSoorXnCd6GjgZ8oM7sddZx0OIjqzTKukPRxgzADZrLyHA28UQbVEMV0YQfWMZ+lX4zAA75xcVvMFTuDzBJMF/UMGYrZYhik6hw8gSCEGIbDK0FmthyClAPjEEo215bNQLKA2YijUcqdGAJZBSgYsWsZ0/YPibFDs/pgOZJDWivK8IT0b9P/qBg0aNPgbvAGvJtukooRPzgAAAABJRU5ErkJggg==",
      "rel": "activation"
    }
  ],
  "metadata": {
    "viewName": "authenticator/encap/activate-device/index"
  },
  "type": "registration-step",
  "actions": [
    {
      "template": "form",
      "kind": "device-register",
      "title": "Activate",
      "model": {
        "href": "/dev/authn/register/create/encap1",
        "method": "POST",
        "type": "application/x-www-form-urlencoded",
        "actionTitle": "Pair device",
        "fields": [
          {
            "name": "activationCode",
            "type": "hidden",
            "value": "459120"
          },
          {
            "name": "alias",
            "type": "text",
            "label": "Device Alias"
          },
          {
            "name": "number",
            "type": "text",
            "label": "Phone Number / Asset ID"
          },
          {
            "name": "devicetype",
            "type": "select",
            "label": "Device Type",
            "options": [
              {
                "value": "phone",
                "label": "Phone"
              },
              {
                "value": "tablet",
                "label": "Tablet"
              },
              {
                "value": "other",
                "label": "Other"
              }
            ]
          }
        ]
      }
    }
  ]
}
"""
}
