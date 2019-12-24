//
//  ServerList.swift
//  Redis Client
//
//  Created by Ilya Trikoz on 07/09/2019.
//  Copyright © 2019 Ilya Trikoz. All rights reserved.
//

import Cocoa

struct ServerDataItem {
    let title: String
    let name: String
    let host: String
    let port: String
    private(set) var status: Int?
    
    
    mutating func setTesting() {
        status = 0
    }
    
    mutating func setOnline(_ online: Bool) {
        if (online) {
            status = 1
        } else {
            status = -1
        }
    }
}

protocol ServerListDelegate {
    func saveServer(_ server: ServerDataItem)
}

class ServerList: NSViewController, NSTableViewDataSource, NSTableViewDelegate, ServerListDelegate {
    
    let storage = UserDefaults.standard
    var dataSource = Array<ServerDataItem>()
    var currentSelectedServer: ServerDataItem? = nil
    
    @IBOutlet var serverContextMenu: NSMenu!
    @IBOutlet weak var connectBtn: NSButton!
    @IBOutlet weak var serverTable: NSTableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        serverTable.delegate = self
        serverTable.dataSource = self
        serverTable.menu = serverContextMenu
        serverTable.doubleAction =  #selector(self.switchToCurrentSelectedServer)
        
        loadData()
        testServers()
    }
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let server = dataSource[row]
        if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "ServerCell"), owner: nil) as? NSTableCellView {
            cell.textField?.stringValue = server.title
            
            cell.imageView?.image = NSImage(named: NSImage.statusNoneName)
            if (server.status == -1) {
                cell.imageView?.image = NSImage(named: NSImage.statusUnavailableName)
            }
            if (server.status == 1) {
                cell.imageView?.image = NSImage(named: NSImage.statusAvailableName)
            }
            return cell
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 25
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        if (serverTable.selectedRow >= 0) {
            currentSelectedServer = dataSource[serverTable.selectedRow]
            connectBtn.isEnabled = true
        } else {
            currentSelectedServer = nil
            connectBtn.isEnabled = false
        }
    }
    
    /*
     calls after save button presed
     */
    func saveServer(_ server: ServerDataItem) {
        dataSource.append(server)
        serverTable.reloadData()
        saveData()
    }
    
    func saveData() {
        var arr = Array<Any>()
        for server in self.dataSource {
            arr.append([
                "name": server.name,
                "host": server.host,
                "port": server.port
            ])
        }
        testServers()
        storage.setValue(arr, forKeyPath: "serverData")
    }
    
    func loadData() {
        let data = storage.array(forKey: "serverData")
        if (data != nil) {
            (data as! Array<Dictionary>).forEach() { item in
                dataSource.append(
                    ServerDataItem(
                        title: "\(item["name"]!) (\(item["host"]!):\(item["port"]!))",
                        name: item["name"]!,
                        host: item["host"]!,
                        port: item["port"]!,
                        status: 0
                    )
                )
            }
            serverTable.reloadData()
        }
    }
    
    func testServers() {
        for i in stride(from: 0, to: self.dataSource.count, by: 1) {
            self.dataSource[i].setOnline(false)
            RC.shared.test(host: self.dataSource[i].host, port: nil) { success in
                DispatchQueue.main.async {
                    if (self.dataSource.count <= i) {
                        return
                    }
                    self.dataSource[i].setOnline(success)
                    self.serverTable.reloadData()
                }
            }
            serverTable.reloadData()
        }
    }
    
    /*
     Add button
     */
    @IBAction func addServer(_ sender: NSButton) {
        let serverSettings = storyboard?.instantiateController(
            withIdentifier: NSStoryboard.SceneIdentifier("ServerSettings")) as! ServerSettings
        serverSettings.serverListDelegate = self
        
        present(serverSettings,asPopoverRelativeTo: (sender.bounds),of: sender, preferredEdge: NSRectEdge.maxY,behavior: NSPopover.Behavior.transient)
    }
    
    @objc func switchToCurrentSelectedServer() {
        if (currentSelectedServer == nil) {
            return
        }
        let client = storyboard?.instantiateController(
            withIdentifier: NSStoryboard.SceneIdentifier("Client")) as! Client
        client.view.frame = (self.view.window?.contentViewController?.view.frame)!
        self.view.window?.title = currentSelectedServer!.title
        self.view.window?.contentViewController = client
        client.setServer(currentSelectedServer!)
    }
    
    @IBAction func connectSever(_ sender: NSButton) {
        switchToCurrentSelectedServer()
    }

    @IBAction func contextMenuConnect(_ sender: Any) {
        switchToCurrentSelectedServer()
    }
    
    @IBAction func contextMenuDelete(_ sender: Any) {
        if (serverTable.selectedRow >= 0) {
            dataSource.remove(at: serverTable.selectedRow)
            serverTable.reloadData()
            saveData()
        }
    }
}

