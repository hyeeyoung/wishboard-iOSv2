//
//  CalendarViewController.swift
//  WishboardV2
//
//  Created by gomin on 9/7/24.
//

import Foundation
import UIKit
import Combine
import SafariServices
import Core

final class CalendarViewController: UIViewController {
    private var viewModel = CalendarViewModel()
    private var calendarView = CalendarView()
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDelegates()
        setupBindings()
        
        viewModel.fetchHighlightedDates()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = true
        super.viewWillAppear(animated)
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        self.view.addSubview(calendarView)
        calendarView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    private func setupDelegates() {
        calendarView.calendar.delegate = self
        calendarView.calendar.selectionBehavior = UICalendarSelectionSingleDate(delegate: self)
        
//        calendarView.tableView.delegate = self
        calendarView.tableView.dataSource = self
    }
    
    private func setupBindings() {
        viewModel.$notificationItems
            .receive(on: RunLoop.main)
            .sink { [weak self] items in
                self?.calendarView.emptyLabel.isHidden = !(items.isEmpty)
                self?.calendarView.tableView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$selectedDate
            .receive(on: RunLoop.main)
            .sink { [weak self] date in
                let dateStr = date.toString()
                self?.calendarView.dateLabel.text = FormatManager.shared.notiDateToKoreanStr(dateStr)
                self?.viewModel.fetchNotifications(for: date)
                self?.calendarView.tableView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func updateTitleLabel() {
        // 현재 보이는 달을 기준으로 타이틀 업데이트
        let visibleMonth = calendarView.calendar.visibleDateComponents.month ?? 1
        let visibleYear = calendarView.calendar.visibleDateComponents.year ?? 2024
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMMM yyyy"
        
        if let date = Calendar.current.date(from: DateComponents(year: visibleYear, month: visibleMonth)) {
            calendarView.monthLabel.text = dateFormatter.string(from: date)
        }
    }
}

// MARK: - UICalendarView Delegate
extension CalendarViewController: UICalendarViewDelegate {
    func calendarView(_ calendarView: UICalendarView, visibleDateComponentsDidChange dateComponents: DateComponents) {
        // 달이 변경될 때마다 타이틀 업데이트
        updateTitleLabel()
    }
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let date = Calendar.current.date(from: dateComponents) else {
            return nil
        }
        
        // 알림이 있는 날짜에 대한 배경 설정
        if viewModel.highlightedDates.contains(where: { Calendar.current.isDate($0.notiDate.toNotiDate() ?? Date(), inSameDayAs: date) }) {
            return .default(color: .green_500, size: .medium)
        }
        
        return nil
    }
}
// MARK: - UICalendarSelectionSingleDateDelegate
extension CalendarViewController: UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let selectedDate = Calendar.current.date(from: dateComponents) else {
            return
        }
        
        viewModel.selectedDate = selectedDate
    }
}

// MARK: - UITableView DataSource
extension CalendarViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.notificationItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        let item = viewModel.notificationItems[indexPath.row]
        cell.textLabel?.text = item.name
        return cell
    }
}
