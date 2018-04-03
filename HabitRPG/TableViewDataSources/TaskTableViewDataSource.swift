//
//  ReactiveTableViewDataSource.swift
//  Habitica
//
//  Created by Phillip Thelen on 05.03.18.
//  Copyright © 2018 HabitRPG Inc. All rights reserved.
//

import UIKit
import Habitica_Models
import ReactiveSwift

@objc
public protocol TaskTableViewDataSourceProtocol {
    @objc var userDrivenDataUpdate: Bool { get set }
    @objc weak var tableView: UITableView? { get set }
    @objc var predicate: NSPredicate { get set }
    
    @objc var tasks: [TaskProtocol] { get set}
    @objc var taskToEdit: TaskProtocol? { get set }
    
    @objc
    func task(at indexPath: IndexPath) -> TaskProtocol?
    @objc
    func idForObject(at indexPath: IndexPath) -> String?
    @objc
    func retrieveData(completed: (() -> Void)?)
    @objc
    func selectRowAt(indexPath: IndexPath)
    @objc
    func fixTaskOrder(movedTask: TaskProtocol, toPosition: Int)
    @objc
    func moveTask(task: TaskProtocol, toPosition: Int, completion: @escaping () -> Void)
}

class TaskTableViewDataSource: BaseReactiveTableViewDataSource<TaskProtocol>, TaskTableViewDataSourceProtocol {
    var tasks: [TaskProtocol] {
        get {
            return sections[0].items
        }
        set {
            sections[0].items = tasks
        }
    }
    
    func task(at indexPath: IndexPath) -> TaskProtocol? {
        return item(at: indexPath)
    }
    
    var predicate: NSPredicate {
        didSet {
            fetchTasks()
        }
    }
    
    internal let userRepository = UserRepository()
    internal let repository = TaskRepository()
    
    @objc var taskToEdit: TaskProtocol?
    private var expandedIndexPath: IndexPath?
    private var fetchTasksDisposable: Disposable?
    
    init(predicate: NSPredicate) {
        self.predicate = predicate
        super.init()
        sections.append(ItemSection<TaskProtocol>())
    }
    
    override func retrieveData(completed: (() -> Void)?) {
        disposable.inner.add(userRepository.retrieveUser().observeCompleted {
            if let action = completed {
                action()
            }
        })
    }
    
    private func fetchTasks() {
        if let disposable = fetchTasksDisposable, !disposable.isDisposed {
            disposable.dispose()
        }
        fetchTasksDisposable = repository.getTasks(predicate: predicate).on(value: { (tasks, changes) in
            self.sections[0].items = tasks
            self.notifyDataUpdate(tableView: self.tableView, changes: changes)
        }).start()
    }

    @objc
    func idForObject(at indexPath: IndexPath) -> String? {
        return item(at: indexPath)?.id
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            if let task = self.item(at: indexPath) {
                repository.deleteTask(task).observeCompleted {}
            }
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        if let taskCell = cell as? TaskTableViewCell, let task = item(at: indexPath) {
            configure(cell: taskCell, indexPath: indexPath, task: task)
        }
        return cell
    }
    
    func configure(cell: TaskTableViewCell, indexPath: IndexPath, task: TaskProtocol) {
        if let checkedCell = cell as? CheckedTableViewCell {
            checkedCell.isExpanded = self.expandedIndexPath?.item == indexPath.item
        }
        cell.configure(task: task)
        cell.syncErrorTouched = {
            let alertController = HabiticaAlertController(title: L10n.syncError, message: L10n.syncErrorMessage)
            alertController.addAction(title: L10n.resyncTask, style: .default, isMainAction: false, handler: { (_) in
                self.repository.syncTask(task).observeCompleted {}
            })
            alertController.addCancelAction()
            alertController.show()
        }
    }
    
    internal func expandSelectedCell(indexPath: IndexPath) {
        var expandedPath = self.expandedIndexPath
        if tableView?.numberOfRows(inSection: 0) ?? 0 < (expandedPath?.item ?? 0) {
            expandedPath = nil
        }
        self.expandedIndexPath = indexPath
        if expandedPath == nil || indexPath.item == expandedPath?.item {
            if expandedPath?.item == self.expandedIndexPath?.item {
                self.expandedIndexPath = nil
            }
            tableView?.beginUpdates()
            tableView?.reloadRows(at: [indexPath], with: .none)
            tableView?.endUpdates()
        } else {
            if let path = expandedPath {
                tableView?.beginUpdates()
                tableView?.reloadRows(at: [indexPath, path], with: .none)
                tableView?.endUpdates()
            }
        }
    }
    
    @objc
    func selectRowAt(indexPath: IndexPath) {
        taskToEdit = item(at: indexPath)
    }
    
    @objc
    func fixTaskOrder(movedTask: TaskProtocol, toPosition: Int) {
        repository.fixTaskOrder(movedTask: movedTask, toPosition: toPosition)
    }
    
    @objc
    func moveTask(task: TaskProtocol, toPosition: Int, completion: @escaping () -> Void) {
        repository.moveTask(task, toPosition: toPosition).observeCompleted {
            completion()
        }
    }
}
