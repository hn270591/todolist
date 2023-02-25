//
//  ViewController.swift
//  todolist
//
//  Created by Nguyen Dac Trung on 14/06/2022.
//

import UIKit

class ViewController: UIViewController {
    
    enum Action {
        case none, adding, editing
    }
    
    // MARK: - Properties
    
    var editingIndex: Int!
    var todos = (0...4).map { "To do \($0 + 1)" } // dummy data
    let tableView = UITableView()
    let reuseIdentifer = "ToDoCell"
    
    var action: Action = .none {
        didSet {
            let addIndex = IndexPath(row: todos.count, section: 0)
            let lastAction = oldValue
            switch (lastAction, action) {
            case (.none, .editing):
                let last = IndexPath(row: todos.count, section: 0)
                tableView.deleteRows(at: [last], with: .automatic)
            case (_, .adding):
                let cell = tableView.cellForRow(at: addIndex) as! ToDoCell
                cell.textView.text = nil
                cell.style = .todo
            case (_, .none):
                if .editing == lastAction {
                    tableView.insertRows(at: [addIndex], with: .automatic)
                }
                // Restore the add cell.
                let cell = tableView.cellForRow(at: addIndex) as! ToDoCell
                cell.textView.text = nil
                cell.style = .add
                // Just in case new item inserted, update correct index for the add cell.
                cell.index = todos.count
                
                // Update cell height for the add cell if needed.
                tableView.beginUpdates()
                tableView.endUpdates()
                
                // Dismiss keyboard.
                view.endEditing(true)
            case (.adding, .editing):
                let last = IndexPath(row: todos.count, section: 0)
                tableView.deleteRows(at: [last], with: .automatic)
            default:
                print("no handle")
            }
        }
    }
    
    override func loadView() {
        view = tableView
    }
    
    // MARK: - View life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Prevent the system keyboard from covering views.
        startAvoidingKeyboard()
        
        tableView.dataSource = self
        tableView.register(ToDoCell.self, forCellReuseIdentifier: reuseIdentifer)
        
        // Add some spacing to table view at the bottom.
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 20, right: 0)
        
        // Tap outside to dismiss keyboard.
        let tap = UITapGestureRecognizer(target: self, action: #selector(tap))
        tableView.addGestureRecognizer(tap)
    }
    
    @objc func tap(_ sender: Any) {
        if action == .adding {
            let adding = IndexPath(row: todos.count, section: 0)
            let cell = tableView.cellForRow(at: adding) as! ToDoCell
            if !cell.textView.text.isEmpty {
                todos.append(cell.textView.text)
                tableView.insertRows(at: [adding], with: .automatic)
            }
        }
        action = .none
    }
}

// MARK: - Table View Data Source

extension ViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch action {
        case .editing: return todos.count
        default: return todos.count + 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifer, for: indexPath) as! ToDoCell
        cell.delegate = self
        cell.index = indexPath.row
        if indexPath.row < todos.count {
            let todo = todos[indexPath.row]
            cell.textView.text = todo
            cell.isDone = Int.random(in: 0...1) > 0 // randomize
        } else {
            cell.textView.text = nil
            cell.style = action == .none ? .add : .todo
        }
        return cell
    }
}

// MARK: - To Do Cell Delegate

extension ViewController: ToDoCellDelegate {
    func addCellDidTap(_ cell: ToDoCell) {
        action = .adding
        cell.textView.becomeFirstResponder()
    }
    
    func todoCellDidSwipeRight(_ cell: ToDoCell) {
        cell.contentView.backgroundColor = [.systemBlue, .systemPink, .systemYellow, .systemIndigo, .systemPurple].randomElement()
    }
    
    func checkmarkButtonDidTap(_ cell: ToDoCell) {
        // TODO: Save DB
    }
    
    func todoCellBeginEditing(_ cell: ToDoCell) {
        editingIndex = cell.index
        action = cell.index == todos.count ? .adding : .editing
    }
    
    func todoCellEndEditing(_ cell: ToDoCell) {
        if cell.index < todos.count {
            // Edit
        } else if let text = cell.textView.text, !text.isEmpty {
            // Add new
            todos.append(text)
            let new = IndexPath(row: cell.index, section: 0)
            tableView.insertRows(at: [new], with: .automatic)
        }
        action = .none
        /*
         TODO: Save DB
         */
    }
    
    func todoCellDidChangeContent(_ cell: ToDoCell) {
        // Update cells to make text views fit cells while adding multiple lines.
        tableView.beginUpdates()
        tableView.endUpdates()
    }
}

protocol ToDoCellDelegate {
    func todoCellBeginEditing(_ cell: ToDoCell)
    func todoCellEndEditing(_ cell: ToDoCell)
    func todoCellDidChangeContent(_ cell: ToDoCell)
    func checkmarkButtonDidTap(_ cell: ToDoCell)
    func todoCellDidSwipeRight(_ cell: ToDoCell)
    func addCellDidTap(_ cell: ToDoCell)
}

class ToDoCell: UITableViewCell {
    
    enum ToDoCellStyle {
        case todo
        case add
    }
    
    var index: Int!
    var delegate: ToDoCellDelegate!
    
    var style: ToDoCellStyle = .todo {
        didSet {
            switch style {
            case .add:
                let image = systemImage("plus")
                leftButton.setImage(image, for: .normal)
            case .todo:
                let image = systemImage("square")
                leftButton.setImage(image, for: .normal)
            }
        }
    }
    
    var isDone: Bool = false {
        didSet {
            let image = isDone ? systemImage("checkmark.square") : systemImage("square")
            leftButton.setImage(image, for: .normal)
        }
    }
    
    let leftButton = UIButton()
    let textView = UITextView()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        // Disable selection
        selectionStyle = .none
        setupViews()
        setupGesture()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupGesture() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(swipeRight))
        swipeGesture.direction = .right
        contentView.addGestureRecognizer(swipeGesture)
    }
    
    private func setupViews() {
        leftButton.tintColor = .label
        leftButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)
        
        textView.delegate = self
        textView.font = UIFont.preferredFont(forTextStyle: .body)
        textView.backgroundColor = .clear
        textView.returnKeyType = .next
        textView.isScrollEnabled = false  // For multiple lines.
        
        contentView.addSubview(leftButton)
        contentView.addSubview(textView)
        
        leftButton.translatesAutoresizingMaskIntoConstraints = false
        textView.translatesAutoresizingMaskIntoConstraints = false
        
        // Don't let checkmark button grows.
        leftButton.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        
        // Setup constrains using VFL
        // https://developer.apple.com/library/archive/documentation/UserExperience/Conceptual/AutolayoutPG/VisualFormatLanguage.html
        let views = ["leftButton": leftButton, "textView": textView]
        let metrics = ["leftButtonSize": NSNumber(36), "margin": NSNumber(8)]
        // Horizontal
        let hConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|-[leftButton(leftButtonSize)]-[textView]-|", metrics: metrics, views: views)
        // Vertical
        let vConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|-(margin)-[textView(>=40)]-(margin)-|", metrics: metrics, views: views)
        contentView.addConstraints(hConstraints)
        contentView.addConstraints(vConstraints)
        contentView.addConstraint(NSLayoutConstraint(item: leftButton, attribute: .centerY, relatedBy: .equal, toItem: textView, attribute: .centerY, multiplier: 1, constant: 0))
    }
    
    @objc func toggle(_ sender: UIButton) {
        switch style {
        case .todo:
            isDone.toggle()
            delegate.checkmarkButtonDidTap(self)
        case .add:
            delegate.addCellDidTap(self)
        }
    }
    
    @objc func swipeRight() {
        delegate.todoCellDidSwipeRight(self)
    }
}

extension ToDoCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        delegate.todoCellBeginEditing(self)
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text.isEmpty == false {
            delegate.todoCellDidChangeContent(self)
        }
        
        // Return key pressed.
        if text == "\n" {
            delegate.todoCellEndEditing(self)
            return false
        }
        
        return true
    }
}

// MARK: - Utilities

extension UIImage.Configuration {
    static let large = UIImage.SymbolConfiguration(scale: .large)
}

func systemImage(_ named: String, config: UIImage.Configuration = .large) -> UIImage? {
    UIImage(systemName: named, withConfiguration: config)
}
