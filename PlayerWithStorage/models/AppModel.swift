import Foundation

typealias SongID = Int;

/**
* Contains data for songs
*/
class AppModel {

    var songs: [SongID: SongData] = [:];
    var songsToDownload: [SongID] = [];
}

extension AppModel {

    /**
    * When song was loaded, it moved to storageUrl
    */
    func getSongStorageURL(songID: SongID?) -> URL? {
        if let songID = songID {
            return songs[songID]?.getStorageURL();
        }
        return nil;
    }

    /**
    * For player controls state
    */
    func isAnyLoaded() -> Bool {
        for data in songs.values {
            if data.getStorageURL() != nil {
                return true;
            }
        }
        return false;
    }

    /**
    * For player controls state
    */
    func isLoaded(songID: SongID?) -> Bool {
        return getSongStorageURL(songID: songID) != nil;
    }

}

class SongData {

    enum SongStatus {
        case NotLoaded;
        case Loaded(storageURL: URL, artist: String, title: String);
    }

    public fileprivate(set) var id: SongID = 0;
    public fileprivate(set) var networkURL: String;

    fileprivate var status: SongStatus = .NotLoaded;

    fileprivate var isBadURL: Bool = false;
    fileprivate var downloadSession: URLSessionDownloadTask? = nil;

    init(id: SongID, url: String) {
        self.id = id;
        self.networkURL = url;
    }

    // ------------------------

    public func canPlay() -> Bool {
        if case .Loaded = status {
            return true;
        }
        return false;
    }

    // ------------------------ Getters

    public func getTitle() -> String {
        if case let .Loaded(_, _, title) = status {
            return title;
        }
        return networkURL;
    }

    public func getArtist() -> String {
        if case let .Loaded(_, artist, _) = status {
            return artist;
        }
        return isBadURL ? "Bad URL" : "";
    }

    public func getStorageURL() -> URL? {
        if case let .Loaded(storageURL, _, _) = status {
            return storageURL;
        }
        return nil;
    }

    // ---------------------- Setters

    public func setLoaded(storageURL: URL, artist: String, title: String) {
        status = .Loaded(storageURL: storageURL, artist: artist, title: title);
        downloadSession = nil;
    }

    public func setDownloadSession(_ session: URLSessionDownloadTask) {
        self.downloadSession = session;
    }

    public func setIsBadURL(_ isBad: Bool) {
        self.isBadURL = isBad;
    }

    // ---------------------

    public func resumeDownload() {
        downloadSession?.resume();
    }



}
