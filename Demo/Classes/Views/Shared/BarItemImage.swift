//
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

struct BarItemImage: View {
    let systemName: String
    let isLeading: Bool

    var body: some View {
        Image(systemName: systemName)
            .imageScale(.large)
            .modifier(PaddingModifier(isLeading: isLeading))
    }
}

private struct PaddingModifier: ViewModifier {
    let isLeading: Bool

    func body(content: Content) -> some View {
        if isLeading {
            return content.padding([.top, .trailing, .bottom], 10)
        } else {
            return content.padding(.all, 10)
        }
    }
}

struct BarItemImage_Previews: PreviewProvider {
    static var previews: some View {
        BarItemImage(systemName: "plus",
                     isLeading: true)
    }
}
