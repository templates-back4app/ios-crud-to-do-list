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
