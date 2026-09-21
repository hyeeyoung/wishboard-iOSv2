//
//  ItemDragSelectionController.swift
//  WishboardV2
//
//  Created by gomin on 2026/09/18.
//

import Foundation
import UIKit
import Core

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
///
/// 두 가지 방법으로 드래그 선택을 시작할 수 있습니다.
/// - 바로 끌기: 가로/대각선으로 끌면 즉시 시작합니다. (2·3열 그리드에서 자연스러운 방향)
/// - 살짝 누른 뒤 끌기: 잠깐 누르고 있으면 방향과 무관하게 시작합니다.
///   1열 리스트처럼 세로로 끌어야 하는 경우, 세로 드래그는 스크롤과 구분할 수 없어 이 방법을 사용합니다.
final class ItemDragSelectionController: NSObject {

    /// 컬렉션뷰의 세로 스크롤과 충돌하지 않도록,
    /// 곧바로 시작하는 드래그는 가로 이동 성분이 세로 성분의 이 비율보다 클 때만 선택으로 인식합니다.
    private static let horizontalVelocityRatio: CGFloat = 0.6

    /// 살짝 눌러 드래그 선택을 시작할 때의 최소 누름 시간.
    /// 스크롤하려고 빠르게 쓸어넘기는 동작은 이 시간을 넘기지 못해 그대로 스크롤됩니다.
    private static let longPressDuration: TimeInterval = 0.25

    /// 드래그 선택 활성화 여부. 다중 선택 모드에서만 true가 됩니다.
    var isEnabled: Bool = false {
        didSet {
            panGesture.isEnabled = isEnabled
            longPressGesture.isEnabled = isEnabled
        }
    }

    weak var delegate: ItemDragSelectionControllerDelegate?

    private weak var collectionView: UICollectionView?
    private let section: Int

    private lazy var panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
    private lazy var longPressGesture: UILongPressGestureRecognizer = {
        let gesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        gesture.minimumPressDuration = ItemDragSelectionController.longPressDuration
        return gesture
    }()

    private var startIndexPath: IndexPath?
    private var lastIndexPath: IndexPath?
    private var isSelecting: Bool = true
    /// 살짝 눌러 시작한 드래그가 진행 중인지 여부
    private var isLongPressDragging: Bool = false

    init(collectionView: UICollectionView, section: Int) {
        self.collectionView = collectionView
        self.section = section
        super.init()

        panGesture.delegate = self
        panGesture.isEnabled = false
        collectionView.addGestureRecognizer(panGesture)

        longPressGesture.delegate = self
        longPressGesture.isEnabled = false
        collectionView.addGestureRecognizer(longPressGesture)
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        let point = gesture.location(in: collectionView)

        switch gesture.state {
        case .began:
            guard let indexPath = itemIndexPath(at: point) else { return }
            beginDrag(at: indexPath)

        case .changed:
            updateDrag(at: point)

        case .ended, .cancelled, .failed:
            endDrag()

        default:
            break
        }
    }

    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        let point = gesture.location(in: collectionView)

        switch gesture.state {
        case .began:
            guard let indexPath = itemIndexPath(at: point) else { return }
            isLongPressDragging = true
            beginDrag(at: indexPath)
            // 드래그 선택이 시작됐음을 알립니다.
            UIDevice.vibrate()

        case .changed:
            guard isLongPressDragging else { return }
            updateDrag(at: point)

        case .ended, .cancelled, .failed:
            guard isLongPressDragging else { return }
            isLongPressDragging = false
            endDrag()

        default:
            break
        }
    }

    // MARK: - Drag

    private func beginDrag(at indexPath: IndexPath) {
        // 드래그 중에는 스크롤을 막아 선택만 동작하도록 합니다.
        collectionView?.isScrollEnabled = false

        startIndexPath = indexPath
        lastIndexPath = indexPath
        isSelecting = !(delegate?.dragSelectionController(self, isItemSelectedAt: indexPath) ?? false)

        delegate?.dragSelectionControllerDidBegin(self)
        delegate?.dragSelectionController(self, didDragOver: [indexPath], isSelected: isSelecting)
    }

    private func updateDrag(at point: CGPoint) {
        // 셀 사이 여백 등으로 아이템을 찾지 못하면 마지막 위치를 유지합니다.
        guard let startIndexPath = startIndexPath,
              let currentIndexPath = itemIndexPath(at: point) ?? lastIndexPath else { return }

        lastIndexPath = currentIndexPath
        delegate?.dragSelectionController(
            self,
            didDragOver: indexPaths(from: startIndexPath, to: currentIndexPath),
            isSelected: isSelecting
        )
    }

    private func endDrag() {
        guard startIndexPath != nil else { return }

        collectionView?.isScrollEnabled = true
        startIndexPath = nil
        lastIndexPath = nil
        delegate?.dragSelectionControllerDidEnd(self)
    }

    // MARK: - Private

    private func itemIndexPath(at point: CGPoint) -> IndexPath? {
        guard let indexPath = collectionView?.indexPathForItem(at: point),
              indexPath.section == section else { return nil }
        return indexPath
    }

    /// 컬렉션뷰의 아이템은 행 우선으로 나열되므로,
    /// 시작과 현재 사이의 인덱스 범위를 선택하면 좌/우/대각선/세로 드래그가 모두 자연스럽게 처리됩니다.
    private func indexPaths(from start: IndexPath, to end: IndexPath) -> [IndexPath] {
        let lower = min(start.item, end.item)
        let upper = max(start.item, end.item)
        return (lower...upper).map { IndexPath(item: $0, section: section) }
    }
}

// MARK: - UIGestureRecognizerDelegate

extension ItemDragSelectionController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard isEnabled, let collectionView = collectionView else { return false }

        // 살짝 누른 뒤 끄는 드래그는 방향을 가리지 않습니다.
        if gestureRecognizer === longPressGesture {
            return itemIndexPath(at: longPressGesture.location(in: collectionView)) != nil
        }

        guard gestureRecognizer === panGesture else { return false }
        // 이미 눌러서 시작한 드래그가 진행 중이면 팬은 관여하지 않습니다.
        guard !isLongPressDragging else { return false }

        // 방향만으로는 스크롤과 구분할 수 없으므로, 세로로 끄는 동작은 스크롤에 양보합니다.
        let velocity = panGesture.velocity(in: collectionView)
        guard abs(velocity.x) > abs(velocity.y) * ItemDragSelectionController.horizontalVelocityRatio else {
            return false
        }

        return itemIndexPath(at: panGesture.location(in: collectionView)) != nil
    }
}
