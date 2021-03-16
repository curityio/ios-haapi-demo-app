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

import SwiftUI

struct AuthorizedView: View {
    @EnvironmentObject var haapiController: HaapiController
    let authorizationCode: String
    
    var body: some View {
        VStack {
            Text("Authorization Code:")
            Text(self.authorizationCode).bold().padding()
            ColorButton(title: "Return to start") { _ in
                haapiController.reset()
            }
        }
    }
}

struct AuthorizedView_Previews: PreviewProvider {
    static var previews: some View {
        AuthorizedView(authorizationCode: "foobar")
    }
}
