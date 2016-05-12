//
//  UITableVIew+Scroll.swift
//  talkingApp
//
//  Created by Jesse on 5/11/16.
//  Copyright © 2016 Jesse. All rights reserved.
//

import Foundation
import UIKit

extension UITableView {
    
    func scrollToBottom() {
        
        if self.numberOfSections > 1 {
            let lastSection = self.numberOfSections - 1
            self.scrollToRowAtIndexPath(NSIndexPath(forRow: self.numberOfRowsInSection(lastSection) - 1, inSection: lastSection), atScrollPosition: .Bottom, animated: true)
        }
        
        else if numberOfRowsInSection(0) > 0 && self.numberOfSections == 1{
           self.scrollToRowAtIndexPath(NSIndexPath(forRow: self.numberOfRowsInSection(0)-1, inSection: 0), atScrollPosition: .Bottom, animated: true)
        }
    }
}