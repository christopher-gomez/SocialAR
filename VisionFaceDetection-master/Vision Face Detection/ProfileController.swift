//
//  ProfileController.swift
//  Vision Face Detection
//
//  Created by Chris Gomez on 12/4/17.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import UIKit
import FacebookCore
import SwiftSocket

class ProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var userName: String!
    var userProfilePicView: UIImageView!
    var userProfilePic: UIImage!
    var userTakenPic: UIImage?
    let imagePicker = UIImagePickerController()
    let cameraButton = UIButton(type: .custom)
    var rawImageData: Data?
    var imageString: String?

    //------------ Server info --------------//
    let host = "172.31.99.190"
    let port = 5024
    var client: TCPClient?
    //---------------------------------------//

    struct ProfileRequest: GraphRequestProtocol {
        
        var graphPath: String = "/me"
        
        var parameters: [String : Any]? = ["fields": "id, name, gender, relationship_status, birthday, email, picture"]
        
        var accessToken: AccessToken? = AccessToken.current
        
        var httpMethod: GraphRequestHTTPMethod = .GET
        
        var apiVersion: GraphAPIVersion = .defaultVersion
        
        struct Response: GraphResponseProtocol {
            
            var name: String?
            var id: String?
            var gender: String?
            var relationship_status: String?
            var birthday: String?
            var email: String?
            var profilePictureUrl: String?
            
            init(rawResponse: Any?) {
                guard let response = rawResponse as? Dictionary<String, Any> else {
                    return
                }
                
                if let name = response["name"] as? String {
                    self.name = name
                }
                
                if let id = response["id"] as? String {
                    self.id = id
                }
                
                if let gender = response["gender"] as? String {
                    self.gender = gender
                }
                
                if let relationship_status = response["relationship_status"] as? String {
                    self.relationship_status = relationship_status
                }
                
                if let birthday = response["birthday"] as? String {
                    self.birthday = birthday
                }
                
                if let email = response["email"] as? String {
                    self.email = email
                }
                
                if let picture = response["picture"] as? Dictionary<String, Any> {
                    
                    if let data = picture["data"] as? Dictionary<String, Any> {
                        if let url = data["url"] as? String {
                            self.profilePictureUrl = url
                        }
                    }
                }
            }
        }
    }
    
    override func viewDidLoad(){
        super.viewDidLoad()
        self.client = TCPClient(address: host, port: Int32(port))
        let connection = GraphRequestConnection()
        connection.add(ProfileRequest()) { response, result in
            switch result {
            case .success(let response):
                print("profileview graph request")
                print("Custom Graph Request Succeeded: \(response)")
                print("My name is \(response.name!)")
                let pictureURL = "https://graph.facebook.com/\(response.id!)/picture?type=large&return_ssl_resources=1"
                self.userProfilePic = UIImage(data: NSData(contentsOf: URL(string: pictureURL)!)! as Data)
                self.userProfilePicView.image = self.userProfilePic
                self.userName = response.name!
                let name = UILabel(frame: CGRect(x: self.view.frame.midX, y: 290, width: self.view.frame.size.width - 20, height: 100))
                name.center = CGPoint(x: self.view.frame.midX, y: 290)
                name.textAlignment = .center
                name.text = self.userName
                name.textColor = UIColor.white
                name.font = UIFont.preferredFont(forTextStyle: .callout)
                name.font = UIFont(name: "Avenir-Light", size: 24)
                name.lineBreakMode = .byWordWrapping
                name.numberOfLines = 0
                name.adjustsFontSizeToFitWidth = true
                self.view.addSubview(name)
            case .failed(let error):
                print("Custom Graph Request Failed: \(error)")
            }
        }
        connection.start()
        loadData()
    }
    
    func loadData(){
        
        let colors = Colors()
        self.view.backgroundColor = UIColor.clear
        let backgroundLayer = colors.gl
        backgroundLayer?.frame = view.frame
        self.view.layer.insertSublayer(backgroundLayer!, at: 0)
        
        let navBar: UINavigationBar = UINavigationBar()
        navBar.frame = CGRect(x: 0, y: 20, width: self.view.frame.size.width, height: 44)
        navBar.backgroundColor = UIColor.clear
        navBar.setBackgroundImage(UIImage(), for: .default)
        navBar.barStyle = .black
        navBar.shadowImage = UIImage()
        navBar.isTranslucent = true
        let navTitle = UINavigationItem(title: "Profile")
        let button = UIBarButtonItem(title: "Done",
                                     style:.plain,
                                     target:self,
                                     action:#selector(done))
        button.tintColor = UIColor.white
        navTitle.rightBarButtonItem = button
        navBar.setItems([navTitle], animated: true)
        self.view.addSubview(navBar)
        
        let welcomeLabel = UILabel(frame: CGRect(x: self.view.frame.midX, y: 115, width: self.view.frame.size.width - 20, height: 300))
        welcomeLabel.center = CGPoint(x: self.view.frame.midX, y: 115)
        welcomeLabel.text = "Please review your Facebook profile picture."
        welcomeLabel.textColor = UIColor.white
        welcomeLabel.textAlignment = .left
        welcomeLabel.numberOfLines = 0
        welcomeLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        welcomeLabel.font = UIFont(name: "Avenir-Light", size: 25)
        welcomeLabel.lineBreakMode = .byWordWrapping
        welcomeLabel.adjustsFontSizeToFitWidth = true
        self.view.addSubview(welcomeLabel)
        let explanation = UILabel(frame: CGRect(x: self.view.frame.midX, y: 205, width: self.view.frame.size.width - 20, height: 300))
        explanation.center = CGPoint(x: self.view.frame.midX, y: 205)
        explanation.text = "This photo will be used for recognition purposes. \nIf you are not the only person in the photo, or your face is obscured in any way, please take a picture of your face."
        explanation.textColor = UIColor.white
        explanation.textAlignment = .left
        explanation.numberOfLines = 0
        explanation.font = UIFont.preferredFont(forTextStyle: .subheadline)
        explanation.font = UIFont(name: "Avenir-Light", size: 16)
        explanation.lineBreakMode = .byWordWrapping
        explanation.adjustsFontSizeToFitWidth = true
        self.view.addSubview(explanation)
        
        self.userProfilePicView = UIImageView(frame: CGRect(x: view.frame.midX, y: 375, width: 100, height: 100))
        self.userProfilePicView.center = CGPoint(x: self.view.frame.midX, y: 375)
        self.view.addSubview(userProfilePicView)
        
        /*let serverLabel = UILabel(frame: CGRect(x: self.view.frame.midX, y: self.view.frame.maxY - 125, width: self.view.frame.width - 75, height: 100))
        serverLabel.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.maxY - 125)
        serverLabel.text = "Please tap the picture above when it meets the requirements."
        serverLabel.textColor = UIColor.white
        serverLabel.textAlignment = .center
        serverLabel.numberOfLines = 0
        serverLabel.font = UIFont.preferredFont(forTextStyle: .callout)
        serverLabel.font = UIFont(name: "Avenir-Light", size: 25)
        serverLabel.lineBreakMode = .byWordWrapping
        serverLabel.adjustsFontSizeToFitWidth = true
        self.view.addSubview(serverLabel)*/
        
        cameraButton.frame = CGRect(x: self.view.frame.midX, y: self.view.frame.maxY - 50, width: 75, height: 75)
        cameraButton.layer.cornerRadius = 0.5*cameraButton.bounds.size.width
        cameraButton.center = CGPoint(x: self.view.frame.midX, y: self.view.frame.maxY - 50)
        cameraButton.backgroundColor = UIColor.clear
        cameraButton.setBackgroundImage(UIImage(named: "camera")?.imageWithColor(.white), for: .normal)
        cameraButton.addTarget(self, action: #selector(openCameraButton), for: .touchUpInside)
        self.view.addSubview(cameraButton)
    }
    
    @objc func openCameraButton(sender: UIButton) {
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            print("open camera")
            imagePicker.sourceType = .camera
            imagePicker.allowsEditing = false
            imagePicker.delegate = self
            self.present(imagePicker, animated: true, completion: nil)
        }
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        let image = info[UIImagePickerControllerOriginalImage] as! UIImage
        userTakenPic = image
        self.userProfilePicView.image = userTakenPic
        print("selected picture")
        dismiss(animated:true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)    {
        dismiss(animated: true, completion: nil)
    }
    
    @objc func done(){
        let transition = CATransition()
        transition.duration = 0.5
        transition.type = kCATransitionPush
        transition.subtype = kCATransitionFromLeft
        transition.timingFunction = CAMediaTimingFunction(name:kCAMediaTimingFunctionEaseInEaseOut)
        view.window!.layer.add(transition, forKey: kCATransition)
        self.dismiss(animated: false, completion: {
            DispatchQueue.global().async {
                self.contactHost(requestType: 1)
            }
        })
    }
    
    func contactHost(requestType: Int){
        guard let client = client else { return }
        
        switch client.connect(timeout: 10) {
        case .success:
            print("Connected to host \(client.address)")
            switch requestType {
            case 1:
                print("Attempting to send user name...")
                if let response = sendRequest(string: "1\n", using: client) {
                    print("Response: \(response)")
                    if let response = sendRequest(string: userName, using: client) {
                        print("Response: \(response)")
                    }
                } else {
                    print("No response")
                }
                print("Attempting to send user picture...")
                if let response = sendRequest(string: "2\n", using: client) {
                    print("Response: \(response)")
                    if self.userTakenPic == nil {
                        self.rawImageData = UIImagePNGRepresentation(self.userProfilePic) as Data?
                        self.imageString = rawImageData?.base64EncodedString()
                        let length = String(describing: imageString!.count)
                        let lengthString = "\(length)\n"
                        print("Sending user picture string length...")
                        if let response = sendRequest(string: lengthString, using: client) {
                            print("Response: \(response)")
                            print("Sending actual picture...")
                            if let response = sendRequest(string: self.imageString!, using: client) {
                                print("Response: \(response)")
                            } else {
                                print("No response")
                            }
                        } else {
                            print("No response")
                        }
                    } else {
                        self.rawImageData = UIImagePNGRepresentation(self.userTakenPic!) as Data?
                        self.imageString = rawImageData?.base64EncodedString()
                        let length = String(describing: imageString!.count)
                        let lengthString = "\(length)\n"
                        print("Sending user picture string length...")
                        if let response = sendRequest(string: lengthString, using: client) {
                            print("Response: \(response)")
                            print("Sending actual picture...")
                            if let response = sendRequest(string: self.imageString!, using: client) {
                                print("Response: \(response)")
                            } else {
                                print("No response")
                            }
                        } else {
                            print("No response")
                        }
                    }
                } else {
                    print("No response")
                }
                break
            default:
                break
            }
            print("contactHost success")
            break
        case .failure(let error):
            print("contactHost error")
            print(String(describing: error))
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
            print(String(describing: error))
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
