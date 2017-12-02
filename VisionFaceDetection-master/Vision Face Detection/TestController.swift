//
//  TestController.swift
//  Vision Face Detection
//
//  Created by Chris Gomez on 12/1/17.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import UIKit
import SwiftSocket

class TestController: UIViewController {
    
    var imageView: UIImageView?
    let imageLayer = UIView()
    var image: UIImage?
    var rawImageData: Data?
    var imageString: String?
    
    let serverButton = UIButton(type: UIButtonType.roundedRect)
    var textView: UITextView?
    
    //------------ Server info --------------//
    let host = "apple.com"
    let port = 80
    var client: TCPClient?
    //---------------------------------------//
    
    convenience init(){
        self.init(image: nil)
    }
    
    init(image: UIImage?){
        self.image = image
        self.imageView = UIImageView(image: image)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        print("deinit")
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        self.client = TCPClient(address: host, port: Int32(port))
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        serverButton.frame = CGRect(x: self.view.frame.midX, y: 600, width: 200, height: 50)
        serverButton.center = CGPoint(x: self.view.frame.midX, y: 600)
        serverButton.backgroundColor = UIColor.clear
        serverButton.layer.cornerRadius = 5
        serverButton.layer.borderWidth = 2
        serverButton.layer.borderColor = UIColor.magenta.cgColor
        serverButton.setTitle("Contact Server", for: .normal)
        serverButton.addTarget(self, action: #selector(contactHost), for: .touchUpInside)
        self.view.addSubview(serverButton)
        self.textView = UITextView(frame: CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 500))
        self.view.addSubview(self.textView!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        imageView?.frame = CGRect(x: 0, y:0, width: self.view.frame.size.width, height: 500)
        self.imageLayer.addSubview(imageView!)
        self.view.addSubview(imageLayer)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        self.image = nil
        self.imageView = nil
    }
    
    @objc func contactHost(sender: UIButton!){
        self.imageLayer.removeFromSuperview()
        
        guard let client = client else { return }
        
        switch client.connect(timeout: 10) {
        case .success:
            appendToTextField(string: "Connected to host \(client.address)")
            if let response = sendRequest(string: "GET / HTTP/1.0\r\n\r\n", using: client) {
                appendToTextField(string: "contactHost success")
                appendToTextField(string: "Response: \(response)")
            } else {
                appendToTextField(string: "No response")
            }
            break
        case .failure(let error):
            appendToTextField(string: "contactHost error")
            appendToTextField(string: String(describing: error))
            break
        }
        appendToTextField(string: "contactHost complete")
    }
    
    private func sendRequest(string: String, using client: TCPClient) -> String? {
        appendToTextField(string: "Sending data ... ")
        
        switch client.send(string: string) {
        case .success:
            appendToTextField(string: "sendRequest success")
            return readResponse(from: client)
        case .failure(let error):
            appendToTextField(string: "sendRequest error")
            appendToTextField(string: String(describing: error))
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
    
    private func appendToTextField(string: String) {
        print(string)
        self.textView?.text = textView?.text.appending("\n\(string)")
    }
    
    
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        // if the user swipes in any direction
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {
            
            // which direction
            switch swipeGesture.direction {
                
            case UISwipeGestureRecognizerDirection.right:
                let transition = CATransition()
                transition.duration = 0.5
                transition.type = kCATransitionPush
                transition.subtype = kCATransitionFromLeft
                transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
                view.window!.layer.add(transition, forKey: kCATransition)
                self.dismiss(animated: false, completion: nil)
                break
            default:
                break
            }
        }
    }
}
