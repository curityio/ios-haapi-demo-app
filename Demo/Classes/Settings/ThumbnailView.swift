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

struct ThumbnailView: View {
    let items: [String]

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack (spacing: 10) {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .padding(8)
                        .background(Color.gray.opacity(0.4))
                        .cornerRadius(16.0)
                }
            }
            .padding([.top, .bottom], /*@START_MENU_TOKEN@*/10/*@END_MENU_TOKEN@*/)
        }
    }
}

struct ThumbnailView_Previews: PreviewProvider {
    static var previews: some View {
        ThumbnailView(items: ["Auto", "Bike", "Something", "Weird", "Nope", "Cool"])
    }
}
