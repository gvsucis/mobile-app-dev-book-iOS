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


    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 200
        self.clearsSelectionOnViewWillAppear = true
        //self.navigationItem.title = self.journal.name
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
           // TBD ...
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
    
    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 0
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return 0
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
    
    /*
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reuseIdentifier", for: indexPath)

        // Configure the cell...

        return cell
    }
    */

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */
    
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
        }
    }

}

extension JournalTableViewController : AddJournalEntryDelegate {
    func save(entry: JournalEntry) {
        
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
        /*
         if let mediaType =
            info[convertFromUIImagePickerControllerInfoKey(
                    UIImagePickerController.InfoKey.mediaType)] as? String
         {
            if mediaType == kUTTypeMovie as String {
                print("got video")
                self.capturedImage = self.thumbnailForVideoAtURL(url:
                    info[convertFromUIImagePickerControllerInfoKey(
                        UIImagePickerController.InfoKey.mediaURL)]as! URL)
                self.captureVideoUrl =
                    info[convertFromUIImagePickerControllerInfoKey(
                        UIImagePickerController.InfoKey.mediaURL)] as? URL
                self.captureType = .video
            } else {
                print("got image")
                self.capturedImage =
                    info[convertFromUIImagePickerControllerInfoKey(
                          UIImagePickerController.InfoKey.originalImage)] as? UIImage
                self.captureType = .photo
            }
        }
        self.performSegue(withIdentifier: "confirmSegue", sender: self)
 */
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
