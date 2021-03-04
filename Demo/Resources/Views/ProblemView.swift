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

struct ProblemView: View {
    @EnvironmentObject var haapiController: HaapiController
    let problem: Problem
    
    var body: some View {
        VStack {
            Text(problem.representation.title ?? "\(problem.representation.type)")
                .foregroundColor(.red)
                .padding([.leading, .trailing], 13)
                .padding([.top, .bottom], 11)
            
            if !problem.representation.messages.isEmpty {
                VStack {
                    ForEach(problem.representation.messages, id: \.text) { message in
                        MessageView(text: message.text)
                    }
                }
                .padding([.top, .bottom])
            }
        }.frame(minWidth: 0,
                maxWidth: .infinity,
                alignment: .top)
        .padding([.leading, .trailing])
        .background(Color(.red).opacity(0.25))
    }
}

struct ProblemView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ProblemView(
                problem: Problem.from(try! Representation.fromJson(RepresentationSamples.incorrectCredentialsProblem))!
            )
            
            ProblemView(
                problem: Problem.from(try! Representation.fromJson(RepresentationSamples.incorrectCredentialsProblemWithMessages))!
            )
        }
    }
}
