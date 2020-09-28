//
//  TraxyBaseViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 9/26/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyBaseViewController: UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
}

class TraxyLoginViewController: TraxyBaseViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = THEME_COLOR2
    }
}

class TraxyNavigationController : UINavigationController {
    override open var preferredStatusBarStyle : UIStatusBarStyle {
        return topViewController?.preferredStatusBarStyle ?? .default
    }
}
