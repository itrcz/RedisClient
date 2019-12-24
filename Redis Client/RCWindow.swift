//
//  RCWindow.swift
//  Redis Client
//
//  Created by Ilya Trikoz on 07/09/2019.
//  Copyright © 2019 Ilya Trikoz. All rights reserved.
//

import Cocoa
import Redis

class RCWindow: NSWindowController, NSWindowDelegate {
    
    override func windowDidLoad() {
        window?.tabbingMode = .preferred
        window?.toggleTabBar(self)
        window?.delegate = self
    }
  
    override func newWindowForTab(_ sender: Any?) {
        let wc: NSWindowController = self.storyboard?.instantiateInitialController() as! NSWindowController
        wc.window?.windowController = self
        
        let tabbedWindows = NSApplication.shared.mainWindow!.tabbedWindows!
        let lastTabIdx = tabbedWindows.count - 1
        tabbedWindows[lastTabIdx].addTabbedWindow(wc.window!, ordered: .above)
        
        wc.window?.orderFront(self)
    }
}
