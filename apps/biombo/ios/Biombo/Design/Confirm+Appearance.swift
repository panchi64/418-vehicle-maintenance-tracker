import SwiftUI

/// Words for the confirm question (PRODUCT.md §4.3) and its replies. Every
/// question names what it confirms, so none falls back to "¿Sigue así?".
extension ConfirmQuestion {
    func text(unit: PriceUnit, locale: Locale) -> LocalizedStringResource {
        switch self {
        case .price(let price):
            let amount = GlanceNumbers.price(price, unit: unit, locale: locale)
            return LocalizedStringResource("¿Sigue a \(amount)?", comment: "Confirm question about a price, e.g. '¿Sigue a $0.99?'")
        case .outage(.water):
            return LocalizedStringResource("¿Sigue sin agua?", comment: "Confirm question about a water outage")
        case .outage(.signal):
            return LocalizedStringResource("¿Sigue sin señal?", comment: "Confirm question about a signal outage")
        case .outage:
            return LocalizedStringResource("¿Sigue sin luz?", comment: "Confirm question about a power outage")
        case .status(let kind):
            return kind.stillQuestion
        }
    }

    /// The price follow-up's "no fuel" reply, in the price's own fuel.
    var noLongerReply: LocalizedStringResource {
        if case .price(let price) = self, price.grade == .diesel {
            return ReportKind.noDiesel.word
        }
        return ReportKind.noGas.word
    }
}

private extension ReportKind {
    var stillQuestion: LocalizedStringResource {
        switch self {
        case .price: LocalizedStringResource("¿Sigue ese precio?", comment: "Confirm question: the reported price still holds")
        case .noGas: LocalizedStringResource("¿Sigue sin gasolina?", comment: "Confirm question: the station is still out of gas")
        case .noDiesel: LocalizedStringResource("¿Sigue sin diésel?", comment: "Confirm question: the station is still out of diesel")
        case .hasGas: LocalizedStringResource("¿Sigue habiendo gasolina?", comment: "Confirm question: the station still has gas")
        case .hasDiesel: LocalizedStringResource("¿Sigue habiendo diésel?", comment: "Confirm question: the station still has diesel")
        case .stationClosed, .closed, .landslide: LocalizedStringResource("¿Sigue cerrada?", comment: "Confirm question: the station or road is still closed")
        case .queue: LocalizedStringResource("¿Sigue la fila?", comment: "Confirm question: there is still a line")
        case .cashOnly: LocalizedStringResource("¿Sigue solo en efectivo?", comment: "Confirm question: still cash only")
        case .perPersonLimit: LocalizedStringResource("¿Sigue el límite?", comment: "Confirm question: the per-person limit still applies")
        case .openOnGenerator, .businessOnGenerator: LocalizedStringResource("¿Sigue con planta?", comment: "Confirm question: still running on a generator")
        case .hasIce: LocalizedStringResource("¿Sigue habiendo hielo?", comment: "Confirm question: ice is still available")
        case .hasCookingGas: LocalizedStringResource("¿Sigue habiendo gas?", comment: "Confirm question: cooking gas is still available")
        case .noPower: LocalizedStringResource("¿Sigue sin luz?", comment: "Confirm question about a power outage")
        case .powerBack: LocalizedStringResource("¿Sigue con luz?", comment: "Confirm question: the power is still back")
        case .unstablePower: LocalizedStringResource("¿Sigue yendo y viniendo?", comment: "Confirm question: the power still goes on and off")
        case .lineDown, .treeOrPole, .transformerBlew, .brokenPipe, .pothole: LocalizedStringResource("¿Sigue ahí?", comment: "Confirm question: the hazard is still there")
        case .noWater: LocalizedStringResource("¿Sigue sin agua?", comment: "Confirm question about a water outage")
        case .waterBack: LocalizedStringResource("¿Sigue con agua?", comment: "Confirm question: the water is still back")
        case .lowPressure: LocalizedStringResource("¿Sigue con poca presión?", comment: "Confirm question: the water pressure is still low")
        case .cloudyWater: LocalizedStringResource("¿Sigue turbia?", comment: "Confirm question: the water is still cloudy")
        case .sawBoilNotice: LocalizedStringResource("¿Sigue el aviso de hervir?", comment: "Confirm question: the boil-water notice is still posted")
        case .waterPoint: LocalizedStringResource("¿Siguen repartiendo agua?", comment: "Confirm question: water is still being handed out here")
        case .noSignal: LocalizedStringResource("¿Sigue sin señal?", comment: "Confirm question about a signal outage")
        case .callsOnly: LocalizedStringResource("¿Siguen solo las llamadas?", comment: "Confirm question: still calls only, no data")
        case .hasData: LocalizedStringResource("¿Sigue habiendo datos?", comment: "Confirm question: mobile data still works")
        case .signalSpot: LocalizedStringResource("¿Sigue habiendo señal aquí?", comment: "Confirm question: this spot still has signal")
        case .flooded: LocalizedStringResource("¿Sigue inundada?", comment: "Confirm question: the road is still flooded")
        case .oneLane: LocalizedStringResource("¿Sigue un solo carril?", comment: "Confirm question: still one lane only")
        case .highClearanceOnly: LocalizedStringResource("¿Sigue solo para vehículos altos?", comment: "Confirm question: still passable only for high-clearance vehicles")
        case .reopened: LocalizedStringResource("¿Sigue abierta?", comment: "Confirm question: people still report the road open")
        case .chargerWorks, .newCharger: LocalizedStringResource("¿Sigue funcionando?", comment: "Confirm question: the charger still works")
        case .chargerBroken, .connectorDamaged: LocalizedStringResource("¿Sigue sin funcionar?", comment: "Confirm question: the charger is still broken")
        case .slowCharging: LocalizedStringResource("¿Sigue cargando lento?", comment: "Confirm question: the charger is still slow")
        case .chargerBusy, .chargerBlocked: LocalizedStringResource("¿Sigue ocupado?", comment: "Confirm question: the charger is still busy")
        case .needsAppOrCard: LocalizedStringResource("¿Sigue pidiendo app o tarjeta?", comment: "Confirm question: the charger still needs an app or card")
        case .businessOpen: LocalizedStringResource("¿Sigue abierto?", comment: "Confirm question: the business is still open")
        case .businessClosed: LocalizedStringResource("¿Sigue cerrado?", comment: "Confirm question: the business is still closed")
        case .productAvailable, .event, .specialHours: LocalizedStringResource("¿Sigue así?", comment: "Confirm question: is it still as reported")
        }
    }
}

extension ConfirmReply {
    /// The sent state: one sentence, with Deshacer beside it.
    var thanks: LocalizedStringResource {
        switch self {
        case .same: LocalizedStringResource("Gracias. Contamos que sigue igual.", comment: "Confirm sent: the user said it is still the same")
        case .changed: LocalizedStringResource("Gracias. Contamos que ya no.", comment: "Confirm sent: the user said it is no longer so")
        case .otherPrice: LocalizedStringResource("Gracias. Repórtanos el precio nuevo.", comment: "Confirm sent: the price changed; asks for the new price")
        case .noGas: LocalizedStringResource("Gracias. Avisamos a los vecinos que no hay.", comment: "Confirm sent: the station has no gas")
        }
    }
}
