//
//  TraxyRespository.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 1/9/21.
//  Copyright © 2021 Jonathan Engelsma. All rights reserved.
//

import Foundation

import Foundation
import Firebase

class TraxyRepository {
    fileprivate static let instance =  TraxyRepository()
    fileprivate var db: Firestore!
    fileprivate var ref: DocumentReference?
    fileprivate var listener: ListenerRegistration?

    var userId: String?
    
    static func getInstance() -> TraxyRepository
    {
        return instance
    }
    
    init() {
        self.db = Firestore.firestore()
    }

    // MARK: Authentication Operations
    func signIn(email: String, password: String, onCompletion: @escaping  (Bool,String?) -> (Void)) {
        Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
            if let _ = user {
                onCompletion(true,nil)
            } else {
                onCompletion(false,error?.localizedDescription ?? "Unknown error.  Please try again later.")
            }
        }
    }
    
    func signUp(email: String, password: String, onCompletion: @escaping  (Bool,String?) -> (Void))
    {
        Auth.auth().createUser(withEmail: email, password: password ) { (user, error) in
            if let _ = user {
                onCompletion(true,nil)
            } else {
                onCompletion(false,error?.localizedDescription ?? "Unknown error.  Please try again later.")
            }
        }
    }
    
    func logout()
    {
        do {
            try Auth.auth().signOut()
            print("Logged out")
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
    }
    
    // MARK: Listener Operations
    func listenForAuthenticationChanges(onChange: @escaping  (String?) -> (Void)) {
        Auth.auth().addStateDidChangeListener { auth, user in
            if let user = user {
                self.userId = user.uid
                self.ref = self.db.collection("user").document(user.uid)
                onChange(self.userId)
            } else {
                // No user is signed in.
                onChange( nil)
            }
        }
        
    }
    
    func listenForJournalUpdates(onChange: @escaping ([Journal]) -> Void) {
        self.listener = self.ref?.collection("journals").addSnapshotListener({ (snapshot, error) in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            var journals = [Journal]()
            for doc in documents {
                let key = doc.documentID
                let name : String? = doc["name"] as! String?
                let location : String?  = doc["address"] as! String?
                let startDateStr  = doc["startDate"] as! String?
                let endDateStr = doc["endDate"] as! String?
                let lat = doc["lat"] as! Double?
                let lng = doc["lng"] as! Double?
                let placeId = doc["placeId"] as! String?

                let journal = Journal(key: key, name: name, location: location,
                        startDate: startDateStr?.dateFromISO8601, endDate: endDateStr?.dateFromISO8601, lat: lat, lng: lng, placeId: placeId)
                journals.append(journal)
            }
            onChange(journals)
        })
    }
    
    func stopListeningForUpdates() {
        if let l = self.listener {
            l.remove()
        }
    }
    
    // MARK: Journal Operations
    func saveJournal(journal: Journal) {
        if let r = self.ref {
            if let k = journal.key {
                let child : DocumentReference? = r.collection("journals").document(k)
                child?.setData(self.toDictionary(vals: journal))
            } else {
                r.collection("journals").addDocument(data: self.toDictionary(vals: journal))
            }
        }
    }
    
    fileprivate func toDictionary(vals: Journal) -> [String:Any] {
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

