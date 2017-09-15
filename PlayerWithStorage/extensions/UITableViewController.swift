import Foundation
import UIKit

/**
 * Simplify work with tables
 */
extension UITableViewController {

    func deselectRow() {
        if let indexPath = self.tableView.indexPathForSelectedRow {
            self.tableView.deselectRow(at: indexPath, animated: true);
        }
    }

    func selectRowAt(index: Int, section: Int = 0) {
        self.tableView.selectRow(at: IndexPath.init(row: index, section: section), animated: true, scrollPosition: .middle);
    }
    
}
