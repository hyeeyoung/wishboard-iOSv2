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
    
    // 첫 진입 시에 로직이 다르기 때문에 플래그 분리
    // 첫 진입 시엔 API 호출 및 오늘날짜 선택
    // 다른 경우에는 API 호출만 진행
    private var isFirstLoad = true
    
    // MARK: - View Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
        setupDelegates()
        setupBindings()
        addTargets()
        
        if isFirstLoad {
            fetchDatas()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.navigationBar.isHidden = true
        self.tabBarController?.tabBar.isHidden = true
        super.viewWillAppear(animated)
        
        if isFirstLoad {return}
        Task {
            do {
                viewModel.updateCalendarDays()
                try await viewModel.fetchAlarms()
            } catch {
                throw error
            }
        }
    }
    
    private func setupUI() {
        view.backgroundColor = .white
        
        self.view.addSubview(calendarView)
        calendarView.snp.makeConstraints { make in
            make.top.equalTo(self.view.safeAreaLayoutGuide)
            make.horizontalEdges.bottom.equalToSuperview()
        }
    }
    
    private func fetchDatas() {
        Task {
            do {
                viewModel.updateCalendarDays()
                try await viewModel.fetchAlarms()
                self.isFirstLoad = false
                // 첫 진입 시 오늘날짜 선택
                DispatchQueue.main.async {
                    self.selectToday()
                }
            } catch {
                // 첫 진입 시 오늘날짜 선택
                DispatchQueue.main.async {
                    self.selectToday()
                }
                throw error
            }
        }
    }
    
    private func setupDelegates() {
        self.setupCollectionView()
        self.setupTableView()
    }
    
    private func setupCollectionView() {
        calendarView.collectionView.delegate = self
        calendarView.collectionView.dataSource = self
        calendarView.collectionView.register(CalendarCell.self, forCellWithReuseIdentifier: CalendarCell.identifier)
    }

    private func setupTableView() {
        calendarView.tableView.delegate = self
        calendarView.tableView.dataSource = self
        calendarView.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "AlarmCell")
    }
    
    private func setupBindings() {
        viewModel.$currentMonth
            .receive(on: RunLoop.main)
            .sink { [weak self] newMonth in
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "MMMM yyyy"
                self?.calendarView.monthLabel.text = dateFormatter.string(from: newMonth)
                self?.calendarView.collectionView.reloadData()
            }
            .store(in: &cancellables)

        viewModel.$selectedAlarms
            .receive(on: RunLoop.main)
            .sink { [weak self] alarms in
                DispatchQueue.main.async {
                    self?.calendarView.setEmptyView(isHidden: !(alarms.isEmpty))
                    self?.calendarView.tableView.reloadData()
                    self?.updateTableViewHeight()
               }
            }
            .store(in: &cancellables)
        
        viewModel.$days
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.calendarView.collectionView.reloadData()
            }
            .store(in: &cancellables)
        
        viewModel.$alarms
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.calendarView.collectionView.reloadData()
            }
            .store(in: &cancellables)
    }
    
    private func addTargets() {
        calendarView.quitButton.addTarget(self, action: #selector(quitCalenderView), for: .touchUpInside)
    }
    
    @objc private func quitCalenderView() {
        UIDevice.vibrate()
        self.dismiss(animated: true)
    }
    
    private func selectToday() {
        var koreanCalendar = Calendar.current
        koreanCalendar.timeZone = TimeZone(identifier: "Asia/Seoul")!

        let today = koreanCalendar.startOfDay(for: Date())
        
        // 현재 달의 days 배열에서 오늘 날짜의 index 찾기
        if let todayIndex = viewModel.days.firstIndex(where: {
            guard let date = $0 else { return false }
            return koreanCalendar.isDate(date, inSameDayAs: today)
        }) {
            viewModel.selectDate(today) // 오늘 날짜 선택
            let indexPath = IndexPath(item: todayIndex, section: 0)
            calendarView.collectionView.reloadItems(at: [indexPath]) // 선택된 셀 업데이트
            calendarView.configureSelectedLabel(today) // 상단 라벨도 업데이트
        }
    }
    
    private func updateTableViewHeight() {
        calendarView.tableView.snp.updateConstraints { make in
            make.height.equalTo(calendarView.tableView.contentSize.height)
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension CalendarViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.days.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CalendarCell.identifier, for: indexPath) as? CalendarCell else {
            return UICollectionViewCell()
        }

        if let date = viewModel.days[indexPath.item] {
            let isSelected = viewModel.selectedDate != nil && Calendar.current.isDate(viewModel.selectedDate!, inSameDayAs: date)
            let hasAlarm = viewModel.alarms[date] != nil
            let day = Calendar.current.component(.day, from: date)
            let isCurrentMonth = Calendar.current.isDate(date, equalTo: viewModel.currentMonth, toGranularity: .month)
            let isToday = Calendar.current.isDate(date, inSameDayAs: Date())

            cell.configure(day: day, hasAlarm: hasAlarm, isSelected: isSelected, isCurrentMonth: isCurrentMonth, isToday: isToday)
        } else {
            cell.configure(day: 0, hasAlarm: false, isSelected: false, isCurrentMonth: false, isToday: false) // 빈 칸 처리
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let selectedDate = viewModel.days[indexPath.item] else { return }
        UIDevice.vibrate()
        let previousSelectedIndex = viewModel.days.firstIndex(where: {
            if let selected = viewModel.selectedDate {
                return Calendar.current.isDate(selected, inSameDayAs: $0 ?? Date())
            }
            return false
        })

        viewModel.selectDate(selectedDate)

        var indexPathsToReload: [IndexPath] = [indexPath]
        
        // 기존 선택된 날짜가 있으면 해당 셀도 갱신
        if let previousIndex = previousSelectedIndex {
            let previousIndexPath = IndexPath(item: previousIndex, section: 0)
            indexPathsToReload.append(previousIndexPath)
        }

        collectionView.reloadItems(at: indexPathsToReload)
        
        calendarView.configureSelectedLabel(selectedDate)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension CalendarViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.selectedAlarms.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.row < viewModel.selectedAlarms.count else {
            print("Index out of range: selectedAlarms 배열에 접근할 수 없음")
            return UITableViewCell() // 빈 셀 반환
        }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NoticeTableViewCell.reuseIdentifier, for: indexPath) as? NoticeTableViewCell else { return UITableViewCell() }
        cell.configureCalendarAlarm(with: viewModel.selectedAlarms[indexPath.row])
        
        DispatchQueue.main.async {
            self.updateTableViewHeight()
        }
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 112
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UIDevice.vibrate()
        let item = viewModel.selectedAlarms[indexPath.row]
        let detailViewController = ItemDetailViewController(id: item.id)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

// MARK: - ScrollView Delegates
extension CalendarViewController: UIScrollViewDelegate {
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        let velocity = scrollView.panGestureRecognizer.velocity(in: scrollView) // 스와이프 속도 감지

        if velocity.x < -500 {
            viewModel.moveToNextMonth() // 🔥 오른쪽으로 스와이프 → 다음 달
            animateCalendarSlide(to: .left)
        } else if velocity.x > 500 {
            viewModel.moveToPreviousMonth() // 🔥 왼쪽으로 스와이프 → 이전 달
            animateCalendarSlide(to: .right)
        }
        viewModel.updateCalendarDays()
    }
    
    func animateCalendarSlide(to direction: SlideDirection) {
        let calendarView = self.calendarView.collectionView
        let animationOffset: CGFloat = 50
        let offsetX = (direction == .left) ? animationOffset : -animationOffset

        calendarView.transform = CGAffineTransform(translationX: offsetX, y: 0)
        calendarView.alpha = 0.0

        UIView.animate(withDuration: 0.8, delay: 0, options: [.curveEaseOut], animations: {
            calendarView.transform = .identity
            calendarView.alpha = 1.0
        })
    }
}

/// 애니메이팅 시 필요한 Enum - slide direction
enum SlideDirection {
    case left
    case right
}
