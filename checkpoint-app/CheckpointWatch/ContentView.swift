//
//  ContentView.swift
//  CheckpointWatch
//
//  Root navigation for Watch app — shows services list or empty state
//

import SwiftUI

struct ContentView: View {
    @Environment(WatchDataStore.self) private var dataStore

    var body: some View {
        NavigationStack {
            ServicesListView()
        }
    }
}
