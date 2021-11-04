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
import os
import HaapiModelsSDK

struct LinkView: View {
    @ObservedObject var viewModel: LinkViewModel

    init(viewModel: LinkViewModel) {
        self.viewModel = viewModel
        self.viewModel.load()
    }

    var body: some View {
        Button(action: viewModel.select) {
            VStack {
                if let image = viewModel.image {
                    Image(uiImage: image)
                } else if viewModel.hasImage {
                    ArcSpinner(color: Color.primaryRegular)
                        .aspectRatio(contentMode: .fit)
                }
                if let title = viewModel.title {
                    Text(title)
                        .font(.link)
                        .foregroundColor(Color.links)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .disabled(viewModel.isDisabled)
    }
}

// swiftlint:disable line_length force_unwrapping
struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        let link3Json = """
    {
      "href": "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAPoAAAD6AQAAAACgl2eQAAABpklEQVR42u2ZS47EMAhEkXIAHylX95F8gEg0VOHE3fNZjGaRkhJl4dhvg4ACHPPfn24P8AAP8DegWzzNN/ejuY99G/uRW6YFeB71bVic5l4DiX0hIIyKHbO9/JOfgSkCYeYeDPa7LJD+go0Rb7siwJCDv/K7MsjFAKR/P9b3G324OXDpbqZ/BF77SavvDCDfYWklDtR4S0FTAuJ0Q6TFGiJg9kWK7w941sGwy+KdKdOpzEJAbFKHk5wuWzNLAkCuI8Yi0ui7KPQfIqYA+EBlzNMkI+TWgqIA5MN2MY2dvjuukNMAcj2qS4GxzkIpBfRpZieTUubogZWA6tshX2ly9lpvUqwBpGox5YdtZ12/yqIG4CglnAGrsjAOlYCaOJg+1ljr+9poSQCoIDXMssViHokBNYm71TyV67d2UQQoEcYmq8kqxSoALkYwj6PQs8uSAuayTUHDhL6EnARQI+15YXUWei3A57Uh5Ree6sfnJcndAV5Y4ZQuq8BTBOoUowcHQ0WAF1YcA9nJawHVMXolyzmGaAHrtVtqstFfuxTw/I16gAf4b+AFsrD1sGayV1UAAAAASUVORK5CYII=",
      "rel": "qrcode",
      "title": "Scan the code in BankID security app"
    }
"""
        let link3 = link3Json.decodedAsJson(as: HaapiModelsSDK.Link.self)!

        let link4Json = """
    {
      "href": "https://curity.io/images/curity-logo-landscape.png",
      "rel": "activation",
      "type": "image/png"
    }
"""
        let link4 = link4Json.decodedAsJson(as: HaapiModelsSDK.Link.self)!

        Group {
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

    let link: HaapiModelsSDK.Link
    let imageLoader: ImageLoader
    let selectHandler: (HaapiModelsSDK.Link) -> Void

    @Published var image: UIImage?
    private var subscriber: AnyCancellable?

    init(link: HaapiModelsSDK.Link,
         imageLoader: ImageLoader,
         selectHandler: @escaping (HaapiModelsSDK.Link) -> Void)
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
        let result: String?
        if let linkTitle = link.title {
            result = linkTitle.value()
        } else {
            if isDataType {
                result = nil
            } else {
                Logger.clientApp.debug("This link does not have a proper title. Fallback to rel")
                result = link.rel
            }
        }

        return result
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

    var isDisabled: Bool {
        return isDataType
    }

    private var isDataType: Bool {
        return link.hrefDataType() == .data
    }
}
