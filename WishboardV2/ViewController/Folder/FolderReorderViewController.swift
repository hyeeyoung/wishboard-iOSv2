//
//  FolderReorderViewController.swift
//  WishboardV2
//
//  Created by gomin on 3/14/26.
//


import UIKit
import Combine
import WBNetwork

final class FolderReorderViewController: UIViewController {

    private let reorderView = FolderReorderView()
    private let viewModel = FolderReorderViewModel()
    private var cancellables = Set<AnyCancellable>()
    public var saveAction: (() -> Void)?

    /// 자동 스크롤이 시작되는 위/아래 가장자리 영역의 높이
    private static let autoScrollEdgeHeight: CGFloat = 80
    /// 자동 스크롤 최대 속도 (pt/s). 가장자리에 가까울수록 이 값에 가까워집니다.
    private static let autoScrollMaxSpeed: CGFloat = 900

    /// 진행 중인 드래그 세션. 매 프레임 손가락 위치를 물어보는 데 씁니다.
    private weak var activeDragSession: UIDragSession?
    private var autoScrollDisplayLink: CADisplayLink?

    init() {
        super.init(nibName: nil, bundle: nil)
        viewModel.fetchFolders()
    }

    required init?(coder: NSCoder) { fatalError() }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.addSubview(reorderView)
        reorderView.snp.makeConstraints { $0.edges.equalToSuperview() }

        setupTable()
        bind()
        addActions()
    }

    private func setupTable() {
        reorderView.tableView.delegate = self
        reorderView.tableView.dataSource = self
        reorderView.tableView.dragInteractionEnabled = true
        reorderView.tableView.dragDelegate = self
        reorderView.tableView.dropDelegate = self
    }

    private func bind() {

        viewModel.$folders
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.reorderView.tableView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$isSaveEnabled
            .receive(on: RunLoop.main)
            .sink { [weak self] enabled in
                self?.reorderView.updateSaveButton(enabled: enabled)
            }
            .store(in: &cancellables)

        viewModel.$showRestoreButton
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.reorderView.recentSortButton.isHidden = !show
            }
            .store(in: &cancellables)

        // 폴더 리스트 조회 동안 로딩뷰 노출
        viewModel.$isLoading
            .removeDuplicates()
            .receive(on: RunLoop.main)
            .sink { [weak self] isLoading in
                self?.reorderView.setLoading(isLoading)
            }
            .store(in: &cancellables)
    }

    private func addActions() {

        reorderView.closeButton.addTarget(self,
                                          action: #selector(closeTap),
                                          for: .touchUpInside)

        reorderView.saveButton.addTarget(self,
                                         action: #selector(saveTap),
                                         for: .touchUpInside)

        reorderView.recentSortButton.addTarget(self,
                                               action: #selector(returnButtonTap),
                                               for: .touchUpInside)
    }

    @objc private func closeTap() {
        dismiss(animated: true)
    }

    @objc private func returnButtonTap() {
        viewModel.restoreOriginalOrder()
    }

    @objc private func saveTap() {
        updateFoldersAndDismiss()
    }
    
    private func updateFoldersAndDismiss() {
        Task {
            do {
                // 폴더 목록 재정렬 API 호출
                try await viewModel.updateFolderOrders()
                saveAction?()
                dismiss(animated: true)
            } catch {
                throw error
            }
        }
    }
}

extension FolderReorderViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        viewModel.folders.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: FolderReorderCell.reuseIdentifier,
            for: indexPath) as? FolderReorderCell else {
            return UITableViewCell()
        }

        cell.configure(with: viewModel.folders[indexPath.row])
        cell.selectionStyle = .none
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 56
    }
}

// MARK: 폴더 순서 이동
extension FolderReorderViewController: UITableViewDragDelegate, UITableViewDropDelegate {
    
    func tableView(_ tableView: UITableView,
                   dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?)
    -> UITableViewDropProposal {

        if tableView.hasActiveDrag {
            return UITableViewDropProposal(operation: .move,
                                           intent: .insertAtDestinationIndexPath)
        } else {
            return UITableViewDropProposal(operation: .forbidden)
        }
    }

    func tableView(_ tableView: UITableView,
                   itemsForBeginning session: UIDragSession,
                   at indexPath: IndexPath) -> [UIDragItem] {

        let item = viewModel.folders[indexPath.row]
        let provider = NSItemProvider()

        let dragItem = UIDragItem(itemProvider: provider)
        dragItem.localObject = item

        return [dragItem]
    }

    func tableView(_ tableView: UITableView,
                   dragSessionWillBegin session: UIDragSession) {
        // 드롭 콜백은 손가락이 테이블 밖으로 나가면 더 이상 오지 않습니다.
        // 세션을 들고 있다가 매 프레임 직접 위치를 물어봐야 화면 밖으로 끌고 가도 스크롤됩니다.
        activeDragSession = session
        startAutoScroll()
    }

    func tableView(_ tableView: UITableView,
                   dragSessionDidEnd session: UIDragSession) {
        stopAutoScroll()
    }

    func tableView(_ tableView: UITableView,
                   performDropWith coordinator: UITableViewDropCoordinator) {
        stopAutoScroll()

        guard let destinationIndexPath = coordinator.destinationIndexPath else { return }

        coordinator.items.forEach { item in

            guard let sourceIndexPath = item.sourceIndexPath else { return }

            tableView.performBatchUpdates {

                viewModel.moveItem(from: sourceIndexPath.row,
                                   to: destinationIndexPath.row)

                tableView.moveRow(at: sourceIndexPath,
                                  to: destinationIndexPath)

            }

            coordinator.drop(item.dragItem,
                             toRowAt: destinationIndexPath)
        }
    }
}

// MARK: - 드래그 중 자동 스크롤

extension FolderReorderViewController {

    /// 손가락이 위/아래 가장자리에 닿았을 때의 자동 스크롤 속도 (pt/s). 0이면 스크롤하지 않습니다.
    private var autoScrollSpeed: CGFloat {
        guard let session = activeDragSession else { return 0 }

        let tableView = reorderView.tableView
        let insets = tableView.adjustedContentInset
        let edge = FolderReorderViewController.autoScrollEdgeHeight
        let topThreshold = insets.top + edge
        let bottomThreshold = tableView.bounds.height - insets.bottom - edge
        let y = session.location(in: tableView).y

        if y < topThreshold {
            // 테이블 밖(음수)까지 끌고 가면 비율이 1로 묶여 최대 속도로 올라갑니다.
            let ratio = min(1, (topThreshold - y) / edge)
            return -FolderReorderViewController.autoScrollMaxSpeed * ratio
        }
        if y > bottomThreshold {
            let ratio = min(1, (y - bottomThreshold) / edge)
            return FolderReorderViewController.autoScrollMaxSpeed * ratio
        }
        return 0
    }

    private func startAutoScroll() {
        guard autoScrollDisplayLink == nil else { return }

        let displayLink = CADisplayLink(target: self, selector: #selector(handleAutoScroll(_:)))
        displayLink.add(to: .main, forMode: .common)
        autoScrollDisplayLink = displayLink
    }

    private func stopAutoScroll() {
        autoScrollDisplayLink?.invalidate()
        autoScrollDisplayLink = nil
        activeDragSession = nil
    }

    @objc private func handleAutoScroll(_ displayLink: CADisplayLink) {
        // 세션이 사라졌는데 종료 콜백을 놓친 경우를 대비해 여기서도 정리합니다.
        guard activeDragSession != nil else {
            stopAutoScroll()
            return
        }

        let speed = autoScrollSpeed
        guard speed != 0 else { return }

        let tableView = reorderView.tableView
        let insets = tableView.adjustedContentInset
        let minOffsetY = -insets.top
        let maxOffsetY = max(minOffsetY,
                             tableView.contentSize.height + insets.bottom - tableView.bounds.height)

        let duration = CGFloat(max(0, displayLink.targetTimestamp - displayLink.timestamp))
        let offsetY = min(maxOffsetY, max(minOffsetY, tableView.contentOffset.y + speed * duration))

        // 끝에 닿았다면 이번 프레임은 넘어갑니다.
        guard offsetY != tableView.contentOffset.y else { return }
        tableView.contentOffset.y = offsetY
    }
}
