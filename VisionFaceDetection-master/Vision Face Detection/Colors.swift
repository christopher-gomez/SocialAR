//
//  Colors.swift
//  Vision Face Detection
//
//  Created by Chris Gomez on 12/4/17.
//  Copyright © 2017 Droids On Roids. All rights reserved.
//

import Foundation
import UIKit

class Colors {
    
    var gl:CAGradientLayer!
    
    init() {
        let colorTop = UIColor(red:0.99, green:0.27, blue:0.42, alpha:1.0).cgColor
        let colorBottom = UIColor(red:0.25, green:0.37, blue:0.98, alpha:1.0).cgColor
        
        self.gl = CAGradientLayer()
        self.gl.colors = [colorTop, colorBottom]
        self.gl.locations = [0.0, 1.0]
    }
}
