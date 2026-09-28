import SwiftUI

/// Ajustes › Muestra: switches for trying the sample island (debug builds
/// only). Crisis mode asks the sample provider for its crisis variant; the
/// connection stands in for a real network monitor.
struct SampleSection: View {
    @Environment(SampleSwitches.self) private var switches
    @Environment(DeviceStore.self) private var device
    @Environment(WatchStore.self) private var watches

    var body: some View {
        @Bindable var switches = switches
        @Bindable var device = device
        Section {
            Toggle(isOn: $switches.isCrisis) {
                Text("Modo emergencia", comment: "Crisis banner title")
            }
            Picker(selection: $device.connection) {
                ForEach(ConnectionStatus.allCases, id: \.self) { status in
                    Text(status.title).tag(status)
                }
            } label: {
                Text("Conexión", comment: "Sample settings: the simulated connection")
            }
            Button {
                watches.replaceAll(with: SampleData.watchedPlaces)
            } label: {
                Text("Vigilar los lugares de muestra", comment: "Sample settings: replace the watch list with the sample places")
            }
        } header: {
            Text("Muestra", comment: "Settings section: sample data switches")
        } footer: {
            Text("Datos inventados para probar la app. Fuera de la muestra, el modo emergencia lo deciden los avisos oficiales y los reportes.", comment: "Sample settings footer: the data is invented; real crisis mode follows official alerts and reports")
        }
    }
}
