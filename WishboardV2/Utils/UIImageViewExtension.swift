//
//  UIImageViewExtension.swift
//  WishboardV2
//
//  Created by gomin on 2/23/25.
//

import Foundation
import UIKit
import Kingfisher

extension UIImageView {
    
    public func loadImage(from url: URL, placeholder: UIImage? = nil) {

        // 보여 줄 크기로 줄여서 디코딩합니다.
        //
        // 상품 사진은 3000x4000 처럼 큰 것들이 섞여 있습니다. 파일은 0.5MB 여도 화면에
        // 그리려면 픽셀로 펼쳐야 해서 한 장에 40MB 를 넘깁니다. 그대로 두면 목록에서
        // 여러 장이 동시에 올라올 때 메모리를 크게 먹고, 한도가 낮은 공유 익스텐션에서는
        // 이미지 한 장만으로 프로세스가 종료됩니다.
        let processor = DownsamplingImageProcessor(size: downsamplingTargetSize)
            |> TintImageProcessor(tint: .black_05)

        self.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: [
                .transition(.fade(0.2)),  // 페이드 인 애니메이션 적용
                .processor(processor),    // 축소 후 dimmedView 추가
                .scaleFactor(UIScreen.main.scale),
            ]
        )
    }

    /// 줄여서 디코딩할 기준 크기.
    /// 레이아웃 전이라 크기가 잡히지 않았으면 화면 너비를 상한으로 씁니다.
    private var downsamplingTargetSize: CGSize {
        let size = bounds.size
        guard size.width > 1, size.height > 1 else {
            let fallback = UIScreen.main.bounds.width
            return CGSize(width: fallback, height: fallback)
        }
        return size
    }
    
    public func loadImage(from urlString: String, placeholder: UIImage? = nil) {
        guard let url = URL(string: urlString) else {
            // 주소가 잘못돼 그냥 돌아가면, 재사용된 셀에 앞 이미지가 남습니다.
            cancelImageLoad(placeholder: placeholder)
            return
        }
        loadImage(from: url, placeholder: placeholder)
    }

    /// 불러올 이미지가 없을 때 씁니다.
    ///
    /// 셀이 재사용된 뒤에 앞 아이템의 이미지가 뒤늦게 도착해 엉뚱한 셀에 그려지는 것을 막습니다.
    ///
    /// `cancelDownloadTask()` 만으로는 부족합니다. Kingfisher 가 뒤늦게 도착한 결과를
    /// 버릴지 판단하는 기준은 이미지뷰에 저장된 작업 식별자인데, 그 메서드는 식별자를
    /// 건드리지 않습니다. 이미 받아 둔(캐시에 있거나 내려받기가 끝난) 이미지는 그대로
    /// 그려집니다. 빈 소스로 `setImage` 를 부르면 식별자가 지워져, 앞선 작업의 결과가
    /// 도착해도 무시됩니다.
    public func cancelImageLoad(placeholder: UIImage? = nil) {
        // 아직 내려받는 중이라면 멈춥니다.
        kf.cancelDownloadTask()
        // 이미 끝난 작업의 뒤늦은 반영까지 막습니다.
        kf.setImage(with: nil as (any Resource)?, placeholder: placeholder)
        image = placeholder
    }
}
