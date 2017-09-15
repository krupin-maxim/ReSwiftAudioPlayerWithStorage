import Foundation
import ReSwift

// Actions are a declarative way of describing a state change. 
// Actions don’t contain any code, they are consumed by the store and forwarded to reducers.
// Reducers will handle the actions by implementing a different state change for each action.

/**
 * Actions for app in general.
 */
enum AppAction: Action {

    case SelectSong(index: Int);
}

/**
* Actions for network
*/
enum NetworkAction: Action {
    case DownloadSongsList(url:String);
    case SetSongs(list:[SongID], data: [SongID:SongData]);
    case SetSongIsDownloaded(id: SongID, storageURL: URL, artist: String, title: String);
}

/**
 * Actions for working with player, play/pause/prev/next/volume and trigger by end
 */
enum PlayerAction: Action {
    case TogglePlayPause;
    case PrevSong;
    case NextSong;
    case ChangeVolume(value: Float);
    case PlayerDidFinishPlaying;
}
