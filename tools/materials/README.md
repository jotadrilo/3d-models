# materials: filament data sheets

Bambu Lab technical data sheets (TDS) for the filaments this repo prints with (CLAUDE.md §1,
§8), kept here so the numbers behind a design or a load analysis can be checked without
searching again. The PDFs are Bambu Lab's documents, copied as published.

## Key figures

Printed test bars, 100 % infill, as each TDS reports them (ISO 527 tensile, ISO 75 heat
deflection). X-Y is along the layers, Z across them. For design, derate Z further from real
parts (CLAUDE.md §2.3): the coupons flatter it.

| Material | TDS | E X-Y / Z (MPa) | Tensile X-Y / Z (MPa) | Elongation X-Y / Z (%) | HDT 1.8 / 0.45 MPa (°C) | Tg (°C) | Density | Source |
|---|---|---|---|---|---|---|---|---|
| [PLA Basic](bambu-pla-basic-tds.pdf) | V3.0 | 2580 / 2060 | 35 / 31 | 12.2 / 7.5 | 54 / 57 | 60 | 1.24 | Bambu CDN |
| [PLA Matte](bambu-pla-matte-tds.pdf) | V3.0 | 1960 / 1670 | 30 / 22 | 14.8 / 4.8 | 52 / 58 | 61 | 1.31 | Bambu CDN |
| [PLA Pure](bambu-pla-pure-tds.pdf) | V1.0 | 2481 / 2196 | 51.5 / 30 | 5.6 / 2.8 | 56 / 60 | 55 | 1.24 | Bambu CDN |
| [PLA Silk](bambu-pla-silk-tds.pdf) | V1.0 | 2470 / 1390 | 35 / 18 | 3.5 / 1.7 | 50 / 53 | 57 | 1.19 | reseller copy (Additive-X) |
| [PETG Basic](bambu-petg-basic-tds.pdf) | V2.0 | 1460 / 1120 | 48 / 39 | 11.2 / 5.7 | 65 / 69 | 68 | 1.25 | reseller copy (Additive-X) |
| [PETG HF](bambu-petg-hf-tds.pdf) | V1.0 | 1810 / 1540 | 34 / 23 | 8.6 / 5.1 | 62 / 69 | 66 | 1.28 | reseller copy (Botland) |
| [ABS](bambu-abs-tds.pdf) | V2.0 | 3800 / 2960 | 41 / 32 | 10.5 / 4.7 | 84 / 87 | — | 1.05 | reseller copy (Additive-X) |
| [TPU 95A HF](bambu-tpu-95a-hf-tds.pdf) | V1.0 | 9.8 / 7.4 | 27.3 / 22.3 | > 650 / > 480 | — | — | 1.22 | reseller copy (Additive-X) |

Notes:
- **PLA Pure**: every ingredient, pigments included, is certified for EU food contact. The TDS
  advises **no glue** on the bed, since adhesive residue may compromise the parts' contact
  safety. Its header says "PLA Silk material" and its comparison table swaps bending modulus
  and strength: template slips in Bambu's PDF, the main tables are right.
- **PLA Silk** is the older PLA Silk, not the Silk+ in CLAUDE.md: no Silk+ sheet was found.
- **PETG Matte** (in `bambu3mf.py`): no sheet found. Launch coverage quotes E 3349 / 3174 MPa and
  elongation 13.8 / 6.5 % (All3DP); add the PDF when Bambu publishes it.
- Reseller copies are Bambu's PDFs as hosted by a reseller; check them against Bambu's
  download page when a number matters.
- Poisson's ratio is not in any TDS: ≈ 0.36 for PLA, 0.38 for PETG (tools/fea).

## Adding one

Download the TDS from the filament's page on the Bambu store (the PDF link sits under
"Specs"/"Downloads"), save it as `bambu-<material>-tds.pdf`, and add its row above.
