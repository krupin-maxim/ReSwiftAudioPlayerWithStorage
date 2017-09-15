import Foundation
import UIKit
import ReSwift

/**
 * Table with songs
 */
class SongsViewController: UITableViewController {

    private static let cellIdentifier = "SongName";

    // --------------- Dependencies

    public var appModel: AppModel? = nil;
    public var appStoreHolder: AppStoreHolder? = nil;

    // ---------------

    fileprivate var innerState: AppState? = nil;

    override func viewDidLoad() {
        super.viewDidLoad();
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated);
        appStoreHolder?.store.subscribe(self);
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated);
        appStoreHolder?.store.unsubscribe(self);
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return innerState?.songsList.count ?? 0;
    }

    override public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: SongsViewController.cellIdentifier, for: indexPath);
        if let songID = innerState?.songsList[indexPath.row], let data = appModel?.songs[songID] {
            cell.textLabel?.text = data.getTitle();
            cell.detailTextLabel?.text = data.getArtist();
        }
        return cell;
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        appStoreHolder?.store.dispatch(.SelectSong(index: indexPath.row));
    }

}

// --------------------------- All about state

extension SongsViewController: ReSwift.StoreSubscriber {

    func newState(state: AppState) {
        DispatchQueue.main.async { [weak self] in
            let oldState = self?.innerState;
            self?.innerState = state;

            if differ(oldState?.songsList, state.songsList) { // Songs loaded
                self?.tableView.reloadData();
            }

            if differ(oldState?.lastLoadedSong, state.lastLoadedSong) { // Loaded song, change cell for it
                if let songID = state.lastLoadedSong {
                    let indexes = state.songsList.enumerated().flatMap { $0.element == songID ? $0.offset : nil };
                    for index in indexes {
                        if let cell = self?.tableView.cellForRow(at: IndexPath.init(row: index, section: 0)),
                           let data = self?.appModel?.songs[songID] {
                            cell.textLabel?.text = data.getTitle();
                            cell.detailTextLabel?.text = data.getArtist();
                        }
                    }
                }
            }

            if differ(oldState?.currentSongIndex, state.currentSongIndex) { // Show current song in table
                if let index = state.currentSongIndex {
                    self?.selectRowAt(index: index);
                } else {
                    self?.deselectRow();
                }
            }
        }
    }

}
