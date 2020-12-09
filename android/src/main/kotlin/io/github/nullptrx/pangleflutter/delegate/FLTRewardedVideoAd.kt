package io.github.nullptrx.pangleflutter.delegate

import android.app.Activity
import com.bytedance.sdk.openadsdk.TTAdNative
import com.bytedance.sdk.openadsdk.TTRewardVideoAd
import io.github.nullptrx.pangleflutter.PangleAdManager
import io.github.nullptrx.pangleflutter.common.PangleLoadingType
import io.github.nullptrx.pangleflutter.common.kBlock

internal class FLTRewardedVideoAd(var target: Activity?, val loadingType: PangleLoadingType, var result: (Any) -> Unit = {}) : TTAdNative.RewardVideoAdListener {

  var ttVideoAd: TTRewardVideoAd? = null

  override fun onRewardVideoAdLoad(ad: TTRewardVideoAd?) {
    if (loadingType == PangleLoadingType.preload || loadingType == PangleLoadingType.preload_only) {
      PangleAdManager.shared.setRewardedVideoAd(ad)
      if (loadingType == PangleLoadingType.preload_only) {
        invoke(0, verify = false)
      }
    } else {
      target?.also {
        ttVideoAd = ad
        ttVideoAd?.setRewardAdInteractionListener(RewardAdInteractionImpl(result))
        ttVideoAd?.showRewardVideoAd(it)
      }
    }
  }

  override fun onRewardVideoCached() {
  }

  override fun onError(code: Int, message: String?) {
    invoke(code, message)

  }

  private fun invoke(code: Int = 0, message: String? = null, verify: Boolean = false) {
    result.apply {
      val args = mutableMapOf<String, Any?>()
      args["code"] = code
      message?.also {
        args["message"] = it
      }
      if (code == 0) {
        args["verify"] = verify
      }
      invoke(args)
    }
    result = {}
    target = null
  }


}

internal class RewardAdInteractionImpl(var result: (Any) -> Unit?) : TTRewardVideoAd.RewardAdInteractionListener {
  private var code = 0
  private var message: String? = null
  private var verify = false

  // 视频广告播完验证奖励有效性回调，参数分别为是否有效，奖励数量，奖励名称
  override fun onRewardVerify(verify: Boolean, amount: Int, rewardName: String, errorCode: Int, errorMsg: String) {
    this.verify = verify
  }

  override fun onSkippedVideo() {
//    invoke(-1, "skip")
    code = -1
    message = "skip"
  }

  override fun onAdShow() {
  }

  override fun onAdVideoBarClick() {
  }

  override fun onVideoComplete() {
  }

  override fun onAdClose() {
    invoke(code = code, message = message, verify = verify)
  }

  override fun onVideoError() {
    invoke(-1, "error")
  }


  private fun invoke(code: Int = 0, message: String? = null, verify: Boolean = false) {
    if (result == kBlock) {
      return
    }
    result.apply {
      val args = mutableMapOf<String, Any?>()
      args["code"] = code
      message?.also {
        args["message"] = it
      }
      if (code == 0) {
        args["verify"] = verify
      }
      invoke(args)
      result = kBlock
    }
  }
}

