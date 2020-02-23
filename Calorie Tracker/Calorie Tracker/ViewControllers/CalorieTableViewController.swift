//
//  CalorieTableViewController.swift
//  Calorie Tracker
//
//  Created by Alex Thompson on 2/22/20.
//  Copyright © 2020 Lambda School. All rights reserved.
//

import UIKit
import CoreData
import SwiftChart

class CalorieTableViewController: UITableViewController {
    @IBOutlet private weak var chartView: Chart!
    
    
    
    let calorieController = CalorieController()
    
    lazy var fetchedResultController: NSFetchedResultsController<Calorie> = {
        
        let fetchRequest: NSFetchRequest<Calorie> = Calorie.fetchRequest()
        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "timestamp", ascending: true)
        ]
        let moc = CoreDataStack.shared.mainContext
        let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: moc, sectionNameKeyPath: "calorie", cacheName: nil)
        frc.delegate = self
        
        do {
            try frc.performFetch()
        } catch {}
        
        return frc
    }()
    
    private var dateFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .short
        return dateFormatter
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.updateChart()

    }
    
    func dateString(for calorie: Calorie?) -> String? {
        return calorie?.timestamp.map { dateFormatter.string(from: $0) }
    }
    
    @IBAction func addPressed(_ sender: Any) {
        
        let ac = UIAlertController(title: "Add calorie Intake", message: "Enter amount of calories in this field.", preferredStyle: .alert)
        
        ac.addTextField()
        
        let submitAction = UIAlertAction(title: "Submit", style: .default) { [unowned ac] _ in
            let answer = ac.textFields![0].text
            
            let calorieInt: Int = Int(answer ?? "0") ?? 0
            let calorieInt16: Int16 = Int16(calorieInt)
            self.calorieController.create(calorie: calorieInt16)
            
        }
        
       
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        
        ac.addAction(cancelAction)
        ac.addAction(submitAction)
        self.present(ac, animated: true, completion: nil)
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultController.sections?.count ?? 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultController.sections?[section].numberOfObjects ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CalorieCell", for: indexPath)
        
        let calorie = fetchedResultController.object(at: indexPath)
        cell.textLabel?.text = "Calorie: \(calorie.calorie)"
        cell.detailTextLabel?.text = dateString(for: calorie)
        return cell
    }
    
    private func updateChart() {
        if let calories = fetchedResultController.fetchedObjects {
            let series = ChartSeries(calories.map { Double($0.calorie) })
            self.chartView.removeAllSeries()
            self.chartView.add(series)
            series.colors = (
                above: ChartColors.greenColor(),
                below: ChartColors.darkRedColor(),
                zeroLevel: -1
            )
            
        }
    }
}

extension CalorieTableViewController: NSFetchedResultsControllerDelegate {
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
        self.updateChart()
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange sectionInfo: NSFetchedResultsSectionInfo,
                    atSectionIndex sectionIndex: Int,
                    for type: NSFetchedResultsChangeType) {
        switch type {
        case .insert:
            tableView.insertSections(IndexSet(integer: sectionIndex), with: .automatic)
        case .delete:
            tableView.deleteSections(IndexSet(integer: sectionIndex), with: .automatic)
        default:
            break
        }
    }
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>,
                    didChange anObject: Any,
                    at indexPath: IndexPath?,
                    for type: NSFetchedResultsChangeType,
                    newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            guard let newIndexPath = newIndexPath else { return }
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case.update:
            guard let indexPath = indexPath else { return }
            tableView.reloadRows(at: [indexPath], with: .automatic)
        case .move:
            guard let oldIndexPath = indexPath,
                let newIndexPath = newIndexPath else { return }
            tableView.deleteRows(at: [oldIndexPath], with: .automatic)
            tableView.insertRows(at: [newIndexPath], with: .automatic)
        case .delete:
            guard let indexPath = indexPath else { return }
            tableView.deleteRows(at: [indexPath], with: .automatic)
        @unknown default:
            break
        }
    }
}
