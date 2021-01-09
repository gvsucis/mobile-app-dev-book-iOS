//
//  ViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 8/18/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit

class LoginViewController: TraxyBaseViewController {

    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // dismiss keyboard when tapping outside of text fields
        let detectTouch = UITapGestureRecognizer(target: self, action:
        #selector(self.dismissKeyboard))
        self.view.addGestureRecognizer(detectTouch)
                                          
        // make this controller the delegate of the text fields.
        self.emailField.delegate = self
        self.passwordField.delegate = self
    }
    
    @objc func dismissKeyboard() {
      self.view.endEditing(true)
    }

    func validateFields() -> Bool {
        let pwOk = self.isEmptyOrNil(password: self.passwordField.text)
        if !pwOk {
            self.validationErrors += "Password cannot be blank."
        }

        let emailOk = self.isValidEmail(emailStr: self.emailField.text)
        if !emailOk {
            self.validationErrors += "Invalid email address."
        }

        return emailOk && pwOk
    }

    
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        if self.validateFields() {
            print("Congratulations!  You entered correct values.")
            let repo = TraxyRepository.getInstance()
            repo.signIn(email: self.emailField.text!, password: self.passwordField.text!) {(success, errorMesg) in
                if success {
                    self.performSegue(withIdentifier: "segueToMain", sender: self)
                } else {
                    if let msg = errorMesg {
                        self.reportError(msg: msg)
                    }
                    self.passwordField.text = ""
                    self.passwordField.becomeFirstResponder()
                }
            }
        } else {
            self.reportError(msg: self.validationErrors)
        }
    }
    
    @IBAction func logout(segue : UIStoryboardSegue) {
        let repo = TraxyRepository.getInstance()
        repo.logout()
        self.passwordField.text = ""
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMain" {
            if let destVC = segue.destination.children[0] as? MainViewController {
                destVC.userEmail = self.emailField.text
            }
        }
    }
}

extension LoginViewController : UITextFieldDelegate {
  func textFieldShouldReturn(_ textField: UITextField) -> Bool {
    if textField == self.emailField {
      self.passwordField.becomeFirstResponder()
    } else {
      if self.validateFields() {
        print(NSLocalizedString("Congratulations!  You entered correct values.", comment: ""))
      }
    }
    return true
  }
}
