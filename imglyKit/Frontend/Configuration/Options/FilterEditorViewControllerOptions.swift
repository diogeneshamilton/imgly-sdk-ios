//
//  FilterEditorViewControllerOptions.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 21/01/16.
//  Copyright © 2016 9elements GmbH. All rights reserved.
//

import UIKit

/// This closure is called every time the user selects a filter.
public typealias FilterSelectedClosure = (String) -> ()

/**
 Options for configuring a `FilterEditorViewController`.
 */
@objc(IMGLYFilterEditorViewControllerOptions) public class FilterEditorViewControllerOptions: EditorViewControllerOptions {

    /// Use this closure to configure the filter intensity slider.
    /// Defaults to an empty implementation.
    public let filterIntensitySliderConfigurationClosure: SliderConfigurationClosure?

    /// An object conforming to the `FiltersDataSourceProtocol`
    /// Per default an `FilterSelectionControllerDataSource` offering all filters
    /// is set.
    public let filterDataSource: FiltersDataSourceProtocol

    /// Enable/Disable the filter intensity slider. Defaults to true.
    public let showFilterIntensitySlider: Bool

    /// This closure is called every time the user selects a filter.
    public let filterSelectedClosure: FilterSelectedClosure?

    /**
     Returns a newly allocated instance of a `FilterEditorViewControllerOptions` using the default builder.

     - returns: An instance of a `FilterEditorViewControllerOptions`.
     */
    public convenience init() {
        self.init(builder: FilterEditorViewControllerOptionsBuilder())
    }

    /**
     Returns a newly allocated instance of a `FilterEditorViewControllerOptions` using the given builder.

     - parameter builder: A `FilterEditorViewControllerOptionsBuilder` instance.

     - returns: An instance of a `FilterEditorViewControllerOptions`.
     */
    public init(builder: FilterEditorViewControllerOptionsBuilder) {
        filterIntensitySliderConfigurationClosure = builder.filterIntensitySliderConfigurationClosure
        filterDataSource = builder.filterDataSource
        showFilterIntensitySlider = builder.showFilterIntensitySlider
        filterSelectedClosure = builder.filterSelectedClosure
        super.init(editorBuilder: builder)
    }
}

// swiftlint:disable type_name
/**
    The default `FilterEditorViewControllerOptionsBuilder` for `FilterEditorViewControllerOptions`.
*/
@objc(IMGLYFilterEditorViewControllerOptionsBuilder) public class FilterEditorViewControllerOptionsBuilder: EditorViewControllerOptionsBuilder {
    // swiftlint:enable type_name

    /// Use this closure to configure the filter intensity slider.
    /// Defaults to an empty implementation.
    public var filterIntensitySliderConfigurationClosure: SliderConfigurationClosure? = nil

    /// This closure is called every time the user selects a filter.
    public var filterSelectedClosure: FilterSelectedClosure? = nil

    /// An object conforming to the `FiltersDataSourceProtocol`
    /// Per default an `FilterSelectionControllerDataSource` offering all filters
    /// is set.
    public var filterDataSource: FiltersDataSourceProtocol = FiltersDataSource()

    /// Enable/Disable the filter intensity slider. Defaults to true.
    public var showFilterIntensitySlider = true

    /**
     :nodoc:
     */
    public override init() {
        super.init()

        /// Override inherited properties with default values
        self.title = Localize("Filter")
    }
}
