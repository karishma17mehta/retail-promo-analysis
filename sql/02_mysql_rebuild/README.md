# 02 — MySQL rebuild (current)

The pipeline rebuilt from the raw Kaggle CSVs in MySQL, with every stage
reconciled against an independent implementation before moving to the next.
**This is the version to run.**

## Order

| File | Builds | Verify |
|---|---|---|
| `mysql_00_create_tables.sql` | 8 raw tables, typed and keyed | 8 tables |
| `mysql_01_load_data.sql` | loads the CSVs | 99,441 / 112,650 / **99,224** reviews / 32,951 / 3,095 / 103,886 / 71 |
| `mysql_02_master_table.sql` | `master_orders` (one row per item per order) | **108,660 rows**, R$13,050,771.48, 95,146 orders, 92,098 people |
| `mysql_03_customer_tables.sql` | `customer_first_order`, `customer_order_counts` | 92,098 people; 28,767 full-price / 63,331 discounted |
| `mysql_heroquery.sql` | 90-day revenue by acquisition | **$73.46 vs $287.47** |
| `mysql_04_category_scorecard.sql` | `category_scorecard` | 42 categories, electronics worst |
| `mysql_05_extra_insights.sql` | delivery, geography, trend, payments | see below |

Loading requires `local_infile` enabled on both server and client — see the
header comment in `mysql_01_load_data.sql`.

## Why the row counts are in the file

Each script states its expected output. A count that moves for a reason you
can't name is the most reliable bug signal in SQL — three defects in the
original version were found exactly this way, including one that cost a single
row out of 99,224.

## Fixes carried over from the original

- **Reviews pre-aggregated** to one row per order before joining. `order_reviews`
  has no unique key (99,224 rows, 98,410 distinct `review_id`), so joining it
  directly multiplies item rows.
- **NULL-category exclusion stated explicitly** in the `WHERE` clause rather
  than happening invisibly through a join on a nullable column.
- **Category benchmark restricted to delivered orders**, matching the
  population being compared against it.

## Supplementary findings (`mysql_05`)

- **Delivery lateness vs review score** — 4.31 stars when early, 2.99 once late
  by a day, 1.74 by day six, then flat. The damage lands immediately and is
  mostly done by day five.
- **Late rate by state** — MA 17.4%, RJ 13.5% against SP's 5.9%. RJ is the
  second-largest market and the clearest operational target.
- **Geography** — remote states show *higher* 90-day revenue (MT R$210 vs SP
  R$145) alongside roughly double the freight burden (26% vs 14% of order
  value): distant customers consolidate purchases.
- **Monthly trend** — discount rate flat at 68–72% for 19 months while volume
  grew ~8x. Discounting here is a standing posture, not a campaign lever.
