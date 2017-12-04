//
//  ViewController.swift
//  Vision Face Detection
//
//  Created by Pawel Chmiel on 21.06.2017.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import UIKit
import AVFoundation
import Vision
import FacebookCore
import FacebookLogin
import FBSDKLoginKit
import SwiftSocket

final class ViewController: UIViewController {
    
    // Camera capture object
    var session: AVCaptureSession?
    
    // Photo from a video
    let photoOutput = AVCapturePhotoOutput()
    
    // Vision Detection UI Layer
    let shapeLayer = CAShapeLayer()
    
    // Capture Button Outline
    var circularOutline = CAShapeLayer()
    
    let flashBtn = UIButton(type: .custom)

    // Label UI Layer
    let labelLayer = UIView()
    
    // Button UI Layer
    let btnLayer = UIView()
    
    // To turn recognition off/on
    var recognize = false

    // Facial Detection object
    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceDetectionRequest = VNSequenceRequestHandler()

    // Facial Features object
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    
    // Actual Video displayed on screen saved into a var
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = self.session else { return nil }
        
        var previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }()
    
    // Back Camera object
    var backCamera: AVCaptureDevice? = {
        var defaultVideoDevice: AVCaptureDevice?
        
        // Choose the back dual camera if available, otherwise default to a wide angle camera.
        if let dualCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInDualCamera, for: AVMediaType.video, position: .back) {
            defaultVideoDevice = dualCameraDevice
        } else if let backCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back) {
            // If the back dual camera is not available, default to the back wide angle camera.
            defaultVideoDevice = backCameraDevice
        } else if let frontCameraDevice = AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .front) {
            /*
             In some cases where users break their phones, the back wide angle camera is not available.
             In this case, we should default to the front wide angle camera.
             */
            defaultVideoDevice = frontCameraDevice
        }
        return defaultVideoDevice
    }()
    
    // stream of media from device to session
    var videoDeviceInput: AVCaptureDeviceInput!
    
    // Photo
    var capturedImage = UIImage()
    var imageArray: [UIImage]!
    var rawImageData: Data?
    var imageString: String?
    
    //------------ Server info --------------//
    let host = "anton's server"
    let port = 80
    var client: TCPClient?
    //---------------------------------------//
    
    /***************************** LIFECYCLE HOOKS **********************************/
    
    // This method executes as soon as the app is done loading assets and src
    override func viewDidLoad() {
        
        // super
        super.viewDidLoad()
        
        // set up gesture support
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        swipeUp.direction = UISwipeGestureRecognizerDirection.up
        swipeLeft.direction = UISwipeGestureRecognizerDirection.left
        self.view.addGestureRecognizer(swipeDown)
        self.view.addGestureRecognizer(swipeUp)
        self.view.addGestureRecognizer(swipeLeft)
        
        self.client = TCPClient(address: host, port: Int32(port))
        self.sessionPrepare()
        self.session?.startRunning()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        AccessToken.refreshCurrentToken()
        
        print("view will appear")
        
    }
    
    // This method lets the app know what our layer bounds are
    override func viewDidLayoutSubviews() {
        
        // super
        super.viewDidLayoutSubviews()
        
        // We need the camera layer, recognition layer, various UI layers
        previewLayer?.frame = view.frame
        labelLayer.frame = view.frame
        btnLayer.frame = view.frame
        shapeLayer.frame = view.frame
    }
    
    // This method executes after viewWillAppear(), two methods down from viewDidLoad()
    override func viewDidAppear(_ animated: Bool) {
        
        // super
        super.viewDidAppear(animated)
        
        AccessToken.refreshCurrentToken()
        
        if AccessToken.current == nil {
            do {
                self.present(FacebookController(), animated: true, completion: nil)
            }
        }
        
        let screenSize: CGPoint = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY-90)
        
        // Set up the camera feed layer
        guard let previewLayer = previewLayer else { return }
        view.layer.addSublayer(previewLayer)
        
        // Set up the Vision detection layer
        shapeLayer.strokeColor = UIColor(red: 1, green: 0.2588, blue: 0.2588, alpha: 1.0).cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
        view.layer.addSublayer(shapeLayer)
        
        // Add the label layer
        self.view.addSubview(labelLayer)
        
        // set up the flash button
        flashBtn.frame = CGRect(x: self.view.frame.maxX-50, y: 40, width: 35, height: 35)
        flashBtn.layer.cornerRadius = 0.5*flashBtn.bounds.size.width
        let image = UIImage(named: "flash_white")
        flashBtn.setImage(image?.withRenderingMode(.alwaysOriginal), for: .normal)
        flashBtn.clipsToBounds = true
        flashBtn.tag = 2
        flashBtn.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        self.btnLayer.addSubview(flashBtn)
        
        // Set up the capture button / buttons layer
        let btnCapture = UIButton(type: .custom)
        btnCapture.frame = CGRect(x: screenSize.x, y:screenSize.y, width: 70, height: 70)
        btnCapture.layer.cornerRadius = 0.5*btnCapture.bounds.size.width
        btnCapture.center = screenSize
        btnCapture.backgroundColor = UIColor.clear
        btnCapture.clipsToBounds = true
        btnCapture.tag = 1
        btnCapture.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        // Ring shape around button
        let circlePath = UIBezierPath(arcCenter: screenSize, radius: CGFloat(0.5*btnCapture.bounds.size.width), startAngle: CGFloat(-rad(value: 90.0)), endAngle: CGFloat(rad(value: 360.0-90.0)), clockwise: true)
        circularOutline.path = circlePath.cgPath
        setOutlineColor(recognition: 0)
        circularOutline.strokeEnd = 1
        circularOutline.lineWidth = 10
        
        // adding a circular outline to a shape layer in the button layer
        self.btnLayer.layer.addSublayer(circularOutline)
        
        // Set up a blur effect on the button
        let blur = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let blurView = UIVisualEffectView(effect: blur)
        blurView.frame = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY-90, width: 70, height: 70)
        blurView.center = screenSize
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 0.5*btnCapture.bounds.size.width
        
        // Add the blur to the button layer
        self.btnLayer.addSubview(blurView)
        
        // Add the capture button to the button layer
        self.btnLayer.addSubview(btnCapture)
        
        // add the button layer to the main view
        self.view.addSubview(btnLayer)
    }
    
    /************************** END LIFECYCLE HOOKS **********************************/
    

    /******************************* MISC METHODS ***********************************/
    
    // Gets and sets up the camera and feed
    func sessionPrepare() {
        session = AVCaptureSession()
        
        guard let session = session, let captureDevice = backCamera else { return }
        
        do {
            let videoDeviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            
            if session.canAddInput(videoDeviceInput) {
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
                session.addOutput(photoOutput)
                
                photoOutput.isHighResolutionCaptureEnabled = true
            }
            
            session.commitConfiguration()
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            print("setup delegate")
        } catch {
            print("can't setup session")
        }
    }
    
    // Button color changes depending on current status of recognition
    func setOutlineColor(recognition: Int) {
        circularOutline.strokeEnd = 0
        switch recognition {
        case 1:
            // change the fill color
            circularOutline.fillColor = UIColor.clear.cgColor
            
            // animate the rim to look like its thinking (looking for faces)
            animateCaptureButton(recognition)
            break
        default:
            
            // change the fill color
            circularOutline.fillColor = UIColor.clear.cgColor
            
            // unanimate the rim
            animateCaptureButton(recognition)
            break
        }
        //circularOutline.strokeEnd = 1
    }
    
    func animateCaptureButton(_ status: Int){
        
        switch status {
        case 1:
            let animcolor = CABasicAnimation(keyPath: "strokeEnd")
            animcolor.fromValue         = 0
            animcolor.toValue           = 1
            animcolor.duration          = 1
            animcolor.repeatCount       = .infinity
            animcolor.autoreverses      = true
            animcolor.timingFunction    = CAMediaTimingFunction(name: kCAMediaTimingFunctionEaseInEaseOut)
            circularOutline.strokeColor = UIColor(red: 1, green: 0.2588, blue: 0.2588, alpha: 1.0).cgColor
            circularOutline.add(animcolor, forKey: "strokeEnd")
            break
        default:
            let animcolor = CABasicAnimation(keyPath: "strokeEnd")
            animcolor.fromValue         = 0
            animcolor.toValue           = 1
            animcolor.duration          = 1
            animcolor.repeatCount       = 0
            animcolor.autoreverses      = false
            circularOutline.strokeColor = UIColor.white.cgColor
            circularOutline.add(animcolor, forKey: "strokeEnd")
            circularOutline.strokeEnd = 1
            break
        
        }
    }
    
    func rad(value: Double) -> Double {
        return (value * Double.pi) / 180
    }
    
    /******************************* END MISC METHODS ***********************************/

    
    /*************************** USER RESPONSE METHODS **********************************/
    
    // This method defines gesture support actions
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        // if the user swipes in any direction
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            // which direction
            switch swipeGesture.direction {
                
            // if down, get rid of the recognition UI
            case UISwipeGestureRecognizerDirection.down:
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                    for view in self.labelLayer.subviews {
                        view.removeFromSuperview()
                    }
                }
                break
            case UISwipeGestureRecognizerDirection.up:
                self.present(FacebookController(), animated: true, completion: nil)
                break
            case UISwipeGestureRecognizerDirection.left:
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromRight
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                if self.imageArray != nil {
                    let tc = TestController(image: self.imageArray[0])
                    self.present(tc, animated: false, completion: nil)
                } else {
                    self.present(TestController(), animated:false, completion: nil)
                }
            default:
                break
            }
        }
    }
    
    // Set up UI button responses
    @objc func buttonAction(sender: UIButton!) {
        let btnsendtag: UIButton = sender
        switch btnsendtag.tag {
            
            // Capture Button
            case 1:
                switch recognize {
                
                    // Sometimes this case needs to run twice to execute the dispatchqueue for some reason, can't figure out why but the swipe down method works for getting rid of recognition UI no matter what
                    case true:
                        recognize = false
                        setOutlineColor(recognition: 0)
                        do {
                            DispatchQueue.main.async {
                                self.shapeLayer.sublayers?.removeAll()
                                for view in self.labelLayer.subviews {
                                    view.removeFromSuperview()
                                }
                            }
                        }
                        break
                    case false:
                        recognize = true
                        setOutlineColor(recognition: 1)
                        break
                }
                break
            
            // Flash Button 
            case 2:
                if (backCamera?.hasTorch)! {
                    do {
                        try backCamera?.lockForConfiguration()
                        
                        if (backCamera?.isTorchActive)! == true {
                            flashBtn.setImage(UIImage(named: "flash_white")?.withRenderingMode(.alwaysOriginal), for: .normal)
                            backCamera?.torchMode = .off
                        } else {
                            flashBtn.setImage(UIImage(named: "flash_yellow")?.withRenderingMode(.alwaysOriginal), for: .normal)
                            backCamera?.torchMode = .on
                        }
                        
                        backCamera?.unlockForConfiguration()
                    }
                    
                    catch {
                        print("Torch failed")
                    }
                } else {
                    print("Torch unavailable")
                }
                break
            default:
                break
        }
    }
    
    /**************************** END USER RESPONSE METHODS *******************************/
    
}

// Server stuff in this extension to keep it cleaner
extension ViewController {
    
    func contactHost(){
        guard let client = client else { return }
        
        switch client.connect(timeout: 10) {
        case .success:
            print("Connected to host \(client.address)")
            if let response = sendRequest(string: "GET / HTTP/1.0\r\n\r\n", using: client) {
                print("contactHost success")
                print("Response: \(response)")
            } else {
                print("No response")
            }
            break
        case .failure(let error):
            print("contactHost error")
            print(error)
            break
        }
        print("contactHost complete")
    }
    
    private func sendRequest(string: String, using client: TCPClient) -> String? {
        print("Sending data ... ")
        
        switch client.send(string: string) {
        case .success:
            print("sendRequest success")
            return readResponse(from: client)
        case .failure(let error):
            print("sendRequest error")
            print(error)
            return nil
        }
    }
    
    private func readResponse(from client: TCPClient) -> String? {
        var data = [UInt8]()
        
        while true {
            guard let response = client.read(1024*10, timeout: 2) else { break }
            data += response
        }
        
        return String(bytes: data, encoding: .utf8)
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate, AVCapturePhotoCaptureDelegate {
        
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        
        //leftMirrored for front camera
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))
        
        if recognize {
            self.imageArray = []
            detectFace(on: ciImageWithOrientation)
        }
    }
    
    func capturePhoto() {
        let photoSettings = AVCapturePhotoSettings()
        
        photoSettings.isHighResolutionPhotoEnabled = true
        
        if !photoSettings.availablePreviewPhotoPixelFormatTypes.isEmpty {
            photoSettings.previewPhotoFormat = [kCVPixelBufferPixelFormatTypeKey as String: photoSettings.availablePreviewPhotoPixelFormatTypes.first!]
        }
        photoOutput.capturePhoto(with: photoSettings, delegate: self)
        print("Photo captured")
    }
    
    func photoOutput(_ captureOutput: AVCapturePhotoOutput, didFinishProcessingPhoto photoSampleBuffer: CMSampleBuffer?, previewPhoto previewPhotoSampleBuffer: CMSampleBuffer?, resolvedSettings: AVCaptureResolvedPhotoSettings, bracketSettings: AVCaptureBracketedStillImageSettings?, error: Error?) {
        
        if let error = error {
            print("Error capturing photo: \(error)")
        } else {
            if let sampleBuffer = photoSampleBuffer, let previewBuffer = previewPhotoSampleBuffer, let dataImage = AVCapturePhotoOutput.jpegPhotoDataRepresentation(forJPEGSampleBuffer: sampleBuffer, previewPhotoSampleBuffer: previewBuffer) {
                
                if let image = UIImage(data: dataImage) {
                    self.capturedImage = image
                    self.imageArray.append(image)
                    self.rawImageData = UIImagePNGRepresentation(self.imageArray[0]) as Data?
                    self.imageString = rawImageData?.base64EncodedString()
                }
            }
        }
    }
}

// All facial detection methods in this extension to keep it cleaner
extension ViewController {
    func detectFace(on image: CIImage) {
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                    /*for view in self.labelLayer.subviews {
                     view.removeFromSuperview()
                     }*/
                }
            }
        }
        return
    }
    
    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                var work: DispatchWorkItem!
                work = DispatchWorkItem { [weak self] in
                    if let boundingBox = self?.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        let faceBoundingBox = boundingBox.scaled(to: (self?.view.bounds.size)!)
                        
                        //different types of landmarks
                        let faceContour = observation.landmarks?.faceContour
                        self?.convertPointsForFace(faceContour, faceBoundingBox)
                        
                        let leftEye = observation.landmarks?.leftEye
                        self?.convertPointsForFace(leftEye, faceBoundingBox)
                        
                        let rightEye = observation.landmarks?.rightEye
                        self?.convertPointsForFace(rightEye, faceBoundingBox)
                        
                        let nose = observation.landmarks?.nose
                        self?.convertPointsForFace(nose, faceBoundingBox)
                        
                        let lips = observation.landmarks?.innerLips
                        self?.convertPointsForFace(lips, faceBoundingBox)
                        
                        let leftEyebrow = observation.landmarks?.leftEyebrow
                        self?.convertPointsForFace(leftEyebrow, faceBoundingBox)
                        
                        let rightEyebrow = observation.landmarks?.rightEyebrow
                        self?.convertPointsForFace(rightEyebrow, faceBoundingBox)
                        
                        let noseCrest = observation.landmarks?.noseCrest
                        self?.convertPointsForFace(noseCrest, faceBoundingBox)
                        
                        let outerLips = observation.landmarks?.outerLips
                        self?.convertPointsForFace(outerLips, faceBoundingBox)
                        
                        // Capture a photo after a face has been detected for 3 seconds
                        let when = DispatchTime.now() + 3
                        var work: DispatchWorkItem!
                        work = DispatchWorkItem { [weak self] in
                            for _ in 1...1 {
                                self?.capturePhoto()
                                break
                            }
                            return
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: when, execute: work)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self?.recognize = false
                        self?.setOutlineColor(recognition: 0)
                        DispatchQueue.main.async {
                            self?.shapeLayer.sublayers?.removeAll()
                        }
                    }
                }
                DispatchQueue.main.async(execute: work)
                //print("recognition over")
            }
        }
    }
    
    func drawLabel() {
        let screenSize = UIScreen.main.bounds
        let label = UILabel(frame: CGRect(x: 0, y: 0, width: screenSize.size.width, height: screenSize.size.height))
        label.font = UIFont.preferredFont(forTextStyle: .headline)
        label.textColor = .white
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.center = CGPoint(x: screenSize.size.width/2, y:screenSize.size.height/10)
        label.textAlignment = .center
        label.text = "I am a test label"
        self.labelLayer.addSubview(label)
    }
    
    func convertPointsForFace(_ landmark: VNFaceLandmarkRegion2D?, _ boundingBox: CGRect) {
        if let convertedPoints = landmark?.normalizedPoints, let _ = landmark?.pointCount {
            let faceLandmarkPoints = convertedPoints.map { (point: CGPoint) -> (x: CGFloat, y: CGFloat) in
                let pointX = point.x * boundingBox.width + boundingBox.origin.x
                let pointY = point.y * boundingBox.height + boundingBox.origin.y
                
                return (x: pointX, y: pointY)
            }
            DispatchQueue.main.async {
                self.draw(points: faceLandmarkPoints)
            }
        }
    }
    
    func draw(points: [(x: CGFloat, y: CGFloat)]) {
        let newLayer = CAShapeLayer()
        newLayer.strokeColor = UIColor(red: 1, green: 0.2588, blue: 0.2588, alpha: 1.0).cgColor
        newLayer.lineWidth = 2.0
        let path = UIBezierPath()
        path.move(to: CGPoint(x: points[0].x, y: points[0].y))
        for i in 0..<points.count - 1 {
            let point = CGPoint(x: points[i].x, y: points[i].y)
            path.addLine(to: point)
            path.move(to: point)
        }
        path.addLine(to: CGPoint(x: points[0].x, y: points[0].y))
        newLayer.path = path.cgPath
        shapeLayer.addSublayer(newLayer)
    }
}

// Random UIImage extension to color icons
extension UIImage {
    func imageWithColor(_ tintColor: UIColor) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(self.size, false, self.scale)
        
        let context = UIGraphicsGetCurrentContext() as! CGContext
        context.translateBy(x: 0, y: self.size.height)
        context.scaleBy(x: 1.0, y: -1.0);
        context.setBlendMode(.normal)
        
        let rect = CGRect(x: 0, y: 0, width: self.size.width, height: self.size.height)
        context.clip(to: rect, mask: self.cgImage!)
        tintColor.setFill()
        context.fill(rect)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext() as! UIImage
        UIGraphicsEndImageContext()
        
        return newImage
    }
}
