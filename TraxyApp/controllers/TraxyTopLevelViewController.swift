//
//  TraxyTopLevelViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/8/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import UIKit

class TraxyTopLevelViewController: TraxyBaseViewController {
    var shouldLoad = true
    var userEmail : String?
    var journals : [Journal]? {
        didSet {
            self.journalsDidLoad()
        }
    }
    
    let repo = TraxyRepository.getInstance()
    
    var userId : String? = "" {
        didSet {
            if userId != nil && userId != "" {
                // pop off any controllers beyond this one.
                if var count = self.navigationController?.children.count
                {
                    if count > 1 {
                        count -= 1
                        for _ in 1...count {
                            _ = self.navigationController?.popViewController(
                                animated: true)
                        }
                    }
                }
                if self.shouldLoad {
                    repo.listenForJournalUpdates { (journals) in
                        self.journals = journals
                    }
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.userId = repo.userId
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        repo.stopListeningForUpdates()
    }
    
    @IBAction func logout() {
        // Note we need not explicitly do a segue as the auth listener on our
        // top level tab bar controller will detect and put up the login.
        repo.logout()
        self.journals?.removeAll()
        self.journals = nil
        self.userEmail = nil
    }

    // Hook that gets called after journals are loaded.
    func journalsDidLoad()
    {
    }
}

