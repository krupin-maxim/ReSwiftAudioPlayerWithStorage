import UIKit
import AELog
import AEConsole

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?;
    var appAudioPlayer: AppAudioPlayer?;
    var controlPanel: PlayerControlsView?;

    var appModel: AppModel?;
    var appStoreHolder: AppStoreHolder?;

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.

        self.appModel = AppModel();
        self.appStoreHolder = AppStoreHolder(self.appModel!);

        // Create root controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil);
        let rootViewController = storyboard.instantiateInitialViewController();

        if let songsViewController = rootViewController as? SongsViewController {
            songsViewController.appModel = appModel;
            songsViewController.appStoreHolder = appStoreHolder;
        }

        self.window = UIWindow(frame: UIScreen.main.bounds);
        self.window?.rootViewController = rootViewController;
        self.window?.makeKeyAndVisible();

        // Create panel for control playing mode and subscribe it to state
        controlPanel = PlayerControlsView.instanceFromNib();
        controlPanel?.appModel = appModel;
        controlPanel?.appStoreHolder = appStoreHolder;

        if let window = self.window {
            controlPanel!.frame = CGRect(x: 0,
                    y: window.frame.height - controlPanel!.frame.height,
                    width: window.frame.width,
                    height: controlPanel!.frame.height);

            window.addSubview(controlPanel!);
            self.appStoreHolder?.store.subscribe(controlPanel!);
        }

        // Create player and subscirbe it
        appAudioPlayer = AppAudioPlayer();
        appAudioPlayer?.appModel = appModel;
        appAudioPlayer?.appStoreHolder = appStoreHolder;
        self.appStoreHolder?.store.subscribe(appAudioPlayer!);

        // Init log console
        AEConsole.launch(with: self);

        self.appStoreHolder?.store.dispatch(.DownloadSongsList(url: AppConsts.MP3_LIST_URL));
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

