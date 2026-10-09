# Podcast-data voor AI Journaal

- `index.json`: lijst van afleveringen, nieuwste eerst. Velden per aflevering: `date` (JJJJ-MM-DD), `title`, `summary`, `durationSeconds`, `file`.
- `episodes/JJJJ-MM-DD.json`: de aflevering zelf, met `date`, `title`, `summary`, `durationSeconds` en `segments`.
- Elk segment heeft `kind` (`intro`, `news` of `outro`), `headline`, `text` en bij nieuws ook `source` en `url`.

De app leest `text` letterlijk voor; schrijf dus voor het oor, zonder afkortingen of opmaak.
