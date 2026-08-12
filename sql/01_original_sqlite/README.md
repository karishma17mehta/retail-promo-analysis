# 01 — Original analysis (SQLite)

The first pass at the question, written against SQLite. **Kept for history, not
for reuse** — run [`../02_mysql_rebuild/`](../02_mysql_rebuild/) instead.

These files were corrected in commit `aefc6f8` to key person-level analysis on
`customer_unique_id` rather than the per-order `customer_id`, but they still
carry three join defects that were only found later and fixed in the rebuild:

| Defect | Effect |
|---|---|
| `order_reviews` joined directly (up to 3 rows per order) | +635 phantom item rows, revenue overstated by R$57,627 |
| Category benchmark inner-joined on a nullable column | 1,537 items dropped silently — `NULL` never matches |
| Benchmark computed over all order statuses | items compared against a population they aren't part of |

The Python notebooks in [`../../notebooks/`](../../notebooks/) were built on this
version and carry correction banners at the top.
