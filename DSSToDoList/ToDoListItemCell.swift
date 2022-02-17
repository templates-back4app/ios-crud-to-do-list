//
//  ToDoListItemCell.swift
//  DSSToDoList
//
//  Created by David on 11/02/22.
//

import UIKit

class ToDoListItemCell: UITableViewCell {
    class var identifier: String { "\(NSStringFromClass(Self.self)).identifier" } // Cell's identifier
    
    /// When set, it updates the title and detail texts of the cell
    var item: ToDoListItem? {
        didSet {
            textLabel?.text = item?.title
            detailTextLabel?.text = item?.description
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        accessoryType = .detailButton // This accessory button will be used to present edit options for the item
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        
        accessoryType = .detailButton // This accessory button will be used to present edit options for the item
    }
}
