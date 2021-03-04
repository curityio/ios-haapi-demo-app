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

enum ModalType: String, HashIdentifiable {
    case settings, json
}

struct StateView: View {
    @EnvironmentObject var haapiController: HaapiController
    @EnvironmentObject var scheduler: Scheduler
    private let haapiState: HaapiState
    
    private var representation: Representation {
        return haapiState.representation
    }
    
    private var actions: [Action] {
        return haapiState.currentActions
    }
    
    private var secondaryProblem: Problem? {
        return haapiState.problem
    }
    

    @State var displayingModal: ModalType? = nil
    @State var showHiddenFields = false
    @State var showParameters = false

    init(
        haapiState: HaapiState
    ) {
        self.haapiState = haapiState
    }

    @ViewBuilder
    var body: some View {
        NavigationView {
            VStack {
                if let problem = secondaryProblem {
                    ProblemView(problem: problem)
                }
                
                ForEach(representation.messages, id: \.text) { message in
                    MessageView(text: message.text)
                        .padding([.leading, .trailing])
                }
                
                if let problem = Problem.from(representation) {
                    ProblemView(problem: problem)
                    ColorButton(title: "Restart") { _ in
                        haapiController.reset()
                    }
                } else if let pollingStep = PollingStep.from(representation) {
                    PollingView(
                        haapiController: haapiController,
                        scheduler: scheduler,
                        pollingStep: pollingStep
                    )
                } else if case .oauthAuthorizationResponse = representation.type {
                    AuthorizedView(authorizationCode: representation.properties["code"] ?? "N/A")
                } else {
                    ActionsView(
                        actions: actions,
                        inNavigationLink: false
                    )
                }
                
                ForEach(representation.links, id: \.title) { link in
                    LinkView(link: link) {link in
                        self.tapLink(link)
                    }
                        .frame(minWidth: 0, maxWidth: .infinity,
                               alignment: .center)
                }
                Spacer()
                    .frame(height: 54)
            }
            .padding(.top, 16)
            .navigationBarTitle("\(String(describing: representation.type))") // Fallback title for when a child doesn't set it
            .sheet(item: $displayingModal, content: { type in
                switch type {
                case .settings:
                    RepresentationSettingsView(
                        showHiddenFields: $showHiddenFields,
                        showParameters: $showParameters
                    )
                case .json:
                    SourceJsonView(representation: representation)
                }
            })
        }
        .toolbar {
            ToolbarItemGroup(placement: .bottomBar) {
                Button(action: {
                    haapiController.reset()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
                Button(action: {
                    displayingModal = .json
                }) {
                    Text("Source")
                }
                Spacer()
                Button(action: {
                    displayingModal = .settings
                }) {
                    Image(systemName: "gear")
                }
                
            }
            
        }
        
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private func tapLink(_ link: Link) {
        self.haapiController.followLink(
            link: link,
            onError: { error in
            },
            willCommitState: { state in
            }
        )
    }
}

struct StateView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.redirect))
            )
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.usernamePassword))
            )
        
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.bankidSelectSameOrOtherDevice))
            )
        
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.selectAuthentication))
            )
        
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.selectAuthenticationWithLinks))
            )
            
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.oauthAuthorizationResponse))
            )
            
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.duo))
            )
            
            StateView(
                haapiState: HaapiState(representation: try! Representation.fromJson(RepresentationSamples.messagesWithTextAndImageLinks))
            )
        }
    }
}
