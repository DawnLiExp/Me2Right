//
//  FinderSync.swift
//  FinderSyncExtension
//
//  Created by me2 on 2025/5/20.
//

import Cocoa
import FinderSync

class FinderSync: FIFinderSync {
    override init() {
        super.init()
        // Log initialization details for debugging
        NSLog("FinderSyncExtension initialized from %@, bundle ID: %@", Bundle.main.bundlePath as NSString, Bundle.main.bundleIdentifier ?? "unknown")
        
        // Set up monitoring for all mounted volumes, including the system root
        let fm = FileManager.default
        var urls = Set<URL>()
        urls.insert(URL(fileURLWithPath: "/")) // Include the system root directory
        if let volumeURLs = fm.mountedVolumeURLs(includingResourceValuesForKeys: nil, options: []) {
            for vol in volumeURLs {
                urls.insert(vol) // Add each mounted volume to the monitored set
            }
        }
        FIFinderSyncController.default().directoryURLs = urls
        
        // Log the directories being monitored for verification
        let monitoredURLs = FIFinderSyncController.default().directoryURLs ?? []
        NSLog("Monitoring directories: %@", monitoredURLs.map { $0.path } as NSArray)
    }
    
    // MARK: - Primary Finder Sync protocol methods
    
    override func beginObservingDirectory(at url: URL) {
        // Called when Finder starts displaying the contents of a directory
        NSLog("beginObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    override func endObservingDirectory(at url: URL) {
        // Called when Finder stops displaying the contents of a directory
        NSLog("endObservingDirectoryAtURL: %@", url.path as NSString)
    }
    
    // MARK: - Context menu support
    
    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        // Initialize an empty context menu
        let menu = NSMenu(title: "")
    
        // Add menu items only for contextual menus (for items or containers)
        if menuKind == .contextualMenuForItems || menuKind == .contextualMenuForContainer {
            // Retrieve the currently targeted directory in Finder
            let targetURL = FIFinderSyncController.default().targetedURL()
        
            // Exit early if no target URL is available
            guard let targetURL = targetURL else {
                return menu
            }
        
            // Verify if the target is a directory
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(atPath: targetURL.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                // Create a top-level menu item for "New File" using localized string
                let newFileMenuItem = NSMenuItem(title: NSLocalizedString("New File", comment: "Menu item for creating a new file"), action: nil, keyEquivalent: "")
            
                // Create a submenu for file type options
                let submenu = NSMenu()
            
                // Add a "Text File" option to the submenu using localized string
                let textFileMenuItem = NSMenuItem(title: NSLocalizedString("Text File", comment: "Submenu item for creating a text file"), action: #selector(createTextFile(_:)), keyEquivalent: "")
                submenu.addItem(textFileMenuItem)
            
                // Attach the submenu to the "New File" menu item
                newFileMenuItem.submenu = submenu
            
                // Add the "New File" menu item to the main context menu
                menu.addItem(newFileMenuItem)
            }
        }
    
        return menu
    }
    
    // MARK: - File creation operations
    
    @objc func createTextFile(_ sender: AnyObject?) {
        // Retrieve the current directory being targeted in Finder
        guard let targetURL = FIFinderSyncController.default().targetedURL() else {
            NSLog("Unable to retrieve target directory")
            return
        }
    
        var finalURL = targetURL
    
        // Check if the target directory is writable
        if !isDirectoryWritable(targetURL) {
            // Log the lack of write permissions and prompt the user to select a writable directory
            NSLog("Directory is not writable, prompting user to select a new directory")
            if let userSelectedURL = promptUserForWritableDirectory() {
                finalURL = userSelectedURL
                NSLog("User selected directory: %@", finalURL.path as NSString)
            } else {
                // Show an alert if no writable directory is selected
                showAlert(title: "Operation canceled", message: "No writable directory selected, unable to create file.")
                return
            }
        }
    
        // Define the base name and extension for the new file using localized strings
        let baseFileName = NSLocalizedString("Untitled", comment: "Base name for new file")
        let fileExtension = "txt"
        // Generate a unique file name to avoid conflicts
        let uniqueFileName = generateUniqueFileName(in: finalURL, baseName: baseFileName, extension: fileExtension)
        let fileURL = finalURL.appendingPathComponent(uniqueFileName)
    
        do {
            // Create an empty text file at the specified URL
            try Data().write(to: fileURL)
            NSLog("Successfully created file: %@", fileURL.path as NSString)
        
            // Refresh Finder to display the newly created file
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        } catch {
            // Log and display an error if file creation fails
            NSLog("Failed to create file: %@", error.localizedDescription)
            showAlert(title: "Creation failed", message: "Unable to create file: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Helper methods
    
    /// Check if the specified directory is writable
    private func isDirectoryWritable(_ url: URL) -> Bool {
        return FileManager.default.isWritableFile(atPath: url.path)
    }
    
    /// Display an NSOpenPanel to let the user select a writable directory
    private func promptUserForWritableDirectory() -> URL? {
        var selectedURL: URL?
        // Run the NSOpenPanel on the main thread to ensure UI compatibility
        DispatchQueue.main.sync {
            let openPanel = NSOpenPanel()
            openPanel.allowsMultipleSelection = false
            openPanel.canChooseDirectories = true
            openPanel.canChooseFiles = false
            openPanel.canCreateDirectories = true
            openPanel.message = "The current directory is not writable, please select a writable directory"
            openPanel.prompt = "Choose"
        
            let result = openPanel.runModal()
            if result == .OK {
                selectedURL = openPanel.url
            }
        }
        return selectedURL
    }
    
    /// Generate a unique file name by appending a number if the file already exists
    private func generateUniqueFileName(in directory: URL, baseName: String, extension fileExtension: String) -> String {
        let fileManager = FileManager.default
        var index = 0
        var fileName = "\(baseName).\(fileExtension)"
        
        // Increment the file name with a numeric suffix until a unique name is found
        while fileManager.fileExists(atPath: directory.appendingPathComponent(fileName).path) {
            index += 1
            fileName = "\(baseName) \(index).\(fileExtension)"
        }
        
        return fileName
    }
    
    /// Display an alert dialog to inform the user of errors or cancellations
    private func showAlert(title: String, message: String) {
        DispatchQueue.main.sync {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = .warning
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
