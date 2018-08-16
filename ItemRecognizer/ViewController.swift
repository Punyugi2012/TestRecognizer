//
//  ViewController.swift
//  ItemRecognizer
//
//  Created by punyawee  on 16/8/61.
//  Copyright © พ.ศ. 2561 Punyugi. All rights reserved.
//

import UIKit
import AVKit
import Vision
import CoreML

class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var outputLabel: UILabel!
    
    let captureSession = AVCaptureSession()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        outputLabel.text = "..."
        setUpInput()
        setupPreview()
        setUpOutput()
        captureSession.startRunning()
    }
    
    func setupPreview() {
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.frame
        view.layer.insertSublayer(previewLayer, at: 0)
    }
    
    func setUpInput() {
        guard let captureDevice =  AVCaptureDevice.default(for: .video) else { return }
        guard let inputCapture = try? AVCaptureDeviceInput(device: captureDevice) else {
            return }
        captureSession.addInput(inputCapture)
    }
    
    func setUpOutput() {
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            return
        }
        let requests =  VNCoreMLRequest(model: model) { (finishedReq, error) in
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            guard let firstObservation = results.first else { return }
            DispatchQueue.main.async {
                self.outputLabel.text = "\(firstObservation.identifier) \(firstObservation.confidence)"
            }
        }
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([requests])
    }
    
    
}



