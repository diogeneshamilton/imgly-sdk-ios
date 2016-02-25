//
//  FocusEditorViewController.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/04/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

/**
 Represents the different types of focus actions.

 - Off:    No focus blur is added. Used to reset other focus settings.
 - Linear: A blur along a straight line.
 - Radial: A blur that spreads radial from a central point.
 */
@objc public enum FocusAction: Int {
    case Off
    case Linear
    case Radial
}

@objc(IMGLYFocusEditorViewController) public class FocusEditorViewController: SubEditorViewController {

    // MARK: - Properties

    public private(set) lazy var offButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: FocusEditorViewController.self)
        let button = ImageCaptionButton()
        button.textLabel.text = Localize("Off")
        button.accessibilityLabel = Localize("Off")
        button.imageView.image = UIImage(named: "icon_focus_off", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "turnOff:", forControlEvents: .TouchUpInside)
        self.options.actionButtonConfigurationClosure?(button, .Off)
        return button
        }()

    public private(set) lazy var linearButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: FocusEditorViewController.self)
        let button = ImageCaptionButton()
        button.textLabel.text = Localize("Linear")
        button.accessibilityLabel = Localize("Linear")
        button.imageView.image = UIImage(named: "icon_focus_linear", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "activateLinear:", forControlEvents: .TouchUpInside)
        self.options.actionButtonConfigurationClosure?(button, .Linear)
        return button
        }()

    public private(set) lazy var radialButton: ImageCaptionButton = {
        let bundle = NSBundle(forClass: FocusEditorViewController.self)
        let button = ImageCaptionButton()
        button.textLabel.text = Localize("Radial")
        button.accessibilityLabel = Localize("Radial")
        button.imageView.image = UIImage(named: "icon_focus_radial", inBundle: bundle, compatibleWithTraitCollection: nil)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: "activateRadial:", forControlEvents: .TouchUpInside)
        self.options.actionButtonConfigurationClosure?(button, .Radial)
        return button
        }()

    private var selectedButton: ImageCaptionButton? {
        willSet(newSelectedButton) {
            self.selectedButton?.selected = false
        }

        didSet {
            self.selectedButton?.selected = true
        }
    }

    private lazy var circleGradientView: CircleGradientView = {
        let view = CircleGradientView()
        view.gradientViewDelegate = self
        view.hidden = true
        view.alpha = 0
        return view
        }()

    private lazy var boxGradientView: BoxGradientView = {
        let view = BoxGradientView()
        view.gradientViewDelegate = self
        view.hidden = true
        view.alpha = 0
        return view
        }()

    // MARK: - EditorViewController

    public override var options: FocusEditorViewControllerOptions {
        return self.configuration.focusEditorViewControllerOptions
    }

    override var enableZoomingInPreviewImage: Bool {
        return false
    }

    public override func zoomingImageViewDidZoom(zoomingImageView: ZoomingImageView) {
        super.zoomingImageViewDidZoom(zoomingImageView)

        circleGradientView.frame = view.convertRect(previewImageView.visibleImageFrame, fromView: previewImageView)
        circleGradientView.centerGUIElements()

        boxGradientView.frame = view.convertRect(previewImageView.visibleImageFrame, fromView: previewImageView)
        boxGradientView.centerGUIElements()
    }

    // MARK: - UIViewController

    override public func viewDidLoad() {
        super.viewDidLoad()

        configureButtons()
        configureGradientViews()

        selectedButton = offButton
        if fixedFilterStack.tiltShiftFilter.tiltShiftType != .Off {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .Off
            updatePreviewImage()
        }
    }

    // MARK: - Configuration

    private func configureButtons() {
        // Map actions and buttons
        let actionToButtonMap: [FocusAction: ImageCaptionButton] = [
            .Off: offButton,
            .Linear: linearButton,
            .Radial: radialButton
        ]

        // Setup button container view
        let buttonContainerView = UIView()
        buttonContainerView.backgroundColor = currentBackgroundColor
        buttonContainerView.translatesAutoresizingMaskIntoConstraints = false
        bottomContainerView.addSubview(buttonContainerView)
        bottomContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[buttonContainerView]|", options: [], metrics: nil, views: ["buttonContainerView": buttonContainerView]))
        bottomContainerView.addConstraint(NSLayoutConstraint(item: buttonContainerView, attribute: .CenterX, relatedBy: .Equal, toItem: bottomContainerView, attribute: .CenterX, multiplier: 1, constant: 0))

        var views = [String: UIView]()
        var viewNames = [String]()
        for action in options.allowedFocusActions {
            let button = actionToButtonMap[action]!
            let viewName = "_\(String(abs(button.hash)))" // View names must start with a letter or underscore
            viewNames.append(viewName)
            buttonContainerView.addSubview(button)
            views[viewName] = button
            buttonContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[\(viewName)]|", options: [], metrics: nil, views: views))
        }

        // Button Constraints
        let visualFormatString = viewNames.reduce("") { (acc, name) -> String in
            return acc + "[\(name)(==buttonWidth)]"
        }
        buttonContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|\(visualFormatString)|", options: [], metrics: [ "buttonWidth": 90 ], views: views))
    }

    private func configureGradientViews() {
        view.addSubview(circleGradientView)
        view.addSubview(boxGradientView)
    }

    // MARK: - Actions

    @objc private func turnOff(sender: ImageCaptionButton) {
        if selectedButton == sender {
            return
        }

        selectedButton = sender
        hideBoxGradientView()
        hideCircleGradientView()
        updateFilterTypeAndPreview()
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
    }

    @objc private func activateLinear(sender: ImageCaptionButton) {
        if selectedButton == sender {
            return
        }

        selectedButton = sender
        hideCircleGradientView()
        showBoxGradientView()
        updateFilterTypeAndPreview()
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
    }

    @objc private func activateRadial(sender: ImageCaptionButton) {
        if selectedButton == sender {
            return
        }

        selectedButton = sender
        hideBoxGradientView()
        showCircleGradientView()
        updateFilterTypeAndPreview()
        UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
    }

    // MARK: - Helpers

    private func updateFilterTypeAndPreview() {
        if selectedButton == linearButton {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .Box
            fixedFilterStack.tiltShiftFilter.controlPoint1 = boxGradientView.normalizedControlPoint1
            fixedFilterStack.tiltShiftFilter.controlPoint2 = boxGradientView.normalizedControlPoint2
        } else if selectedButton == radialButton {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .Circle
            fixedFilterStack.tiltShiftFilter.controlPoint1 = circleGradientView.normalizedControlPoint1
            fixedFilterStack.tiltShiftFilter.controlPoint2 = circleGradientView.normalizedControlPoint2
        } else if selectedButton == offButton {
            fixedFilterStack.tiltShiftFilter.tiltShiftType = .Off
        }

        updatePreviewImage()
    }

    private func showCircleGradientView() {
        circleGradientView.hidden = false
        UIView.animateWithDuration(NSTimeInterval(0.15), animations: {
            self.circleGradientView.alpha = 1.0
        })
    }

    private func hideCircleGradientView() {
        UIView.animateWithDuration(NSTimeInterval(0.15), animations: {
            self.circleGradientView.alpha = 0.0
            },
            completion: { finished in
                if finished {
                    self.circleGradientView.hidden = true
                }
            })
    }

    private func showBoxGradientView() {
        boxGradientView.hidden = false
        UIView.animateWithDuration(NSTimeInterval(0.15), animations: {
            self.boxGradientView.alpha = 1.0
        })
    }

    private func hideBoxGradientView() {
        UIView.animateWithDuration(NSTimeInterval(0.15), animations: {
            self.boxGradientView.alpha = 0.0
            },
            completion: { finished in
                if finished {
                    self.boxGradientView.hidden = true
                }
            })
    }

}

extension FocusEditorViewController: GradientViewDelegate {
    public func gradientViewUserInteractionStarted(gradientView: UIView) {
        fixedFilterStack.tiltShiftFilter.tiltShiftType = .Off
        updatePreviewImage()
    }

    public func gradientViewUserInteractionEnded(gradientView: UIView) {
        updateFilterTypeAndPreview()
    }

    public func gradientViewControlPointChanged(gradientView: UIView) {

    }
}
