

import UIKit

protocol SubtitlesTableViewControllerDelegate: class {
    func didSelectASubtitle(subtitle: PCTSubtitle?)
}

class SubtitlesTableViewController: UITableViewController {
    
    var dataSourceArray: [PCTSubtitle]!
    weak var delegate: SubtitlesTableViewControllerDelegate?
    var selectedSubtitle: PCTSubtitle?

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath)
        cell.textLabel?.text = dataSourceArray[indexPath.row].language
        if let currentSubtitle = selectedSubtitle where currentSubtitle.link == dataSourceArray[indexPath.row].link {
            cell.accessoryType = .Checkmark
        } else {
            cell.accessoryType = .None
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        if cell.accessoryType == .Checkmark // If selected cell is already the current subtitle, the user wants to remove subtitles
        {
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            delegate?.didSelectASubtitle(nil)
            return
        }
        delegate?.didSelectASubtitle(dataSourceArray[indexPath.row])
        dismissViewControllerAnimated(true, completion: nil)
    }
}

extension PCTPlayerViewController {
    func didSelectASubtitle(subtitle: PCTSubtitle?) {
        currentSubtitle = subtitle
    }
}
