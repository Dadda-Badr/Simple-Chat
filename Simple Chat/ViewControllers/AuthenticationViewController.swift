//
//  AuthenticationViewController.swift
//  Simple Chat
//
//  Created by Badr Dadda on 11/10/2019.
//  Copyright © 2019 Adria. All rights reserved.
//

import UIKit
import Firebase

class AuthenticationViewController: UIViewController {

    @IBOutlet weak var mailTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
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
    
    @IBAction func loginAction(_ sender: Any) {
        
        let mail = mailTextField.text
        let pwd = pwdTextField.text
        
        if mail == "" || pwd == "" {
            SCManager.showAlert(title: "Simple Chat", message:"Veuillez remplir tous les champs !", okString: "Ok", cancelString: nil, parent: self, completion: nil)
        }
        else {
            SCManager.addProgressHUDToView(parentView: self.view, title: nil, message: nil)
            Auth.auth().signIn(withEmail: mail!, password: pwd!) { user, error in
                if user == nil {
                if let safeError = error{
                    SCManager.showAlert(title: "Simple Chat", message: safeError.localizedDescription, okString: "Ok", cancelString: nil, parent: self, completion: nil)
                   }
                }
                else {
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let nc = storyboard.instantiateViewController(withIdentifier: "UsersListNavigationController") as! UINavigationController
                    SCManager.switchRootViewController(rootViewController: nc, animated: true, completion: nil)
                    NotificationCenter.default.post(name: Notification.Name("updateInformations"), object: nil)
                }
                SCManager.removeProgressHUDFromView(parentView: self.view)
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

extension AuthenticationViewController: UITextFieldDelegate
{
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == mailTextField {
            pwdTextField.becomeFirstResponder()
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
