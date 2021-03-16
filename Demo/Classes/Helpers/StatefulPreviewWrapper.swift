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

//  Wrapper to allow hardcoded state in SwiftUI previews.
//  Usage:
//      static var previews: some View {
//          StatefulPreviewWrapper(true) { // true is value
//              ActivityIndicator(isAnimating: $0, style: .medium) // $0 is location value is needed
//          }
//      }
//

import SwiftUI

struct StatefulPreviewWrapper<Value, Content: View>: View {
    @State var value: Value
    var content: (Binding<Value>) -> Content

    var body: some View {
        content($value)
    }

    init(_ value: Value, content: @escaping (Binding<Value>) -> Content) {
        self._value = State(wrappedValue: value)
        self.content = content
    }
}

struct TwoStatefulPreviewWrapper<Value1, Value2, Content: View>: View {
    @State var value1: Value1
    @State var value2: Value2
    var content: (Binding<Value1>, Binding<Value2>) -> Content

    var body: some View {
        content($value1, $value2)
    }

    init(_ value1: Value1, _ value2: Value2, value content: @escaping (Binding<Value1>, Binding<Value2>) -> Content) {
        self._value1 = State(wrappedValue: value1)
        self._value2 = State(wrappedValue: value2)
        self.content = content
    }
}

struct ThreeStatefulPreviewWrapper<Value1, Value2, Value3, Content: View>: View {
    @State var value1: Value1
    @State var value2: Value2
    @State var value3: Value3
    var content: (Binding<Value1>, Binding<Value2>, Binding<Value3>) -> Content

    var body: some View {
        content($value1, $value2, $value3)
    }

    init(_ value1: Value1, _ value2: Value2, _ value3: Value3, value content: @escaping (Binding<Value1>, Binding<Value2>, Binding<Value3>) -> Content) {
        self._value1 = State(wrappedValue: value1)
        self._value2 = State(wrappedValue: value2)
        self._value3 = State(wrappedValue: value3)
        self.content = content
    }
}
