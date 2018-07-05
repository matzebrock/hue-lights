//
//  CreateBridgeAccessController.swift
//  HueLights
//
//  Created by Matthias Brock on 05.07.18.
//  Copyright © 2018 Matthias Brock. All rights reserved.
//

import Foundation
import UIKit
import SwiftyHue

public protocol CreateBridgeAccessControllerDelegate: class {
    
    func bridgeAccessCreated(bridgeAccessConfig: BridgeAccessConfig)
}

public class CreateBridgeAccessController: UINavigationController {
    public weak var bridgeAccessCreationDelegate: CreateBridgeAccessControllerDelegate?
    
    func bridgeAccessCreated(bridgeAccessConfig: BridgeAccessConfig) {
        dismiss(animated: true, completion: nil)
        bridgeAccessCreationDelegate?.bridgeAccessCreated(bridgeAccessConfig: bridgeAccessConfig)
    }
}
