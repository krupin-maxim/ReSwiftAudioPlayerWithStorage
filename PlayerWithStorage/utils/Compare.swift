import Foundation

/**
 * Helper for observe states. It compares left-optional and right-nonoptional
 */
func differ<TArg:Equatable>(_ left: TArg?, _ right: TArg) -> Bool {
    return left.flatMap {
        $0 != right
    } ?? true;
}

/**
* Array is not Equatable in swift
*/
func differ<TItem:Equatable>(_ left: Array<TItem>?, _ right: Array<TItem>) -> Bool {
    return left.flatMap { left in
        if left.count != right.count {
            return true;
        } else {
            return left != right
        }
    } ?? true;
}

/**
* Just for unification code-style
*/
func differ<TArg:Equatable>(_ left: TArg?, _ right: TArg?) -> Bool {
    return left != right;
}
