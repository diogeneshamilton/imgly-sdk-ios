//
//  BleachedBlueFilter.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 24/02/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

/**
 :nodoc:
 */
@objc(IMGLYBleachedBlueFilter) public class BleachedBlueFilter: ResponseFilter {
    /**
     :nodoc:
     */
    required public init() {
        super.init(responseName: "BleachedBlue")
    }

    /**
     Returns an object initialized from data in a given unarchiver.

     - parameter aDecoder: An unarchiver object.

     - returns: `self`, initialized using the data in decoder.
     */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

extension BleachedBlueFilter: EffectFilter {
    /// The name that is used within the UI.
    public var displayName: String {
        return "B-Blue"
    }

    /// The filter type.
    public var filterType: FilterType {
        return .BleachedBlue
    }
}
