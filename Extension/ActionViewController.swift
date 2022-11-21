//
//  ActionViewController.swift
//  Extension
//
//  Created by Huy Bui on 2022-11-15.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

class ActionViewController: UIViewController, SavedCodeDelegate {

    @IBOutlet var script: UITextView!
    
    var pageTitle = "", pageURL = ""
    var codeSnippets: [CodeSnippet] = []
    var savedCode: Dictionary<String, String> = Dictionary()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Inject JavaScript"
        
        script.selectAll(nil) // Select all text (i.e. "// code") by default
        script.tintColor = .systemGray
        
        // Get notified when keyboard appeared/disappeared to size text view accordingly
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(adjustTextViewForKeyboard), name: UIResponder.keyboardWillChangeFrameNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(adjustTextViewForKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        loadCodeSnippets()
        
        let insertCodeSnippetAction = UIAction(title: "Insert Code Snippet", image: UIImage(systemName: "text.insert")) { [weak self] _ in
            self?.showCodeSnippets()
        }
        
        let loadSavedCodeAction = UIAction(title: "Load Saved Code", image: UIImage(systemName: "tray.and.arrow.down")) { [weak self] _ in
            self?.showSavedCode()
        }
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.leftBarButtonItem = cancelButton
        
        let options = UIMenu(title: "", children: [insertCodeSnippetAction, loadSavedCodeAction])
        let optionsButton = UIBarButtonItem(image: UIImage(systemName: "ellipsis.circle"), menu: options)
        let doneButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(done))
        navigationItem.rightBarButtonItems = [doneButton, optionsButton]
        
        if let inputItem = extensionContext?.inputItems.first as? NSExtensionItem { // Get first piece of data (inputItems.first) sent from parent app
            if let itemProvider = inputItem.attachments?.first { // Get first attachment from first input item
                itemProvider.loadItem(forTypeIdentifier: UTType.propertyList.identifier as String) {
                    [weak self] (dictionary, error) in
                    
                    guard let itemDictionary = dictionary as? NSDictionary else { return }
                    guard let javaScriptPreprocessingResultValues = itemDictionary[NSExtensionJavaScriptPreprocessingResultsKey] as? NSDictionary else { return }
                    
                    self?.pageTitle = javaScriptPreprocessingResultValues["title"] as? String ?? ""
                    self?.pageURL = javaScriptPreprocessingResultValues["URL"] as? String ?? ""
                    
//                    DispatchQueue.main.async { // No need for "[weak self] in" (already declared by wrapping closure)
//                        // Updating UI must be done on main thread
//                        self?.title = self?.pageTitle
//                    }
                }
            }
        }
    }
    
    func loadCodeSnippets() {
        DispatchQueue.global(qos: .background).async {
            if let codeSnippetsFile = Bundle.main.url(forResource: "CodeSnippets", withExtension: "js") {
                if let codeSnippetsFileContent = try? String(contentsOf: codeSnippetsFile) {
                    let snippets = codeSnippetsFileContent.components(separatedBy: "\n\n// MARK: ")
                    
                    for (index, codeSnippet) in snippets.enumerated() {
                        if (index > 0) { // Skip first array item (header)
                            let codeSnippetComponents = codeSnippet.components(separatedBy: ".\n")
                            let snippet = CodeSnippet(name: codeSnippetComponents[0], code: codeSnippetComponents[1])
                            self.codeSnippets.append(snippet)
                        }
                    }
                }
            }
        }
    }
    
    func showCodeSnippets() {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: "Code Snippets", message: "Snippet will be inserted at current cursor position.", preferredStyle: .actionSheet)
            for snippet in self.codeSnippets {
                alertController.addAction(UIAlertAction(title: snippet.name, style: .default) { [weak self] _ in
                    self?.script.insertText(snippet.code)
                })
            }
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            self.present(alertController, animated: true)
        }
    }
    
    @objc func loadSavedCode() {
        let defaults = UserDefaults.standard
        if let savedCode = defaults.object(forKey: "code") as? Dictionary<String, String> {
            self.savedCode = savedCode
        }
    }
    
    func showSavedCode() {
        loadSavedCode()
        
        if let viewController = storyboard?.instantiateViewController(withIdentifier: "SavedCodeTableViewController") as? SavedCodeTableViewController {
            viewController.savedCode = savedCode
            viewController.delegate = self
            navigationController?.pushViewController(viewController, animated: true)
        }
    }
    
    @objc func cancel() {
        extensionContext?.completeRequest(returningItems: nil)
    }

    @objc func done() {
        let saveAs = UIAlertAction(title: "Save & Execute Code...", style: .default) { [weak self] _ in
            self?.requestNameToSaveCode();
        }
        let discard = UIAlertAction(title: "Execute Code", style: .destructive) { [weak self] _ in
            self?.completeRequest()
        }
        showAlert(title: "Save Code", message: "Before executing, would you like to store this piece of code to reuse later?", actions: [saveAs, discard])
    }
    
    @objc func requestNameToSaveCode() {
        let input = UIAlertController(title: "Name This Piece of Code", message: "Enter a name to save this piece of code as.", preferredStyle: .alert)
        input.addTextField()
        input.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        input.addAction(UIAlertAction(title: "Save", style: .default) { [weak self] _ in
            if let name = input.textFields?[0].text {
                self?.loadSavedCode()
                
                if name.isEmpty {
                    self?.showAlert(title: "Unable to Save Code", message: "No name was entered.", cancelText: "OK")
                } else if self?.savedCode.keys.contains(name) ?? false {
                    self?.showAlert(title: "A Piece of Code With This Name Already Exists", message: "Would you like to overwrite it?",
                                    actions: [UIAlertAction(title: "Overwrite", style: .destructive) { _ in
                        self?.saveCode(withKey: name)
                    }])
                } else {
                    self?.saveCode(withKey: name)
                }
            }
        })
        present(input, animated: true)
    }
    
    func saveCode(withKey key: String) {
        savedCode[key] = script.text ?? ""
        let defaults = UserDefaults.standard
        defaults.set(savedCode, forKey: "code")
        completeRequest()
    }
    
    func completeRequest() {
        // Return any edited content to the host app
        let item = NSExtensionItem()
        let argument: NSDictionary = ["code": script.text ?? "alert('No JavaScript code entered.');"]
        let dictionary: NSDictionary = [NSExtensionJavaScriptFinalizeArgumentKey: argument] // Argument that will be passed to finalize() in Action.js
        let itemProvider = NSItemProvider(item: dictionary, typeIdentifier: UTType.propertyList.identifier as String)
        item.attachments = [itemProvider]
        
        extensionContext?.completeRequest(returningItems: [item]) // item will be passed to finalize() in Action.js
    }
    
    func showAlert(title: String?, message: String? = nil, cancelText: String = "Cancel", actions: [UIAlertAction]? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: cancelText, style: .cancel))
        if let actions = actions { // Unwrap actions since it's optional
            for action in actions {
                alertController.addAction(action)
            }
        }
        present(alertController, animated: true)
    }
    
    @objc func adjustTextViewForKeyboard(notification: Notification) {
        // Grab keyboard's frame after it's finished animating (keyboardFrameEndUserInfoKey)
        // from notification information dictionary (userInfo)
        guard let keyboardValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        // keyboardValue is an NSValue object that wraps a CGRect structure (dictionaries can't contain structure so NSValue wrapper was required)
        
        // Pull CGRect structure from keyboardValue
        let keyboardScreenEndFrame = keyboardValue.cgRectValue
        
        // Convert rectangle to view's coordinates to fix width & height flipped when in landscape
        let keyboardViewEndFrame = view.convert(keyboardScreenEndFrame, from: view.window)
        
        // Keyboard disappearing
        if notification.name == UIResponder.keyboardWillHideNotification {
            script.contentInset = .zero
        }
        
        // Keyboard appearing
        else {
            script.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: keyboardViewEndFrame.height - view.safeAreaInsets.bottom, right: 0)
        }
        
        // Prevent scroll indicator from scrolling underneath the keyboard
        script.scrollIndicatorInsets = script.contentInset
        
        let selectedRange = script.selectedRange
        script.scrollRangeToVisible(selectedRange) // Scroll until cursor is visible
    }
    
    func didSelectSavedCode(withKey key: String) {
        showAlert(title: "Load \"\(key)\"?", message: "This will overwrite the everything you currently have in the editor.", actions: [UIAlertAction(title: "Load", style: .destructive) { [weak self] _ in
            self?.navigationController?.popViewController(animated: true)
            self?.script.text = self?.savedCode[key]
        }])
    }
    
    func deleteSavedCode(withKey key: String) {
        savedCode.removeValue(forKey: key)
        let defaults = UserDefaults.standard
        defaults.set(savedCode, forKey: "code")
    }

}
