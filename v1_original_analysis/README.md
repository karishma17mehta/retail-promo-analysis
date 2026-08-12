# v1 — Original analysis (SQLite + Python)

The first pass at the question. **Kept for history — run
[`../v2_mysql_rebuild/`](../v2_mysql_rebuild/) instead.**

| Folder | Contents |
|---|---|
| `sql/` | SQLite pipeline: master table, LTV, hero query, category scorecard |
| `notebooks/` | EDA, OLS regression, robustness check, RFM segmentation |
| `output/` | charts produced by the notebooks |
| `clean/` | processed CSVs this version produced |

## What this version got wrong

**Corrected in commit `aefc6f8`** — person-level analysis was keyed on
`customer_id`, which in Olist is unique *per order*; the person is
`customer_unique_id`. One customer appears under 17 different `customer_id`
values. Keying on it made repeat detection structurally impossible: the
"repeat customers" reported here were multi-item orders, not returning buyers.

After re-keying, the revenue finding *strengthened* (the gap widened from 70%
to 74%) but the RFM and churn claims did not survive and were retracted — true
repeat rate is ~3% for both acquisition groups.

**Found later, fixed in v2** — three join defects that survived the first
correction:

| Defect | Effect |
|---|---|
| `order_reviews` joined directly (up to 3 rows per order) | +635 phantom item rows; revenue overstated by R$57,627 |
| Category benchmark inner-joined on a nullable column | 1,537 items dropped silently — `NULL` never matches |
| Benchmark computed across all order statuses | items compared against a population they aren't part of |

The notebooks carry correction banners at the top; their charts and printed
outputs predate both rounds of fixes.
