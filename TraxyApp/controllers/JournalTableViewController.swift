//
//  JournalTableViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/29/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit
import FirebaseFirestore
import FirebaseStorage
import Firebase
import AVFoundation
import AVKit
import MobileCoreServices
import Kingfisher

class JournalTableViewController: UITableViewController {
    
    var capturedImage : UIImage?
    var captureVideoUrl : URL?
    var captureType : EntryType = .photo

    var journal: Journal!
    var userId : String!
    var entries : [JournalEntry] = []
    var entryToEdit : JournalEntry?

    fileprivate var db: Firestore!
    fileprivate var ref: DocumentReference?
    fileprivate var storageRef : StorageReference?
    fileprivate var listener: ListenerRegistration?

    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        self.clearsSelectionOnViewWillAppear = true
        self.navigationItem.title = self.journal.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.db = Firestore.firestore()
        self.ref = self.db.collection("user").document(self.userId!).collection("journals").document(journal.key!)
        self.registerForFireBaseUpdates()
        self.configureStorage()
    }
    
    func registerForFireBaseUpdates()
    {
        self.listener = self.ref?.collection("entries").addSnapshotListener({ [weak self] (snapshot, error) in
            guard let documents = snapshot?.documents else {
                print("Error fetching documents: \(error!)")
                return
            }
            guard let strongSelf = self else { return }
            var tmpItems = [JournalEntry]()
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

                tmpItems.append(JournalEntry(key: key, type: type, caption: caption, url:
                    url!, thumbnailUrl: thumbnailUrl!, date: dateStr?.dateFromISO8601, lat: lat,
                          lng: lng))
            }
            strongSelf.entries = tmpItems
            strongSelf.entries.sort {$0.date! > $1.date! }
            strongSelf.tableView.reloadData()
        })
    }
    
    func configureStorage() {
        let storageUrl = FirebaseApp.app()?.options.storageBucket
        self.storageRef = Storage.storage().reference(forURL: "gs://" + storageUrl!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if let l = self.listener {
            l.remove()
        }
    }

    @IBAction func addEntryButtonPressed(_ sender: UIBarButtonItem) {
         let alertController = UIAlertController(title: nil, message:
            "What kind of entry would you like to add to your journal?",
            preferredStyle: .actionSheet)
         
         let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
           // TBD ...
         }
         alertController.addAction(cancelAction)
         
         let addTextAction = UIAlertAction(title: "Text Entry", style: .default) {
         (action) in
            self.captureType = .text
                self.capturedImage = nil
                self.performSegue(withIdentifier: "confirmSegue", sender: self)
         }
         alertController.addAction(addTextAction)
         
         let addCameraAction = UIAlertAction(title: "Photo or Video Entry",
         style: .default) { (action) in
            self.displayCameraIfPermitted()
         }
         alertController.addAction(addCameraAction)
         
         let selectCameraRollAction = UIAlertAction(title: "Select from Camera Roll",
         style: .default) { (action) in
            self.displayImagePicker(type: .photoLibrary)
         }
         alertController.addAction(selectCameraRollAction)
         
         let addAudioAction = UIAlertAction(title: "Audio Entry", style: .default) {
         (action) in
           // TBD ...
         }
         alertController.addAction(addAudioAction)
         
         self.present(alertController, animated: true) {
           // TBD ...
         }
    }
    
    @IBAction func imageButtonPressed(_ sender: UIButton) {
           let row = Int(sender.tag)
           let indexPath = IndexPath(row: row, section: 0)
           let cell = self.tableView.cellForRow(at: indexPath) as! JournalEntryTableViewCell
           if let tnImg = cell.thumbnailImage {
               self.capturedImage = tnImg.image
           }
           self.entryToEdit = cell.entry
           if let entry = cell.entry {
               switch(entry.type!) {
                   case .photo:
                   self.performSegue(withIdentifier: "viewPhoto", sender: self)
                   case.video:
                   self.showContentOfUrlWithAVPlayer(url: entry.url)
                   case .audio:
                   self.showContentOfUrlWithAVPlayer(url: entry.url)
                   default: break
               }
           }
    }

    func showContentOfUrlWithAVPlayer(url : String) {
           if url == "" { return}
           let mediaUrl = URL(string: url)
           let player = AVPlayer(url: mediaUrl!)
           let playerViewController = AVPlayerViewController()
           playerViewController.player = player
           self.present(playerViewController, animated: true) {
               playerViewController.player!.play()
           }
    }

    @IBAction func editButtonPressed(_ sender: UIButton) {
           let row = Int(sender.tag)
           print("Row \(row) edit button pressed.")
           let indexPath = IndexPath(row: row, section: 0)
           let cell = self.tableView.cellForRow(at: indexPath) as! JournalEntryTableViewCell
           if let tnImg = cell.thumbnailImage {
               self.capturedImage = tnImg.image
           }
           self.entryToEdit = cell.entry
           self.captureType = (self.entryToEdit?.type)!
           self.performSegue(withIdentifier: "confirmSegue", sender: self)
    }

    func displayCameraIfPermitted() {
        let cameraMediaType = AVMediaType.video
        let cameraAuthorizationStatus =
            AVCaptureDevice.authorizationStatus(for: cameraMediaType)
        
        switch cameraAuthorizationStatus {
        case .denied:
            self.displaySettingsAppAlert()
        case .authorized:
            self.displayImagePicker(type: .camera)
        case .restricted: break
        case .notDetermined:
            // Prompting user for the permission to use the camera.
            AVCaptureDevice.requestAccess(for: cameraMediaType) { granted in
                if granted {
                    DispatchQueue.main.async {
                        self.displayImagePicker(type: .camera)
                    }
                } else {
                    print("Denied access to \\(cameraMediaType)")
                }
            }
        @unknown default:
            print("Error: unexpected status")
        }
    }
    
    func displaySettingsAppAlert()
    {
        let avc = UIAlertController(title: "Camera Permission Required",
                                    message: "You need to provide this app permissions to use your camera for this feature. You can do this by going to your Settings app and goingto Privacy -> Camera", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default ) { action in
            UIApplication.shared.open(NSURL(string: UIApplication.openSettingsURLString)! as URL,
                options: [:], completionHandler: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        avc.addAction(settingsAction)
        avc.addAction(cancelAction)
        
        self.present(avc, animated: true, completion: nil)
    }
    
    func displayImagePicker(type: UIImagePickerController.SourceType)
    {
        let picker = UIImagePickerController()
        picker.allowsEditing = false
        picker.sourceType = type
        picker.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        picker.modalPresentationStyle = .fullScreen
        picker.delegate = self
        self.present(picker, animated: true, completion: nil)
    }

    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "confirmSegue" {
            if let destCtrl = segue.destination as? JournalEntryConfirmationViewController {
                destCtrl.imageToConfirm = self.capturedImage
                destCtrl.delegate = self
                destCtrl.type = self.captureType
                destCtrl.entry = self.entryToEdit  // will be nil on new item
                destCtrl.journal = self.journal
            }
        }  else if segue.identifier == "viewPhoto" {
            if let destCtrl = segue.destination as? PhotoViewController {
                destCtrl.imageToView = self.capturedImage
                destCtrl.captionToView = self.entryToEdit?.caption
            }
        }
    }
}

extension JournalTableViewController : AddJournalEntryDelegate {
    
    func save(entry: JournalEntry) {
        switch(entry.type!) {
            case .photo:
                self.savePhoto(entry: entry)
            case .video:
                self.saveVideo(entry: entry)
            case .text:
                var vals = self.toDictionary(vals: entry)
                vals["url"]  = ""
                _ = self.saveEntryToFireStore(key: entry.key, ref: self.ref, vals: vals)
            case .audio:
                self.saveAudio(entry: entry)
        }
    }
    
    func saveEntryToFireStore(key: String?, ref : DocumentReference?, vals:
                                [String:Any]) -> DocumentReference?
    {
        var child : DocumentReference?
        if let k = key {
            child = ref?.collection("entries").document(k)
            child?.setData(vals)
        } else {
            child = ref?.collection("entries").addDocument(data: vals)
        }
        return child
    }
    
    func toDictionary(vals: JournalEntry) -> [String:Any] {
        return [
            "caption": vals.caption! as NSString,
            "lat": vals.lat! as NSNumber,
            "lng": vals.lng! as NSNumber,
            "date" : NSString(string: (vals.date?.iso8601)!) ,
            "type" : NSNumber(value: vals.type!.rawValue),
            "url" : vals.url as NSString,
            "thumbnailUrl" : vals.thumbnailUrl as NSString
        ]
    }
    
    func saveAudio(entry: JournalEntry) {
        // TODO: stub method, to be completed in next chapter.
    }
    
    func savePhoto(entry: JournalEntry) {
           let vals = self.toDictionary(vals: entry)
           let entryRef = self.saveEntryToFireStore(key: entry.key, ref: self.ref, vals: vals)
           if entry.key == nil {
               self.saveImageToFirebase(imageToSave: self.capturedImage, saveRefClosure: {
               (downloadUrl) in
                   // store the image URL
                   let vals = [
                       "url" : downloadUrl as NSString
                   ]
                entryRef?.setData(vals, merge: true)
               })
           }
     }
    
    func saveImageToFirebase(imageToSave : UIImage?,
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
    
    func saveVideo(entry: JournalEntry) {
        
        let vals = self.toDictionary(vals: entry)
        let entryRef = self.saveEntryToFireStore(key: entry.key, ref: self.ref, vals: vals)
        
        // if we have a nil key, then this is a new entry and we have an video file to save.
        // as well as a thmbnai image.
        if entry.key == nil {
            
            // save captured video
            if let url = self.captureVideoUrl {
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
            self.saveImageToFirebase(imageToSave: self.capturedImage, saveRefClosure: {
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
    
    func saveMediaFileToFirebase(entry: JournalEntry, saveRefClosure: @escaping (String)
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

extension JournalTableViewController : UIImagePickerControllerDelegate,
                        UINavigationControllerDelegate
{
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print("canceled")
        self.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
        didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {
        //let info = convertFromUIImagePickerControllerInfoKeyDictionary(info)
        self.dismiss(animated: true, completion: nil)
        if let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String {
            if mediaType == kUTTypeMovie as String {
                print("got video")
                self.capturedImage = self.thumbnailForVideoAtURL(url: info[UIImagePickerController.InfoKey.mediaURL] as! URL)
                self.captureVideoUrl = info[UIImagePickerController.InfoKey.mediaURL] as? URL
                self.captureType = .video
            } else {
                print("got image")
                self.capturedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage
                self.captureType = .photo
            }
        }
        self.performSegue(withIdentifier: "confirmSegue", sender: self)
    }


    func thumbnailForVideoAtURL(url: URL) -> UIImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try generator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }
    }
}

// MARK: - UITableViewDelegate and UITableViewDataSource
extension JournalTableViewController  {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection
      section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.entries.count
    }
    
    override func tableView(_ tableView: UITableView,
      cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let entry = self.entries[indexPath.row]
        let cellIds = ["NA", "TextCell", "PhotoCell", "AudioCell", "PhotoCell"]
        
        let cell = tableView.dequeueReusableCell(withIdentifier:
          cellIds[entry.type!.rawValue],
          for: indexPath) as! JournalEntryTableViewCell
        
        cell.editButton?.tag = indexPath.row
        if let imgButton = cell.imageButton {
            imgButton.tag = cell.editButton!.tag
        }
        
        cell.setValues(entry: entry)
        if let iv = cell.thumbnailImage {
            iv.image = UIImage(named: "landscape")
        }
        switch(entry.type!) {
        case .photo:
            let url = URL(string: entry.url)
            cell.thumbnailImage.kf.indicatorType = .activity
            cell.thumbnailImage.kf.setImage(with: url)
            cell.playButton.isHidden = true
        case .video:
                let url = URL(string: entry.thumbnailUrl)
                cell.thumbnailImage.kf.indicatorType = .activity
                cell.thumbnailImage.kf.setImage(with: url)
                cell.playButton.isHidden = false
                cell.playButton.tag = indexPath.row
        default: break
        }
        
        return cell
    }
}

