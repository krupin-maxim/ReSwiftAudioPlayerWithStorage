import Foundation
import AELog
import AudioToolbox

/**
* Implements network layer: loading songs list, loading songs.
* Songs are loaded in queue by AppConsts.MAX_LOADED_FILES_IN_TIME
*/
class NetworkReducer {

    enum TryLoadSongStatus {
        case BadURL;
        case WasLoaded(fileURL: URL, artist: String, title: String);
        case InProgress(task: URLSessionDownloadTask);
    }

    // --------------- Dependencies

    public var appStoreHolder: AppStoreHolder?;
    var appModel: AppModel;

    init(_ appModel: AppModel) {
        self.appModel = appModel;
    }

    // ---------------

    /**
    * Reducer for NetworkAction
    */
    public func reducer(action: NetworkAction, inState: AppState) -> AppState {
        var state = inState;
        switch action {
        case .DownloadSongsList(let url):
            downloadSongsList(url);

        case .SetSongs(let songsList, let songsData):
            // Fill model and state
            appModel.songs = songsData;
            appModel.songsToDownload = [];
            state.songsList = songsList;

            // Try to read song files
            for songID in songsList.orderedSet {
                if let data = appModel.songs[songID] {
                    switch tryLoadSongFile(songID, data.networkURL) {
                    case .BadURL:
                        data.setIsBadURL(true);
                    case .WasLoaded(let storageURL, let artist, let title):
                        data.setLoaded(storageURL: storageURL, artist: artist, title: title);
                    case .InProgress(let session):
                        data.setDownloadSession(session);
                        appModel.songsToDownload.append(songID);
                    }
                }
            }

            // Start queue for loading songs
            let maxLoadedInTime = min(appModel.songsToDownload.count, AppConsts.MAX_LOADED_FILES_IN_TIME);
            let toLoadSongIDs = appModel.songsToDownload.cutSubarray(0..<maxLoadedInTime);
            for songID in toLoadSongIDs {
                if let data = appModel.songs[songID] {
                    data.resumeDownload();
                }
            }

        case .SetSongIsDownloaded(let id, let storageURL, let artist, let title):
            // Fill model and state
            if let songData = appModel.songs[id] {
                songData.setLoaded(storageURL: storageURL, artist: artist, title: title);
                state.lastLoadedSong = id;

            }
            // Check downloads list
            if let downloadedIndex = appModel.songsToDownload.index(of: id) {
                appModel.songsToDownload.remove(at: downloadedIndex);
            }
            // Start loading next song
            if appModel.songsToDownload.count > 0 {
                let songID = appModel.songsToDownload.removeFirst();
                if let data = appModel.songs[songID] {
                    data.resumeDownload();
                }
            }

        }
        return state;
    }

    // ------------------------- Work with songs lists

    // Just load and parse
    fileprivate func downloadSongsList(_ url: String) {
        if let url = URL(string: url) {
            let request = URLRequest(url: url);
            let task = URLSession.shared.dataTask(with: request, completionHandler: { (data: Data?, _: URLResponse?, error: Error?) -> Void in
                if let data = data, let content = String(data: data, encoding: .ascii) {
                    self.parseSongsListResponse(content: content);
                } else {
                    aelog("Bad data");
                }
                if let error = error {
                    aelog("Error: \(error)");
                }
            });
            task.resume();
        } else {
            aelog("Bad url: \(url)");
        }
    }

    fileprivate func parseSongsListResponse(content: String) {
        let mp3urls: [String] = content.components(separatedBy: "\n");

        var songID: SongID = 0;
        var songsData: [SongID: SongData] = [:];
        var songsList: [SongID] = [];
        for mp3url in mp3urls {
            if !mp3url.isEmpty {
                songID = mp3url.hash;
                songsData.updateValue(SongData.init(id: songID, url: mp3url), forKey: songID);
                songsList.append(songID);
            }
        }

        self.appStoreHolder?.store.dispatch(.SetSongs(list: songsList, data: songsData))
    }

    // -------------------------- Work with song loading

    // Cases: 1. song was loaded, 2. song need load
    fileprivate func tryLoadSongFile(_ id: Int, _ url: String) -> TryLoadSongStatus {
        if let audioUrl = URL(string: url), let host = audioUrl.host {
            let fileName = getSongFileName(host: host, path: audioUrl.pathComponents);
            let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0];
            let destinationUrl = documentsDirectoryURL.appendingPathComponent(fileName);

            if FileManager.default.fileExists(atPath: destinationUrl.path) {
                aelog("The file \(fileName) already exists at path");

                let tags = readTags(fileURL: destinationUrl);
                return .WasLoaded(fileURL: destinationUrl, artist: tags?.artist ?? "No meta", title: tags?.title ?? "No meta")

            } else {
                let task = downloadSong(id: id, audioUrl: audioUrl, destinationUrl: destinationUrl);
                return .InProgress(task: task);
            }
        } else {
            aelog("Bad url: \(url)");
            return .BadURL;
        }
    }

    fileprivate func getSongFileName(host: String, path: [String]) -> String {
        let fromHost = host.components(separatedBy: ".").joined(separator: "_");
        let fromPath = Array(path.dropFirst()).joined(separator: "_");
        let fileName = fromHost + "_" + fromPath;
        return fileName;
    }

    fileprivate func downloadSong(id: Int, audioUrl: URL, destinationUrl: URL) -> URLSessionDownloadTask {
        return URLSession.shared.downloadTask(with: audioUrl, completionHandler: { (location, _, error) -> Void in
            if let location = location {
                do {
                    try FileManager.default.moveItem(at: location, to: destinationUrl);
                    aelog("File moved to \(destinationUrl)");
                    self.sendDownloadedSong(id, fileURL: destinationUrl);
                } catch {
                    aelog("Error: \(error)");
                }
            }
            if let error = error {
                aelog("Error: \(error)");
            }
        });
    }

    fileprivate func sendDownloadedSong(_ id: Int, fileURL: URL) {
        let tags = readTags(fileURL: fileURL);
        appStoreHolder?.store.dispatch(.SetSongIsDownloaded(id: id, storageURL: fileURL, artist: tags?.artist ?? "No meta", title: tags?.title ?? "No meta"));
    }

    // ------------------- Work with tags in mp3

    fileprivate func readTags(fileURL: URL) -> (artist: String, title: String)? {
        var forwardAudioFile: AudioFileID?;
        var status = AudioFileOpenURL(fileURL as CFURL, .readPermission, kAudioFileMP3Type, &forwardAudioFile);
        guard status == noErr else {
            aelog("Cannot open file: \(fileURL)");
            return nil;
        }

        var size: UInt32 = 0;
        var isWritable: UInt32 = 0;
        status = AudioFileGetPropertyInfo(forwardAudioFile!, kAudioFilePropertyInfoDictionary, &size, &isWritable);
        guard status == noErr else {
            aelog("Cannot get property info for file: \(fileURL)");
            return nil;
        }

        var infoDictionary: NSDictionary = NSDictionary.init()

        status = AudioFileGetProperty(forwardAudioFile!, kAudioFilePropertyInfoDictionary, &size, &infoDictionary);
        guard status == noErr else {
            aelog("Cannot get property for file: \(fileURL)");
            return nil;
        }

        let title = infoDictionary.value(forKey: "title") as? String;
        let artist = infoDictionary.value(forKey: "artist") as? String;

        return (artist: artist ?? "", title: title ?? "");
    }
}
