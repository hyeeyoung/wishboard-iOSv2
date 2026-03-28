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

        viewModel.$showRecentSortButton
            .receive(on: RunLoop.main)
            .sink { [weak self] show in
                self?.reorderView.recentSortButton.isHidden = !show
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
                                               action: #selector(recentSortTap),
                                               for: .touchUpInside)
    }

    @objc private func closeTap() {
        dismiss(animated: true)
    }

    @objc private func recentSortTap() {
        viewModel.sortByRecent()
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
                   performDropWith coordinator: UITableViewDropCoordinator) {

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
