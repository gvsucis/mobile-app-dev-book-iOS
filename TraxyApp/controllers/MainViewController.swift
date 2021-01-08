//
//  MainViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 8/19/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseFirestore

class MainViewController: TraxyTopLevelViewController, UITableViewDataSource, UITableViewDelegate, AddJournalDelegate {
    
//    fileprivate var db: Firestore!
//    fileprivate var ref: DocumentReference?
//    fileprivate var userId: String? = ""
//    fileprivate var listener: ListenerRegistration?
    
    @IBOutlet weak var tableView: UITableView!
//    var userEmail : String?
//    var journals : [Journal]?
    
    var tableViewData: [(sectionHeader: String, journals: [Journal])]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        self.db = Firestore.firestore()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        Auth.auth().addStateDidChangeListener { auth, user in
//            if let user = user {
//                self.userId = user.uid
//                if self.userId != nil {
//                    self.ref = self.db.collection("user").document(self.userId!)
//                    self.registerForFireBaseUpdates()
//                }
//            }
//        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
//        if let l = self.listener {
//            l.remove()
//        }
    }
    
//    fileprivate func registerForFireBaseUpdates()
//    {
//        self.listener = self.ref?.collection("journals").addSnapshotListener({ (snapshot, error) in
//            guard let documents = snapshot?.documents else {
//                print("Error fetching documents: \(error!)")
//                return
//            }
//
//            self.journals = [Journal]()
//            for j in documents {
//                let key = j.documentID
//                let name : String? = j["name"] as! String?
//                let location : String?  = j["address"] as! String?
//                let startDateStr  = j["startDate"] as! String?
//                let endDateStr = j["endDate"] as! String?
//                let lat = j["lat"] as! Double?
//                let lng = j["lng"] as! Double?
//                let placeId = j["placeId"] as! String?
//                let journal = Journal(key: key, name: name, location: location, startDate: startDateStr?.dateFromISO8601, endDate: endDateStr?.dateFromISO8601, lat: lat, lng: lng, placeId: placeId)
//                self.journals?.append(journal)
//            }
//            self.sortIntoSections(journals: self.journals!)
//        })
//    }
    
    override func journalsDidLoad() {
        if let j = self.journals {
            self.sortIntoSections(journals: j)
        } else {
            self.tableViewData?.removeAll()
        }
    }
    
    func sortIntoSections(journals: [Journal]) {
        
        // We assume the model already provides them ascending date order.
        var currentSection  = [Journal]()
        var futureSection = [Journal]()
        var pastSection = [Journal]()
        
        let today = (Date().short.dateFromShort)!
        for j in journals {
            let endDate = (j.endDate?.short.dateFromShort)!
            let startDate = (j.startDate?.short.dateFromShort)!
            if today <=  endDate && today >= startDate {
                currentSection.append(j)
            } else if today < startDate {
                futureSection.append(j)
            } else {
                pastSection.append(j)
            }
        }
        
        var tmpData: [(sectionHeader: String, journals: [Journal])] = []
        if currentSection.count > 0 {
            tmpData.append((sectionHeader: "CURRENT", journals: currentSection))
        }
        if futureSection.count > 0 {
            tmpData.append((sectionHeader: "FUTURE", journals: futureSection))
        }
        if pastSection.count > 0 {
            tmpData.append((sectionHeader: "PAST", journals: pastSection))
        }
        
        self.tableViewData = tmpData
    }
    
    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.tableViewData?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.tableViewData?[section].journals.count ?? 0
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath)
        -> UITableViewCell
    {
        let cell = self.tableView.dequeueReusableCell(withIdentifier: "FancyCell", for:
                                                        indexPath) as! TraxyMainTableViewCell
        
        guard let journal = tableViewData?[indexPath.section].journals[indexPath.row] else {
            return cell
        }
        
        cell.name?.text = journal.name
        cell.subName?.text = journal.location
        cell.coverImage?.image = UIImage(named: "landscape")
        
        return cell
    }
    
    
    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    {
        return self.tableViewData?[section].sectionHeader
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 200.0
    }
    
    func tableView(_ tableView: UITableView, willDisplayFooterView view: UIView,
                   forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3
    }
    
    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView,
                   forSection section: Int)
    {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.textColor = THEME_COLOR2
        header.contentView.backgroundColor = THEME_COLOR3
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let journal = tableViewData?[indexPath.section].journals[indexPath.row] else {
            return
        }
        print("Selected\(String(describing: journal.name))")
    }
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "addJournalSegue" {
            if let destVC = segue.destination as? AddJournalViewController {
                destVC.delegate = self
            }
        } else if segue.identifier == "showJournalSegue" {
            if let destVC = segue.destination as? JournalTableViewController {
                let indexPath = self.tableView.indexPathForSelectedRow
                let values = self.tableViewData?[indexPath!.section]
                destVC.journal  = values?.journals[indexPath!.row]
                destVC.userId = self.userId
            }
        }
    }

    // MARK: - AddJournalDelegate
    func save(journal: Journal) {
        if let r = self.ref {
            r.collection("journals").addDocument(data: self.toDictionary(vals: journal))
        }
    }

    func toDictionary(vals: Journal) -> [String:Any] {
        return [
            "name": vals.name! as NSString,
            "address": vals.location! as NSString,
            "startDate" : NSString(string: (vals.startDate?.iso8601)!) ,
            "endDate": NSString(string: (vals.endDate?.iso8601)!),
            "lat" : NSNumber(value: vals.lat!),
            "lng" : NSNumber(value: vals.lng!),
            "placeId" : vals.placeId! as NSString
        ]
    }
    
}

