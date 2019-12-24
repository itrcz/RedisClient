//
//  CreateKey.swift
//  Redis Client
//
//  Created by Ilya Trikoz on 07/09/2019.
//  Copyright © 2019 Ilya Trikoz. All rights reserved.
//

import Cocoa

class CreateKey: NSViewController {
    
    var clientDelegate: ClientDelegate?
    
    @IBOutlet weak var commitBTN: NSButton!
    @IBOutlet weak var busyAI: NSProgressIndicator!
    @IBOutlet weak var keyTF: NSTextField!
    @IBOutlet weak var ttlTF: NSTextField!
    @IBOutlet weak var valueTF: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func commit(_ sender: NSButton) {
        if (keyTF.stringValue.count == 0) {
            return
        }
        
        var ttl: TimeInterval?

        if (ttlTF.intValue > 0) {
            ttl = TimeInterval(ttlTF.intValue)
        }
        
        clientDelegate?.set(keyTF.stringValue, value: valueTF.stringValue, expire: ttl)
        self.dismiss(sender)
    }
}
