

import UIKit

protocol GenresDelegate: class {
    func finished(genreArrayIndex: Int)
    func populateDataSourceArray(inout array: [String])
}


class GenresTableViewController: UITableViewController, NSDiscardableContent {
    
    weak var delegate: GenresDelegate?
    var genres = [String]()
    var selectedRow: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate?.populateDataSourceArray(&genres)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        tableView.reloadData()
    }

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return genres.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! GenresTableViewCell
        cell.titleLabel?.text = genres[indexPath.row]
        cell.selectedRow = selectedRow
        cell.currentRow = indexPath.row
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        selectedRow = indexPath.row
        delegate?.finished(indexPath.row)
        dismissViewControllerAnimated(true, completion: nil)
    }
    
    // MARK: - NSDiscardableContent
    
    func beginContentAccess() -> Bool {
        return true
    }
    func endContentAccess() {}
    func discardContentIfPossible() {}
    func isContentDiscarded() -> Bool {
        return false
    }
}
