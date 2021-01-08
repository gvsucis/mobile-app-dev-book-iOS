//
//  TraxyTopLevelViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/8/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class TraxyTopLevelViewController: TraxyBaseViewController {
    var shouldLoad = true
    var userEmail : String?
    var journals : [Journal]? {
        didSet {
            self.journalsDidLoad()
        }
    }
    
    fileprivate var db: Firestore!
    var ref: DocumentReference?
    fileprivate var listener: ListenerRegistration?
    
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
                self.ref = self.db.collection("user").document(self.userId!)
                if self.shouldLoad {
                    self.registerForFireBaseUpdates()
                }
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.db = Firestore.firestore()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let tbc = self.tabBarController as? TraxyTabBarController {
            self.userId = tbc.userId
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // unregister from listeners here.
        if let l = self.listener {
            l.remove()
        }
    }

    fileprivate func registerForFireBaseUpdates()
    {
        self.listener = self.ref?.collection("journals").addSnapshotListener({ (snapshot, error) in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }

            var tmpItems = [Journal]()
            for j in documents {
                let key = j.documentID
                let name : String? = j["name"] as! String?
                let location : String?  = j["address"] as! String?
                let startDateStr  = j["startDate"] as! String?
                let endDateStr = j["endDate"] as! String?
                let lat = j["lat"] as! Double?
                let lng = j["lng"] as! Double?
                let placeId = j["placeId"] as! String?
                let journal = Journal(key: key, name: name, location: location, startDate: startDateStr?.dateFromISO8601, endDate: endDateStr?.dateFromISO8601, lat: lat, lng: lng, placeId: placeId)
                tmpItems.append(journal)
            }
            self.journals = tmpItems
        })
    }
    
    @IBAction func logout() {
        // Note we need not explicitly do a segue as the auth listener on our
        // top level tab bar controller will detect and put up the login.
        do {
            try Auth.auth().signOut()
            print("Logged out")
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        self.journals?.removeAll()
        self.journals = nil
        self.userEmail = nil
    }

    // Hook that gets called after journals are loaded.
    func journalsDidLoad()
    {
    }
}

