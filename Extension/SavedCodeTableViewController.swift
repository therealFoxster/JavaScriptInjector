//
//  SavedCodeTableViewController.swift
//  Extension
//
//  Created by Huy Bui on 2022-11-17.
//

import UIKit

class SavedCodeTableViewController: UITableViewController {

    weak var delegate: SavedCodeDelegate?
    
    var savedCode: Dictionary<String, String>!
    var savedCodeKeys: [String] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard savedCode != nil else { return }
        savedCodeKeys = Array(savedCode.keys).sorted()
        
        title = "Saved Code"
        navigationItem.backButtonDisplayMode = .minimal

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return savedCode.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        cell.textLabel?.text = savedCodeKeys[indexPath.row]

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        delegate?.didSelectSavedCode(withKey: savedCodeKeys[indexPath.row])
    }
    
    // Swipe to delete (thanks to @TwoStraws)
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
            if editingStyle == .delete {
                let key = savedCodeKeys[indexPath.row]
                
                let confirmAlert = UIAlertController(title: "Delete \"\(key)\"?", message: "This action is irreversible.", preferredStyle: .alert)
                confirmAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
                confirmAlert.addAction(UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
                    self?.savedCode.removeValue(forKey: key)
                    self?.delegate?.deleteSavedCode(withKey: key)
                    self?.tableView.deleteRows(at: [indexPath], with: .fade)
                })
                present(confirmAlert, animated: true)
            } else if editingStyle == .insert {
                // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
            }
        }

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
