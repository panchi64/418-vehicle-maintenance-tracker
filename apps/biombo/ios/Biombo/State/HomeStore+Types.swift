extension HomeStore {
    /// What the sheet is doing besides answering for the area.
    enum Mode: Equatable {
        case nearby
        case searching
        /// Quick Report, about `reportFocus`.
        case reporting
    }

    /// Why the search is open: to find something, or to pick a place to watch.
    enum SearchPurpose: Equatable {
        case find
        case watch
    }

    /// What the watch list asked for as it closed.
    enum AfterWatchList: Equatable {
        case setup(WatchedPlace)
        case findPlaceToWatch
    }
}
