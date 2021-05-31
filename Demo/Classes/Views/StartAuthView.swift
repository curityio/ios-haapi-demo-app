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

import SwiftUI

struct StartAuthView: View {
    var startAction: (ColorButton) -> Void

    var body: some View {
        VStack (alignment: .leading) {
            Group {
                Text("info_app_title")
                    .font(.curityTitle)
                    .padding([.top], 41)
                    .padding([.bottom], 13)
                Text("info_app_body")
                    .font(.text)
            }
            .padding([.leading], 17)
            Spacer()
            Image("StartIllustration")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding([.leading, .trailing])
            Spacer()
            ColorButton(title: "info_app_start_authentication") { button in
                startAction(button)
            }
            .padding([.bottom], UIConstants.spacing)
        }
        .paddingContentView()
    }
}

struct StartAuthView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            StartAuthView(startAction: { _ in })
            StartAuthView(startAction: { _ in })
                .previewDevice("iPhone 11 Pro")
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MainView(viewModel: FlowViewModel(controller: HaapiController()))
                .previewDevice("iPod touch (7th generation)")
                .preferredColorScheme(.dark)
                .environmentObject(ImageLoader())
                .environmentObject(ProfileManager())
            MainView(viewModel: FlowViewModel(controller: HaapiController()))
                .previewDevice("iPhone 12")
                .preferredColorScheme(.dark)
                .environmentObject(ImageLoader())
                .environmentObject(ProfileManager())
        }
    }
}
