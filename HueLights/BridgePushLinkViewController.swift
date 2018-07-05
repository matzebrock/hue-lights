//
//  BridgePushLinkViewController.swift
//  HueLights
//
//  Created by Matthias Brock on 05.07.18.
//  Copyright © 2018 Matthias Brock. All rights reserved.
//

import Foundation
import UIKit
import SwiftyHue

class BridgePushLinkViewController: UIViewController {
    
    var bridge: HueBridge!;
    var bridgeAuthenticator: BridgeAuthenticator!
    var bridgeAccessConfig: BridgeAccessConfig!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        bridgeAuthenticator = BridgeAuthenticator(bridge: bridge, uniqueIdentifier: "swiftyhue#\(UIDevice.current.name)")
        bridgeAuthenticator.delegate = self;
        bridgeAuthenticator.start()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destController = segue.destination as! BridgeAccessConfigPresentationViewController;
        destController.bridgeAccesssConfig = bridgeAccessConfig;
    }
    
}

extension BridgePushLinkViewController: BridgeAuthenticatorDelegate {
    
    // you should now ask the user to press the link button
    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
        
    }
    
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        self.bridgeAccessConfig = BridgeAccessConfig(bridgeId: "BridgeId", ipAddress: bridge.ip, username: username)
        
        self.performSegue(withIdentifier: "BridgeAccessConfigPresentationViewControllerSegue", sender: self)
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        print(error)
    }
    
    
    
    // user did not press the link button in time, you restart the process and try again
    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        print("[hue] timeout")
    }
}
