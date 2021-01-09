//
//  TraxyTabBarController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/8/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyTabBarController: UITabBarController {

    var userId : String? = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().barTintColor = THEME_COLOR2
        UITabBar.appearance().tintColor = THEME_COLOR3
        let repo = TraxyRepository.getInstance()
        repo.listenForAuthenticationChanges{ userId in
            if let uid = userId {
                self.userId = uid
                for child in self.children {
                    if let nc = child as? UINavigationController {
                        if let c = nc.children[0]
                          as? TraxyTopLevelViewController {
                            c.userId = self.userId
                        }
                    }
                }
            } else {
                // No user is signed in.
                self.performSegue(withIdentifier: "presentLogin", sender: self)
            }
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    @IBAction func unwindFromSignup(segue: UIStoryboardSegue) {
        // we end up here when the user signs up for a new account.
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
