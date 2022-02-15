//
//  ToDoListItem.swift
//  DSSToDoList
//
//  Created by David on 12/02/22.
//

import Foundation
import ParseSwift

struct ToDoListItem: ParseObject {
    // Required properties from ParseObject protocol
    var objectId: String?
    var createdAt: Date?
    var updatedAt: Date?
    var ACL: ParseACL?
    
    /// Title for the todo item
    var title: String?
    
    /// Description for the todo item
    var description: String?
}

// Custom initializer for ToDoListItemModel to map a ToDoListItem object into ToDoListItemModel
extension ToDoListItemModel {
    init?(_ toDoListItem: ToDoListItem) {
        guard let title = toDoListItem.title else { return nil }
        self.init(id: toDoListItem.id, title: title, description: toDoListItem.description)
    }
}
