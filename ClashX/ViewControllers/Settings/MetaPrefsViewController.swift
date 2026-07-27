//
//  MetaPrefsViewController.swift
//  ClashX Meta
//
//  Copyright © 2023 west2online. All rights reserved.
//

import Cocoa
import Network

class MetaPrefsViewController: NSViewController {
	// Meta Setting
	@IBOutlet var hideUnselectableButton: NSButton!
	
	@IBAction func hideUnselectable(_ sender: NSButton) {
		var newState = NSControl.StateValue.off
		switch sender.state {
		case .off:
			newState = .mixed
		case .mixed:
			newState = .on
		case .on:
			newState = .off
		default:
			return
		}

		sender.state = newState
		MenuItemFactory.hideUnselectable = newState.rawValue
	}
	
	@IBOutlet var tunDNSTextField: NSTextField!
	@IBAction func tunDNSChanged(_ sender: NSTextField) {
		let ds = sender.stringValue
		guard let _ = IPv4Address(ds) else { return }
		ConfigManager.metaTunDNS = ds
		updateNeedsRestart()
	}
	
	// Dashboard
	@IBOutlet var useSwiftuiButton: NSButton!
	@IBOutlet var useYacdButton: NSButton!
	@IBOutlet var useXDButton: NSButton!
    @IBOutlet var useZashButton: NSButton!
    
    
    @IBAction func switchDashboard(_ sender: NSButton) {
		switch sender {
		case useSwiftuiButton:
			DashboardManager.shared.useSwiftUI = sender.state == .on
		case useYacdButton:
            ConfigManager.webDashboard = .yacd
		case useXDButton:
            ConfigManager.webDashboard = .metacubexd
        case useZashButton:
            ConfigManager.webDashboard = .zashboard
		default:
			break
		}
		initDashboardButtons()
		updateNeedsRestart()
	}
	
	
	
	@IBOutlet var restartTextField: NSTextField!
	
	var prefsSnapshot = [String]()
	
	override func viewDidLoad() {
        super.viewDidLoad()
		// Meta Setting
		hideUnselectableButton.state = .init(rawValue: MenuItemFactory.hideUnselectable)
		
		tunDNSTextField.placeholderString = ConfigManager.defaultTunDNS
		tunDNSTextField.stringValue = ConfigManager.metaTunDNS
		tunDNSTextField.delegate = self
		
		// Dashboard
		initDashboardButtons()
		
		
		// Snapshot
		prefsSnapshot = takePrefsSnapshot()
		restartTextField.isHidden = true
    }
	
	func initDashboardButtons() {
		let useSwiftUI = DashboardManager.shared.useSwiftUI
		let dashboard = ConfigManager.webDashboard
		
        useSwiftuiButton.isEnabled = true
		useSwiftuiButton.state = useSwiftUI ? .on : .off
        
        let buttons = [useYacdButton, useXDButton, useZashButton]
        
        buttons.forEach {
            $0?.state = .off
            $0?.isEnabled = !useSwiftUI
        }
        
        switch dashboard {
        case .yacd:
            useYacdButton.state = .on
        case .metacubexd:
            useXDButton.state = .on
        case .zashboard:
            useZashButton.state = .on
        }
	}
	
	
	func takePrefsSnapshot() -> [String] {
		[
			ConfigManager.metaTunDNS,
            ConfigManager.webDashboard.rawValue
		]
	}
	
	func updateNeedsRestart() {
		let needsRestart = prefsSnapshot != takePrefsSnapshot()
		restartTextField.isHidden = !needsRestart
	}
}

extension MetaPrefsViewController: NSTextFieldDelegate {
	func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool {
		IPv4Address(fieldEditor.string) != nil
	}
}
