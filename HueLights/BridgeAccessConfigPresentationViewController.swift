//
//  BridgeAccessConfigPresentationViewController.swift
//  HueLights
//
//  Created by Matthias Brock on 05.07.18.
//  Copyright © 2018 Matthias Brock. All rights reserved.
//

import Foundation
import UIKit
import SwiftyHue

class BridgeAccessConfigPresentationViewController: UIViewController {
    
    var bridgeAccesssConfig: BridgeAccessConfig!
    
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var bridgeIdLabel: UILabel!
    @IBOutlet var ipLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        usernameLabel?.text = bridgeAccesssConfig.username
        bridgeIdLabel?.text = bridgeAccesssConfig.bridgeId
        ipLabel?.text = bridgeAccesssConfig.ipAddress
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func okButtonTapped(_ sender: AnyObject) {
        (navigationController as! CreateBridgeAccessController).bridgeAccessCreated(bridgeAccessConfig: bridgeAccesssConfig)
    }
}
