/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import UIKit
import AVFoundation
import OneTimePassword

class QRScannerController: UIViewController {
    lazy var captureSession: AVCaptureSession = AVCaptureSession()
    var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    
    var completion: ((Token) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCaptureDeviceInput()
        setupCaptureMetadataOutput()
        
        setupVideoLayer()
        
        captureSession.startRunning()
    }
    
    private func setupCaptureDeviceInput() {
        let session = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInDualCamera],
            mediaType: .video,
            position: .back
        )
        
        guard let captureDevice = session.devices.first else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            captureSession.addInput(input)
        } catch {
            print(error)
            return
        }
    }
    
    private func setupCaptureMetadataOutput() {
        let output = AVCaptureMetadataOutput()
        captureSession.addOutput(output)
        
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]
    }
    
    private func setupVideoLayer() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer?.videoGravity = AVLayerVideoGravity.resizeAspectFill
        videoPreviewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(videoPreviewLayer!)
    }
}

extension QRScannerController: AVCaptureMetadataOutputObjectsDelegate {
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              metadataObject.type == .qr,
              let value = metadataObject.stringValue else {
            return
        }
        
        guard let tokenUri = URL(string: value),
              let token = Token(url: tokenUri) else {
            
            let alert = UIAlertController(title: "Unable to create token!", message: nil, preferredStyle: .alert)
            present(alert, animated: true)
            return
        }
        
        self.navigationController?.popViewController(animated: true)
        self.captureSession.stopRunning()

        self.completion?(token)
    }
}
