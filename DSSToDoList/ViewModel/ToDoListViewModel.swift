//
//  ToDoListViewModel.swift
//  DSSToDoList
//
//  Created by David on 11/02/22.
//

import Foundation
import ParseSwift

class ToDoListViewModel {
    enum UIUpdateType {
        case full, append, update, delete
    }
        
    var updateUI: (([ToDoListItemModel], _ type: UIUpdateType) -> Void)? // Closure to update the UI
    
    var presentMessage: ((_ title: String, _ description: String) -> Void)? // Closure to present a message
    
    /// Creates a ToDoListItem and stores it on your Back4App Database
    /// - Parameters:
    ///   - title: The title for the to-do task
    ///   - description: An optional description for the to-to task
    func createObject(title: String, description: String?) {
        let item = ToDoListItem(title: title, description: description)
        
        item.save { [weak self] result in
            switch result {
            case .success(let savedItem):
                if let model = ToDoListItemModel(savedItem) {                    
                    self?.updateUI?([model], .append) // Update the UI after saving the item
                }
            case .failure(let error):
                self?.presentMessage?("Error", "Failed to save item: \(error.message)")
            }
        }
    }
    
    /// Retrieves all the ToDoListItem objects from your Back4App Database
    func readObjects() {
        let query = ToDoListItem.query()
        
        query.find { [weak self] result in
            switch result {
            case .success(let items):
                let models: [ToDoListItemModel] = items.compactMap(ToDoListItemModel.init)
                
                self?.updateUI?(models, .full)
            case .failure(let error):
                self?.presentMessage?("Error", "Failed to fetch items: \(error.message)")
            }
        }
    }
    
    /// Updates a ToDoListItem object on your Back4App Database
    /// - Parameters:
    ///   - objectId: The object id of tha ParseObject
    ///   - newTitle: New title for the to-to task
    ///   - newDescription: New description for the to-do task
    func updateObject(objectId: String, newTitle: String, newDescription: String?) {
        var item = ToDoListItem(objectId: objectId)
        item.title = newTitle
        item.description = newDescription
        
        item.save { [weak self] result in
            switch result {
            case .success:
                
                if let model = ToDoListItemModel(item) {
                    self?.updateUI?([model], .update)
                }
            case .failure(let error):
                self?.presentMessage?("Error", "Failed to update item: \(error.message)")
            }
        }
    }
    
    /// Deletes a ToDoListItem on your Back4App Database from its model representation
    /// - Parameter model: The model mapped from the ToDoListItem object to delete
    func deleteObject(model: ToDoListItemModel) {
        let item = ToDoListItem(objectId: model.id)

        item.delete { [weak self] result in
            switch result {
            case .success:
                self?.updateUI?([model], .delete)
            case .failure(let error):
                self?.presentMessage?("Error", "Failed to delete item: \(error.message)")
            }
        }
    }
}
