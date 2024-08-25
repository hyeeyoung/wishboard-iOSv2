//
//  LoadingPlugin.swift
//  WishboardV2
//
//  Created by gomin on 8/3/24.
//

import Foundation
import Moya

public final class LoadingPlugin: PluginType {
    // 빈 값으로 유지
    public static var loadingTargets: [String] = []
    
    public var noLoadingAPIs: [String] = []
    
    public var needLoadingAPIs: [String] = []
    
    var _tagLoadingView: Int = 0
//    var _loadingViewController: UIViewController?
    
    public func didReceive(_ result: Swift.Result<Response, MoyaError>, target: TargetType) {
        if needLoadingAPIs.contains(target.path) {

            let url = target.baseURL.absoluteString + target.path
            DispatchQueue.main.async {
                if let idx = LoadingPlugin.loadingTargets.lastIndex(of: url) {
                    LoadingPlugin.loadingTargets.remove(at: idx)
                    print("\(url): \(LoadingPlugin.loadingTargets)")

                    if LoadingPlugin.loadingTargets.count == 0 {
                        // 로드 완료 -> 로딩뷰 숨기기
                        // 타임 딜레이 없이 즉시로 바꿈. 딜레이 때문에 다른 UI 가 침투한다.
                        self.stopLoading(url)
                    }
                }
            }
        }
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        let urlString = target.baseURL.absoluteString + target.path
        
        if needLoadingAPIs.contains(target.path) {
            DispatchQueue.main.async {
                LoadingPlugin.loadingTargets.append(urlString)
                print("\(urlString): \(LoadingPlugin.loadingTargets)")
                // 로딩뷰 보이기
                self.showLoading(urlString)
            }
        }
        return request
    }
    
    public func addNoLoadingTarget(path: String) {
        noLoadingAPIs.append(path)
    }
    
    public func removeNoLoadingTarget(path: String) {
        if let idx = noLoadingAPIs.lastIndex(of: path) {
            noLoadingAPIs.remove(at: idx)
        }
        
    }
    
    private func showLoading(_ url: String) {
//        let storyboard = UIStoryboard(name: "CommonPopup", bundle: nil)
//        let c = storyboard.instantiateViewController(withIdentifier: "ProgressLoadingView")
//        _tagLoadingView = c.view.tag
//        _loadingViewController = c
//        
//        if let _loadingViewController = _loadingViewController {
//            UIApplication.shared.keyWindow?.addSubview(_loadingViewController.view)
//        }
        print("Loading from api path: \(url)")
    }
    private func stopLoading(_ url: String) {
//        if let _loadingViewController = _loadingViewController {
//            _loadingViewController.view.removeFromSuperview()
//        }
        
        print("Stop loading from api path: \(url)")
    }
}
