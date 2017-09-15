import Foundation
import ReSwift

/**
 * The state struct store entire application state, that includes the UI state and the state of model layer.
 */
struct AppState: StateType {

    var currentSongIndex: Int? = nil;
    var songsList: [SongID] = [];

    var isPlayingMode: Bool = false;
    var currentVolume: Float = 1.0;

    var lastLoadedSong: SongID? = nil;

}

/**
* Helpers for work with playlist
*/
extension AppState {

    func getCurrentSongID() -> SongID? {
        if let index = self.currentSongIndex, index < self.songsList.count {
            return self.songsList[index];
        }
        return nil;
    }

    func getNextSongIndex() -> Int? {
        if songsList.count > 0, let index = self.currentSongIndex {
            return (index + 1) % songsList.count;
        }
        return nil;
    }

    func getPrevSongIndex() -> Int? {
        if songsList.count > 0, let index = self.currentSongIndex {
            return (songsList.count + index - 1) % songsList.count;
        }
        return nil;
    }

    func getNextSongID() -> SongID? {
        if let songIndex = getNextSongIndex() {
            return songsList[songIndex];
        }
        return nil;
    }

    func getPrevSongID() -> SongID? {
        if let songIndex = getPrevSongIndex() {
            return songsList[songIndex];
        }
        return nil;
    }

}
