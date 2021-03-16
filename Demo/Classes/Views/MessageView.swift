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

struct MessageView: View {
    let text: String
    
    var body: some View {
        VStack {
            HStack {
                Text(text)
                    .foregroundColor(.black)
                    .padding([.leading, .trailing], 13)
                    .padding([.top, .bottom], 11)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .center)
            .background(Color(.blue).opacity(0.25))
        }
        .background(Color(.white))
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(text: "Test message here")
    }
}
