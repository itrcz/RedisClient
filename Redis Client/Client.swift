//
//  Client.swift
//  Redis Client
//
//  Created by Ilya Trikoz on 07/09/2019.
//  Copyright © 2019 Ilya Trikoz. All rights reserved.
//

import Cocoa
import Redis

class Key {
    var name: String
    var key: String? = nil
    var childs: [Key] = []
    func push(_ name: String) {
        childs.append(Key(name))
    }
    init(_ name: String) {
        self.name = name
    }
}

protocol ClientDelegate {
    func set(_ key: String, value: String, expire: TimeInterval?)
}


class Client: NSViewController, NSOutlineViewDataSource, NSOutlineViewDelegate, ClientDelegate {
   
    var currentServer: ServerDataItem? = nil
    var client: RedisClient? = nil
    
    let separator = "_"
    var dataSource: [Key] = []
    var selectedKey: Key? = nil
    var watchTimer: Timer? = nil
    
    @IBOutlet weak var searchTF: NSSearchFieldCell!
    @IBOutlet weak var treeTable: NSOutlineView!
    @IBOutlet weak var statusView: NSButton!
    @IBOutlet weak var watchBtn: NSButton!
    @IBOutlet weak var valueTF: NSTextField!
    @IBOutlet weak var createKeyBtn: NSButton!
    @IBOutlet weak var updateKeyBtn: NSButton!
    @IBOutlet weak var deleteKeyBtn: NSButton!
    @IBOutlet weak var ttlLabel: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        treeTable.delegate = self
        treeTable.dataSource = self
        treeTable.reloadData()
        treeTable.doubleAction = #selector(expandRowOnDoubleClick)
        self.view.window?.tabbingMode = .preferred
    }
    
    override func viewWillAppear() {
        watchTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if (self?.selectedKey == nil) {
                return
            }
            if (self?.watchBtn.state == NSControl.StateValue.off) {
                return
            }
            self?.get(nil)
        }
    }
    
    override func viewWillDisappear() {
        watchTimer?.invalidate()
    }
    
    @objc func expandRowOnDoubleClick() {
        if (treeTable.selectedRow < 0) {
            return
        }
        let item: Key = treeTable.item(atRow: treeTable.selectedRow) as! Key
        
        if (treeTable.isExpandable(item) == true) {
            if (treeTable.isItemExpanded(item) == true) {
                treeTable.collapseItem(item)
            } else {
                treeTable.expandItem(item)
            }
        }
    }
    
    public func setServer(_ server: ServerDataItem) {
        currentServer = server
        client = RC.shared.getClient(host: currentServer!.host, port: nil)
        displayStatus()
        self.loadKeys()
    }
    
    func displayStatus() {
        if (currentServer!.status == -1) {
            statusView.title = "unavailable"
            statusView.image = NSImage(named: NSImage.statusUnavailableName)
        }
        if (currentServer!.status == 1) {
            statusView.title = "available"
            statusView.image = NSImage(named: NSImage.statusAvailableName)
        }
    }
    
    func insertKey(_ name: String) {
        var keyPointer: Key? = nil
        let sks = name.components(separatedBy: separator)
        for sk in sks {
            var shouldPush = true
            for key in (keyPointer?.childs ?? dataSource) {
                if (key.name == sk) {
                    shouldPush = false
                    keyPointer = key
                    break
                }
            }
            if (shouldPush == true) {
                if (keyPointer == nil) {
                    dataSource.append(Key(sk))
                    keyPointer = dataSource.last
                } else {
                    keyPointer!.push(sk)
                    keyPointer = keyPointer!.childs.last
                }
            }
        }
        if (keyPointer != nil) {
            keyPointer!.key = name
        }
    }
    
    func loadKeys() {
        client!.keys() { err, result in
            DispatchQueue.main.async {
                if (err != nil) {
                    return
                }
                self.dataSource = []
                for name in result! {
                    self.insertKey(name)
                }
                self.treeTable.reloadData()
            }
        }
    }
    
    func selectKey(_ key: Key?, index: Int?) {
        selectedKey = key
        if (index != nil) {
            get(index!)
            updateKeyBtn.isEnabled = true
            deleteKeyBtn.isEnabled = true
            valueTF.isEnabled = true
        } else {
            updateKeyBtn.isEnabled = false
            deleteKeyBtn.isEnabled = false
            valueTF.isEnabled = false
            valueTF.stringValue = ""
        }
    }
    
    func get(_ index: Int?) {
        if (selectedKey == nil) {
            return
        }
        client?.get(selectedKey!.key!) { err, result in
            DispatchQueue.main.async {
                self.valueTF.stringValue = ""
                if (result != nil) {
                    self.valueTF.stringValue = result ?? ""
                }
                if (index == nil) {
                    return
                }
                self.treeTable.reloadData(forRowIndexes: IndexSet(integer: index!), columnIndexes: IndexSet(integer: 0))
            }
        }
        client?.ttl(selectedKey!.key!).map { interval in
            let s = Int(interval)
            DispatchQueue.main.async {
                if (s >= 0) {
                    self.ttlLabel.textColor = .orange
                    self.ttlLabel.stringValue = "Record will be removed in \(s) second(s)"
                }
                if (s == -1) {
                    self.ttlLabel.textColor = .green
                    self.ttlLabel.stringValue = "OK"
                }
                if (s == -2) {
                    self.ttlLabel.textColor = .red
                    self.ttlLabel.stringValue = "Record is removed"
                }
            }
        }
    }
    
    func set(_ key: String, value: String, expire: TimeInterval?) {
        client?.set(key, value, expire: TimeInterval(exactly: 1000)) { err, result in
            DispatchQueue.main.async {
                if (err != nil) {
                    return
                }
                if (key != self.selectedKey?.key) {
                    self.insertKey(key)
                    self.treeTable.reloadData()
                } else {
                    self.get(nil)
                }
            }
        }
    }
    
    func del(_ key: String) {
        client?.del(key) { err, result in
            DispatchQueue.main.async {
                if (err != nil) {
                    return
                }
                if (key == self.selectedKey?.key) {
                    self.get(nil)
                }
            }
        }
    }
    
    
    
    @IBAction func reloadKeys(_ sender: NSButton) {
        loadKeys()
    }
    
    @IBAction func createKey(_ sender: NSButton) {
        let createKey = storyboard?.instantiateController(
            withIdentifier: NSStoryboard.SceneIdentifier("CreateKey")) as! CreateKey
        
        createKey.clientDelegate = self
        
        present(createKey, asPopoverRelativeTo: (sender.bounds),of: sender, preferredEdge: NSRectEdge.maxX,behavior: NSPopover.Behavior.transient)
    }
    
    @IBAction func updateKey(_ sender: NSButton) {
        self.set(selectedKey!.key!, value: valueTF.stringValue, expire: nil)
    }
    
    @IBAction func deleteKey(_ sender: NSButton) {
        del((selectedKey?.key)!)
    }
    
    
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if (item == nil) {
            return dataSource.count
        }
        return (item as! Key).childs.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return (item as! Key).childs.count > 0
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if (item != nil) {
            return (item as! Key).childs[index]
        }
        return dataSource[index]
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        
        if let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "key"), owner: nil) as? NSTableCellView {
                let key = (item as! Key)
  
                cell.textField?.stringValue = key.key ?? key.name
                return cell
            }
        return nil
    }

    func outlineViewSelectionDidChange(_ notification: Notification) {
        let index = treeTable.selectedRow
        if (index >= 0) {
            let key = treeTable.item(atRow: index) as! Key
            if (key.childs.count == 0) {
                selectKey(key, index: index)
                return
            }
        }
        self.ttlLabel.textColor = .secondaryLabelColor
        self.ttlLabel.stringValue = "Please select a key"

        selectKey(nil, index: nil)
    }
}

