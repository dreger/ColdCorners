//
//  AppDelegate.swift
//  ColdCorners
//
//  Created by Kyle Dreger on 4/7/16.
//  Copyright © 2016 Kyle Dreger. All rights reserved.
//  My personal preference: var defaultHotCorners = ["tl": "2", "tr": "4", "bl": "5", "br": "1"]
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    @IBOutlet weak var window: NSWindow!
    
    var currentHotCorners = ["tl": "1", "tr": "1", "bl": "1", "br": "1"]
    let disabledHotCorners: [String: String] = ["tl": "1", "tr": "1", "bl": "1", "br": "1"]
    
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-2)
    var currentlyEnabled = false
    
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        if let button = statusItem.button {
            button.image = NSImage(named: "StatusBarButtonImageDisabled")
            button.action = #selector(AppDelegate.switchTemp(_:))
        }
        
        currentHotCorners["tl"] = runCommand("/bin/sh", args:"-c", "defaults read com.apple.dock wvous-tl-corner").output[0]
        currentHotCorners["tr"] = runCommand("/bin/sh", args:"-c", "defaults read com.apple.dock wvous-tr-corner").output[0]
        currentHotCorners["bl"] = runCommand("/bin/sh", args:"-c", "defaults read com.apple.dock wvous-bl-corner").output[0]
        currentHotCorners["br"] = runCommand("/bin/sh", args:"-c", "defaults read com.apple.dock wvous-br-corner").output[0]
        print("Current Hot Corners: \(currentHotCorners)")
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
    func switchTemp(sender: AnyObject) {
        
        if currentlyEnabled {
            currentlyEnabled = false
            
            for (location, value) in disabledHotCorners {
                print("Switched to: \(location): \(value)")
                runCommand("/bin/sh", args:"-c", "defaults write com.apple.dock wvous-\(location)-corner -int \(value)")
            }
            
            if let button = statusItem.button {
                button.image = NSImage(named: "StatusBarButtonImageDisabled")
                button.action = #selector(AppDelegate.switchTemp(_:))
            }
        }
        else {
            currentlyEnabled = true
            
            for (location, value) in currentHotCorners {
                runCommand("/bin/sh", args:"-c", "defaults write com.apple.dock wvous-\(location)-corner -int \(value)")
                print("Switched to: \(location): \(value)")
            }
            
            if let button = statusItem.button {
                button.image = NSImage(named: "StatusBarButtonImageEnabled")
                button.action = #selector(AppDelegate.switchTemp(_:))
            }
        }
        runCommand("/bin/sh", args:"-c", "killall Dock")
    }
    
    func runCommand(cmd : String, args : String...) -> (output: [String], error: [String], exitCode: Int32) {
        
        var output : [String] = []
        var error : [String] = []
        
        let task = NSTask()
        task.launchPath = cmd
        task.arguments = args
        
        let outpipe = NSPipe()
        task.standardOutput = outpipe
        let errpipe = NSPipe()
        task.standardError = errpipe
        
        task.launch()
        
        let outdata = outpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String.fromCString(UnsafePointer(outdata.bytes)) {
            string = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            output = string.componentsSeparatedByString("\n")
        }
        
        let errdata = errpipe.fileHandleForReading.readDataToEndOfFile()
        if var string = String.fromCString(UnsafePointer(errdata.bytes)) {
            string = string.stringByTrimmingCharactersInSet(NSCharacterSet.newlineCharacterSet())
            error = string.componentsSeparatedByString("\n")
        }
        
        task.waitUntilExit()
        let status = task.terminationStatus
        
        return (output, error, status)
    }
}

