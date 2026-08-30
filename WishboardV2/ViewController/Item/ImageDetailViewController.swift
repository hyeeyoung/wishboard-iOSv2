//
//  ImageDetailViewController.swift
//  WishboardV2
//
//  Created by gomin on 8/30/25.
//

import Foundation
import UIKit
import SnapKit
import Then
import Core
import Kingfisher

final class ImageDetailViewController: UIViewController {

    // MARK: - Properties
    private let imageUrls: [String?]
    private var currentIndex: Int
    private var hasScrolledToInitial = false

    // MARK: - UI
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.isPagingEnabled = true
        cv.showsHorizontalScrollIndicator = false
        cv.backgroundColor = .black
        cv.dataSource = self
        cv.delegate = self
        cv.register(ImageDetailCell.self, forCellWithReuseIdentifier: "ImageDetailCell")
        return cv
    }()

    private let pageControl = UIPageControl().then {
        $0.currentPageIndicatorTintColor = .white
        $0.pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.4)
        $0.transform = CGAffineTransform(scaleX: 0.857, y: 0.857)
    }

    private let closeButton = UIButton(type: .custom).then {
        $0.setImage(Image.whiteQuit, for: .normal)
        $0.tintColor = .white
    }

    // MARK: - Init
    init(imageUrls: [String?], initialIndex: Int) {
        self.imageUrls = imageUrls
        self.currentIndex = initialIndex
        super.init(nibName: nil, bundle: nil)
        self.modalPresentationStyle = .overFullScreen
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        setupViews()
        setupConstraints()
        setupActions()

        pageControl.numberOfPages = imageUrls.count
        pageControl.currentPage = currentIndex
        pageControl.isHidden = imageUrls.count < 2
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard !hasScrolledToInitial, collectionView.bounds.width > 0 else { return }
        hasScrolledToInitial = true

        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.itemSize = collectionView.bounds.size
            layout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }

        if currentIndex > 0 {
            let offset = CGPoint(x: CGFloat(currentIndex) * collectionView.bounds.width, y: 0)
            collectionView.setContentOffset(offset, animated: false)
        }
    }

    // MARK: - Setup
    private func setupViews() {
        view.addSubview(collectionView)
        view.addSubview(pageControl)
        view.addSubview(closeButton)
    }

    private func setupConstraints() {
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(12)
            make.leading.equalToSuperview().offset(16)
            make.size.equalTo(24)
        }

        pageControl.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(6)
        }
    }

    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeTapped), for: .touchUpInside)
    }

    @objc private func closeTapped() {
        UIDevice.vibrate()
        dismiss(animated: true)
    }
}

// MARK: - UICollectionView DataSource & Delegate
extension ImageDetailViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return imageUrls.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "ImageDetailCell",
            for: indexPath
        ) as? ImageDetailCell else {
            return UICollectionViewCell()
        }
        cell.configure(url: imageUrls[indexPath.item])
        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView, scrollView.bounds.width > 0 else { return }
        let page = Int(round(scrollView.contentOffset.x / scrollView.bounds.width))
        pageControl.currentPage = page
        currentIndex = page
    }
}

extension ImageDetailViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return collectionView.bounds.size
    }
}

// MARK: - Image Detail Cell
private final class ImageDetailCell: UICollectionViewCell {

    private let scrollView = UIScrollView().then {
        $0.minimumZoomScale = 1.0
        $0.maximumZoomScale = 4.0
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.backgroundColor = .black
        $0.bouncesZoom = true
    }

    private let imageView = UIImageView().then {
        $0.contentMode = .scaleAspectFit
        $0.backgroundColor = .black
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .black
        contentView.backgroundColor = .black
        setupViews()
        addGestures()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupViews() {
        contentView.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.delegate = self

        scrollView.snp.makeConstraints { $0.edges.equalToSuperview() }
        imageView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            make.width.height.equalTo(scrollView.frameLayoutGuide)
        }
    }

    private func addGestures() {
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTap.numberOfTapsRequired = 2
        contentView.addGestureRecognizer(doubleTap)
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            scrollView.setZoomScale(scrollView.minimumZoomScale, animated: true)
        } else {
            let location = gesture.location(in: imageView)
            let zoomFactor: CGFloat = 2.0
            let size = CGSize(
                width: scrollView.bounds.width / zoomFactor,
                height: scrollView.bounds.height / zoomFactor
            )
            let origin = CGPoint(
                x: location.x - size.width / 2,
                y: location.y - size.height / 2
            )
            scrollView.zoom(to: CGRect(origin: origin, size: size), animated: true)
        }
    }

    func configure(url: String?) {
        scrollView.setZoomScale(1.0, animated: false)
        if let urlString = url {
            imageView.loadImage(from: urlString, placeholder: Image.emptyView)
        } else {
            imageView.image = Image.emptyView
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        scrollView.setZoomScale(1.0, animated: false)
        imageView.image = nil
    }
}

extension ImageDetailCell: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }

    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        let offsetX = max((scrollView.bounds.width - scrollView.contentSize.width) * 0.5, 0)
        let offsetY = max((scrollView.bounds.height - scrollView.contentSize.height) * 0.5, 0)
        scrollView.contentInset = UIEdgeInsets(top: offsetY, left: offsetX, bottom: 0, right: 0)
    }
}
