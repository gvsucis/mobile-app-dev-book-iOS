//
//  SignUpViewController.swift
//  TraxyApp
//
//  Created by Jonathan Engelsma on 8/19/20.
//  Copyright © 2020 Jonathan Engelsma. All rights reserved.
//

import UIKit

class SignUpViewController: TraxyBaseViewController {
    @IBOutlet weak var emailField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var verifyPasswordField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailField.delegate = self
        self.passwordField.delegate = self
        self.verifyPasswordField.delegate = self
    }
    
    func validateFields() -> Bool {

        let pwOk = self.isEmptyOrNil(password: self.passwordField.text)
        if !pwOk {
            self.validationErrors += "Password cannot be blank."
        }

        let pwMatch = self.passwordField.text == self.verifyPasswordField.text
        if !pwMatch {
            self.validationErrors += "Passwords do not match."
        }

        let emailOk = self.isValidEmail(emailStr: self.emailField.text)
        if !emailOk {
            self.validationErrors += "Invalid email address."
        }

        return emailOk && pwOk && pwMatch
    }
            
    @IBAction func signupButtonPressed(_ sender: UIButton) {
        if self.validateFields() {
            let repo = TraxyRepository.getInstance()
            repo.signUp(email: self.emailField.text!, password: self.passwordField.text!) {(success, errorMesg) in
                if success {
                    self.performSegue(withIdentifier: "segueToMainFromSignUp", sender: self)
                } else {
                    if let msg = errorMesg {
                        self.reportError(msg: msg)
                    }
                    self.passwordField.text = ""
                    self.verifyPasswordField.text = ""
                    self.passwordField.becomeFirstResponder()
                }
            }
        } else {
            self.passwordField.text = ""
            self.verifyPasswordField.text = ""
            self.passwordField.becomeFirstResponder()
            self.reportError(msg: self.validationErrors)
        }
    }  

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segueToMainFromSignUp" {
            if let destVC = segue.destination.children[0] as? MainViewController {
                destVC.userEmail = self.emailField.text
            }
        }
    }
    
    @IBAction func cancelButtonPressed(_ sender: UIButton) {
       self.dismiss(animated: true, completion: nil)
    }

}

extension SignUpViewController : UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == self.emailField {
            self.passwordField.becomeFirstResponder()
        } else if textField == self.passwordField {
            self.verifyPasswordField.becomeFirstResponder()
        } else {
            if self.validateFields() {
                print(NSLocalizedString("Congratulations!  You entered correct values.", comment: ""))
            }
        }
        return true
    }
}

