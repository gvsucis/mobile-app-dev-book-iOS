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
    fileprivate var currentDocRef: DocumentReference?
    fileprivate var listener: ListenerRegistration?
    fileprivate var storageRef : StorageReference?
    
    var userId: String?
    
    static func getInstance() -> TraxyRepository
    {
        return instance
    }
    
    init() {
        self.db = Firestore.firestore()
        let storageUrl = FirebaseApp.app()?.options.storageBucket
        self.storageRef = Storage.storage().reference(forURL: "gs://" + storageUrl!)
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
    
    func listenForJournalEntryUpdates(journalKey: String, onChange: @escaping ([JournalEntry]) -> Void) {
        self.listener = self.ref?.collection("journals").document(journalKey).collection("entries").addSnapshotListener({(snapshot, error) in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            
            var entries = [JournalEntry]()
            for entry in documents {
                let key = entry.documentID
                let caption : String? = entry["caption"] as! String?
                var url : String? = entry["url"] as? String
                if url == nil {
                    url = ""
                }
                var thumbnailUrl : String? = entry["thumbnailUrl"] as? String
                if thumbnailUrl == nil {
                    thumbnailUrl = ""
                }
                let dateStr  = entry["date"] as! String?
                let lat = entry["lat"] as! Double?
                let lng = entry["lng"] as! Double?
                let typeRaw = entry["type"] as! Int?
                let type = EntryType(rawValue: typeRaw!)
                
                entries.append(JournalEntry(key: key, type: type, caption: caption, url:
                                                url!, thumbnailUrl: thumbnailUrl!, date: dateStr?.dateFromISO8601, lat: lat,
                                             lng: lng))
            }
            onChange(entries)
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
    
    // MARK: Journal Entry Operations
    func saveTextEntry(journalKey: String, entry: JournalEntry) {
        setCurrentJournal(journalKey: journalKey)
        var vals = self.toDictionary(vals: entry)
        vals["url"]  = ""
        _ = self.saveEntryToFireStore(key: entry.key, vals: vals)
    }
    
    fileprivate func setCurrentJournal(journalKey: String) {
        self.currentDocRef = self.db.collection("user").document(self.userId!).collection("journals").document(journalKey)
    }
    
    fileprivate func saveEntryToFireStore(key: String?, vals: [String:Any]) -> DocumentReference?
    {
        var child : DocumentReference?
        if let k = key {
            child = currentDocRef?.collection("entries").document(k)
            child?.setData(vals)
        } else {
            child = currentDocRef?.collection("entries").addDocument(data: vals)
        }
        return child
    }
    
    fileprivate func toDictionary(vals: JournalEntry) -> [String:Any] {
        var retval =  [
            "caption": vals.caption! as NSString,
            "lat": vals.lat! as NSNumber,
            "lng": vals.lng! as NSNumber,
            "date" : NSString(string: (vals.date?.iso8601)!) ,
            "type" : NSNumber(value: vals.type!.rawValue),
            "url" : vals.url as NSString,
            "thumbnailUrl" : vals.thumbnailUrl as NSString
        ]
        return retval
    }
    
    func saveAudioEntry(journalKey: String, entry: JournalEntry) {
        // TODO: finish in Ch10
    }
    
    
    func savePhotoEntry(journalKey: String, image: UIImage?, entry: JournalEntry) {
        setCurrentJournal(journalKey: journalKey)
        let vals = self.toDictionary(vals: entry)
        let entryRef = self.saveEntryToFireStore(key: entry.key, vals: vals)
        if entry.key == nil {
            self.saveImageToFirebase(imageToSave: image, saveRefClosure: {
                (downloadUrl) in
                // store the image URL
                let vals = [
                    "url" : downloadUrl as NSString
                ]
                entryRef?.setData(vals, merge: true)
            })
        }
    }
    
    fileprivate func saveImageToFirebase(imageToSave : UIImage?,
                             saveRefClosure: @escaping (String) -> ())
    {
        if let image = imageToSave {
            let imageData = image.jpegData(compressionQuality: 0.8)
            let imagePath = "\(self.userId!)/photos/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).jpg"
            let metadata = StorageMetadata()
            metadata.contentType = "image/jpeg"
            if let sr = self.storageRef {
                sr.child(imagePath)
                    .putData(imageData!, metadata: metadata) { (metadata, error) in
                        if let error = error {
                            print("Error uploading: \(error)")
                            return
                        }
                        let imageRef = sr.child(imagePath)
                        imageRef.downloadURL(completion: { (url, error) in
                            if let error = error {
                                // Handle any errors
                                print("Error getting url to uploaded image: \(error)")
                            } else {
                                if let str = url?.absoluteString {
                                    saveRefClosure(str)
                                }
                            }
                        })
                    }
            }
        }
    }
    
    func saveVideoEntry(journalKey: String, captureVideoUrl: URL?, videoThumbNail: UIImage?, entry: JournalEntry) {
        setCurrentJournal(journalKey: journalKey)
        let vals = self.toDictionary(vals: entry)
        let entryRef = self.saveEntryToFireStore(key: entry.key,  vals: vals)
        
        // if we have a nil key, then this is a new entry and we have an video file to save.
        // as well as a thmbnai image.
        if entry.key == nil {
            
            // save captured video
            if let url = captureVideoUrl {
                var newEntry = entry
                newEntry.url = url.absoluteString
                self.saveMediaFileToFirebase(entry: newEntry, saveRefClosure: { (downloadUrl)
                    in
                    
                    // record the URL of the video
                    let vals = [
                        "url" : downloadUrl as NSString
                    ]
                    print("Updating URL video: \(downloadUrl)")
                    entryRef?.setData(vals, merge: true)
                    
                })
            }
            
            // save video's thumbnail image
            self.saveImageToFirebase(imageToSave: videoThumbNail, saveRefClosure: {
                (downloadUrl) in
                
                // record the URL of the thumbnail
                let vals = [
                    "thumbnailUrl" : downloadUrl as NSString
                ]
                print("Updating thumbnail URL : \(downloadUrl)")
                entryRef?.setData(vals, merge: true)
            })
        }
    }
    
    fileprivate func saveMediaFileToFirebase(entry: JournalEntry, saveRefClosure: @escaping (String)
                                    -> () ) {
        
        let type : String = entry.type! == .audio ? "audio" : "video"
        let ext : String = entry.type! == .audio ? "m4a" : "mp4"
        let mime : String = entry.type! == .audio ? "audio/mp4" : "video/mp4"
        
        do {
            
            if  entry.url != ""  {
                let url = URL(string: entry.url)
                let media = try Data(contentsOf: url!)
                print("got data")
                let mediaPath = "\(self.userId!)/\(type)/\(Int(Date.timeIntervalSinceReferenceDate * 1000)).\(ext)"
                let metadata = StorageMetadata()
                metadata.contentType = mime
                if let sr = self.storageRef {
                    sr.child(mediaPath)
                        .putData(media, metadata: metadata) {(metadata, error) in
                            if let error = error {
                                print("Error uploading: \(error)")
                                return
                            }
                            
                            let videoRef = sr.child(mediaPath)
                            videoRef.downloadURL(completion: { (url, error) in
                                if let error = error {
                                    // Handle any errors
                                    print("Error getting url to uploaded video: \(error)")
                                } else {
                                    if let str = url?.absoluteString {
                                        saveRefClosure(str)
                                    }
                                }
                            })
                        }
                }
            }
        } catch {
            print("oops that wasn't good now")
        }
    }
}

