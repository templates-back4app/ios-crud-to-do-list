//
//  ToDoListController.swift
//  DSSToDoList
//
//  Created by David on 11/02/22.
//

import UIKit

class ToDoListController: UITableViewController {
    enum ItemDescription: Int { case title = 0, description = 1 }
        
    var items: [ToDoListItem] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        readObjects()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "To-do list".uppercased()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNewItem))
    }
    
    private func setupTableView() {
        tableView.register(ToDoListItemCell.self, forCellReuseIdentifier: ToDoListItemCell.identifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ToDoListItemCell.identifier, for: indexPath) as! ToDoListItemCell
        cell.item = items[indexPath.row]
        return cell
    }
    
    /// This method is called when the user wants to add a new item to the to-do list
    @objc private func handleNewItem() {
        showEditController(item: nil)
    }
    
    /// Presents an alert where the user enters a to-do task for either create a new one (item parameter is nil) or edit an existing one
    private func showEditController(item: ToDoListItem?) {
        let controllerTitle: String = item == nil ? "New item" : "Update item"
        
        let editItemAlertController = UIAlertController(title: controllerTitle, message: nil, preferredStyle: .alert)
        
        editItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.title.rawValue
            textField.placeholder = "Title"
            textField.text = item?.title
        }

        editItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.description.rawValue
            textField.placeholder = "Description"
            textField.text = item?.description
        }
        
        let mainActionTitle: String = item == nil ? "Add" : "Update"
        
        let mainAction: UIAlertAction = UIAlertAction(title: mainActionTitle, style: .default) { [weak self] _ in
            guard let title = editItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.title.rawValue })?.text else {
                return editItemAlertController.dismiss(animated: true, completion: nil)
            }
            
            let description = editItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.description.rawValue })?.text
            
            editItemAlertController.dismiss(animated: true) {
                if let objectId = item?.objectId { // if the item passed as parameter is not nil, the alert will update it
                    self?.updateObject(objectId: objectId, newTitle: title, newDescription: description)
                } else {
                    self?.createObject(title: title, description: description)
                }
            }
        }
                
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        editItemAlertController.addAction(mainAction)
        editItemAlertController.addAction(cancelAction)

        present(editItemAlertController, animated: true, completion: nil)
    }
}

// MARK: UITableViewDataSource delegate
extension ToDoListController {
    // When the user taps on the accessory button of a cell, we present the edit options for the to-do list task
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard !items.isEmpty else { return }
        
        showEditOptions(item: items[indexPath.row])
    }
    
    /// Presents a sheet where the user can select an action for the to-do list item
    private func showEditOptions(item: ToDoListItem) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.showEditController(item: item)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            alertController.dismiss(animated: true) {
                self?.deleteObject(item: item)
            }
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { _ in
            alertController.dismiss(animated: true, completion: nil)
        }
        
        alertController.addAction(editAction)
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)

        present(alertController, animated: true, completion: nil)
    }
}

// MARK: - CRUD Flow
extension ToDoListController {
    /// Creates a ToDoListItem and stores it on your Back4App Database
    /// - Parameters:
    ///   - title: The title for the to-do task
    ///   - description: An optional description for the to-to task
    func createObject(title: String, description: String?) {
        let item = ToDoListItem(title: title, description: description)
        
        item.save { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let savedItem):
                self.items.append(savedItem)
                DispatchQueue.main.async {
                    self.tableView.insertRows(at: [IndexPath(row: self.items.count - 1, section: 0)], with: .right)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to save item: \(error.message)")
                }
            }
        }
    }
    
    /// Retrieves all the ToDoListItem objects from your Back4App Database
    func readObjects() {
        let query = ToDoListItem.query()
        
        query.find { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let items):
                self.items = items
                DispatchQueue.main.async {
                    self.tableView.reloadSections([0], with: .top)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self.showAlert(title: "Error", message: "Failed to save item: \(error.message)")
                }
            }
        }
    }
    
    /// Updates a ToDoListItem object on your Back4App Database
    /// - Parameters:
    ///   - objectId: The object id of the ToDoListItem to update
    ///   - newTitle: New title for the to-to task
    ///   - newDescription: New description for the to-do task
    func updateObject(objectId: String, newTitle: String, newDescription: String?) {
        var item = ToDoListItem(objectId: objectId)
        item.title = newTitle
        item.description = newDescription
        
        item.save { [weak self] result in
            switch result {
            case .success:
                if let row = self?.items.firstIndex(where: { $0.objectId == item.objectId }) {
                    self?.items[row] = item
                    DispatchQueue.main.async {
                        self?.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .fade)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to save item: \(error.message)")
                }
            }
        }
    }
    
    /// Deletes a ToDoListItem on your Back4App Database
    /// - Parameter item: The item to be deleted on your Back4App Database
    func deleteObject(item: ToDoListItem) {
        item.delete { [weak self] result in
            switch result {
            case .success:
                if let row = self?.items.firstIndex(where: { $0.objectId == item.objectId }) {
                    self?.items.remove(at: row)
                    DispatchQueue.main.async {
                        self?.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .left)
                    }
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    self?.showAlert(title: "Error", message: "Failed to save item: \(error.message)")
                }
            }
        }
    }
}
