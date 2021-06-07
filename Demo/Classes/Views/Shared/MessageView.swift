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

struct MessageView: View {
    @Environment(\.colorScheme) var colorScheme

    let text: String
    let messageType: MessageType

    init(text: String,
         messageType: MessageType)
    {
        self.text = text
        self.messageType = messageType
    }

    var body: some View {
        HStack (alignment: text.hasMultiline(bySubtracting: UIConstants.spacing * 2 + 28.0) ? .top : .center) {
            if let imageName = messageType.imageName {
                Image(imageName)
                    .foregroundColor(colorScheme == .dark ? .white : messageType.foregroundColor)
            }
            Text(text)
                .font(messageType.font)
                .foregroundColor(colorScheme == .dark ? .white : messageType.foregroundColor)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(messageType.textAlignment)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], 22)
        .padding([.top, .bottom])
        .background(messageType.backgroundColor(colorScheme))
        .cornerRadius(UIConstants.cornerRadius)
    }
}

struct MessageView_Previews: PreviewProvider {
    static var previews: some View {
        MessageView(text: "Test message", messageType: .error)
        MessageView(text: "Warning: Lorem ipsum dolor sit amet, consectetur.",
                    messageType: .warning)
        MessageView(text: "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi molestie nisl.",
                    messageType: .info)
        MessageView(text: "Help: Lorem ipsum dolor sit amet, consectetur.",
                    messageType: .help)
        MessageView(text: "Heading: Lorem ipsum dolor sit amet, consectetur.",
                    messageType: .heading)
    }
}

private extension String {

    func hasMultiline(bySubtracting widthPadding: CGFloat,
                      for font: UIFont = .curitySubheadline) -> Bool
    {
        let label = UILabel()
        label.font = font
        label.numberOfLines = 0
        label.text = "A"
        label.sizeToFit()
        let oneLineHeight = label.bounds.height
        label.text = self

        let constraintSize = CGSize(width: UIScreen.main.bounds.width - widthPadding,
                                    height: .greatestFiniteMagnitude)
        let labelHeight = label.textRect(forBounds: CGRect(origin: .zero,
                                                           size: constraintSize),
                                         limitedToNumberOfLines: 0).height
        
        return oneLineHeight < labelHeight
    }
}
