//
//  ViewController.swift
//  HueLights
//
//  Created by Matthias Brock on 05.07.18.
//  Copyright © 2018 Matthias Brock. All rights reserved.
//

import UIKit
import SwiftyHue
import Gloss
import AVFoundation
import AudioKit

var swiftyHue: SwiftyHue = SwiftyHue();

class ViewController: UIViewController, BridgeFinderDelegate, BridgeAuthenticatorDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var referenceColorLabel: UILabel!
    @IBOutlet weak var referenceAudioLabel: UILabel!
    @IBOutlet weak var activeCaptureLabel: UILabel!
    @IBOutlet weak var activeTestLabel: UILabel!
        
    var videoFrameExtractor: VideoFrameExtractor!
    
    var testToggled = false
    var testTimer: Timer!
    
    var captureToggled = false
    var captureTimer: Timer!
    
    var outputLight: Light!
    
    var tracker: AKFrequencyTracker!

    fileprivate let bridgeAccessConfigUserDefaultsKey = "BridgeAccessConfig"
    
    fileprivate let bridgeFinder = BridgeFinder()
    fileprivate var bridgeAuthenticator: BridgeAuthenticator?
    
    var currentColor: UIColor!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        swiftyHue.enableLogging(true)
        videoFrameExtractor = VideoFrameExtractor()
        videoFrameExtractor.delegate = self
        videoFrameExtractor.imageView = imageView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        let bridgeAccessConfig = readBridgeAccessConfig()
        
        if bridgeAccessConfig != nil {
            initializeApi()
        } else {
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateBridgeAccessController") as! CreateBridgeAccessController
            controller.bridgeAccessCreationDelegate = self;
            
            self.present(controller, animated: false, completion: nil)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        UIApplication.shared.isIdleTimerDisabled = false
        
        if (captureToggled) {
            captureTimer.invalidate()
        }
        
        if (testToggled) {
            testTimer.invalidate()
        }
        
        if (self.outputLight != nil) {
            var lightState = LightState()
            lightState.on = false;
            
            sendLightState(state: lightState)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func startCapture() {
        captureToggled = !captureToggled;
        
        if (captureToggled) {
            self.activeCaptureLabel.isHidden = false
            
            captureTimer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(runCapture), userInfo: nil, repeats: true)
        } else {
            self.activeCaptureLabel.isHidden = true
            
            captureTimer.invalidate()
            
            if (self.outputLight != nil) {
                var lightState = LightState()
                lightState.on = false;
                
                sendLightState(state: lightState)
            }
        }
    }
    
    @IBAction func sendTest() {
        testToggled = !testToggled;
        
        if (testToggled) {
            self.activeTestLabel.isHidden = false
            
            testTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(runTest), userInfo: nil, repeats: true)
        } else {
            self.activeTestLabel.isHidden = true
            
            testTimer.invalidate()
            
            if (self.outputLight != nil) {
                var lightState = LightState()
                lightState.on = false;
                
                sendLightState(state: lightState)
            }
        }
    }
    
    @objc func runTest() {
        var lightState = LightState()
        lightState.on = self.testToggled;
        
        lightState.brightness = Int(arc4random_uniform(254))
        lightState.saturation = Int(arc4random_uniform(254))
        lightState.hue = Int(arc4random_uniform(65535))
        lightState.transitiontime = 1
        
        sendLightState(state: lightState)
    }
    
    @objc func runCapture() {
        let hsba = self.currentColor.hsbColor;
        var lightState = LightState()
        lightState.on = true;
        
        // lightState.brightness = Int(254 * tracker.amplitude * Float(hsba.brightness))
        lightState.brightness = Int(254 * hsba.brightness)
        lightState.saturation = Int(254 * hsba.saturation)
        lightState.hue = Int(65535 * hsba.hue)
        lightState.transitiontime = 1
        
        sendLightState(state: lightState)
    }
    
    func sendLightState(state: LightState) {
        if (self.outputLight != nil) {
            print("[hue] send light state", state.toJSON() as Any)
            
            swiftyHue.bridgeSendAPI.updateLightStateForId((self.outputLight?.identifier)!, withLightState: state) { (errors) in
                print(errors as Any)
            }
        }
    }
    
    func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if (testToggled) {
        } else {
            if (captureOutput is AVCaptureVideoDataOutput) {
                let image = videoFrameExtractor.imageFromSampleBuffer(sampleBuffer: sampleBuffer)
                let color = videoFrameExtractor.getAverageColor(image: image)
                
                DispatchQueue.main.async { [unowned self] in
                    let bgColor: UIColor = color!.copy() as! UIColor
                    
                    self.referenceColorLabel.backgroundColor = bgColor
                    self.referenceAudioLabel.backgroundColor = bgColor.withAlphaComponent(CGFloat(1 - self.tracker.amplitude))
                    self.referenceAudioLabel.text = String(format: "%0.2f", self.tracker.amplitude)
                    
                    self.currentColor = color;
                }
            }
        }
    }
}

extension ViewController {
    func readBridgeAccessConfig() -> BridgeAccessConfig? {
        let userDefaults = UserDefaults.standard
        let bridgeAccessConfigJSON = userDefaults.object(forKey: bridgeAccessConfigUserDefaultsKey) as? JSON
        
        var bridgeAccessConfig: BridgeAccessConfig?
        if let bridgeAccessConfigJSON = bridgeAccessConfigJSON {
            bridgeAccessConfig = BridgeAccessConfig(json: bridgeAccessConfigJSON)
        }
        
        return bridgeAccessConfig
    }
    
    func writeBridgeAccessConfig(bridgeAccessConfig: BridgeAccessConfig) {
        let userDefaults = UserDefaults.standard
        let bridgeAccessConfigJSON = bridgeAccessConfig.toJSON()
        userDefaults.set(bridgeAccessConfigJSON, forKey: bridgeAccessConfigUserDefaultsKey)
    }
}

extension UIColor {
    public struct HSBColor {
        var hue: CGFloat
        var saturation: CGFloat
        var brightness: CGFloat
        var alpha: CGFloat
        
        var uiColor: UIColor {
            get {
                return UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: alpha)
            }
        }
    }
    
    var hsbColor: HSBColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return HSBColor(hue: h, saturation: s, brightness: b, alpha: a)
    }
}

extension ViewController: CreateBridgeAccessControllerDelegate {
    func bridgeAccessCreated(bridgeAccessConfig: BridgeAccessConfig) {
        writeBridgeAccessConfig(bridgeAccessConfig: bridgeAccessConfig)
    }
}

extension ViewController {
    func initializeApi() {
        print("[hue] Init api")
        let bridgeAccessConfig = self.readBridgeAccessConfig()!
        swiftyHue.setBridgeAccessConfig(bridgeAccessConfig)
        swiftyHue.setLocalHeartbeatInterval(0.2, forResourceType: .lights)
        swiftyHue.startHeartbeat();
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.lightChanged), name: NSNotification.Name(rawValue: ResourceCacheUpdateNotification.lightsUpdated.rawValue), object: nil)
        
        swiftyHue.resourceAPI.fetchLights { (result) in
            guard let lights = result.value else {
                print("No lights found at all")
                return
            }
            
            let light = lights.values.first(where: { $0.type == "Extended color light" })
            
            if (light != nil) {
                self.outputLight = light;
                print("Output light found. Nice")
            } else {
                print("NO output light found")
            }
        }
       
        let microphone = AKMicrophone()
        let filter = AKHighPassFilter(microphone, cutoffFrequency: 1, resonance: 0)
        tracker = AKFrequencyTracker(filter)
        let silence = AKBooster(tracker, gain: 0)
        
        AKSettings.audioInputEnabled = true
        AudioKit.output = silence
        
        do {
            try AudioKit.start()
        } catch {
            AKLog("Something went wrong.")
        }
    }
    
    @objc public func lightChanged() {
        // print("[hue] lights Changed")
    }
    
    func bridgeFinder(_ finder: BridgeFinder, didFinishWithResult bridges: [HueBridge]) {
        print(bridges)
        guard let bridge = bridges.first else {
            return
        }
        
        bridgeAuthenticator = BridgeAuthenticator(bridge: bridge, uniqueIdentifier: "example#simulator")
        bridgeAuthenticator!.delegate = self
        bridgeAuthenticator!.start()
    }
    
    func bridgeAuthenticatorDidTimeout(_ authenticator: BridgeAuthenticator) {
        print("[hue] Timeout")
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFailWithError error: NSError) {
        print("[hue] Error while authenticating: \(error)")
    }
    
    func bridgeAuthenticatorRequiresLinkButtonPress(_ authenticator: BridgeAuthenticator, secondsLeft: TimeInterval) {
        print("[hue] Press link button")
    }
    
    func bridgeAuthenticator(_ authenticator: BridgeAuthenticator, didFinishAuthentication username: String) {
        print("[hue] Authenticated, hello \(username)")
    }
}

