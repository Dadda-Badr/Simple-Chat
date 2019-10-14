//
//  UsersListViewController.swift
//  Simple Chat
//
//  Created by Badr Dadda on 11/10/2019.
//  Copyright © 2019 Adria. All rights reserved.
//

import UIKit
import Firebase

class UsersListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private var listUsers : [NSDictionary] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(updateViewControllerInformations(notification:)), name: Notification.Name("updateInformations"), object: nil)
        
        tableView.register(UINib(nibName: "UserCell", bundle: nil), forCellReuseIdentifier: "userCell")
        tableView.tableFooterView = UIView()
        
        if Auth.auth().currentUser != nil
        {
            getListUsers()
            getCurrentUsername()
        }
    }
    
    func getCurrentUsername() {
        guard let uid = Auth.auth().currentUser?.uid else {
                   return
        }
        let userRef = Database.database().reference().child("Users").child(uid)
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
           guard let dictionary = snapshot.value as? [String:Any] else {
               return
           }
           let appDelegate = UIApplication.shared.delegate as! AppDelegate
           appDelegate.currentUser = dictionary as Dictionary<String, AnyObject> 
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        checkUserSession()
    }
    
    @objc func updateViewControllerInformations(notification: NSNotification) {
        getListUsers()
        getCurrentUsername()
    }
    
    func getListUsers()
    {
        SCManager.addProgressHUDToView(parentView: self.view, title: nil, message: nil)
        let ref = Database.database().reference()
        ref.child("Users").observe(.childAdded, with: { (snapshot) in
            if snapshot.exists()
            {
                if let value = snapshot.value as? [String: Any] {
                    if(Auth.auth().currentUser!.uid != snapshot.key) {
                        let dict = NSMutableDictionary()
                        dict.setObject(snapshot.key, forKey:"firebaseId" as NSCopying)
                        dict.setObject(value["name"]!,forKey: "username" as NSCopying)
                        dict.setObject(value["email"]!,forKey: "mail" as NSCopying)
                        self.listUsers.append(dict)
                        self.tableView.reloadData()
                    }
                }
            }
            SCManager.removeProgressHUDFromView(parentView: self.view)
        })
    }
    
    
    func checkUserSession()
    {
        if Auth.auth().currentUser == nil
        {
            let storyboard = UIStoryboard(name: "Auth", bundle: nil)
            let nc = storyboard.instantiateViewController(withIdentifier: "AuthenticationNavigationController") as! UINavigationController
            SCManager.switchRootViewController(rootViewController: nc, animated: true, completion: nil)
        }
    }

    @IBAction func logoutAction(_ sender: Any) {
        
        let alert = UIAlertController(title:NSLocalizedString("Simple Chat", comment: ""), message: NSLocalizedString("Voulez-vous vraiment vous déconnecter ?", comment: ""), preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: NSLocalizedString("Se déconnecter", comment: ""), style: .destructive, handler: { action in
            try! Auth.auth().signOut()
            let storyboard = UIStoryboard(name: "Auth", bundle: nil)
            let nc = storyboard.instantiateViewController(withIdentifier: "AuthenticationNavigationController") as! UINavigationController
                 SCManager.switchRootViewController(rootViewController: nc, animated: true, completion: nil)
        }))
        
        alert.addAction(UIAlertAction(title: NSLocalizedString("Retour", comment: ""), style: .cancel, handler: { action in
            
        }))
        self.present(alert, animated: true)
    }
}


extension UsersListViewController : UITableViewDelegate,UITableViewDataSource
{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if listUsers.count == 0 {
            self.tableView.setEmptyMessage("Liste des utilisateurs vide.")
        }
        else {
            self.tableView.restore()
        }
        
        return listUsers.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let user = listUsers[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell") as! UserCell
        
        cell.labUsername.text = user["username"] as? String
        cell.labMail.text = user["mail"] as? String
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let chatVC = ChatViewController()
        let user = listUsers[indexPath.row]
        chatVC.user = user as? Dictionary<String, Any>
        self.navigationController?.show(chatVC, sender: self)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
