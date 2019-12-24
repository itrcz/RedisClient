//
//  ServerSettings.swift
//  Redis Client
//
//  Created by Ilya Trikoz on 07/09/2019.
//  Copyright © 2019 Ilya Trikoz. All rights reserved.
//

import Cocoa

class ServerSettings: NSViewController {
    
    var serverListDelegate: ServerListDelegate?
    
    @IBOutlet weak var nameTF: NSTextField!
    @IBOutlet weak var hostTF: NSTextField!
    @IBOutlet weak var portTF: NSTextField!
    @IBOutlet weak var testConnectionBTN: NSButton!
    @IBOutlet weak var testSpinner: NSProgressIndicator!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func testConnection(_ sender: NSButton) {
        self.testConnectionBTN.isEnabled = false
        self.testConnectionBTN.image = NSImage(named: NSImage.statusNoneName)
        testSpinner.startAnimation(sender)
        
        var host = hostTF.stringValue
        if (host.count == 0) {
            host = "127.0.0.1"
        }
        
        RC.shared.test(host: host, port: nil) { ok in
            DispatchQueue.main.async {
                self.testConnectionBTN.isEnabled = true
                self.testSpinner.stopAnimation(sender)
                if (ok) {
                    self.testConnectionBTN.image = NSImage(named: NSImage.statusAvailableName)
                } else {
                    self.testConnectionBTN.image = NSImage(named: NSImage.statusUnavailableName)
                }
            }
        }
    }
    
    @IBAction func save(_ sender: NSButton) {
        var name = nameTF.stringValue
        var host = hostTF.stringValue
        var port = portTF.stringValue
        
        if (name.count == 0) {
            name = "New Server"
        }
        if (host.count == 0) {
            host = "127.0.0.1"
        }
        if (port.count == 0) {
            port = "6379"
        }
        
        serverListDelegate!.saveServer(
            ServerDataItem(
                title: "\(name) (\(host):\(port))",
                name: name,
                host: host,
                port: port,
                status: nil
            )
        )
        
        self.dismiss(sender)
    }
}
