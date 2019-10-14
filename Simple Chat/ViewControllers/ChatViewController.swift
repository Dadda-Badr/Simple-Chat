//
//  ChatViewController.swift
//  Simple Chat
//
//  Created by Badr Dadda on 11/10/2019.
//  Copyright © 2019 Adria. All rights reserved.
//

import UIKit
import MessengerKit
import Firebase

class ChatViewController: MSGMessengerViewController {
    
    private var correspondent : MSGUser?
    private var writer : MSGUser?
    private var id = 100
    private var messages: [[MSGMessage]] = []
    
    var user : Dictionary <String,Any>!
    
    override var style: MSGMessengerStyle {
        var style = MessengerKit.Styles.iMessage
        style.inputPlaceholder = ""
        return style
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = user["username"] as? String
        dataSource = self
        delegate = self
        
        var currentUsername = ""
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        if let currentUser = appDelegate.currentUser {
            currentUsername = currentUser["name"] as! String
        }
        else {
            currentUsername = ""
        }
        correspondent = ChatUser(displayName: user["username"] as! String, avatar: nil, avatarUrl: nil, isSender: false)
        writer = ChatUser(displayName: currentUsername, avatar: nil, avatarUrl:nil, isSender: true)
        
        buildMSGList()
    }
    
    func buildMSGList()
    {
        var message : MSGMessage!
        
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid)
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
      
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("messages").child(messageId)
            messageRef.observeSingleEvent(of: .value, with: { (snapshot) in

                guard let dictionary = snapshot.value as? [String:Any] else {
                    return
                }
                
                var partnerStr = ""
                let fromId = dictionary["fromId"]  as! String
                if fromId == Auth.auth().currentUser?.uid {
                   partnerStr = "toId"
                }
                else {
                   partnerStr = "fromId"
                }

                let correspondentId = self.user["firebaseId"] as! String
                let msgCorrespondentId = dictionary[partnerStr] as! String
                if correspondentId == msgCorrespondentId
                {
                    let timestamp = dictionary["timestamp"] as! NSNumber
                    let date = Date(timeIntervalSince1970: TimeInterval(truncating: timestamp))
                    if fromId == uid {
                        message = MSGMessage(id: self.id, body: .text(dictionary["text"] as! String), user: self.writer!, sentAt: date)
                    }
                    else {
                        message = MSGMessage(id: self.id, body: .text(dictionary["text"] as! String), user: self.correspondent!, sentAt: date)
                    }
                  
                    self.insert(message)
                    self.id += 1
                }
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        collectionView.scrollToBottom(animated: false)
    }
    
    override func inputViewPrimaryActionTriggered(inputView: MSGInputView) {
        sendMessage(userMessage : inputView.message)
        inputView.resignFirstResponder()
    }
    
    func sendMessage(userMessage : String) {
       
        let ref =  Database.database().reference().child("messages")
        let childRef = ref.childByAutoId()
        let fromId = Auth.auth().currentUser!.uid
        guard let toId = user["firebaseId"] as? String else {
            return
        }

        let timestamp = Int(NSDate().timeIntervalSince1970)
        let msgData = ["toId":toId,"fromId":fromId,"text":userMessage,"timestamp":timestamp] as [String : Any]
        
        childRef.updateChildValues(msgData) { (error, reference) in
            if error != nil {
                print(error!.localizedDescription)
                return
            }
            
            guard let messageId = childRef.key else {
                return
            }
            
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId)
            userMessageRef.updateChildValues([messageId: 1])
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId)
            recipientUserMessagesRef.updateChildValues([messageId: 1])
        }
    }
    
    override func insert(_ message: MSGMessage) {
        
        collectionView.performBatchUpdates({
            if let lastSection = self.messages.last, let lastMessage = lastSection.last, lastMessage.user.displayName == message.user.displayName  /*,
               Calendar.current.dateComponents([.hour], from: lastMessage.sentAt, to: message.sentAt).hour! < 1 */{
                self.messages[self.messages.count - 1].append(message)
                
                let sectionIndex = self.messages.count - 1
                let itemIndex = self.messages[sectionIndex].count - 1
                self.collectionView.insertItems(at: [IndexPath(item: itemIndex, section: sectionIndex)])
                
            } else {
                self.messages.append([message])
                let sectionIndex = self.messages.count - 1
                self.collectionView.insertSections([sectionIndex])
            }
        }, completion: { (_) in
            self.collectionView.scrollToBottom(animated: true)
            //self.collectionView.layoutTypingLabelIfNeeded()
        })
        
    }
    
    override func insert(_ messages: [MSGMessage], callback: (() -> Void)? = nil) {
        
        collectionView.performBatchUpdates({
            for message in messages {
                if let lastSection = self.messages.last, let lastMessage = lastSection.last, lastMessage.user.displayName == message.user.displayName {
                    self.messages[self.messages.count - 1].append(message)
                    
                    let sectionIndex = self.messages.count - 1
                    let itemIndex = self.messages[sectionIndex].count - 1
                    self.collectionView.insertItems(at: [IndexPath(item: itemIndex, section: sectionIndex)])
                    
                } else {
                    self.messages.append([message])
                    let sectionIndex = self.messages.count - 1
                    self.collectionView.insertSections([sectionIndex])
                }
            }
        }, completion: { (_) in
            self.collectionView.scrollToBottom(animated: false)
            //self.collectionView.layoutTypingLabelIfNeeded()
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                callback?()
            }
        })
        
    }
    
}

// MARK: - MSGDataSource

extension ChatViewController: MSGDataSource {
    
    func numberOfSections() -> Int {
        return messages.count
    }
    
    func numberOfMessages(in section: Int) -> Int {
        return messages[section].count
    }
    
    func message(for indexPath: IndexPath) -> MSGMessage {
        return messages[indexPath.section][indexPath.item]
    }
    
    func footerTitle(for section: Int) -> String? {
        let date = messages[section].last?.sentAt
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "GMT+1")
        dateFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "dd/MM - HH:mm"
        let strDate = dateFormatter.string(from: date!)
        return strDate
    }
    
    func headerTitle(for section: Int) -> String? {
        return messages[section].first?.user.displayName
    }
    
}

// MARK: - MSGDelegate

extension ChatViewController: MSGDelegate {
    
    func linkTapped(url: URL) {
        print("Link tapped:", url)
    }
    
    func avatarTapped(for user: MSGUser) {
        print("Avatar tapped:", user)
    }
    
    func tapReceived(for message: MSGMessage) {
        print("Tapped: ", message)
    }
    
    func longPressReceieved(for message: MSGMessage) {
        print("Long press:", message)
    }
    
    func shouldDisplaySafari(for url: URL) -> Bool {
        return true
    }
    
    func shouldOpen(url: URL) -> Bool {
        return true
    }
    
}
