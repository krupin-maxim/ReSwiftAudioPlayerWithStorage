import Foundation
import ReSwift
import AELog


class AppStoreHolder {

    /**
     * The Store stores your entire app state in the form of a single data structure.
     * This state can only be modified by dispatching Actions to the store.
     * Whenever the state in the store changes, the store will notify all observers.
     */
    public let store: Store<AppState>;

    /**
    * ReSwift supports middleware in the same way as Redux does.
    * The simplest example of a middleware, is one that prints all actions to the console.
    */
    public let loggingMiddleware: Middleware<Any> = { dispatch, getState in
        return { next in
            return { action in
                aelog("<action> \(action)");
                return next(action);
            }
        }
    }

    init(_ appModel: AppModel) {
        let networkReducer = NetworkReducer(appModel);
        let appReducer = AppReducer(appModel, networkReducer: networkReducer);
        store = Store<AppState>(reducer: appReducer.mainReducer, state: AppState.init(), middleware: [loggingMiddleware]);
        networkReducer.appStoreHolder = self;
    }
}

