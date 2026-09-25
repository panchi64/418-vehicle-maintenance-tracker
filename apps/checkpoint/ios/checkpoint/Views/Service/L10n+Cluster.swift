//
//  L10n+Cluster.swift
//  checkpoint
//
//  Strings for the service-visit (cluster) detail sheet. Keys are prefixed
//  `cluster.`.
//

import Foundation

extension L10n {
    private static func cluster(_ key: String) -> String {
        NSLocalizedString(key, comment: "")
    }

    static var clusterTitle: String { cluster("cluster.title") }
    static var clusterSummary: String { cluster("cluster.summary") }
    static var clusterServices: String { cluster("cluster.services") }
    static var clusterRowServices: String { cluster("cluster.row.services") }
    static var clusterRowWindow: String { cluster("cluster.row.window") }
    static var clusterRowTarget: String { cluster("cluster.row.target") }
    static var clusterRowDue: String { cluster("cluster.row.due") }
    static var clusterMarkAllDone: String { cluster("cluster.markAllDone") }
    static func clusterLogAll(_ count: Int) -> String {
        String(format: cluster("cluster.logAll"), count)
    }
    static var clusterTipLabel: String { cluster("cluster.tip.label") }
    static var clusterTipTitle: String { cluster("cluster.tip.title") }
    static var clusterTipBody: String { cluster("cluster.tip.body") }
}
