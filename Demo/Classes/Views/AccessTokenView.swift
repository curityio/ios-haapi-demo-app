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

import SwiftUI

struct AccessTokenView: View {
    let viewModel: AccessTokenViewModel

    init(_ viewModel: AccessTokenViewModel) {
        self.viewModel = viewModel
    }

    @State private var firstCardExpended = false
    @State private var secondCardExpended = false
    @State private var thirdCardExpended = false

    var body: some View {
        VStack {
            Image("checkmark")
                .padding()
            // Access Token
            DisclosureView(title: "Access Token") {
                firstCardExpended = !firstCardExpended
            }
            if firstCardExpended {
                CardView(text: viewModel.accessToken,
                         details: viewModel.details)
            }

            // ID Token
            if viewModel.hasIDToken {
                DisclosureView(title: "ID Token") {
                    secondCardExpended = !secondCardExpended
                }
                if secondCardExpended {
                    CardView(text: viewModel.idToken)
                }
            }

            // Refresh Token
            DisclosureView(title: "Refresh Token") {
                thirdCardExpended = !thirdCardExpended
            }
            if thirdCardExpended  {
                CardView(text: viewModel.refreshToken)
            }
        }
        .padding([.leading, .trailing])
        .navigationBarTitle("Success")
    }
}

struct AccessTokenView_Previews: PreviewProvider {
    static var previews: some View {
        AccessTokenView(AccessTokenViewModel([
            "expires_in": "300",
            "refresh_token": "be9d3f8b-c18b-46b7-9asd-e0734d95c71d",
            "token_type": "bearer",
            "scope": "",
            "access_token": "6adf18ca-9d77-4947-945d-c939c8890977"
        ]))
    }
}

// MARK: - AccessTokenViewModel

struct AccessTokenViewModel {
    let accessTokenRepresentation: [String: String]

    init(_ accessTokenRepresentation: [String: String]) {
        self.accessTokenRepresentation = accessTokenRepresentation
    }

    var hasIDToken: Bool {
        return accessTokenRepresentation["id_token"] != nil
    }

    var accessToken: String {
        return accessTokenRepresentation["access_token"] ?? ""
    }

    var details: [CardDetails] {
        return [
            CardDetails(header: "expires_in",
                        value: accessTokenRepresentation["expires_in"] ?? ""),
            CardDetails(header: "token_type",
                        value: accessTokenRepresentation["token_type"] ?? ""),
            CardDetails(header: "scope",
                        value: accessTokenRepresentation["scope"] ?? "")
        ]
    }

    var refreshToken: String {
        return accessTokenRepresentation["refresh_token"] ?? ""
    }

    var idToken: String {
        return accessTokenRepresentation["id_token"] ?? ""
    }
}
