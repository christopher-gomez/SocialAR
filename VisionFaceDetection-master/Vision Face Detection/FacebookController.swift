//
//  FacebookController.swift
//  Vision Face Detection
//
//  Created by Chris Gomez on 11/29/17.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import FacebookCore
import FacebookLogin
import FBSDKLoginKit

class FacebookController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.white
        
        // facebook account login
        let loginButton = LoginButton(readPermissions: [ .publicProfile ])
        loginButton.center = view.center
        
        let navBar: UINavigationBar = UINavigationBar()
        navBar.frame = CGRect(x: 0, y: 20, width: self.view.frame.size.width, height: 400)
        navBar.backgroundColor = UIColor.white;
        let navTitle = UINavigationItem(title: "Facebook Login Page")
        navTitle.rightBarButtonItem = UIBarButtonItem(title: "Done",
                                                      style:.plain,
                                                      target:self,
                                                      action:#selector(done))
        navBar.setItems([navTitle], animated: true)
        self.view.addSubview(navBar)
        self.view.addSubview(loginButton)
        
        loginButton.delegate = self as? LoginButtonDelegate
        
        if AccessToken.current != nil  {
            print("logged in!")
        }
    }
    
    /*********************** FACEBOOK/SERVER METHODS ********************************/
    
    func loginButtonDidCompleteLogin(_ loginButton:LoginButton,result:LoginResult) {
        switch result {
        case .success:
            print("Gage is a bitch")
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
    
    /*********************** END FACEBOOK/SERVER METHODS ********************************/

    
    @objc func done(){
        self.dismiss(animated: true, completion: nil)
    }
}
