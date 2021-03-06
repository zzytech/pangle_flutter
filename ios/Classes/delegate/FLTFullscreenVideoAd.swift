//
//  FLTFullscreenVideoAd.swift
//  pangle_flutter
//
//  Created by nullptrX on 2020/8/25.
//

import Foundation

internal final class FLTFullscreenVideoAd: NSObject, BUFullscreenVideoAdDelegate {
    typealias Success = () -> Void
    typealias Fail = (Error?) -> Void
    
    private var isSkipped = false
    
    let success: Success?
    let fail: Fail?
    private var loadingType: LoadingType
    
    init(_ loadingType: LoadingType, success: Success?, fail: Fail?) {
        self.loadingType = loadingType
        self.success = success
        self.fail = fail
    }
    
    func fullscreenVideoAdVideoDataDidLoad(_ fullscreenVideoAd: BUFullscreenVideoAd) {
        let preload = self.loadingType == .preload || self.loadingType == .preload_only
        if preload {
            self.loadingType = .normal
            fullscreenVideoAd.extraDelegate = self
            /// 存入缓存
            PangleAdManager.shared.setFullScreenVideoAd(fullscreenVideoAd)
            /// 必须回调，否则task不能销毁，导致内存泄漏
            self.success?()
        } else {
            let vc = AppUtil.getVC()
            fullscreenVideoAd.show(fromRootViewController: vc)
        }
    }
    
    func fullscreenVideoAdDidClose(_ fullscreenVideoAd: BUFullscreenVideoAd) {
        if self.isSkipped {
            return
        }
        if fullscreenVideoAd.didReceiveSuccess != nil {
            fullscreenVideoAd.didReceiveSuccess?()
        } else {
            self.success?()
        }
    }
    
    func fullscreenVideoAdDidClickSkip(_ fullscreenVideoAd: BUFullscreenVideoAd) {
        self.isSkipped = true
        let error = NSError(domain: "skip", code: -1, userInfo: nil)
        if fullscreenVideoAd.didReceiveFail != nil {
            fullscreenVideoAd.didReceiveFail?(error)
        } else {
            self.fail?(error)
        }
    }
    
    func fullscreenVideoAd(_ fullscreenVideoAd: BUFullscreenVideoAd, didFailWithError error: Error?) {
        if fullscreenVideoAd.didReceiveFail != nil {
            fullscreenVideoAd.didReceiveFail?(error)
        } else {
            self.fail?(error)
        }
    }
    
    func fullscreenVideoAdDidPlayFinish(_ fullscreenVideoAd: BUFullscreenVideoAd, didFailWithError error: Error?) {}
}

private var delegateKey = "nullptrx.github.io/delegate"
private var successKey = "nullptrx.github.io/delegate_success"
private var failKey = "nullptrx.github.io/delegate_fail"

extension BUFullscreenVideoAd {
    var extraDelegate: BUFullscreenVideoAdDelegate? {
        get {
            return objc_getAssociatedObject(self, &delegateKey) as? BUFullscreenVideoAdDelegate
        } set {
            objc_setAssociatedObject(self, &delegateKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var didReceiveSuccess: (() -> Void)? {
        get {
            objc_getAssociatedObject(self, &successKey) as? (() -> Void)
        } set {
            objc_setAssociatedObject(self, &successKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    var didReceiveFail: ((Error?) -> Void)? {
        get {
            objc_getAssociatedObject(self, &failKey) as? ((Error?) -> Void)
        } set {
            objc_setAssociatedObject(self, &failKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
}
