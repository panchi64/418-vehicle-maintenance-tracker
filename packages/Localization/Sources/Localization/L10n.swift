import Foundation

/// Shared string lookups for terms used across Checkpoint and Biombo.
/// Per-app strings live in each app's own String Catalog; this package only
/// hosts the genuinely shared vocabulary (units, fuel grades, common verbs).
public enum L10n {
    public enum Shared {
        public enum Units {
            public static let liters = NSLocalizedString("shared.units.liters", tableName: "Shared", bundle: .module, comment: "Unit label — liters")
            public static let gallons = NSLocalizedString("shared.units.gallons", tableName: "Shared", bundle: .module, comment: "Unit label — gallons")
            public static let miles = NSLocalizedString("shared.units.miles", tableName: "Shared", bundle: .module, comment: "Unit label — miles")
            public static let kilometers = NSLocalizedString("shared.units.kilometers", tableName: "Shared", bundle: .module, comment: "Unit label — kilometers")
        }

        public enum FuelGrade {
            public static let regular = NSLocalizedString("shared.fuelGrade.regular", tableName: "Shared", bundle: .module, comment: "Fuel grade — Regular")
            public static let premium = NSLocalizedString("shared.fuelGrade.premium", tableName: "Shared", bundle: .module, comment: "Fuel grade — Premium")
            public static let diesel = NSLocalizedString("shared.fuelGrade.diesel", tableName: "Shared", bundle: .module, comment: "Fuel grade — Diesel")
        }

        public enum Action {
            public static let cancel = NSLocalizedString("shared.action.cancel", tableName: "Shared", bundle: .module, comment: "Button label — Cancel")
            public static let save = NSLocalizedString("shared.action.save", tableName: "Shared", bundle: .module, comment: "Button label — Save")
            public static let delete = NSLocalizedString("shared.action.delete", tableName: "Shared", bundle: .module, comment: "Button label — Delete")
            public static let done = NSLocalizedString("shared.action.done", tableName: "Shared", bundle: .module, comment: "Button label — Done")
        }
    }
}
