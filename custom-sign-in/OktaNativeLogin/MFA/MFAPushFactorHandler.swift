/*
 * Copyright 2019 Okta, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import OktaAuthSdk

protocol MFAPushFactorHandlerProtocol: class {
    func onStatusChanged(status: OktaAuthStatus)
    func onPollingProgress(status: OktaAuthStatus)
    func onPollingStopped(status: OktaAuthStatus)
    func onError(error: OktaError)
}

class MFAPushFactorHandler {
    
    public weak var delegate: MFAPushFactorHandlerProtocol?

    public func handlePushFactorResponse(status: OktaAuthStatus) {
        if status.canPoll() {
            if let factorResult = status.factorResult {
                if factorResult != OktaAPISuccessResponse.FactorResult.waiting {
                    self.delegate?.onPollingStopped(status: status)
                } else {
                    if let factor = self.getFactorFromStatus(status: status) {
                        self.delegate?.onPollingProgress(status: status)
                        self.verifyPushFactor(factor: factor)
                    } else {
                        self.delegate?.onStatusChanged(status: status)
                    }
                }
                return
            }
        }
        else {
            self.delegate?.onStatusChanged(status: status)
        }
    }

    public func cancel() {
        self.stopPollTimer(timer: self.factorResultPollTimer)
    }
    
    private var factorResultPollTimer: Timer? = nil

    private func getFactorFromStatus(status: OktaAuthStatus) -> OktaFactorPush? {
        if let status = status as? OktaAuthStatusFactorChallenge,
           let factor = status.factor as? OktaFactorPush {
            return factor
        }
        if let status = status as? OktaAuthStatusFactorEnrollActivate,
           let factor = status.factor as? OktaFactorPush {
            return factor
        }

        return nil
    }
    
    private func startPollTimer(timer: Timer) {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.startPollTimer(timer: timer)
            }
            return
        }

        self.stopPollTimer(timer: self.factorResultPollTimer)
        self.factorResultPollTimer = timer
        RunLoop.current.add(timer, forMode: .common)
    }
    
    private func stopPollTimer(timer: Timer?) {
        guard let timer = timer else {
            return
        }
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.stopPollTimer(timer: timer)
            }
            return
        }
        if timer.isValid {
            timer.invalidate()
        }
    }
    
    private func verifyPushFactor(factor: OktaFactorPush, with delay: TimeInterval = 5) {
        let timer = Timer(timeInterval: delay, repeats: false) { _ in
            factor.checkFactorResult(onStatusChange: { [weak self] status in
                    self?.handlePushFactorResponse(status: status)
                }, onError: { [weak self] error in
                    self?.delegate?.onError(error: error)
            })
        }
        self.startPollTimer(timer: timer)
    }
}
