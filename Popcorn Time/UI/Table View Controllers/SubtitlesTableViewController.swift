

import UIKit

protocol SubtitlesTableViewControllerDelegate: class {
    func didSelectASubtitle(subtitle: PCTSubtitle?)
}

class SubtitlesTableViewController: UITableViewController {
    
    var dataSourceArray: [PCTSubtitle]!
    weak var delegate: SubtitlesTableViewControllerDelegate?

    // MARK: - Table view data source

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSourceArray.count
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SubtitlesTableViewCell
        cell.titleLabel?.text = dataSourceArray[indexPath.row].language
        cell.currentSubtitle = dataSourceArray[indexPath.row].language
        return cell
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let cell = tableView.cellForRowAtIndexPath(indexPath) as! SubtitlesTableViewCell
        if cell.checkmarkAccessory?.hidden == false // If selected cell is already the current subtitle, the user wants to remove subtitles
        {
            cell.checkmarkAccessory?.hidden = true
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
