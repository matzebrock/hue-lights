//
//  UITableViewController+Extensions.swift
//  HueLights
//
//  Created by Matthias Brock on 05.07.18.
//  Copyright © 2018 Matthias Brock. All rights reserved.
//

import Foundation
import UIKit

extension UITableViewController {
    func setBackgroundMessage(message: String?) {
        if let message = message {
            // Display a message when the table is empty
            let messageLabel = UILabel()
            
            messageLabel.text = message
            messageLabel.font = UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
            messageLabel.textColor = UIColor.lightGray
            messageLabel.textAlignment = .center
            messageLabel.sizeToFit()
            
            tableView.backgroundView = messageLabel
            tableView.separatorStyle = .none
        }
        else {
            tableView.backgroundView = nil
            tableView.separatorStyle = .singleLine
        }
    }
}
