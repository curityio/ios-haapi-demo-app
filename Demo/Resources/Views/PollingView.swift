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

import os
import SwiftUI

private let logger = Logger()

struct PollingView: View {
    // The HaapiController and Scheduler cannot be EnvironmentObjects in this view, as they are used asynchronosly from init
    let haapiController: HaapiController
    let scheduler: Scheduler
    let pollingStep: PollingStep
    let automaticPolling = true

    init(
        haapiController: HaapiController,
        scheduler: Scheduler,
        pollingStep: PollingStep
    ) {
        self.haapiController = haapiController
        self.scheduler = scheduler
        self.pollingStep = pollingStep
        
        schedulePoll()
    }
    
    var body: some View {
        VStack {
            if !automaticPolling {
                if let pollingForm = pollingStep.pollingForm {
                    ColorButton(title: "Poll") { button in
                        self.doPoll(pollingForm, fromButton: button)
                    }
                } else if let doneForm = pollingStep.doneForm {
                    ColorButton(title: "Done") { button in
                        self.doPoll(doneForm, fromButton: button)
                    }
                }
            }
            
            if let cancelForm = pollingStep.cancelForm {
                ColorButton(
                    title: cancelForm.actionTitle ?? "Cancel",
                    color: .orange
                ) { button in
                    self.submitCancelForm(cancelForm, fromButton: button)
                }
            }
            
            if let auxiliaryActions = pollingStep.auxiliaryActions,
               !auxiliaryActions.isEmpty {
                ActionsView(
                    actions: auxiliaryActions, inNavigationLink: false
                ).environmentObject(haapiController)
            }
        }
        .navigationBarTitle("Polling")
        .onDisappear {
            self.scheduler.invalidate()
        }
    }
    
    private func schedulePoll() {
        guard self.automaticPolling,
              !self.haapiController.transitioning else {
            return
        }
        
        if let pollingForm = self.pollingStep.pollingForm {
            logger.debug("Scheduling poll")
            
            self.scheduler.schedule(withTimeInterval: 2) {
                logger.debug("Polling")
                self.doPoll(pollingForm, fromButton: nil)
            }
        } else if case PollingStatus.done = self.pollingStep.status {
            logger.debug("Polling done")
            // We should never get here if the HaapiController automatically follows redirects
        } else if case PollingStatus.failed = self.pollingStep.status {
            logger.debug("Polling failed")
            // We should never get here if the HaapiController automatically follows redirects
        }
    }
    
    private func doPoll(_ form: FormModel, fromButton button: ColorButton?) {
        self.haapiController.submitForm(
            form: form,
            onError: { error in
                button?.reset()
                logger.debug("Error polling: \(error.localizedDescription)")
            }, willCommitState: { state in
                if state != nil {
                    button?.reset()
                }
            }
        )
    }
    
    private func submitCancelForm(_ form: FormModel, fromButton button: ColorButton?) {
        logger.debug("Canceling poll")
        
        scheduler.invalidate()
        
        self.haapiController.submitForm(
            form: form,
            onError: { error in
                button?.reset()
                logger.debug("Error: \(error.localizedDescription)")
            },
            willCommitState: { state in
                if state != nil {
                    button?.reset()
                }
            }
        )
    }
}

struct PollingView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            NavigationView {
                PollingView(
                    haapiController: HaapiController(),
                    scheduler: Scheduler(),
                    pollingStep: PollingStep.from(try! Representation.fromJson(RepresentationSamples.pollingStep))!
                )
            }.navigationViewStyle(StackNavigationViewStyle())

            NavigationView {
                PollingView(
                    haapiController: HaapiController(),
                    scheduler: Scheduler(),
                    pollingStep: PollingStep.from(try! Representation.fromJson(RepresentationSamples.pollingStepDone))!
                )
            }.navigationViewStyle(StackNavigationViewStyle())
        }
        .environmentObject(HaapiController())
    }
}
