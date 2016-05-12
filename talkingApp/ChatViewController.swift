//
//  ViewController.swift
//  talkingApp
//
//  Created by Jesse on 5/10/16.
//  Copyright © 2016 Jesse. All rights reserved.
//

import UIKit
import CoreData

class ChatViewController: UIViewController {
    
    private let tableView = UITableView(frame: CGRectZero, style: .Grouped)
   // private var messages = [Message]()
    
    private var sections = [NSDate: [Message]]()
    private var dates = [NSDate]()
    
    private var bottomConstriant: NSLayoutConstraint!
    
    var context: NSManagedObjectContext?
    
    private let cellIdentifier = "Cell"
    private let newMessageFeild = UITextView()
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        tableView.scrollToBottom()
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        do {
            let request = NSFetchRequest(entityName: "Message")
            request.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
            if let result = try context?.executeFetchRequest(request) as? [Message] {
                for message in result {
                    addMessage(message)
                }
                //this is using the sort closure $0 is first arguement and $1 is second arguement
                //dates = dates.sort({$0.earlierDate($1) == $0})
            }
        } catch {
            print("could not fetch")
        }
        
        
        tableView.dataSource = self
        tableView.delegate = self
        
        let newMessageArea = UIView()
        newMessageArea.backgroundColor = UIColor.lightGrayColor()
        
        newMessageArea.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(newMessageArea)
        
        newMessageFeild.translatesAutoresizingMaskIntoConstraints = false
        
        newMessageArea.addSubview(newMessageFeild)
        
        newMessageFeild.scrollEnabled = false
        
        let sendButton = UIButton()
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        newMessageArea.addSubview(sendButton)
        
        sendButton.setTitle("Send", forState: .Normal)
        
        sendButton.addTarget(self, action: #selector(ChatViewController.PressedSend(_:)), forControlEvents: .TouchUpInside)
        
        sendButton.setContentHuggingPriority(251, forAxis: .Horizontal)
        sendButton.setContentCompressionResistancePriority(751, forAxis: .Horizontal)
        
        bottomConstriant = newMessageArea.bottomAnchor.constraintEqualToAnchor(view.bottomAnchor)
        bottomConstriant.active = true
        
        let messageContriants: [NSLayoutConstraint] = [
            newMessageArea.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor),
            newMessageArea.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            newMessageFeild.leadingAnchor.constraintEqualToAnchor(newMessageArea.leadingAnchor, constant: 10),
            newMessageFeild.centerYAnchor.constraintEqualToAnchor(newMessageArea.centerYAnchor),
            sendButton.trailingAnchor.constraintEqualToAnchor(newMessageArea.trailingAnchor, constant: -10),
            newMessageFeild.trailingAnchor.constraintEqualToAnchor(sendButton.leadingAnchor, constant: -10),
            
            sendButton.centerYAnchor.constraintEqualToAnchor(newMessageFeild.centerYAnchor),
            
            newMessageArea.heightAnchor.constraintEqualToAnchor(newMessageFeild.heightAnchor, constant: 20)
            
        ]
        
        NSLayoutConstraint.activateConstraints(messageContriants)
        
        tableView.estimatedRowHeight = 44
        
        tableView.registerClass(ChatCell.self, forCellReuseIdentifier: cellIdentifier)
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        let tableViewConstraints: [NSLayoutConstraint] = [
            
            tableView.topAnchor.constraintEqualToAnchor(view.topAnchor),
            
            tableView.bottomAnchor.constraintEqualToAnchor(newMessageArea.topAnchor),
            
            tableView.trailingAnchor.constraintEqualToAnchor(view.trailingAnchor),
            tableView.leadingAnchor.constraintEqualToAnchor(view.leadingAnchor)
            
        ]
        
        NSLayoutConstraint.activateConstraints(tableViewConstraints)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyBoardWillShow(_:)), name: UIKeyboardWillShowNotification, object: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(ChatViewController.keyBoardWillHide(_:)), name: UIKeyboardWillHideNotification, object: nil)
        
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(ChatViewController.handleSingleTap(_:)))
        
        tapRecognizer.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapRecognizer)
    }
    
    
    //This is a helper function to move the message area on top of the keyboard
    func keyBoardWillShow(notification: NSNotification) {
        updateBottomConstraint(notification)
    }
    
    func keyBoardWillHide(notification: NSNotification) {
        updateBottomConstraint(notification)
    }
    
    func handleSingleTap(recognizer: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    func updateBottomConstraint(notification: NSNotification) {
        if let userInfo = notification.userInfo, frame = userInfo[UIKeyboardFrameEndUserInfoKey]?.CGRectValue, animationDuration = userInfo[UIKeyboardAnimationDurationUserInfoKey]?.doubleValue {
            
            let newFrame = view.convertRect(frame, fromView: (UIApplication.sharedApplication().delegate?.window)!)
            
            //get height of the keyboard
            bottomConstriant.constant = newFrame.origin.y - CGRectGetHeight(view.frame)
            
            UIView.animateWithDuration(animationDuration, animations: {
                self.view.layoutIfNeeded()
            })
            tableView.scrollToBottom()
        }
    }
    
    func PressedSend(button: UIButton) {
        
        guard let text = newMessageFeild.text where text.characters.count > 0 else {
            return
        }
        
        guard let context = context else {return}
        guard let message = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: context) as? Message else {
            return
        }
        
        message.text = text
        message.isIncoming = false
        message.timestamp = NSDate()
        
        do {
            try context.save()
        } catch {
            print("Problem occured while saving")
            return
        }
        
        addMessage(message)
        newMessageFeild.text = ""
        tableView.reloadData()
        tableView.scrollToBottom()
        view.endEditing(true)
        
    }
    
    func addMessage(message: Message) {
        
        guard let date = message.timestamp else {
            return
        }
        
        let calender = NSCalendar.currentCalendar()
        //group messages by day
        let startDay = calender.startOfDayForDate(date)
        var messages = sections[startDay]
        if messages == nil {
            dates.append(startDay)
            dates = dates.sort({$0.earlierDate($1) == $0})
            messages = [Message]()
        }
        messages!.append(message)
        messages?.sortInPlace{$0.timestamp!.earlierDate($1.timestamp!) == $0.timestamp!}
        sections[startDay] = messages
        
    }

}



extension ChatViewController: UITableViewDataSource {
    
    func getMessages(section: Int) -> [Message] {
        let date = dates[section]
        return sections[date]!
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return dates.count
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return getMessages(section).count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier, forIndexPath: indexPath) as! ChatCell
        
        let messages = getMessages(indexPath.section)
        let message = messages[indexPath.row]
        cell.messageLabel.text = message.text
        cell.incoming(message.isIncoming)
        cell.separatorInset = UIEdgeInsetsMake(0, tableView.bounds.size.width, 0, 0)
        cell.backgroundColor = UIColor.clearColor()
        
        return cell
    }
    
    func tableView(tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        
        let view = UIView()
        view.backgroundColor = UIColor.clearColor()
        let paddingView = UIView()
        view.addSubview(paddingView)
        
        paddingView.translatesAutoresizingMaskIntoConstraints = false
        
        let dateLabel = UILabel()
        
        paddingView.addSubview(dateLabel)
        dateLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let constraints: [NSLayoutConstraint] = [
            
            paddingView.centerXAnchor.constraintEqualToAnchor(view.centerXAnchor),
            paddingView.centerYAnchor.constraintEqualToAnchor(view.centerYAnchor),
            
            dateLabel.centerXAnchor.constraintEqualToAnchor(paddingView.centerXAnchor),
            dateLabel.centerYAnchor.constraintEqualToAnchor(paddingView.centerYAnchor),
            
            paddingView.heightAnchor.constraintEqualToAnchor(dateLabel.heightAnchor, constant: 5),
            paddingView.widthAnchor.constraintEqualToAnchor(dateLabel.widthAnchor, constant: 10),
            
            view.heightAnchor.constraintEqualToAnchor(paddingView.heightAnchor)
            
        ]
        
        NSLayoutConstraint.activateConstraints(constraints)
        
        //date formater
        
        let formater = NSDateFormatter()
        formater.dateFormat = "MMM dd, YYYY"
        dateLabel.text = formater.stringFromDate(dates[section])
        
        paddingView.layer.cornerRadius = 10
        paddingView.layer.masksToBounds = true
        paddingView.backgroundColor = UIColor(red: 153/255, green: 204/255, blue: 255/255, alpha: 1.0)
        
        return view
    }
    
    func tableView(tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        
        return UIView()
        
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }
    
}

extension ChatViewController: UITableViewDelegate {
    func tableView(tableView: UITableView, shouldHighlightRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return false
    }
    
}

