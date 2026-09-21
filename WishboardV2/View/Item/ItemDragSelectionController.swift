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
///
/// 드래그 중 손가락이 화면 위/아래 가장자리에 닿으면 자동으로 스크롤되며 선택이 이어집니다.
final class ItemDragSelectionController: NSObject {

    /// 컬렉션뷰의 세로 스크롤과 충돌하지 않도록,
    /// 곧바로 시작하는 드래그는 가로 이동 성분이 세로 성분의 이 비율보다 클 때만 선택으로 인식합니다.
    private static let horizontalVelocityRatio: CGFloat = 0.6

    /// 살짝 눌러 드래그 선택을 시작할 때의 최소 누름 시간.
    /// 스크롤하려고 빠르게 쓸어넘기는 동작은 이 시간을 넘기지 못해 그대로 스크롤됩니다.
    private static let longPressDuration: TimeInterval = 0.25

    /// 자동 스크롤이 시작되는 위/아래 가장자리 영역의 높이
    private static let autoScrollEdgeHeight: CGFloat = 80
    /// 자동 스크롤 최대 속도 (pt/s). 가장자리에 가까울수록 이 값에 가까워집니다.
    private static let autoScrollMaxSpeed: CGFloat = 900

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

    /// 마지막 터치 위치. 자동 스크롤로 내용이 움직여도 손가락 위치는 그대로이므로,
    /// 컨텐츠 좌표가 아니라 화면에 보이는 영역 기준 좌표로 들고 있습니다.
    private var lastTouchPointInBounds: CGPoint = .zero
    private var autoScrollDisplayLink: CADisplayLink?

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

    deinit {
        stopAutoScroll()
    }

    // MARK: - Gesture

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let collectionView = collectionView else { return }
        let point = gesture.location(in: collectionView)

        switch gesture.state {
        case .began:
            guard let indexPath = itemIndexPath(at: point) else { return }
            beginDrag(at: indexPath, point: point)

        case .changed:
            dragChanged(at: point)

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
            beginDrag(at: indexPath, point: point)
            // 드래그 선택이 시작됐음을 알립니다.
            UIDevice.vibrate()

        case .changed:
            guard isLongPressDragging else { return }
            dragChanged(at: point)

        case .ended, .cancelled, .failed:
            guard isLongPressDragging else { return }
            isLongPressDragging = false
            endDrag()

        default:
            break
        }
    }

    // MARK: - Drag

    private func beginDrag(at indexPath: IndexPath, point: CGPoint) {
        // 드래그 중에는 손으로 스크롤되지 않도록 막습니다. (자동 스크롤은 contentOffset으로 직접 처리)
        collectionView?.isScrollEnabled = false

        startIndexPath = indexPath
        lastIndexPath = indexPath
        isSelecting = !(delegate?.dragSelectionController(self, isItemSelectedAt: indexPath) ?? false)
        storeTouchLocation(point)

        delegate?.dragSelectionControllerDidBegin(self)
        delegate?.dragSelectionController(self, didDragOver: [indexPath], isSelected: isSelecting)

        // 가장자리에서 시작했다면 손가락을 움직이지 않아도 바로 스크롤되도록 합니다.
        updateAutoScroll()
    }

    private func dragChanged(at point: CGPoint) {
        guard startIndexPath != nil else { return }

        storeTouchLocation(point)
        updateDrag(at: point)
        updateAutoScroll()
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

        stopAutoScroll()
        collectionView?.isScrollEnabled = true
        startIndexPath = nil
        lastIndexPath = nil
        delegate?.dragSelectionControllerDidEnd(self)
    }

    // MARK: - Auto Scroll

    /// 손가락이 위/아래 가장자리에 닿았을 때의 자동 스크롤 속도 (pt/s). 0이면 스크롤하지 않습니다.
    private var autoScrollSpeed: CGFloat {
        guard let collectionView = collectionView else { return 0 }

        let insets = collectionView.adjustedContentInset
        let edge = ItemDragSelectionController.autoScrollEdgeHeight
        let topThreshold = insets.top + edge
        let bottomThreshold = collectionView.bounds.height - insets.bottom - edge
        let y = lastTouchPointInBounds.y

        if y < topThreshold {
            let ratio = min(1, (topThreshold - y) / edge)
            return -ItemDragSelectionController.autoScrollMaxSpeed * ratio
        }
        if y > bottomThreshold {
            let ratio = min(1, (y - bottomThreshold) / edge)
            return ItemDragSelectionController.autoScrollMaxSpeed * ratio
        }
        return 0
    }

    private func updateAutoScroll() {
        guard autoScrollSpeed != 0 else {
            stopAutoScroll()
            return
        }
        guard autoScrollDisplayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(handleAutoScroll(_:)))
        displayLink.add(to: .main, forMode: .common)
        autoScrollDisplayLink = displayLink
    }

    private func stopAutoScroll() {
        autoScrollDisplayLink?.invalidate()
        autoScrollDisplayLink = nil
    }

    @objc private func handleAutoScroll(_ displayLink: CADisplayLink) {
        guard let collectionView = collectionView, startIndexPath != nil else {
            stopAutoScroll()
            return
        }

        let speed = autoScrollSpeed
        guard speed != 0 else {
            stopAutoScroll()
            return
        }

        let insets = collectionView.adjustedContentInset
        let minOffsetY = -insets.top
        let maxOffsetY = max(minOffsetY,
                             collectionView.contentSize.height + insets.bottom - collectionView.bounds.height)

        let duration = CGFloat(max(0, displayLink.targetTimestamp - displayLink.timestamp))
        let offsetY = min(maxOffsetY, max(minOffsetY, collectionView.contentOffset.y + speed * duration))

        // 끝에 닿았다면 이번 프레임은 넘어갑니다.
        // 페이징으로 아이템이 더 불러와지면 다시 스크롤될 수 있으므로 멈추지는 않습니다.
        guard offsetY != collectionView.contentOffset.y else { return }
        collectionView.contentOffset.y = offsetY

        // 손가락은 그대로지만 아래 내용이 움직였으므로, 현재 위치를 다시 계산해 선택 범위를 갱신합니다.
        updateDrag(at: touchPointInContent)
    }

    // MARK: - Private

    private func storeTouchLocation(_ pointInContent: CGPoint) {
        guard let collectionView = collectionView else { return }
        lastTouchPointInBounds = CGPoint(x: pointInContent.x - collectionView.contentOffset.x,
                                         y: pointInContent.y - collectionView.contentOffset.y)
    }

    /// 마지막 터치 위치를 현재 스크롤 위치 기준의 컨텐츠 좌표로 변환합니다.
    private var touchPointInContent: CGPoint {
        guard let collectionView = collectionView else { return lastTouchPointInBounds }
        return CGPoint(x: lastTouchPointInBounds.x + collectionView.contentOffset.x,
                       y: lastTouchPointInBounds.y + collectionView.contentOffset.y)
    }

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
