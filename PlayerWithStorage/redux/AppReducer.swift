import Foundation
import ReSwift
import AELog

/**
 * Reducers provide pure functions, that based on the current action and the current app state, create a new app state
 */
class AppReducer {

    // --------------- Dependencies

    var appModel: AppModel;
    fileprivate var networkReducer: NetworkReducer;

    init(_ appModel: AppModel, networkReducer: NetworkReducer) {
        self.appModel = appModel;
        self.networkReducer = networkReducer;
    }

    // ---------------

    /**
    * Top level reducer. It routes actions in sub-reducers
    */
    public func mainReducer(action: Action, state: AppState?) -> AppState {
        var state = state ?? AppState();

        // Handle app action
        if let action = action as? AppAction {
            return handle(appAction: action, inState: state);
        }

        // Handle NetworkReducer
        if let action = action as? NetworkAction {
            DispatchQueue.global(qos: .background).sync { [unowned self] in
                 state = self.networkReducer.reducer(action: action, inState: state);
            }
            return state;
        }

        // Handle PlayerAction
        if let action = action as? PlayerAction {
            return handle(playerAction: action, inState: state);
        }

        aelog("Unknown action: \(action)");
        return state;
    }

    // ------------- All about AppAction

    fileprivate func handle(appAction: AppAction, inState: AppState) -> AppState {
        var state = inState;
        switch appAction {
        case .SelectSong(let index):
            state.isPlayingMode = true;
            state.currentSongIndex = index;
        }
        return state;
    }

    // ------------- All about PlayerAction

    fileprivate func handle(playerAction: PlayerAction, inState: AppState) -> AppState {
        var state = inState;
        switch playerAction {

        case .PlayerDidFinishPlaying, .NextSong:
            if appModel.isLoaded(songID: state.getNextSongID()) {
                state.currentSongIndex = state.getNextSongIndex();
            } else {
                state.currentSongIndex = nil;
                state.isPlayingMode = false;
            }

        case .ChangeVolume(let value):
            state.currentVolume = value;

        case .TogglePlayPause:
            state.isPlayingMode = !state.isPlayingMode;
            if state.currentSongIndex == nil { // Try to find first loaded song
                for (index, songID) in state.songsList.enumerated() {
                    if appModel.isLoaded(songID: songID) {
                        state.currentSongIndex = index;
                        break;
                    }
                }
            }

        case .PrevSong:
            if appModel.isLoaded(songID: state.getPrevSongID()) {
                state.currentSongIndex = state.getPrevSongIndex();
            } else {
                state.currentSongIndex = nil;
                state.isPlayingMode = false;
            }

        }
        return state;
    }

}


