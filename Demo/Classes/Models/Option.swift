/*
 * Copyright (C) 2021 Curity AB. All rights reserved.
 *
 * The contents of this file are the property of Curity AB.
 * You may not copy or use this file, in either source code
 * or executable form, except in compliance with terms
 * set by Curity AB.
 *
 * For further information, please contact Curity AB.
 */

import Foundation

class Option: Action {
    var form: FormModel? {
        model as? FormModel
    }

    required init(from decoder: Decoder) throws {
        try super.init(from: decoder)
    }
}
