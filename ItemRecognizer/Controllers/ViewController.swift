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
    
    @IBOutlet weak var nbsBBLbl: UILabel!
    
    let captureSession = AVCaptureSession()
    
    var requests = [VNRequest]()
    
    var classifier = MyCustomObjectDetector()
    
    var classes: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        nbsBBLbl.text = "0 BB"
        setUpInput()
        setupPreview()
        setUpOutput()
        setupVision()
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
    
    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: classifier.model) else {
            fatalError("Can’t load VisionML model")
        }
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: handleDetections)
        classificationRequest.imageCropAndScaleOption = .scaleFill
        requests = [classificationRequest]
    }
    
    func handleDetections(request: VNRequest, error: Error?) {
        if let _ = error {
            return
        }
        let mlmodel = classifier
        let userDefined: [String: String] = mlmodel.model.modelDescription.metadata[MLModelMetadataKey.creatorDefinedKey]! as! [String : String]
        classes = userDefined["classes"]!.components(separatedBy: ",")
        let nmsThreshold = Float(userDefined["non_maximum_suppression_threshold"]!) ?? 0.5
        guard let observations = request.results as? [VNCoreMLFeatureValueObservation] else {
            fatalError("unexpected result type from VNCoreMLRequest")
        }
        guard let predictions = Predictions.FromMultiDimensionalArrays(observations: observations, nmsThreshold: nmsThreshold)
            else { return }
        
        DispatchQueue.main.async {
            for subview in self.view.subviews {
                if subview.tag == 20 {
                    subview.removeFromSuperview()
                }
            }
            for prediction in predictions {
                self.highlightArea(boundingRect: prediction.boundingBox, classIndex: prediction.labelIndex, confidence: prediction.confidence)
            }
            var count = 0
            for subView in self.view.subviews {
                if subView.tag == 20 {
                    count += 1
                }
            }
            self.nbsBBLbl.text = "\(count) BB"
        }
    }
    
    func highlightArea(boundingRect: CGRect, classIndex: Int, confidence: Float) {
        let source = self.view.bounds
        let rectWidth = source.size.width * boundingRect.size.width
        let rectHeight = source.size.height * boundingRect.size.height
        let boundingBox = Bundle.main.loadNibNamed("BoundingBoxView", owner: self, options: nil)!.first as! BoundingBoxView
        boundingBox.frame = CGRect(x: boundingRect.origin.x * source.size.width, y:boundingRect.origin.y * source.size.height, width: rectWidth, height: rectHeight)
        boundingBox.tag = 20
        boundingBox.backgroundColor = UIColor.clear
        boundingBox.nameLbl.text = classes[classIndex]
        let pct = Float(Int(confidence * 10000)) / 100
        boundingBox.pctLbl.text = "\(pct)%"
        self.view.addSubview(boundingBox)
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        guard let pixelBuffer: CVPixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, orientation: CGImagePropertyOrientation.right, options: [:])
        try? imageRequestHandler.perform(requests)
    }
    
}



