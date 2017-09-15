import Foundation

extension Array where Element:Hashable {

    var orderedSet: Array {
        var unique = Set<Element>();
        return filter { element in
            return unique.insert(element).inserted;
        }
    }

    mutating func cutSubarray(_ bounds: Range<Int>) -> Array {
        let slice = Array(self[bounds]);
        self.removeSubrange(bounds);
        return slice;
    }

}
