//
// Created by Carsten Przyluczky on 01/03/15.
// Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import UIKit

public struct Line {
    public let start: CGPoint
    public let end: CGPoint
}

/**
   This class represents the box gradient view. It is used within the focus editor view controller
   to visualize the choosen focus parameters. Basicaly a box shaped area is left unblured.
   Two controlpoints define the upper and lower midpoint of that box. Therefore they determin the rotation,
   position and size of the box.
 */
@objc(IMGLYBoxGradientView) public class BoxGradientView: UIView {

    /// The receiver’s delegate.
    /// seealso: `GradientViewDelegate`.
    public weak var gradientViewDelegate: GradientViewDelegate?

    /// :nodoc:
    public var centerPoint = CGPoint.zero

    ///  The first control point.
    public var controlPoint1 = CGPoint.zero

    /// The second control point.
    public var controlPoint2 = CGPoint.zero {
        didSet {
            calculateCenterPointFromOtherControlPoints()
            setNeedsDisplay()
            gradientViewDelegate?.gradientViewControlPointChanged(self)
        }
    }

    private var setup = false

    // MARK: - setup

    /**
      Initializes and returns a newly allocated view with the specified frame rectangle.

    - parameter frame: The frame rectangle for the view, measured in points.

    - returns: An initialized view object or `nil` if the object couldn't be created.
    */
    public override init(frame: CGRect) {
        super.init(frame:frame)
        commonInit()
    }

    /**
     Returns an object initialized from data in a given unarchiver.

     - parameter aDecoder: An unarchiver object.

     - returns: `self`, initialized using the data in decoder.
     */
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }

    private func commonInit() {
        if setup {
            return
        }
        setup = true

        backgroundColor = UIColor.clearColor()
        configureControlPoints()
        configurePanGestureRecognizer()
        configurePinchGestureRecognizer()
        configureRotationGestureRecognizer()

        isAccessibilityElement = true
        accessibilityTraits |= UIAccessibilityTraitAdjustable
        accessibilityLabel = Localize("Linear focus area")
        accessibilityHint = Localize("Double-tap and hold to move focus area")

        let rotateLeftAction = UIAccessibilityCustomAction(name: Localize("Rotate left"), target: self, selector: "rotateLeft")
        let rotateRightAction = UIAccessibilityCustomAction(name: Localize("Rotate right"), target: self, selector: "rotateRight")
        accessibilityCustomActions = [rotateLeftAction, rotateRightAction]
    }

    private func configureControlPoints() {
        controlPoint1 = CGPoint(x: 100, y: 100)
        controlPoint2 = CGPoint(x: 150, y: 200)
        calculateCenterPointFromOtherControlPoints()
    }

    private func configurePanGestureRecognizer() {
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: "handlePanGesture:")
        addGestureRecognizer(panGestureRecognizer)
    }

    private func configurePinchGestureRecognizer() {
        let pinchGestureRecognizer = UIPinchGestureRecognizer(target: self, action: "handlePinchGesture:")
        pinchGestureRecognizer.delegate = self
        addGestureRecognizer(pinchGestureRecognizer)
    }

    private func configureRotationGestureRecognizer() {
        let rotationGestureRecognizer = UIRotationGestureRecognizer(target: self, action: "handleRotationGesture:")
        rotationGestureRecognizer.delegate = self
        addGestureRecognizer(rotationGestureRecognizer)
    }

    // MARK: - drawing

    private func diagonalLengthOfFrame() -> CGFloat {
        return sqrt(frame.size.width * frame.size.width +
            frame.size.height * frame.size.height)
    }

    private func normalizedOrtogonalVector() -> CGVector {
        let vector = CGVector(startPoint: controlPoint1, endPoint: controlPoint2)
        return CGVector(dx: -vector.dy / vector.length, dy: vector.dx / vector.length)
    }

    private func distanceBetweenControlPoints() -> CGFloat {
        return CGVector(startPoint: controlPoint1, endPoint: controlPoint2).length
    }

    /*
    This method appears a bit tricky, but its not.
    We just take the vector that connects the control points,
    and rotate it by 90 degrees. Then we normalize it and give it a total
    lenghts that is the lenght of the diagonal, of the Frame.
    That diagonal is the longest line that can be drawn in the Frame, therefore its a good orientation.
    */

    private func lineForControlPoint(controlPoint: CGPoint) -> Line {
        let ortogonalVector = normalizedOrtogonalVector()
        let halfDiagonalLengthOfFrame = diagonalLengthOfFrame()
        let scaledOrthogonalVector = halfDiagonalLengthOfFrame * ortogonalVector
        let lineStart = controlPoint - scaledOrthogonalVector
        let lineEnd = controlPoint + scaledOrthogonalVector
        return Line(start: lineStart, end: lineEnd)
    }

    private func addLineForControlPoint1ToPath(path: UIBezierPath) {
        let line = lineForControlPoint(controlPoint1)
        path.moveToPoint(line.start)
        path.addLineToPoint(line.end)
    }

    private func addLineForControlPoint2ToPath(path: UIBezierPath) {
        let line = lineForControlPoint(controlPoint2)
        path.moveToPoint(line.start)
        path.addLineToPoint(line.end)
    }

    /**
     Draws the receiver’s image within the passed-in rectangle.

     - parameter rect: The portion of the view’s bounds that needs to be updated.
     */
    public override func drawRect(rect: CGRect) {
        let aPath = UIBezierPath()
        UIColor.whiteColor().setStroke()
        addLineForControlPoint1ToPath(aPath)
        addLineForControlPoint2ToPath(aPath)
        aPath.closePath()

        aPath.lineWidth = 2
        aPath.stroke()
    }

    // MARK: - gesture handling
    private func calculateCenterPointFromOtherControlPoints() {
        centerPoint = (controlPoint1 + controlPoint2) * 0.5
    }

    private func informDelegateAboutRecognizerStates(recognizer recognizer: UIGestureRecognizer) {
        if recognizer.state == .Began {
            gradientViewDelegate?.gradientViewUserInteractionStarted(self)
        }

        if recognizer.state == .Ended || recognizer.state == .Cancelled {
                gradientViewDelegate?.gradientViewUserInteractionEnded(self)
        }
    }

    @objc private func handlePanGesture(recognizer: UIPanGestureRecognizer) {
        informDelegateAboutRecognizerStates(recognizer: recognizer)

        let translation = recognizer.translationInView(self)

        controlPoint1 = controlPoint1 + translation
        controlPoint2 = controlPoint2 + translation

        recognizer.setTranslation(CGPoint.zero, inView: self)
    }

    @objc private func handlePinchGesture(recognizer: UIPinchGestureRecognizer) {
        informDelegateAboutRecognizerStates(recognizer: recognizer)

        let vector1 = CGVector(startPoint: centerPoint, endPoint: controlPoint1).normalizedVector()
        let vector2 = CGVector(startPoint: centerPoint, endPoint: controlPoint2).normalizedVector()

        let length = CGVector(startPoint: controlPoint1, endPoint: controlPoint2).length * recognizer.scale / 2

        controlPoint1 = centerPoint + vector1 * length
        controlPoint2 = centerPoint + vector2 * length

        recognizer.scale = 1
    }

    @objc private func handleRotationGesture(recognizer: UIRotationGestureRecognizer) {
        informDelegateAboutRecognizerStates(recognizer: recognizer)

        rotateByRadians(recognizer.rotation)

        recognizer.rotation = 0
    }

    /**
     Lays out subviews.
     */
    public override func layoutSubviews() {
        super.layoutSubviews()

        let line1 = lineForControlPoint(controlPoint1)
        let line2 = lineForControlPoint(controlPoint2)

        if let frame = CGRect(points: [line1.start, line1.end, line2.start, line2.end]) {
            accessibilityFrame = convertRect(frame, toView: nil)
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, nil)
        }
    }

    /**
     Centers the ui-elements within the views frame.
     */
    public func centerGUIElements() {
        let x1 = frame.size.width * 0.5
        let x2 = frame.size.width * 0.5
        let y1 = frame.size.height * 0.25
        let y2 = frame.size.height * 0.75
        controlPoint1 = CGPoint(x: x1, y: y1)
        controlPoint2 = CGPoint(x: x2, y: y2)
    }

    // MARK: - Accessibility

    public override func accessibilityIncrement() {
        let vector1 = CGVector(startPoint: centerPoint, endPoint: controlPoint1).normalizedVector()
        let vector2 = CGVector(startPoint: centerPoint, endPoint: controlPoint2).normalizedVector()

        // Widen gap by 20 points
        controlPoint1 = controlPoint1 + 10 * vector1
        controlPoint2 = controlPoint2 + 10 * vector2
    }

    public override func accessibilityDecrement() {
        let vector1 = CGVector(startPoint: centerPoint, endPoint: controlPoint1).normalizedVector()
        let vector2 = CGVector(startPoint: centerPoint, endPoint: controlPoint2).normalizedVector()

        // Reduce gap by 20 points
        controlPoint1 = controlPoint1 - 10 * vector1
        controlPoint2 = controlPoint2 - 10 * vector2
    }

    private func rotateByRadians(radians: CGFloat) {
        // Calculate angle of new point
        let angle1 = angleOfPoint(controlPoint1, onCircleAroundCenter: centerPoint) + radians
        let angle2 = angleOfPoint(controlPoint2, onCircleAroundCenter: centerPoint) + radians

        // Calculate vector
        let vector1 = CGVector(startPoint: centerPoint, endPoint: controlPoint1)
        let vector2 = CGVector(startPoint: centerPoint, endPoint: controlPoint2)

        // Calculate radius
        let radius1 = sqrt(vector1.dx * vector1.dx + vector1.dy * vector1.dy)
        let radius2 = sqrt(vector2.dx * vector2.dx + vector2.dy * vector2.dy)

        // Calculate points
        controlPoint1 = CGPoint(x: radius1 * cos(angle1) + centerPoint.x, y: radius1 * sin(angle1) + centerPoint.y)
        controlPoint2 = CGPoint(x: radius2 * cos(angle2) + centerPoint.x, y: radius2 * sin(angle2) + centerPoint.y)
    }

    @objc private func rotateLeft() -> Bool {
        // Move control points by -10 degrees around centerPoint
        rotateByRadians(CGFloat(-10 * M_PI / 180))
        return true
    }

    @objc private func rotateRight() -> Bool {
        // Move control points by +10 degrees around centerPoint
        rotateByRadians(CGFloat(10 * M_PI / 180))
        return true
    }

    private func angleOfPoint(point: CGPoint, onCircleAroundCenter center: CGPoint) -> CGFloat {
        return atan2(point.y - center.y, point.x - center.x)
    }
}

extension BoxGradientView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer || gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer {
            return true
        }

        return false
    }
}
