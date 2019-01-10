//
//  ViewController.swift
//  AICameraApp
//
//  Created by Deven  on 1/9/19.
//  Copyright © 2019 Deven . All rights reserved.
//

import UIKit
import AVKit
import Vision
import SafariServices


var globalItemString = "desk"


class ViewController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        //Starting Up Camera Here
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let captureDevice = AVCaptureDevice.default(for: .video) else {return}
    
        //do catch
        guard let input = try? AVCaptureDeviceInput(device: captureDevice) else {return}

        captureSession.addInput(input)
        captureSession.startRunning()
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        view.layer.addSublayer(previewLayer)
        previewLayer.frame = view.frame
        
        let dataOutput = AVCaptureVideoDataOutput()
        dataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
        captureSession.addOutput(dataOutput)

        //https://stackoverflow.com/questions/24030348/how-to-create-a-button-programmatically
      
        let button = UIButton(frame: CGRect(x: 0, y: 600, width: 400, height: 50))
        button.backgroundColor = .blue
        button.setTitle("Find Item!", for: .normal)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.view.addSubview(button)
        

    }
    
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        //sleep(3)

        //print("Camera was able to capture frame", Date())
        
        guard let pixelBuffer : CVPixelBuffer =
            CMSampleBufferGetImageBuffer(sampleBuffer) else {return}
        
        guard let model = try? VNCoreMLModel(for: Resnet50().model) else {return}
        
        let request = VNCoreMLRequest(model: model) { (finishedReq, err) in
            
            //Check ERR
            
            //print(finishedReq.results)
            
            guard let results = finishedReq.results as? [VNClassificationObservation] else { return }
            
            guard let firstObservation = results.first else { return }
            
            //https://stackoverflow.com/questions/27226128/what-is-the-more-elegant-way-to-remove-all-characters-after-specific-character-i
            
            //print(firstObservation.identifier)
            
            var str = firstObservation.identifier
            
            if let dotRange = str.range(of: ",") {
                str.removeSubrange(dotRange.lowerBound..<str.endIndex)
                globalItemString = str
            }
            print(globalItemString)
            
        }
        
        try? VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:]).perform([request])
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //https://stackoverflow.com/questions/28010518/swift-open-web-page-in-app-button-doesnt-react
    
    
    @objc func buttonAction(sender: UIButton!) {
        //print(globalItemString)
        
        let amazonSearchString1 = "https://www.amazon.com/s/ref=sr_st_price-asc-rank?keywords="
        
        let amazonSearchString2 = "&rh=i%3Aaps%2Ck%3Ahat&qid=1547093654&sort=price-asc-rank"
        
        //https://stackoverflow.com/questions/46532885/how-to-remove-spaces-from-a-string-in-swift
        //https://stackoverflow.com/questions/28570973/how-should-i-remove-all-the-leading-spaces-from-a-string-swift
        let formattedString = globalItemString.replacingOccurrences(of: " ", with: "+")

        let finalConcatString = amazonSearchString1 + formattedString + amazonSearchString2
        //print(finalConcatString)
        
        let vc = SFSafariViewController(url: NSURL(string: finalConcatString)! as URL)
        present(vc, animated: true, completion: nil)
        
    }
}

