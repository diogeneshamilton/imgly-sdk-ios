//
//  PhotoEffectThumbnailRenderer.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 19/02/16.
//  Copyright © 2016 9elements GmbH. All rights reserved.
//

import UIKit

/**
 *  A `PhotoEffectThumbnailRenderer` can be used to generate thumbnails of a given input image
 *  for multiple photo effects.
 */
@objc(IMGLYPhotoEffectThumbnailRenderer) public class PhotoEffectThumbnailRenderer: NSObject {

    // MARK: - Properties

    /// The input image that will be used to generate the thumbnails.
    public let inputImage: UIImage
    private let renderQueue = dispatch_queue_create("photo_effect_thumbnail_rendering", DISPATCH_QUEUE_SERIAL)
    private let ciContext: CIContext
    private let eaglContext: EAGLContext
    private let lutConverter = LUTToNSDataConverter(identityLUTAtURL: NSBundle(forClass: PhotoEffectThumbnailRenderer.self).URLForResource("Identity", withExtension: "png")!)
    private var thumbnailImage: UIImage?

    // MARK: - Initializers

    /**
    Returns a newly initialized photo effect thumbnail renderer with the given input image.

    - parameter inputImage: The input image that will be used to generate the thumbnails.

    - returns: A newly initialized `PhotoEffectThumbnailRenderer` object.
    */
    public init(inputImage: UIImage) {
        self.inputImage = inputImage
        eaglContext = EAGLContext(API: .OpenGLES2)
        ciContext = CIContext(EAGLContext: eaglContext)
        super.init()
    }

    // MARK: - Rendering

    /**
    Generates thumbnails for multiple photo effects of the given size.

    - parameter photoEffects:     The photo effects that should be used to generate thumbnails.
    - parameter size:             The size of the thumbnails.
    - parameter singleCompletion: This handler will be called for each thumbnail that has been created successfully.
    */
    public func generateThumbnailsForPhotoEffects(photoEffects: [PhotoEffect], ofSize size: CGSize, singleCompletion: ((thumbnail: UIImage, index: Int) -> Void)) {

        dispatch_async(renderQueue) {
            self.renderBaseThumbnailIfNeededOfSize(size)
            var index = 0

            for effect in photoEffects {
                let thumbnail: UIImage?

                if let filter = effect.newEffectFilter {
                    if let filterName = effect.CIFilterName where (filterName == "CIColorCube" || filterName == "CIColorCubeWithColorSpace") && effect.options?["inputCubeData"] == nil {
                        self.lutConverter.lutURL = effect.lutURL
                        filter.setValue(self.lutConverter.colorCubeData, forKey: "inputCubeData")
                    }

                    thumbnail = self.renderThumbnailWithFilter(filter)
                } else {
                    thumbnail = self.thumbnailImage
                }

                if let thumbnail = thumbnail {
                    singleCompletion(thumbnail: thumbnail, index: index)
                }

                index = index + 1
            }
        }
    }

    private func renderBaseThumbnailIfNeededOfSize(size: CGSize) {
        let renderThumbnail = {
            UIGraphicsBeginImageContextWithOptions(size, false, 0)
            self.inputImage.imgly_drawInRect(CGRect(origin: CGPoint.zero, size: size), withContentMode: .ScaleAspectFill)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            self.thumbnailImage = image
        }

        if let thumbnailImage = thumbnailImage where thumbnailImage.size != size {
            renderThumbnail()
        } else if thumbnailImage == nil {
            renderThumbnail()
        }
    }

    private func renderThumbnailWithFilter(filter: CIFilter) -> UIImage? {
        guard let thumbnailImage = thumbnailImage?.CGImage else {
            return nil
        }

        let inputImage = CIImage(CGImage: thumbnailImage)
        filter.setValue(inputImage, forKey: kCIInputImageKey)

        guard let outputImage = filter.outputImage else {
            return nil
        }

        let cgOutputImage = ciContext.createCGImage(outputImage, fromRect: outputImage.extent)

        return UIImage(CGImage: cgOutputImage)
    }
}
