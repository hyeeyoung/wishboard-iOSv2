//
//  CartViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/28/24.
//

import Foundation
import UIKit
import Combine

final class CartViewController: UIViewController {
    
    private var viewModel = CartViewModel()
    private var cartView = CartView()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        viewModel.fetchCartItems()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        self.view.addSubview(cartView)
        cartView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
        
        self.cartView.toolBar.delegate = self
        self.setupTableView()
    }
    
    private func setupTableView() {
        cartView.tableView.dataSource = self
        cartView.tableView.delegate = self
        cartView.tableView.register(CartItemTableViewCell.self, forCellReuseIdentifier: CartItemTableViewCell.reuseIdentifier)
    }
    
    private func setupBindings() {
        viewModel.$cartItems
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.cartView.emptyLabel.isHidden = !(items.isEmpty)
                self?.cartView.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$totalQuantity
            .receive(on: RunLoop.main)
            .sink { [weak self] totalQuantity in
                self?.cartView.configureQuantityLabel(with: totalQuantity)
            }
            .store(in: &cancellables)
        
        viewModel.$totalPrice
            .receive(on: RunLoop.main)
            .sink { [weak self] totalPrice in
                self?.cartView.configurePriceLabel(with: String(totalPrice))
            }
            .store(in: &cancellables)
    }
}

// MARK: - UITableViewDataSource
extension CartViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.cartItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "CartItemTableViewCell", for: indexPath) as? CartItemTableViewCell else {
            return UITableViewCell()
        }
        let cartItem = viewModel.cartItems[indexPath.row]
        cell.configure(with: cartItem)
        
        // Cart Item Actions
        cell.increaseQuantity = { [weak self] in
            self?.viewModel.increaseQuantity(of: cartItem)
        }
        cell.decreaseQuantity = { [weak self] in
            self?.viewModel.decreaseQuantity(of: cartItem)
        }
        cell.removeItem = { [weak self] in
            // Show Alert
            let alert = AlertViewController(alertType: .deleteCart)
            alert.buttonHandlers = [
                { _ in
                    print("장바구니 삭제 취소")
                }, { _ in
                    self?.viewModel.removeItem(cartItem)
                }
            ]
            alert.modalTransitionStyle = .crossDissolve
            alert.modalPresentationStyle = .overFullScreen
            self?.present(alert, animated: true, completion: nil)
        }
        
        cell.selectionStyle = .none
        return cell
    }
}

// MARK: - UITableViewDelegate
extension CartViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 116
    }
}

// MARK: - CartItemCellDelegate
extension CartViewController: ToolBarDelegate {
    func leftNaviItemTap() {
        self.navigationController?.popViewController(animated: true)
    }
    
    
}
