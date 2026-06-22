//
//  UIImage.swift
//  Wishboard
//
//  Created by gomin on 2023/08/13.
//

import Foundation
import UIKit

extension UIImage {
    
    /// 이미지를 원하는 사이즈로 리사이징
    public func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// 가로와 세로의 비율을 유지한 채로 긴 쪽의 길이를 720으로 유지
    public func resizeImageIfNeeded() -> UIImage {
        let targetSize = CGSize(width: 720, height: 720)
        
        guard var cgImage = self.cgImage else {
            return self
        }
        
        let size = CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
        
        if size.width <= targetSize.width && size.height <= targetSize.height {
            // 이미지가 작은 경우 리사이징하지 않고 그대로 반환
            return self
        }
        
        var newSize = size
        if size.width > size.height {
            newSize.height = targetSize.height * size.height / size.width
            newSize.width = targetSize.width
        } else {
            newSize.width = targetSize.width * size.width / size.height
            newSize.height = targetSize.height
        }
        
        // 이미지의 방향 정보를 탐지
        switch imageOrientation.rawValue {
        // 제대로 된 방향일 때 break
        case 0, 4:
            break
        // 위아래로 뒤집혀져있을 때 180도 회전
        case 1, 5:
            if let rotatedCGImage = rotateCGImage180(cgImage: cgImage) {
                cgImage = rotatedCGImage
            }
        // 왼쪽으로 회전되어있을 때 오른쪽으로 90도 회전
        case 2, 6:
            if let rotatedCGImage = rotateCGImageRight90(cgImage: cgImage) {
                cgImage = rotatedCGImage
            }
        // 오른쪽으로 회전되어있을 때 오른쪽으로 90도 회전 후 180도 뒤집기
        case 3, 7:
            if let rotatedCGImage = rotateCGImageRight90(cgImage: cgImage) {
                if let rotatedImage = rotateCGImage180(cgImage: rotatedCGImage) {
                    cgImage = rotatedImage
                }
                
            }
        default:
            print("이미지 방향 파악 불가")
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(newSize.width), height: Int(newSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.interpolationQuality = .high
        context?.draw(cgImage, in: CGRect(origin: .zero, size: newSize))
        
        if let resizedImage = context?.makeImage().flatMap({ UIImage(cgImage: $0) }) {
            // ✅ 여기서 용량 체크 + 필요 시 추가 리사이즈
            return resizedImage.ensureUnder1MBAfterResize(limitBytes: 1_000_000, quality: 0.9)
        } else {
            // 원본도 체크해서 넘으면 줄이기
            return self.ensureUnder1MBAfterResize(limitBytes: 1_000_000, quality: 0.9)
        }
    }
    
    /// 이미지 가로 세로 로그 출력
    public func printImageDimensions(_ image: UIImage) {
        let width = image.size.width
        let height = image.size.height
        
        print("Image Width: \(width)")
        print("Image Height: \(height)")
    }
    
    /// cgImage를 180도 회전시키는 메서드
    public func rotateCGImage180(cgImage: CGImage) -> CGImage? {
        let rotatedSize = CGSize(width: cgImage.width, height: cgImage.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(rotatedSize.width), height: Int(rotatedSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.translateBy(x: rotatedSize.width, y: rotatedSize.height)
        context?.rotate(by: .pi)  // 180도 회전 (라디안 단위)
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: rotatedSize.width, height: rotatedSize.height))
        
        return context?.makeImage()
    }
    /// cgImage를 오른쪽으로 90도 회전시키는 메서드
    public func rotateCGImageRight90(cgImage: CGImage) -> CGImage? {
        let rotatedSize = CGSize(width: cgImage.height, height: cgImage.width)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: Int(rotatedSize.width), height: Int(rotatedSize.height), bitsPerComponent: 8, bytesPerRow: 0, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        
        context?.translateBy(x: rotatedSize.width, y: 0)
        context?.rotate(by: .pi / 2)  // 오른쪽으로 90도 회전 (라디안 단위)
        
        // 이미지를 그릴 위치와 크기를 조정하여 그립니다.
        context?.draw(cgImage, in: CGRect(x: 0, y: 0, width: rotatedSize.height, height: rotatedSize.width))
        
        return context?.makeImage()
    }

    /// JPEG(기본 q=0.9)로 1MB 이하가 될 때까지 긴 변을 shrinkStep 비율로 줄여가며 리사이즈
    /// - limitBytes: 바이트 한도 (기본 1MB)
    /// - quality: JPEG 품질 (리사이즈만 반복하고 싶다 해서 고정)
    /// - minDimension: 너무 작아지지 않도록 하한(긴 변)
    /// - shrinkStep: 한 번 실패할 때마다 긴 변을 줄이는 비율
    func ensureUnder1MBAfterResize(limitBytes: Int = 1_000_000,
                                   quality: CGFloat = 0.9,
                                   minDimension: CGFloat = 320,
                                   shrinkStep: CGFloat = 0.9) -> UIImage {
        var img = self
        var maxDim = max(img.size.width, img.size.height)

        // 현재 용량이 이미 제한 이하면 바로 반환
        if let bytes = img.jpegData(compressionQuality: quality)?.count, bytes <= limitBytes {
            return img
        }

        // 제한 넘으면 단계적으로 더 축소
        while maxDim > minDimension {
            maxDim = floor(maxDim * shrinkStep)
            img = img._resizedKeepingAspect(maxDimension: maxDim)

            if let bytes = img.jpegData(compressionQuality: quality)?.count, bytes <= limitBytes {
                return img
            }
        }
        // 하한까지 줄였는데도 초과면 마지막 결과 반환
        return img
    }

    /// 긴 변 = maxDimension 으로 비율 유지 리사이즈 (추가 리사이징용)
    fileprivate func _resizedKeepingAspect(maxDimension: CGFloat) -> UIImage {
        let maxSide = max(size.width, size.height)
        guard maxSide > maxDimension else { return self }

        let scale = maxDimension / maxSide
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let format = UIGraphicsImageRendererFormat()
        format.scale = 1   // 픽셀 단위 정확히
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
