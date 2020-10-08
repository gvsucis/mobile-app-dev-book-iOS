//
//  TraxyBaseViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 9/26/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyBaseViewController: UIViewController {
    
    var validationErrors = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = THEME_COLOR2
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

class TraxyNavigationController : UINavigationController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return .lightContent
    }
}
