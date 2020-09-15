//
//  AppDelegate.swift
//  What's Playing
//
//  Created by Phillip Key on 9/14/20.
//  Copyright © 2020 Phillip Key. All rights reserved.
//

import Cocoa
import SwiftUI
import CoreAudio

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

    var window: NSWindow!
    var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Create the SwiftUI view that provides the window contents.
        // let contentView = ContentView()
        
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        
        guard let button = statusItem?.button else {
            print("status bar item failed. Remove some items from the menu bar")
            NSApp.terminate(nil)
            return
        }
        
        getSongInfo()
        let timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(getSongInfo), userInfo: nil, repeats: true)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    @objc
    func getSongInfo() {
        // Load framework
        let bundle = CFBundleCreate(kCFAllocatorDefault, NSURL(fileURLWithPath: "/System/Library/PrivateFrameworks/MediaRemote.framework"))

        // Get a Swift function for MRMediaRemoteGetNowPlayingInfo
        guard let MRMediaRemoteGetNowPlayingInfoPointer = CFBundleGetFunctionPointerForName(bundle, "MRMediaRemoteGetNowPlayingInfo" as CFString) else { return }
        typealias MRMediaRemoteGetNowPlayingInfoFunction = @convention(c) (DispatchQueue, @escaping ([String: Any]) -> Void) -> Void
        let MRMediaRemoteGetNowPlayingInfo = unsafeBitCast(MRMediaRemoteGetNowPlayingInfoPointer, to: MRMediaRemoteGetNowPlayingInfoFunction.self)
        
        // Get a Swift function for MRNowPlayingClientGetBundleIdentifier
        guard let MRNowPlayingClientGetBundleIdentifierPointer = CFBundleGetFunctionPointerForName(bundle, "MRNowPlayingClientGetBundleIdentifier" as CFString) else { return }
        typealias MRNowPlayingClientGetBundleIdentifierFunction = @convention(c) (AnyObject?) -> String
        let MRNowPlayingClientGetBundleIdentifier = unsafeBitCast(MRNowPlayingClientGetBundleIdentifierPointer, to: MRNowPlayingClientGetBundleIdentifierFunction.self)
        
        // Get song info
        MRMediaRemoteGetNowPlayingInfo(DispatchQueue.main, { (information) in
            let artist = information["kMRMediaRemoteNowPlayingInfoArtist"] as! String? ?? ""
            let title = information["kMRMediaRemoteNowPlayingInfoTitle"] as! String? ?? ""
            guard let button = self.statusItem?.button else {
                   print("status bar item failed. Remove some items from the menu bar")
                   NSApp.terminate(nil)
                   return
               }
            if (artist == "" && title == "") {
                button.title = ""
            } else {
                button.title = artist + " - " + title
            }
        
        // Get bundle identifier
        let _MRNowPlayingClientProtobuf: AnyClass? = NSClassFromString("_MRNowPlayingClientProtobuf")
        let handle : UnsafeMutableRawPointer! = dlopen("/usr/lib/libobjc.A.dylib", RTLD_NOW)
        let object = unsafeBitCast(dlsym(handle, "objc_msgSend"), to:(@convention(c)(AnyClass?,Selector?)->AnyObject).self)(_MRNowPlayingClientProtobuf,Selector("a"+"lloc"))
        unsafeBitCast(dlsym(handle, "objc_msgSend"), to:(@convention(c)(AnyObject?,Selector?,Any?)->Void).self)(object,Selector("i"+"nitWithData:"),information["kMRMediaRemoteNowPlayingInfoClientPropertiesData"] as AnyObject?)
        NSLog("%@", MRNowPlayingClientGetBundleIdentifier(object))
        dlclose(handle)
        })
    }
}

