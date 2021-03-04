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

import Foundation

protocol HashIdentifiable: Identifiable {
}

extension HashIdentifiable where Self: RawRepresentable, Self: Hashable {
    var id: Int {
        hashValue
    }
}
