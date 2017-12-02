//
//  TestController.swift
//  Vision Face Detection
//
//  Created by Chris Gomez on 12/1/17.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import UIKit

class TestController: UIViewController {
    
    var image: UIImageView?
    
    let serverButton = UIButton(type: .system)
    
    convenience init(){
        self.init(image: nil)
    }
    
    init(image: UIImage?){
        self.image = UIImageView(image: image)
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        
        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeRight.direction = .right
        self.view.addGestureRecognizer(swipeRight)
        image?.frame = CGRect(x: 0, y:0, width: self.view.frame.size.width, height: 400)
        serverButton.frame = CGRect(x: 0, y: 250, width: self.view.frame.size.width, height: 50)
        self.view.addSubview(serverButton)
        self.view.addSubview(image!)
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
