//
//  ItemDragSelectionController.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit

protocol ItemDragSelectionControllerDelegate: AnyObject {
    /// 드래그를 시작한 아이템이 이미 선택되어 있는지 여부
    func dragSelectionController(_ controller: ItemDragSelectionController, isItemSelectedAt indexPath: IndexPath) -> Bool
    /// 드래그 시작. 드래그 이전의 선택 상태를 저장해두기 위해 호출됩니다.
    func dragSelectionControllerDidBegin(_ controller: ItemDragSelectionController)
    /// 드래그가 지나간 범위와, 그 범위에 적용할 선택 여부를 전달합니다.
    /// 손가락을 되돌리면 범위가 줄어들 수 있으므로, 항상 드래그 시작 시점의 선택 상태를 기준으로 적용해야 합니다.
    func dragSelectionController(_ controller: ItemDragSelectionController, didDragOver indexPaths: [IndexPath], isSelected: Bool)
    /// 드래그 종료
    func dragSelectionControllerDidEnd(_ controller: ItemDragSelectionController)
}

/// 컬렉션뷰 위에서 손가락을 끌어 아이템을 연속으로 선택할 수 있게 해주는 제스처 컨트롤러
final class ItemDragSelectionController: NSObject {

    /// 컬렉션뷰의 세로 스크롤과 충돌하지 않도록,
    /// 가로 이동 성분이 세로 성분의 이 비율보다 큰 드래그만 선택 제스처로 인식합니다. (좌/우 + 대각선 드래그)
    private static let horizontalVelocityRatio: CGFloat = 0.6

    /// 드래그 선택 활성화 여부. 다중 선택 모드에서만 true가 됩니다.
    var isEnabled: Bool = false {
        didSet { panGesture.isEnabled = isEnabled }
    }

    weak var delegate: ItemDragSelectionControllerDelegate?

    private weak var collectionView: UICollectionView?
    private let section: Int
    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))

    private var startIndexPath: IndexPath?
    private var lastIndexPath: IndexPath?
    private var isSelecting: Bool = true

    init(collectionView: UICollectionView, section: Int) {
        self.collectionView = collectionView
        self.section = section
        super.init()

        panGesture.delegate = self
        panGesture.isEnabled = false
        collectionView.addGestureRecognizer(panGesture)
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        let point = gesture.location(in: collectionView)

        switch gesture.state {
        case .began:
            guard let indexPath = itemIndexPath(at: point) else { return }

            // 드래그 중에는 스크롤을 막아 선택만 동작하도록 합니다.
            collectionView.isScrollEnabled = false

            startIndexPath = indexPath
            lastIndexPath = indexPath
            isSelecting = !(delegate?.dragSelectionController(self, isItemSelectedAt: indexPath) ?? false)

            delegate?.dragSelectionControllerDidBegin(self)
            delegate?.dragSelectionController(self, didDragOver: [indexPath], isSelected: isSelecting)

        case .changed:
            // 셀 사이 여백 등으로 아이템을 찾지 못하면 마지막 위치를 유지합니다.
            guard let startIndexPath = startIndexPath,
                  let currentIndexPath = itemIndexPath(at: point) ?? lastIndexPath else { return }

            lastIndexPath = currentIndexPath
            delegate?.dragSelectionController(
                self,
                didDragOver: indexPaths(from: startIndexPath, to: currentIndexPath),
                isSelected: isSelecting
            )

        case .ended, .cancelled, .failed:
            collectionView.isScrollEnabled = true
            startIndexPath = nil
            lastIndexPath = nil
            delegate?.dragSelectionControllerDidEnd(self)

        default:
            break
        }
    }

    // MARK: - Private

    private func itemIndexPath(at point: CGPoint) -> IndexPath? {
        guard let indexPath = collectionView?.indexPathForItem(at: point),
              indexPath.section == section else { return nil }
        return indexPath
    }

    /// 컬렉션뷰의 아이템은 행 우선으로 나열되므로,
    /// 시작과 현재 사이의 인덱스 범위를 선택하면 좌/우/대각선 드래그가 모두 자연스럽게 처리됩니다.
    private func indexPaths(from start: IndexPath, to end: IndexPath) -> [IndexPath] {
        let lower = min(start.item, end.item)
        let upper = max(start.item, end.item)
        return (lower...upper).map { IndexPath(item: $0, section: section) }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ItemDragSelectionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled,
              gestureRecognizer === panGesture,
              let collectionView = collectionView else { return false }

        // 세로로 끄는 동작은 스크롤에 양보합니다.
        let velocity = panGesture.velocity(in: collectionView)
        guard abs(velocity.x) > abs(velocity.y) * ItemDragSelectionController.horizontalVelocityRatio else {
            return false
        }

        return itemIndexPath(at: panGesture.location(in: collectionView)) != nil
    }
}
