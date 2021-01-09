//
//  MainViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 8/19/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit

class MainViewController: TraxyTopLevelViewController, UITableViewDataSource, UITableViewDelegate, JournalEditorDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
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
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
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
        if let coverUrl = journal.coverPhotoUrl {
            if coverUrl != "" {
                let url = URL(string: coverUrl)
                cell.coverImage?.kf.indicatorType = .activity
                cell.coverImage?.kf.setImage(with: url)
            } else {
                cell.coverImage?.image = UIImage(named: "landscape")
            }
        } else {
            cell.coverImage?.image = UIImage(named: "landscape")
        }
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
            if let destVC = segue.destination as? JournalEditorViewController {
                destVC.delegate = self
            }
        } else if segue.identifier == "showJournalSegue" {
            if let destVC = segue.destination as? JournalTableViewController {
                let indexPath = self.tableView.indexPathForSelectedRow
                let values = self.tableViewData?[indexPath!.section]
                destVC.journal  = values?.journals[indexPath!.row]
                destVC.userId = self.userId
                destVC.journalEditorDelegate = self
            }
        }
    }

    // MARK: - JournalEditorDelegate
    func save(journal: Journal) {
        repo.saveJournal(journal: journal)
    }
}

