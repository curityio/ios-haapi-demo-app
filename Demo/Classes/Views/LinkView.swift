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

struct LinkView: View {
    @State private var link: Link
    @ObservedObject private var imageLoader: RemoteImageLoader
    private var clickCallback: ((Link) -> Void)
    @State private var remoteLoadedImage = UIImage()

    init(link: Link, clickCallback: @escaping (Link) -> Void) {
        self._link = State(initialValue: link)
        self.clickCallback = clickCallback
        imageLoader = RemoteImageLoader(url: link.imageUrl())
    }

    var body: some View {
        VStack {
            Button(action: linkTapped) {
                VStack {
                    if let image = self.image() {
                        image
                    }
                    if let title = link.title {
                        Text(title)
                            .padding([.leading, .trailing], 16)
                            .padding([.bottom, .top], 4)
                    }
                }
            }
        }
    }

    private func image() -> AnyView? {
        if let dataImage = link.dataImage() {
            return AnyView(Image(uiImage: dataImage))
        } else if case .url = self.link.hrefDataType(), let mimeType = self.link.mimeType, mimeType.contains("image") {
            return AnyView(
                Image(uiImage: remoteLoadedImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: UIScreen.main.bounds.width)
                    .onReceive(imageLoader.didChange) { data in
                        self.remoteLoadedImage = UIImage(data: data) ?? UIImage()
                    }
            )
        } else {
            return nil
        }
    }

    private func linkTapped() {
        clickCallback(self.link)
    }

}

struct LinkView_Previews: PreviewProvider {
    static var previews: some View {
        let link1 = Link(href: "", rel: "", title: "Title here")

        let imageRepresentation = try! Representation.fromJson(RepresentationSamples.messagesWithTextAndImageLinks)
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
            LinkView(link: link1, clickCallback: {_ in})
            LinkView(link: link2, clickCallback: {_ in})
            LinkView(link: link3, clickCallback: {_ in})
            LinkView(link: link4, clickCallback: {_ in})
        }
            .previewLayout(.sizeThatFits)
    }
}
