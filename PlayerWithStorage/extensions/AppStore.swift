import Foundation
import ReSwift

/**
* Aliases for using actions
*/
extension Store {

    func dispatch(_ action: AppAction) {
        self.dispatch(action as Action);
    }

    func dispatch(_ action: NetworkAction) {
        self.dispatch(action as Action);
    }

    func dispatch(_ action: PlayerAction) {
        self.dispatch(action as Action);
    }

}
