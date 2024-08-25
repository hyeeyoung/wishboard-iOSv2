//
//  PaddingLabel.swift
//  WishboardV2
//
//  Created by gomin on 8/18/24.
//

import Foundation
import UIKit

class PaddedLabel: UILabel {
    var edgeInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: edgeInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + edgeInsets.left + edgeInsets.right,
                      height: size.height + edgeInsets.top + edgeInsets.bottom)
    }

    override func textRect(forBounds bounds: CGRect, limitedToNumberOfLines numberOfLines: Int) -> CGRect {
        let insetRect = bounds.inset(by: edgeInsets)
        let textRect = super.textRect(forBounds: insetRect, limitedToNumberOfLines: numberOfLines)
        return CGRect(x: textRect.origin.x - edgeInsets.left,
                      y: textRect.origin.y - edgeInsets.top,
                      width: textRect.size.width + edgeInsets.left + edgeInsets.right,
                      height: textRect.size.height + edgeInsets.top + edgeInsets.bottom)
    }
}
