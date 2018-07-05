//
//  FrameExtractor.swift
//  HueLights
//
//  Created by Matthias Brock on 05.07.18.
//  Copyright © 2018 Matthias Brock. All rights reserved.
//

import UIKit
import AVFoundation

class AudioFrameExtractor: NSObject {
    private var permissionGranted = false
    private let sessionQueue = DispatchQueue(label: "session queue")
    private let captureSession = AVCaptureSession()
    private let context = CIContext()
    
    weak var delegate: ViewController?
    
    override init() {
        super.init()
        checkPermission()
        sessionQueue.async { [unowned self] in
            self.configureSession()

            self.captureSession.startRunning()
            
            print("[hue] Mic session running")
        }
    }
    
    // MARK: AVSession configuration
    private func checkPermission() {
        switch AVCaptureDevice.authorizationStatus(for: AVMediaType.audio) {
        case .authorized:
            permissionGranted = true
        case .notDetermined:
            requestPermission()
        default:
            permissionGranted = false
        }
    }
    
    private func requestPermission() {
        sessionQueue.suspend()
        AVCaptureDevice.requestAccess(for: AVMediaType.audio) { [unowned self] granted in
            self.permissionGranted = granted
            self.sessionQueue.resume()
        }
    }
    
    private func configureSession() {
        guard permissionGranted else { return }
        
        print("[hue] Configuring camera session")
        
        guard let captureDevice = selectCaptureDevice() else {
            print("[hue] No audio device found")
            return
        }
        guard let captureDeviceInput = try? AVCaptureDeviceInput(device: captureDevice) else { return }
        guard captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        let audioOutput = AVCaptureAudioDataOutput()
        audioOutput.setSampleBufferDelegate(self.delegate, queue: DispatchQueue(label: "AudioQueue"))
        guard captureSession.canAddOutput(audioOutput) else { return }
        captureSession.addOutput(audioOutput)
        
        print("[hue] Audio connection complete")
    }
    
    private func selectCaptureDevice() -> AVCaptureDevice? {
        print("[hue] Selecting capture device")
        
        let audioDeviceDiscovery = AVCaptureDevice.DiscoverySession(deviceTypes: [AVCaptureDevice.DeviceType.builtInMicrophone], mediaType: AVMediaType.audio, position: .unspecified)
        
        return audioDeviceDiscovery.devices.first
    }
    
    func audioFromSampleBuffer(sampleBuffer : CMSampleBuffer) {
        var audioBufferList = AudioBufferList()
        var data = Data()
        var blockBuffer : CMBlockBuffer?
        
        CMSampleBufferGetAudioBufferListWithRetainedBlockBuffer(sampleBuffer, nil, &audioBufferList, MemoryLayout<AudioBufferList>.size, nil, nil, 0, &blockBuffer)
        
        let buffers = UnsafeBufferPointer<AudioBuffer>(start: &audioBufferList.mBuffers, count: Int(audioBufferList.mNumberBuffers))
        
        for audioBuffer in buffers {
            let frame = audioBuffer.mData?.assumingMemoryBound(to: UInt8.self)
            data.append(frame!, count: Int(audioBuffer.mDataByteSize))
        }
    }
}
