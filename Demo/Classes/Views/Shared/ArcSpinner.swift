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

struct ArcSpinner: View {
    @State private var isAnimating = false

    let color: Color
    let size: CGSize

    init(color: Color,
         size: CGSize = CGSize(width: 26.0, height: 26.0))
    {
        self.color = color
        self.size = size
    }

    var body: some View {
        Circle()
            .trim(from: 0, to: 0.8)
            .stroke(color, lineWidth: 1.8)
            .frame(width: size.width,
                   height: size.height,
                   alignment: .center)
            .rotationEffect(Angle(degrees: isAnimating ? 360 : 0))
            // Animation needs to be called explicitly because of NavigationView
            .animation(Animation.linear
                        .speed(0.8)
                        .repeatForever(autoreverses: false),
                       value: isAnimating)
            .onAppear {
                isAnimating = true
            }
    }
}

struct ArcSpinner_Previews: PreviewProvider {
    static var previews: some View {
        ArcSpinner(color: .red)
            .frame(height: 50.0)
    }
}
