# materials: filament data sheets

Bambu Lab technical data sheets (TDS) for the filaments this repo prints with (CLAUDE.md §1,
§8), kept here so the numbers behind a design or a load analysis can be checked without
searching again. The PDFs are Bambu Lab's documents, copied as published.

## Key figures

Printed test bars, 100 % infill, as each TDS reports them (ISO 527 tensile, ISO 75 heat
deflection). X-Y is along the layers, Z across them. For design, derate Z further from real
parts (CLAUDE.md §2.3): the coupons flatter it.

| Material | TDS | E X-Y / Z (MPa) | Tensile X-Y / Z (MPa) | Elongation X-Y / Z (%) | HDT 1.8 / 0.45 MPa (°C) | Tg (°C) | Density |
|---|---|---|---|---|---|---|---|
| [PLA Basic](bambu-pla-basic-tds.pdf) | V3.0 | 2580 / 2060 | 35 / 31 | 12.2 / 7.5 | 54 / 57 | 60 | 1.24 |
| [PLA Matte](bambu-pla-matte-tds.pdf) | V3.0 | 1960 / 1670 | 30 / 22 | 14.8 / 4.8 | 52 / 58 | 61 | 1.31 |
| [PLA Pure](bambu-pla-pure-tds.pdf) | V1.0 | 2481 / 2196 | 51.5 / 30 | 5.6 / 2.8 | 56 / 60 | 55 | 1.24 |
| [PLA Silk+](bambu-pla-silk-plus-tds.pdf) | V1.0 | 2130 / 1850 | 33 / 25 | 2.8 / 1.5 | 56 / 60 | 57 | 1.27 |
| [PETG Basic](bambu-petg-basic-tds.pdf) | V3.0 | 2780 / 2550 | 51 / 35 | 9.5 / 5.2 | 68 / 71 | 69 | 1.25 |
| [PETG HF](bambu-petg-hf-tds.pdf) | V1.0 | 1810 / 1540 | 34 / 23 | 8.6 / 5.1 | 62 / 69 | 66 | 1.28 |
| [PETG Matte](bambu-petg-matte-tds.pdf) | V1.0 | 3349 / 3174 | 42.9 / 30.1 | 13.8 / 6.5 | 71.2 / 72.3 | 71 | 1.37 |
| [ABS](bambu-abs-tds.pdf) | V3.0 | 2200 / 1960 | 33 / 28 | 10.5 / 4.7 | 84 / 87 | — | 1.05 |
| [TPU 95A HF](bambu-tpu-95a-hf-tds.pdf) | V1.0 | 9.8 / 7.4 | 27.3 / 22.3 | > 650 / > 480 | — | — | 1.22 |

All of them are Bambu Lab's own PDFs, from its store CDN (`store.bblcdn.com` / `.eu`) or
its wiki, downloaded 2026-10-25.

Notes:
- **PLA Pure**: every ingredient, pigments included, is certified for EU food contact; it is
  the only sheet here that claims food contact. The TDS advises **no glue** on the bed, since
  adhesive residue may compromise the parts' contact safety. Its header says "PLA Silk
  material" and its comparison table swaps bending modulus and strength: template slips in
  Bambu's PDF, the main tables are right.
- **PETG Basic V3.0** replaces V2.0 (E 1460 / 1120, tensile 48 / 39 MPa), which the
  sink-organizers analyses used: the reformulated filament is about twice as stiff. Spools
  bought before 2025 may be the old one.
- **ABS V3.0** replaces V2.0 (E 3800 / 2960, tensile 41 / 32 MPa).
- The PETG sheets recommend glue on the plate (as a release layer on textured PEI).
- Poisson's ratio is not in any TDS: ≈ 0.36 for PLA, 0.38 for PETG (tools/fea).

## Adding one

Download the TDS from the filament's page on the Bambu store (the PDF link sits under
"Specs"/"Downloads"), save it as `bambu-<material>-tds.pdf`, and add its row above.
