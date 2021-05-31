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

struct HeaderView: View {

    let title: String
    let imageName: String

    init(_ title: String,
         imageName: String = "Logo")
    {
        self.title = title
        self.imageName = imageName
    }

    var body: some View {
        VStack (spacing: 18.4) {
            Image(imageName)
            Text(title)
                .font(.curityTitle2)
        }
    }
}

struct HeaderView_Previews: PreviewProvider {
    static var previews: some View {
        HeaderView("A title is a long text that tells a story")
            .background(Color.red)
            .paddingContentView()
    }
}
