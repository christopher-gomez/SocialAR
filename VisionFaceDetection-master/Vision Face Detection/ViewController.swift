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
import FBSDKCoreKit
import FBSDKLoginKit
import FacebookCore
import FacebookLogin

final class ViewController: UIViewController {
    var session: AVCaptureSession?
    let shapeLayer = CAShapeLayer()
    
    var circularOutline = CAShapeLayer()
    
    let labelLayer = UIView()
    let btnLayer = UIView()
    
    var recognize = false

    let faceDetection = VNDetectFaceRectanglesRequest()
    let faceLandmarks = VNDetectFaceLandmarksRequest()
    let faceLandmarksDetectionRequest = VNSequenceRequestHandler()
    let faceDetectionRequest = VNSequenceRequestHandler()
    
    lazy var previewLayer: AVCaptureVideoPreviewLayer? = {
        guard let session = self.session else { return nil }
        
        var previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        
        return previewLayer
    }()
    
    var backCamera: AVCaptureDevice? = {
        return AVCaptureDevice.default(AVCaptureDevice.DeviceType.builtInWideAngleCamera, for: AVMediaType.video, position: .back)
    }()
    
    // This method executes as soon as the app is done loading assets and src
    override func viewDidLoad() {
        
        
        // super
        super.viewDidLoad()
        
        // set up gesture support
        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizerDirection.down
        self.view.addGestureRecognizer(swipeDown)
        
        
        
        // facebook account login
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        
        view.addSubview(loginButton)
        
        loginButton.delegate = self as? LoginButtonDelegate

        if let accessToken = AccessToken.current  {
            print("logged in!")
            view.removeFromSuperview()
            
            // start the the feed
            session?.startRunning()
            
            // prepare the camera feed (check if theres a valid camera, grabs the feed in a variable)
            sessionPrepare()
        }
    }
    
    func loginButtonDidCompleteLogin(_ loginButton:LoginButton,result:LoginResult) {
        switch result {
        case .success:
            print("Gage is a bitch")
            view.removeFromSuperview()
            
            // start the the feed
            session?.startRunning()
            
            // prepare the camera feed (check if theres a valid camera, grabs the feed in a variable)
            sessionPrepare()
        default:
            break;
        }
    }
    
    func loginButtonDidLogOut(loginButton:LoginButton) {
        print("logged out")
    }
    /*
    //when login button clicked
    @objc func loginButtonClicked() {
        let loginManager = LoginManager()
        loginManager.logIn([.publicProfile], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                print(error)
            case .cancelled:
                print("User cancelled login.")
            case .success(let grantedPermissions, let declinedPermissions, let accessToken):
                self.getFBUserData()
            }
        }
    }
    
    //function is fetching the user data
    func getFBUserData(){
        if((FBSDKAccessToken.current()) != nil){
            FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, picture.type(large), email"]).start(completionHandler: { (connection, result, error) -> Void in
                if (error == nil){
                    self.dict = result as! [String : AnyObject]
                    print(result!)
                    print(self.dict)
                }
            })
        }
    }
    */
    
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
    
    // This method executes after viewWillAppear(), to methods down from viewDidLoad()
    override func viewDidAppear(_ animated: Bool) {
        
        // super
        super.viewDidAppear(animated)
        
        // Set up the camera feed layer
        guard let previewLayer = previewLayer else { return }
        view.layer.addSublayer(previewLayer)
        
        // Set up the Vision detection layer
        shapeLayer.strokeColor = UIColor.red.cgColor
        shapeLayer.lineWidth = 2.0
        shapeLayer.setAffineTransform(CGAffineTransform(scaleX: 1, y: -1))
        view.layer.addSublayer(shapeLayer)

        // Add the label layer
        self.view.addSubview(labelLayer)
        
        // Set up the button / button layer
        let btnCapture = UIButton(type: .custom)
        let screenSize: CGPoint = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY-90)
        btnCapture.frame = CGRect(x: screenSize.x, y:screenSize.y, width: 100, height: 100)
        btnCapture.layer.cornerRadius = 0.5*btnCapture.bounds.size.width
        btnCapture.center = screenSize
        btnCapture.backgroundColor = UIColor.clear
        btnCapture.clipsToBounds = true
        btnCapture.tag = 1
        btnCapture.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        
        // This circle path doesnt do anything yet, I eventually want to make a circle with a hole in it like snapchat, turn the circle rim blue when recognition is happening
        let circlePath = UIBezierPath(arcCenter: screenSize, radius: CGFloat(20), startAngle: CGFloat(0), endAngle:CGFloat(Double.pi * 2), clockwise: true)
        
        circularOutline.path = circlePath.cgPath
        setOutlineColor(recognition: self.recognize)
        circularOutline.lineWidth = 2.5
        
        self.btnLayer.layer.addSublayer(circularOutline)
        
        // Set up a blur effect on the button
        let blur = UIBlurEffect(style: UIBlurEffectStyle.regular)
        let blurView = UIVisualEffectView(effect: blur)
        
        blurView.frame = CGRect(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.maxY-90, width: 100, height: 100)
        blurView.center = screenSize
        blurView.clipsToBounds = true
        blurView.layer.cornerRadius = 0.5*btnCapture.bounds.size.width
        blurView.tag = 2
        
        // Add the blur to the button layer
        self.btnLayer.addSubview(blurView)
        
        // Add the button to the button layer
        self.btnLayer.addSubview(btnCapture)
        
        // add the button layer to the main view
        self.view.addSubview(btnLayer)
    }
    
    // Gets and sets up the camera and feed
    func sessionPrepare() {
        session = AVCaptureSession()
        
        guard let session = session, let captureDevice = backCamera else { return }
        
        do {
            let deviceInput = try AVCaptureDeviceInput(device: captureDevice)
            session.beginConfiguration()
            
            if session.canAddInput(deviceInput) {
                session.addInput(deviceInput)
            }
            
            let output = AVCaptureVideoDataOutput()
            output.videoSettings = [
                String(kCVPixelBufferPixelFormatTypeKey) : Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
            ]
            
            output.alwaysDiscardsLateVideoFrames = true
            
            if session.canAddOutput(output) {
                session.addOutput(output)
            }
            
            session.commitConfiguration()
            let queue = DispatchQueue(label: "output.queue")
            output.setSampleBufferDelegate(self, queue: queue)
            print("setup delegate")
        } catch {
            print("can't setup session")
        }
    }
    
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
            default:
                break
            }
        }
    }
    
    // Button color changes depending on current status of recognition
    func setOutlineColor(recognition: Bool) {
        
        switch recognition {
            case true:
                
                // change the fill color
                circularOutline.fillColor = UIColor.blue.cgColor
                
                // you can change the stroke color
                circularOutline.strokeColor = UIColor.blue.cgColor
                break
            case false:
                
                // change the fill color
                circularOutline.fillColor = UIColor.clear.cgColor
                
                // you can change the stroke color
                circularOutline.strokeColor = UIColor.clear.cgColor
                break
        }
        
    }
    
    // Set up UI button responses
    @objc func buttonAction(sender: UIButton!) {
        let btnsendtag: UIButton = sender
        if btnsendtag.tag == 1 {
            switch recognize {
                
                // Sometimes this case needs to run twice to execute the dispatchqueue for some reason, can't figure out why but the swipe down method works for getting rid of recognition UI no matter what
                case true:
                    recognize = false
                    setOutlineColor(recognition: recognize)
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
                    setOutlineColor(recognition: recognize)
                    break
                
            }
        }
    }
    
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
        
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
        let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer)
        
        let attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate)
        let ciImage = CIImage(cvImageBuffer: pixelBuffer!, options: attachments as! [String : Any]?)
        
        //leftMirrored for front camera
        let ciImageWithOrientation = ciImage.oriented(forExifOrientation: Int32(UIImageOrientation.leftMirrored.rawValue))
        
        if recognize {
            detectFace(on: ciImageWithOrientation)
        }
    }
        
}

extension ViewController {
    
    func detectFace(on image: CIImage) {
        try? faceDetectionRequest.perform([faceDetection], on: image)
        if let results = faceDetection.results as? [VNFaceObservation] {
            if !results.isEmpty {
                faceLandmarks.inputFaceObservations = results
                detectLandmarks(on: image)
                
                DispatchQueue.main.async {
                    self.shapeLayer.sublayers?.removeAll()
                    for view in self.labelLayer.subviews {
                        view.removeFromSuperview()
                    }
                }
            }
        }
    }
    
    func detectLandmarks(on image: CIImage) {
        try? faceLandmarksDetectionRequest.perform([faceLandmarks], on: image)
        if let landmarksResults = faceLandmarks.results as? [VNFaceObservation] {
            for observation in landmarksResults {
                DispatchQueue.main.async {
                    if let boundingBox = self.faceLandmarks.inputFaceObservations?.first?.boundingBox {
                        let faceBoundingBox = boundingBox.scaled(to: self.view.bounds.size)
                        
                        //different types of landmarks
                        let faceContour = observation.landmarks?.faceContour
                        self.convertPointsForFace(faceContour, faceBoundingBox)
                        
                        let leftEye = observation.landmarks?.leftEye
                        self.convertPointsForFace(leftEye, faceBoundingBox)
                        
                        let rightEye = observation.landmarks?.rightEye
                        self.convertPointsForFace(rightEye, faceBoundingBox)
                        
                        let nose = observation.landmarks?.nose
                        self.convertPointsForFace(nose, faceBoundingBox)
                        
                        let lips = observation.landmarks?.innerLips
                        self.convertPointsForFace(lips, faceBoundingBox)
                        
                        let leftEyebrow = observation.landmarks?.leftEyebrow
                        self.convertPointsForFace(leftEyebrow, faceBoundingBox)
                        
                        let rightEyebrow = observation.landmarks?.rightEyebrow
                        self.convertPointsForFace(rightEyebrow, faceBoundingBox)
                        
                        let noseCrest = observation.landmarks?.noseCrest
                        self.convertPointsForFace(noseCrest, faceBoundingBox)
                        
                        let outerLips = observation.landmarks?.outerLips
                        self.convertPointsForFace(outerLips, faceBoundingBox)
                        
                        DispatchQueue.main.async {
                            self.drawLabel();
                        }
                    }
                }
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
        newLayer.strokeColor = UIColor.red.cgColor
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
    
    
   /* func convert(_ points: UnsafePointer<vector_float2>, with count: Int) -> [(x: CGFloat, y: CGFloat)] {
        var convertedPoints = [(x: CGFloat, y: CGFloat)]()
        for i in 0...count {
            convertedPoints.append((CGFloat(points[i].x), CGFloat(points[i].y)))
        }
        
        return convertedPoints
    }*/
}
