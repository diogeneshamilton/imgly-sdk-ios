//
//  BorderEditorViewController.swift
//  imglyKit
//
//  Created by Carsten Przyluczky on 11/02/16.
//  Copyright © 2016 9elements GmbH. All rights reserved.
//

import UIKit

let kBorderCollectionViewCellSize = CGSize(width: 90, height: 90)
let kBorderCollectionViewCellReuseIdentifier = "BorderCollectionViewCell"

@objc(IMGLYBorderEditorViewController) public class BorderEditorViewController: SubEditorViewController {

    // MARK: - Properties

    public var bordersDataSource = BordersDataSource()
    public private(set) lazy var bordersClipView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()

    private var draggedView: UIImageView?
    private var overlayConverter: OverlayConverter?
    private var borderCount = 0
    private var collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: UICollectionViewFlowLayout())
    private var imageRatio: Float = 6.0 / 4.0
    private var choosenBorder: Border?
    private var borderView = StickerImageView(image: nil)

    // MARK: - EditorViewController

    public override var options: BorderEditorViewControllerOptions {
        return self.configuration.borderEditorViewControllerOptions
    }

    override var enableZoomingInPreviewImage: Bool {
        return false
    }

    // MARK: - SubEditorViewController

    public override func tappedDone(sender: UIBarButtonItem?) {
        fixedFilterStack.borderFilter.border = choosenBorder
        fixedFilterStack.borderFilter.tolerance = 0.1

        updatePreviewImageWithCompletion {
            super.tappedDone(sender)
        }
    }

    // MARK: - UIViewController

    /**
    :nodoc:
    */
    override public func viewDidLoad() {
        super.viewDidLoad()

        imageRatio = Float(self.previewImageView.image!.size.width / self.previewImageView.image!.size.height)

        configureStickersCollectionView()
        configureStickersClipView()
        configureOverlayConverter()

        invokeCollectionViewDataFetch()
    }

    private func invokeCollectionViewDataFetch() {
        options.bordersDataSource.borderCount(imageRatio, tolerance: 0.1, completionBlock: { count, error in
            self.borderCount = count
                dispatch_async(dispatch_get_main_queue(), {
                    self.collectionView.reloadData()
                })
            if let error = error {
                print(error.description)
            }
        })
    }

    /**
     :nodoc:
     */
    public override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        rerenderPreviewWithoutStickers()
        options.didEnterToolClosure?()
    }

    /**
     :nodoc:
     */
    public override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        options.willLeaveToolClosure?()
    }

    /**
     :nodoc:
     */
    override public func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bordersClipView.frame = view.convertRect(previewImageView.visibleImageFrame, fromView: previewImageView)
    }

    // MARK: - Configuration

    private func configureOverlayConverter() {
        self.overlayConverter = OverlayConverter(fixedFilterStack: self.fixedFilterStack)
    }

    private func configureStickersCollectionView() {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.itemSize = kStickersCollectionViewCellSize
        flowLayout.scrollDirection = .Horizontal
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 10, bottom: 0, right: 10)
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 10

        collectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: flowLayout)
        collectionView.backgroundColor = currentBackgroundColor
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.registerClass(StickerCollectionViewCell.self, forCellWithReuseIdentifier: kStickersCollectionViewCellReuseIdentifier)

        let views = [ "collectionView" : collectionView ]
        bottomContainerView.addSubview(collectionView)
        bottomContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("|[collectionView]|", options: [], metrics: nil, views: views))
        bottomContainerView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[collectionView]|", options: [], metrics: nil, views: views))
    }

    private func configureStickersClipView() {
        bordersClipView.addSubview(borderView)
        view.addSubview(bordersClipView)
    }

    private func rerenderPreviewWithoutStickers() {
        let backupBorder = self.fixedFilterStack.borderFilter.border
        choosenBorder = backupBorder
        if let backupBorder = backupBorder {
            self.fixedFilterStack.borderFilter.border = nil
            updatePreviewImageWithCompletion { () -> (Void) in
                self.setBorderToView(backupBorder)
            }
        }
    }

    // MARK: - Helpers

    private func hitImageView(point: CGPoint) -> UIImageView? {
        var result: UIImageView? = nil
        for imageView in bordersClipView.subviews where imageView is UIImageView {
            if imageView.frame.contains(point) {
                result = imageView as? UIImageView
            }
        }
        return result
    }

    private func showError(message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
    }
}

extension BorderEditorViewController: UICollectionViewDataSource {
    public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return borderCount + 1
    }

    public func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(kStickersCollectionViewCellReuseIdentifier, forIndexPath: indexPath) as! StickerCollectionViewCell
        // swiftlint:enable force_cast
        let index = indexPath.item
        if index == 0 {
            cell.imageView.image = UIImage(named: "icon_frames_no", inBundle: NSBundle(forClass: BorderEditorViewController.self), compatibleWithTraitCollection: nil)
            cell.imageView.contentMode = .Center
        } else {
            options.bordersDataSource.borderAtIndex(index - 1, ratio: imageRatio, tolerance: 0.1, completionBlock: { border, error in
                if let border = border {
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        let updateCell = self.collectionView.cellForItemAtIndexPath(indexPath)
                        if let updateCell = updateCell as? StickerCollectionViewCell {
                            updateCell.imageView.image = border.thumbnail ?? border.imageForRatio(self.imageRatio, tolerance: 0.1)
                            updateCell.imageView.contentMode = .Center
                            if let label = border.label {
                                updateCell.accessibilityLabel = Localize(label)
                            }
                        }
                    })
                } else {
                    if let error = error {
                        self.showError(error.description)
                    }
                }
            })
        }
        return cell
    }

    private func setBorderToView(border: Border?) {
        if let border = border {
            self.borderView.image = border.imageForRatio(self.imageRatio, tolerance: 0.1)
            self.borderView.frame.size = self.bordersClipView.frame.size
            self.borderView.center = CGPoint(x: self.bordersClipView.bounds.midX, y: self.bordersClipView.bounds.midY)
        }
    }
}

extension BorderEditorViewController: UICollectionViewDelegate {
    // add selected sticker
    public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        let index = indexPath.item
        if index == 0 {
            self.choosenBorder = nil
            self.borderView.image = nil
            let label = Localize("No border")
            self.borderView.accessibilityLabel = label
            self.options.addedBorderClosure?(label)
        } else {
            options.bordersDataSource.borderAtIndex(index - 1, ratio: imageRatio, tolerance: 0.1, completionBlock: { border, error in
                if let border = border {
                    self.setBorderToView(border)

                    if let label = border.label {
                        self.choosenBorder = border
                        self.borderView.accessibilityLabel = Localize(label)
                        self.options.addedBorderClosure?(label)
                    }
                } else {
                    if let error = error {
                        self.showError(error.description)
                    }
                }
            })
        }
    }
}

extension BorderEditorViewController: UIGestureRecognizerDelegate {
    public func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) || (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
            return true
        }
        return false
    }
}
