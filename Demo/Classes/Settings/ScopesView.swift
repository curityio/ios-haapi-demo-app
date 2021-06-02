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

struct ScopesView: View {
    @ObservedObject var viewModel: ScopesViewModel

    init(viewModel: ScopesViewModel) {
        self.viewModel = viewModel
    }

    private var columnsLayout = [
        GridItem(.flexible(minimum: 0, maximum: .infinity)),
        GridItem(.flexible(minimum: 0, maximum: .infinity))
    ]

    var body: some View {
        LazyVGrid(columns: columnsLayout,
                  spacing: UIConstants.spacing)
        {
            ForEach(viewModel.items, id: \.self) { item in
                ColorButton(title: item,
                            buttonType: viewModel.buttonTypeForItem(item))
                { btn in
                    viewModel.toggleItem(item)
                    btn.reset()
                }
            }
        }
    }
}

struct ScopesView_Previews: PreviewProvider {
    static var previews: some View {
        ScopesView(viewModel: ScopesViewModel(["Auto", "Bike", "Something", "Weird", "Nope", "Cool"],
                                              selectedItems: []))
    }
}

// MARK: - ScopesViewModel

class ScopesViewModel: ObservableObject {
    let items: [String]
    @Published var selectedItems: [String]
    weak var delegate: ScopesViewModelDelegate?

    init(_ items: [String],
         selectedItems: [String],
         delegate: ScopesViewModelDelegate? = nil)
    {
        self.items = items
        self.selectedItems = selectedItems
        self.delegate = delegate
    }

    func toggleItem(_ item: String) {
        if let index = selectedItems.firstIndex(of: item) {
            selectedItems.remove(at: index)
        } else {
            selectedItems.append(item)
        }
        delegate?.updateSelectedItems(selectedItems)
    }

    func buttonTypeForItem(_ item: String) -> ButtonType {
        return selectedItems.contains(item) ? .primary : .secondary
    }
}

protocol ScopesViewModelDelegate: AnyObject {
    func updateSelectedItems(_ items: [String])
}
