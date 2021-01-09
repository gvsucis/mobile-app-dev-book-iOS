//
//  JournalTableViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 12/29/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit
import MobileCoreServices
import Kingfisher
import Lightbox

class JournalTableViewController: UITableViewController {
    
    var capturedImage : UIImage?
    var captureVideoUrl : URL?
    var captureType : EntryType = .photo
    
    var journal: Journal!
    var userId : String!
    var entries : [JournalEntry] = []
    var entryToEdit : JournalEntry?
    
    var journalEditorDelegate : JournalEditorDelegate!
    let repo = TraxyRepository.getInstance()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        self.clearsSelectionOnViewWillAppear = true
        self.navigationItem.title = self.journal.name
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let key = self.journal.key {
            repo.listenForJournalEntryUpdates(journalKey: key) { entries in
                self.entries = entries
                self.entries.sort {$0.date! > $1.date! }
                self.tableView.reloadData()
            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        repo.stopListeningForUpdates()
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
            self.performSegue(withIdentifier: "recordAudio", sender: self)
        }
        alertController.addAction(addAudioAction)
        
        self.present(alertController, animated: true) {
            self.entryToEdit = nil
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
                self.showPhoto(image: self.capturedImage, caption: entry.caption)
            case.video:
                self.showContentOfUrlWithAVPlayer(url: entry.url)
            case .audio:
                self.showContentOfUrlWithAVPlayer(url: entry.url)
            default: break
            }
        }
    }
    
    func showPhoto(image: UIImage?, caption: String?)
    {
        guard let img = image, let cap = caption else {
            return
        }
        let images = [
            LightboxImage(
                image: img,
                text: cap
            )
        ]
        let photoCtrl = LightboxController(images: images)
        photoCtrl.dynamicBackground = true
        present(photoCtrl, animated: true, completion: nil)
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
        } else if segue.identifier == "recordAudio" {
            if let destCtrl = segue.destination as? AudioViewController {
                destCtrl.entry = self.entryToEdit // will be nil if new item.
                destCtrl.delegate = self
                destCtrl.journal = self.journal
            }
        } else if segue.identifier == "editJournalSegue" {
            if let destVC = segue.destination as? JournalEditorViewController {
                destVC.delegate = self.journalEditorDelegate
                destVC.journal = self.journal
            }
        }
    }
    
}

// MARK: - JournalEditorDelegate
extension JournalTableViewController : AddJournalEntryDelegate {
    
    func save(entry: JournalEntry) {
        switch(entry.type!) {
        case .photo:
            repo.savePhotoEntry(journalKey: journal.key!, image: self.capturedImage, entry: entry)
        case .video:
            repo.saveVideoEntry(journalKey: journal.key!,
                captureVideoUrl: self.captureVideoUrl,
                videoThumbNail: self.capturedImage,
                entry: entry)
        case .text:
            repo.saveTextEntry(journalKey: journal.key!, entry: entry)
        case .audio:
            repo.saveAudioEntry(journalKey: journal.key!, entry: entry)
        }
    }
}

// MARK: - UIImagePickerControllerDelegate,UINavigationControllerDelegate
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


