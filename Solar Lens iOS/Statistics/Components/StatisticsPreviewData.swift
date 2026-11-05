#if DEBUG
    internal import Foundation

    /// Made-up but plausibly shaped figures for the statistics previews: a
    /// roughly 10 kWp roof with a 10 kWh battery and an EV that charges on
    /// some days. Seeded, so a preview looks the same on every render.
    ///
    /// These are NOT measurements. Shapes judged on them still need a look
    /// with a real installation's data.
    extension DayStatistic {

        /// Every day of a month in 2026.
        static func previewMonth(month: Int) -> [DayStatistic] {
            let calendar = Calendar(identifier: .iso8601)
            guard
                let start = calendar.date(
                    from: DateComponents(year: 2026, month: month, day: 1)
                ),
                let count = calendar.range(of: .day, in: .month, for: start)?.count
            else { return [] }

            var random = SeededGenerator(seed: UInt64(month) &* 7919)
            let sun = sunFactor[month - 1]
            let heating = heatingFactor[month - 1]

            return (0..<count).compactMap { offset in
                guard let day = calendar.date(byAdding: .day, value: offset, to: start)
                else { return nil }

                // Mostly decent days with the odd dull one.
                let clear = 1 - pow(Double.random(in: 0...1, using: &random), 2.2)
                let production = (4 + clear * 58) * sun

                let chargesCar = Double.random(in: 0...1, using: &random) < 0.28
                let consumption =
                    (15 + Double.random(in: 0...9, using: &random)) * heating
                    + (chargesCar ? 14 : 0)

                // What the roof covers directly, then what the battery shifts
                // into the evening. Charge and discharge differ, so production
                // minus export is not consumption minus import.
                // The car mostly charges after sunset, so those days lean on
                // the grid however sunny they were.
                let direct =
                    min(production, consumption)
                    * Double.random(in: 0.38...0.6, using: &random)
                let charged = min(production - direct, 10)
                let discharged = min(
                    (consumption - direct) * Double.random(in: 0.45...0.95, using: &random),
                    charged * 0.9
                )

                return DayStatistic(
                    day: day,
                    consumption: consumption * 1000,
                    production: production * 1000,
                    imported: (consumption - direct - discharged) * 1000,
                    exported: (production - direct - charged) * 1000,
                    batteryCharged: charged * 1000,
                    batteryDischarged: discharged * 1000
                )
            }
        }

        /// The twelve month buckets of 2025.
        static func previewYear() -> [DayStatistic] {
            let calendar = Calendar(identifier: .iso8601)
            return (1...12).compactMap { month in
                guard
                    let start = calendar.date(
                        from: DateComponents(year: 2025, month: month, day: 1)
                    )
                else { return nil }

                let production = 1250 * sunFactor[month - 1]
                let consumption = 620 * heatingFactor[month - 1]
                let own = min(production, consumption) * 0.74

                return DayStatistic(
                    day: start,
                    consumption: consumption * 1000,
                    production: production * 1000,
                    imported: (consumption - own) * 1000,
                    exported: (production - own) * 1000
                )
            }
        }

        /// Yield per month relative to a good summer month, Swiss midlands.
        private static let sunFactor: [Double] = [
            0.22, 0.36, 0.62, 0.84, 0.98, 1.0, 1.0, 0.92, 0.70, 0.44, 0.24, 0.17,
        ]

        /// Consumption per month relative to summer — a heat pump in winter.
        private static let heatingFactor: [Double] = [
            2.1, 1.9, 1.6, 1.3, 1.05, 1.0, 1.0, 1.0, 1.1, 1.4, 1.8, 2.1,
        ]
    }

    /// SplitMix64 — small, and the same sequence on every run.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64

        init(seed: UInt64) { state = seed }

        mutating func next() -> UInt64 {
            state &+= 0x9E37_79B9_7F4A_7C15
            var z = state
            z = (z ^ (z >> 30)) &* 0xBF58_476D_1CE4_E5B9
            z = (z ^ (z >> 27)) &* 0x94D0_49BB_1331_11EB
            return z ^ (z >> 31)
        }
    }
#endif
