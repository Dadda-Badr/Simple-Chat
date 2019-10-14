//
//  CreateAccountViewController.swift
//  Simple Chat
//
//  Created by Badr Dadda on 11/10/2019.
//  Copyright © 2019 Adria. All rights reserved.
//

import UIKit
import Firebase

class CreateAccountViewController: UIViewController {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var confirmPwdTextField: UITextField!
    @IBOutlet weak var scrollView: UIScrollView!
     
    private var activeTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboardNotifications()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        deRegisterKeyboardNotifications()
    }
    
    
    @IBAction func createAccountAction(_ sender: Any) {
        
        let mail = mailTextField.text
        let name = nameTextField.text
        let pwd = pwdTextField.text
        let confirmPwd = confirmPwdTextField.text
        
        if name == "" || mail == "" || pwd == "" || confirmPwd == "" {
            SCManager.showAlert(title: "Simple Chat", message:"Veuillez remplir tous les champs !", okString: "Ok", cancelString: nil, parent: self, completion: nil)
        }
        else if pwd != confirmPwd {
            SCManager.showAlert(title: "Simple Chat", message:"Mot de passe incorrect", okString: "Ok", cancelString: nil, parent: self, completion: nil)
        }
        else {
            SCManager.addProgressHUDToView(parentView: self.view, title: nil, message: nil)
            Auth.auth().createUser(withEmail: mail!, password: pwd!) { user, error in
                if error == nil {
                   self.loginAndSaveUser(mail: mail!, name: name!, pwd: pwd!)
                   SCManager.showAlert(title: "Simple Chat", message:"Votre compte a été creé avec succès", okString: "Ok", cancelString: nil, parent: self, completion: { result in
                      if result {
                         let storyboard = UIStoryboard(name: "Main", bundle: nil)
                         let nc = storyboard.instantiateViewController(withIdentifier: "UsersListNavigationController") as! UINavigationController
                         SCManager.switchRootViewController(rootViewController: nc, animated: true, completion: nil)
                         NotificationCenter.default.post(name: Notification.Name("updateInformations"), object: nil)
                      }
                   })
                }
                else {
                    SCManager.showAlert(title: "Simple Chat", message:error!.localizedDescription, okString: "Ok", cancelString: nil, parent: self, completion:nil)
                }
                SCManager.removeProgressHUDFromView(parentView: self.view)
            }
        }
    }
    
    func loginAndSaveUser(mail : String , name : String, pwd : String)
    {
        Auth.auth().signIn(withEmail: mail, password: pwd)
        Auth.auth().addStateDidChangeListener { (auth, user) in
            if let firebaseUser = Auth.auth().currentUser {
                let changeRequest = firebaseUser.createProfileChangeRequest()
                changeRequest.displayName = self.nameTextField.text!
                changeRequest.commitChanges { error in
                    if error != nil {
                        print("Error commiting changes")
                    }
                    else {

                        let userData = ["email" : mail,"name": name] as [String : Any]
                    Database.database().reference().child("Users").child(firebaseUser.uid).updateChildValues(userData)
                    }
                }
            }
        }
    }
    
    
    //MARK: - Keyboard management
    
    fileprivate func registerKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(AuthenticationViewController.keyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(AuthenticationViewController.keyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    fileprivate func deRegisterKeyboardNotifications() {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification,object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardDidHideNotification,object: nil)
    }
    
    @objc func keyboardWillShow(notification: NSNotification) {
        if let activeTextField = activeTextField {
            
            let info: NSDictionary = notification.userInfo! as NSDictionary
            let value: NSValue = info.value(forKey: UIResponder.keyboardFrameBeginUserInfoKey) as! NSValue
            let keyboardSize: CGSize = value.cgRectValue.size
            let contentInsets: UIEdgeInsets = UIEdgeInsets(top: 0.0, left: 0.0, bottom: keyboardSize.height, right: 0.0)
            scrollView.contentInset = contentInsets
            scrollView.scrollIndicatorInsets = contentInsets
               
            var aRect: CGRect = self.view.frame
            aRect.size.height -= keyboardSize.height
            let activeTextFieldRect: CGRect? = activeTextField.frame
            let activeTextFieldOrigin: CGPoint? = activeTextFieldRect?.origin
            if (!aRect.contains(activeTextFieldOrigin!)) {
                scrollView.scrollRectToVisible(activeTextFieldRect!, animated:true)
            }
        }
    }
     
    @objc func keyboardWillHide(notification: NSNotification) {
        let contentInsets: UIEdgeInsets = .zero
        scrollView.contentInset = contentInsets
        scrollView.scrollIndicatorInsets = contentInsets
    }
}

extension CreateAccountViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == mailTextField {
            pwdTextField.becomeFirstResponder()
        }
        else if textField == pwdTextField  {
            confirmPwdTextField.becomeFirstResponder()
        }
        else {
            self.view.endEditing(true)
        }
        return true
    }
    func textFieldDidBeginEditing(_ textField: UITextField) {
        activeTextField = textField
        scrollView.isScrollEnabled = true
    }
    
    func textFieldDidEndEditing(_ textField: UITextField) {
        activeTextField = nil
        scrollView.isScrollEnabled = false
    }
}

