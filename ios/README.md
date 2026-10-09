# AI Journaal (iPhone-app)

Native SwiftUI-app die elke ochtend een nieuwslezing van vijf minuten over AI voorleest.

- De afleveringen staan als JSON in [`/podcast`](../podcast) en worden dagelijks aangevuld door een scheduled task.
- De app haalt `podcast/index.json` op en leest de aflevering voor met de Nederlandse stem van iOS (AVSpeechSynthesizer).
- Vereist Xcode 16 of nieuwer en iOS 17 of nieuwer.

## Op je iPhone zetten

1. Open `ios/AIJournaal/AIJournaal.xcodeproj` in Xcode.
2. Kies bij het target **AIJournaal › Signing & Capabilities** je eigen team (een gratis Apple ID volstaat) en pas zo nodig de bundle identifier aan.
3. Sluit je iPhone aan, kies hem als doel en druk op Run.

Voor de beste stem: Instellingen › Toegankelijkheid › Gesproken materiaal › Stemmen › Nederlands, en download een verbeterde of premium stem.
