//
//  ToDoListController.swift
//  DSSToDoList
//
//  Created by David on 11/02/22.
//

import UIKit

class ToDoListController: UITableViewController {
    enum ItemDescription: Int { case title = 0, description = 1 }
    
    var viewModel: ToDoListViewModel = ToDoListViewModel()
    
    var models: [ToDoListItemModel] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTableView()
        setupNavigationBar()
        setupViewModel()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        viewModel.readObjects()
    }
    
    private func setupNavigationBar() {
        navigationItem.title = "To-do list".uppercased()
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(handleNewItem))
    }
    
    private func setupTableView() {
        tableView.tableFooterView = .init()
        tableView.register(ToDoListItemCell.self, forCellReuseIdentifier: ToDoListItemCell.identifier)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        models.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ToDoListItemCell.identifier, for: indexPath) as! ToDoListItemCell
        cell.model = models[indexPath.row]
        return cell
    }
    
    private func setupViewModel() {
        viewModel.updateUI = { [weak self] models, updateType in
            guard let self = self else { return }
            switch updateType {
            case .full:
                self.models = models
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            case .append:
                let offset = self.models.count
                self.models += models
                let indexPaths: [IndexPath] = models.enumerated().map { IndexPath(row: offset + $0.offset, section: 0) }
                DispatchQueue.main.async {
                    self.tableView.insertRows(at: indexPaths, with: .right)
                }
            case .update:
                var indexPaths: [IndexPath] = []
                models.forEach { model in
                    if let index = self.models.firstIndex(where: { $0.id == model.id } ) {
                        self.models[index] = model
                        indexPaths.append(IndexPath(row: index, section: 0))
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.reloadRows(at: indexPaths, with: .fade)
                }
            case .delete:
                var indexPaths: [IndexPath] = []
                models.forEach { model in
                    if let index = self.models.firstIndex(where: { $0.id == model.id } ) {
                        self.models.remove(at: index)
                        indexPaths.append(IndexPath(row: index, section: 0))
                    }
                }
                DispatchQueue.main.async {
                    self.tableView.deleteRows(at: indexPaths, with: .left)
                }
            }
        }
        
        viewModel.presentMessage = { [weak self] title, message in
            self?.showAlert(title: title, message: message)
        }
    }
    
    /// This method is called when the user wants to add a new item to the to-do list
    @objc private func handleNewItem() {
        showEditController(model: nil)
    }
    
    /// Presents an alert where the user enters a to-do task for either create a new one (model parameter is nil) or edit an existing one
    private func showEditController(model: ToDoListItemModel?) {
        let controllerTitle: String = model == nil ? "New item" : "Update item"
        
        let editItemAlertController = UIAlertController(title: controllerTitle, message: nil, preferredStyle: .alert)
        
        editItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.title.rawValue
            textField.placeholder = "Title"
            textField.text = model?.title
        }

        editItemAlertController.addTextField { textField in
            textField.tag = ItemDescription.description.rawValue
            textField.placeholder = "Description"
            textField.text = model?.description
        }
        
        let mainActionTitle: String = model == nil ? "Add" : "Update"
        
        let mainAction: UIAlertAction = UIAlertAction(title: mainActionTitle, style: .default) { [weak self] _ in
            guard let title = editItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.title.rawValue })?.text else {
                return editItemAlertController.dismiss(animated: true, completion: nil)
            }
            
            let description = editItemAlertController.textFields?.first(where: { $0.tag == ItemDescription.description.rawValue })?.text
            
            editItemAlertController.dismiss(animated: true) {
                if let objectId = model?.id { // if the model passed as parameter is not nil, the alert will update it
                    self?.viewModel.updateObject(objectId: objectId, newTitle: title, newDescription: description)
                } else {
                    self?.viewModel.createObject(title: title, description: description)
                }
            }
        }
                
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        editItemAlertController.addAction(mainAction)
        editItemAlertController.addAction(cancelAction)

        present(editItemAlertController, animated: true, completion: nil)
    }
}

// MARK: DataSource delegate
extension ToDoListController {
    // When the user taps on the accessory button of a cell, we present the edit options for the to-do list task
    override func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard !models.isEmpty else { return }
        
        let model = models[indexPath.row]
        
        showEditOptions(model: model)
    }
    
    /// Presents a sheet where the user can select an action for the to-do list item
    private func showEditOptions(model: ToDoListItemModel) {
        let alertController = UIAlertController(title: title, message: nil, preferredStyle: .actionSheet)
        
        let editAction = UIAlertAction(title: "Edit", style: .default) { [weak self] _ in
            self?.showEditController(model: model)
        }
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            alertController.dismiss(animated: true) {
                self?.viewModel.deleteObject(model: model)
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
