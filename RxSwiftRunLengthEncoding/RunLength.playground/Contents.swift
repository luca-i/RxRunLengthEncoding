//: Run Length Encoding using RxSwift
// see [this](https://stackoverflow.com/questions/50163947/rxswift-count-how-many-equal-consecutive-equatable-items-are-emitted/50164733#50164733) question on StackOverflow

import Foundation
import RxSwift

// we have a sequence of Equatable elements
let numbers = Observable<Int>.from([
    0, 0,
    3, 3, 3, 3, 3,
    2,
    0, 0, 0,
    6, 6,
    ])

// and we want to 'rx-process' it to get something like:
//
// (0, 2), (3, 5), (2, 1), (0, 3), (6, 2)

// What follows is (my)[https://stackoverflow.com/users/1194774/luca] solution

// first I use scan operator to count how many consecutive elements have the
// same value

let repetitions = numbers
    .scan((0, 0), accumulator: {
        (prev: (value: Int, reps: Int), newValue: (Int)) in
        if prev.value == newValue {
            return (value: newValue, reps: prev.reps + 1)
        } else {
            return (value: newValue, reps: 1)
        }
    })

// now repetitions is something like:
// (0, 1), (0, 2),
// (3, 1), (3, 2), (3, 3), (3, 4), (3, 5),
// (2, 1),
// (0, 1), (0, 2), (0, 3),
// (6, 1), (6, 2)

// the elements that are part of the solution are:
// a. those that precede a tuple with a different `value`
// b. the last one

// to solve case a. I need to look ahead the stream of numbers.
// `lookaheadNumbers` = `numbers` without the very first item and a nil item at
// the end, so the two streams emit the exact same number of elements.
    
let lookaheadNumbers: Observable<Int?> = numbers
    .skip(1)
    .map({ $0 })
    .concat(Observable<Int?>.just(nil))

// Now I zip the two Observables:
//
// repetitions  |  lookaheadNumbers
//              |
//   (0, 1),    |          0
//   (0, 2),    |          3            condition a. met
//   (3, 1),    |          3
//   (3, 2),    |          3
//   (3, 3),    |          3
//   (3, 4),    |          3
//   (3, 5),    |          2            condition a. met
//   (2, 1),    |          0            condition a. met
//   (0, 1),    |          0
//   (0, 2),    |          0
//   (0, 3),    |          6            condition a. met
//   (6, 1),    |          6
//   (6, 2)     |        nil            condition b. met

let runLengthEncoded = Observable<(Int, Int)?>
    .zip(repetitions, lookaheadNumbers, resultSelector: {
        (repetitions: (value: Int, reps: Int), lookahead: Int?) -> ((Int, Int)?) in
        if lookahead == nil || lookahead != repetitions.value {
            return repetitions
        } else {
            return nil
        }
    })
    .filter({
        $0 != nil
    })

// the output is

runLengthEncoded.subscribe(onNext: {
    print($0!)
})
