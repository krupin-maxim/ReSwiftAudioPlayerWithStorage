import Foundation
import UIKit
import ReSwift

/**
 * Controller for PlayerControls.xib
 * Works with play/pause/prev/next buttons and volume slider
 */
class PlayerControlsView: UIView {

    fileprivate static let PLAY_PAUSE_BTN_POS: Int = 2;

    // --------------- Dependencies

    public var appStoreHolder: AppStoreHolder?;
    public var appModel: AppModel?;

    // ---------------

    @IBOutlet weak var toolbar: UIToolbar!
    @IBOutlet weak var prevSongBtn: UIBarButtonItem!
    @IBOutlet weak var nextSongBtn: UIBarButtonItem!
    @IBOutlet weak var volumeSlider: UISlider!

    var playButton: UIBarButtonItem!;
    var pauseButton: UIBarButtonItem!;

    fileprivate var innerState: AppState? = nil;

    class func instanceFromNib() -> PlayerControlsView {
        return UINib(nibName: "PlayerControls", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! PlayerControlsView;
    }

    public func setEnabled(isAllEnabled: Bool, isPrevEnabled: Bool, isNextEnabled: Bool) {
        prevSongBtn?.isEnabled = isAllEnabled && isPrevEnabled;
        playButton?.isEnabled = isAllEnabled;
        pauseButton?.isEnabled = isAllEnabled;
        nextSongBtn?.isEnabled = isAllEnabled && isNextEnabled;
    }

    override func awakeFromNib() {
        self.playButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.play, target: self, action: #selector(PlayerControlsView.handlePlayPauseBtnTap(_:)));
        self.pauseButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.pause, target: self, action: #selector(PlayerControlsView.handlePlayPauseBtnTap(_:)));

        setPlayPauseButton(isPlaying: false);
        setEnabled(isAllEnabled: false, isPrevEnabled: false, isNextEnabled: false);
    }

    func handlePlayPauseBtnTap(_ sender: AnyObject) {
        appStoreHolder?.store.dispatch(.TogglePlayPause);
    }

    @IBAction func handlePrevBtnTap(_ sender: UIBarButtonItem) {
        appStoreHolder?.store.dispatch(.PrevSong);
    }

    @IBAction func handleNextBtnTap(_ sender: UIBarButtonItem) {
        appStoreHolder?.store.dispatch(.NextSong);
    }

    @IBAction func handleVolumeValueChanged(_ sender: UISlider) {
        appStoreHolder?.store.dispatch(.ChangeVolume(value: sender.value));
    }

    func setPlayPauseButton(isPlaying: Bool) {
        self.toolbar.items![PlayerControlsView.PLAY_PAUSE_BTN_POS] = isPlaying ? pauseButton : playButton;
    }

}

// -------------------------- All about state

extension PlayerControlsView: ReSwift.StoreSubscriber {

    func newState(state: AppState) {
        DispatchQueue.main.async { [weak self] in
            let oldState = self?.innerState;
            self?.innerState = state;

            if differ(oldState?.isPlayingMode, state.isPlayingMode) { // Toggle play/pause button
                self?.setPlayPauseButton(isPlaying: state.isPlayingMode);
            }

            if differ(oldState?.currentVolume, state.currentVolume) { // Restore volume slider position
                self?.volumeSlider.value = state.currentVolume;
            }

            if differ(oldState?.songsList, state.songsList) || // Set enabled buttons
                       differ(oldState?.lastLoadedSong, state.lastLoadedSong) ||
                       differ(oldState?.currentSongIndex, state.currentSongIndex) {
                let prevLoaded = self?.appModel?.isLoaded(songID: state.getPrevSongID());
                let nextLoaded = self?.appModel?.isLoaded(songID: state.getNextSongID());

                self?.setEnabled(isAllEnabled: self?.appModel?.isAnyLoaded() ?? false,
                        isPrevEnabled: prevLoaded ?? false,
                        isNextEnabled: nextLoaded ?? false
                );
            }
        }
    }
}
