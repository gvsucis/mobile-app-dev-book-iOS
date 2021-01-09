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

class MainViewController: TraxyBaseViewController, UITableViewDataSource, UITableViewDelegate, AddJournalDelegate {
    
    fileprivate var userId: String? = ""

    @IBOutlet weak var tableView: UITableView!
    var userEmail : String?
    var journals : [Journal]?
    let repo = TraxyRepository.getInstance()
    
    var tableViewData: [(sectionHeader: String, journals: [Journal])]? {
        didSet {
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        repo.listenForAuthenticationChanges { userId in
            if let uid = userId {
                self.userId = uid
                if self.userId != nil {
                    self.repo.listenForJournalUpdates { (journals) in
                        self.journals = journals
                        self.sortIntoSections(journals: self.journals!)
                    }
                }
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.repo.stopListeningForUpdates()
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
        }
    }

    // MARK: - AddJournalDelegate
    func save(journal: Journal) {
        self.repo.saveJournal(journal: journal)
    }
    
}

