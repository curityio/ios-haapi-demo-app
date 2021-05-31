//
// Copyright (C) 2020 Curity AB.
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
import Combine

struct LinkView: View {
    @ObservedObject var viewModel: LinkViewModel

    init(viewModel: LinkViewModel) {
        self.viewModel = viewModel
        self.viewModel.load()
    }

    var body: some View {
        VStack {
            Button(action: viewModel.select) {
                VStack {
                    if let image = viewModel.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: UIScreen.main.bounds.width)
                    } else if viewModel.hasImage {
                        ArcSpinner(color: Color.primary)
                            .aspectRatio(contentMode: .fit)
                    }
                    if let title = viewModel.title {
                        Text(title)
                            .padding([.leading, .trailing], 16)
                            .padding([.bottom, .top], 4)
                    }
                }
            }
        }
    }
}

// swiftlint:disable force_try line_length force_unwrapping
struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        let link1 = Link(href: "", rel: "", title: "Title here", type: nil)

        let imageRepresentation = try! Representation(Data(.messagesWithTextAndImageLinks))
        let link2 = imageRepresentation.links.first!

        let link3Json = """
    {
      "href": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPoAAAD6AQAAAACgl2eQAAABpklEQVR42u2ZS47EMAhEkXIAHylX95F8gEg0VOHE3fNZjGaRkhJl4dhvg4ACHPPfn24P8AAP8DegWzzNN/ejuY99G/uRW6YFeB71bVic5l4DiX0hIIyKHbO9/JOfgSkCYeYeDPa7LJD+go0Rb7siwJCDv/K7MsjFAKR/P9b3G324OXDpbqZ/BF77SavvDCDfYWklDtR4S0FTAuJ0Q6TFGiJg9kWK7w941sGwy+KdKdOpzEJAbFKHk5wuWzNLAkCuI8Yi0ui7KPQfIqYA+EBlzNMkI+TWgqIA5MN2MY2dvjuukNMAcj2qS4GxzkIpBfRpZieTUubogZWA6tshX2ly9lpvUqwBpGox5YdtZ12/yqIG4CglnAGrsjAOlYCaOJg+1ljr+9poSQCoIDXMssViHokBNYm71TyV67d2UQQoEcYmq8kqxSoALkYwj6PQs8uSAuayTUHDhL6EnARQI+15YXUWei3A57Uh5Ree6sfnJcndAV5Y4ZQuq8BTBOoUowcHQ0WAF1YcA9nJawHVMXolyzmGaAHrtVtqstFfuxTw/I16gAf4b+AFsrD1sGayV1UAAAAASUVORK5CYII=",
      "rel": "qrcode",
      "title": "Scan the code in BankID security app"
    }
"""
        let link3 = link3Json.decodedAsJson(as: Link.self)!

        let link4Json = """
    {
      "href": "https://curity.io/images/curity-logo-landscape.png",
      "rel": "activation",
      "type": "image/png"
    }
"""
        let link4 = link4Json.decodedAsJson(as: Link.self)!

        Group {
            LinkView(viewModel: LinkViewModel(link: link1,
                                              imageLoader: ImageLoader(),
                                              selectHandler: { _ in }))
            LinkView(viewModel: LinkViewModel(link: link2,
                                              imageLoader: ImageLoader(),
                                              selectHandler: { _ in }))
            LinkView(viewModel: LinkViewModel(link: link3,
                                              imageLoader: ImageLoader(),
                                              selectHandler: { _ in }))
            LinkView(viewModel: LinkViewModel(link: link4,
                                              imageLoader: ImageLoader(),
                                              selectHandler: { _ in }))
        }
            .previewLayout(.sizeThatFits)
    }
}

// MARK: - LinkViewModel

class LinkViewModel: ObservableObject {

    let link: Link
    let imageLoader: ImageLoader
    let selectHandler: (Link) -> Void

    @Published var image: UIImage?
    private var subscriber: AnyCancellable?

    init(link: Link,
         imageLoader: ImageLoader,
         selectHandler: @escaping (Link) -> Void)
    {
        self.link = link
        self.imageLoader = imageLoader
        self.selectHandler = selectHandler
        image = link.dataImage()
    }

    deinit {
        subscriber?.cancel()
    }

    // MARK: Values + Actions

    var title: String? {
        return link.title
    }

    func load() {
        guard image == nil,
              let imageURL = link.imageUrl()
        else { return }

        subscriber = imageLoader.loadImageFromURL(imageURL)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] newImage in
                self?.image = newImage
            })
    }

    func select() {
        selectHandler(link)
    }

    var hasImage: Bool {
        return link.imageUrl() != nil && image == nil
    }
}
