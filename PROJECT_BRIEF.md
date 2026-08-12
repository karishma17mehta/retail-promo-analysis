# Retail Promotion Effectiveness Analysis — Project Brief

---

## 1. Objective

**Business question:** Does promotional discounting build long-term customer value, or does it only buy short-term transaction volume?

This matters because discounting is one of the few levers a retailer can pull unilaterally and immediately. It reliably lifts units sold — that part is never in doubt. The open question is what *kind* of customer it brings, and whether that customer is worth the margin given up. If discount-acquired customers spend as much over time as full-price customers, discounting is efficient acquisition. If they don't, it's margin erosion dressed up as growth.

**Decision the analysis feeds:** a category-level go/no-go on promotional spend — which categories should keep discounting, and which should restructure.

---

## 2. The data

**Olist** — a Brazilian e-commerce marketplace, public on Kaggle. Nine linked tables covering Sept 2016 – Aug 2018.

| Metric | Value |
|---|---|
| Order items (analysis grain) | 108,660 |
| Distinct orders | 95,146 |
| Distinct customers (people) | 92,098 |
| Total revenue | R$ 13,050,771 |
| Product categories | 71 total; **42** with >200 customers (scorecard set) |

**Critical limitation of the source:** Olist has **no discount or promotion field.** There is no column saying "this item was on sale." Everything downstream depends on a proxy — which becomes the project's central design decision and its main vulnerability.

---

## 3. The SQL pipeline — what and why

Five raw tables joined into one analysis-ready table, then three derived tables.

**`master_orders`** — one row per item per order. Joins `orders → order_items → products → customers`, plus reviews and category translations. Filtered to `order_status = 'delivered'` (cancelled orders would pollute revenue).

*Why item grain:* price and category are recorded per item. An order containing a book and a chair has no single price and no single category. Build at order grain and category analysis becomes impossible. You can always aggregate up; you can never split back down.

**`customer_first_order`** — one row per person, carrying the acquisition flag and first purchase date.
**`customer_order_counts`** — distinct orders per person (repeat detection).
**`customer_ltv`** — revenue per person in the 90 days from first purchase.
**`category_scorecard`** — the recommendation table: per category, discount rate, AOV, review score, 90-day revenue, repeat rate.

**Three correctness issues found and fixed during review:**
1. `order_reviews` has up to 3 rows per order — joining it directly duplicated item rows and inflated revenue by R$57,627 (+0.44%).
2. The category-average subquery inner-joined on `product_category_name`; NULL never matches, so 1,537 items vanished silently. Now excluded explicitly.
3. The category-average benchmark was computed over *all* orders while the analysis covered only *delivered* orders — comparison group and analysis population must come from the same universe.

---

## 4. The discount proxy — the central design decision

**Definition used:** an item is flagged discounted if its price is below the average price of its category.

**Why category-relative:** R$50 means something different for electronics than for furniture. Comparing to the category norm is what makes "cheap" interpretable.

**What it actually measures — and this is the honest caveat:** the flag captures *"is this a cheap product"* more than *"was this item marked down."* Because prices are right-skewed, ~70% of items fall below their own category's mean. A stricter, more literal markdown definition — comparing each item to *that same product's* typical selling price — flags only 9.3% of items, and the two definitions agree on just 35%.

So the proxy is a reasonable first pass, but it conflates *product choice* with *promotion*. Any interpretation must be phrased as association, not causation.

---

## 5. The person-level key — the correction that mattered

In Olist, **`customer_id` is unique per order**; `customer_unique_id` identifies the person. One customer in the data appears under 17 different `customer_id` values.

The first version of this analysis grouped by `customer_id`, which makes repeat-purchase detection structurally impossible — every "customer" had exactly one order by construction. Its "repeat customers" were actually multi-item orders.

**After re-keying on `customer_unique_id`:**
- The revenue finding **strengthened** (gap widened from 70% to 74%)
- The regression coefficient barely moved (−165 → −159), confirming the core result was sound
- The RFM/churn claims were **retracted** — true repeat rate is ~3% for both groups

**Transferable lesson:** the grain of your key must match the grain of your claim. A person-level claim requires a person-level key.

---

## 6. The regression — what it does and why

**Specification:** OLS of 90-day customer revenue on the acquisition flag, controlling for first-order category, first-order month (seasonality), freight value; top 1% of revenue trimmed.

**Result:** −159.28 BRL, 95% CI [−160.73, −157.83], p < 0.001, n = 91,184, R² = 0.468.

Note the R²: most of the explained variance comes from the category controls, not the discount flag. The coefficient is a difference, not a model of what drives customer value.

**Why run it at all — this is the point most people miss.** The raw comparison ($73 vs $287) invites an obvious objection: *"discount-acquired customers might simply be buying in cheaper categories."* If so, the gap says nothing about discounting. Controls answer exactly that objection: the coefficient is the difference in revenue between the two groups *within the same category, same month, similar freight.* Controls are named confounders you're ruling out.

**Why it is not causal.** Customers were not randomly assigned to discounts — they self-selected. Any unobserved trait (budget-consciousness, product need) could drive both. Controls handle confounders you can name and measure; they cannot handle the ones you can't. A causal answer requires a randomised pricing test.

---

## 7. Robustness check

Re-ran the regression with a stricter definition — bottom 25th percentile of category price rather than below-mean.

**Result:** −92.12 BRL, p < 0.001. Direction and significance hold; magnitude shrinks.

**Why it matters:** the discount flag was invented, not observed. If the finding only existed under one arbitrary threshold, it would be an artifact of that choice. Surviving an independent definition is evidence the signal is real.

---

## 8. Findings

1. **Discount-acquired customers generate R$73 vs R$287** in 90-day revenue — a 74% gap (n = 92,098).
2. **Regression confirms −159 BRL** after controls (p < 0.001, n = 91,184), robust under a stricter definition (−92 BRL).
3. **Repeat purchasing is ~3% and essentially identical** across groups (2.6% full-price, 3.1% discount-acquired). Discounting does not differentially drive churn — this marketplace has a structural retention problem affecting everyone.
4. **The differentiator is spend level, not loyalty.** The opportunity is in acquisition quality, not retention.
5. **Worst categories:** electronics (75.3% discount rate, R$72 revenue), food (63.5%, R$76), food_drink (75.8%, R$83) — against a R$141 average. By customer volume the biggest prizes are health_beauty (8,498 customers), telephony (4,047) and electronics (2,507).
6. **Delivery timing outweighs price for satisfaction by roughly 100×.** Review scores span 2.6 stars across delivery timing (4.31 early → 1.73 very late) versus 0.02 stars between discounted and full-price orders. The relationship has three regimes: flat at 4.28 for anything early, a steep decline of **0.373 stars per day** through day six (R² = 0.98), then flat at 1.61. Early delivery buys nothing extra; past a week the customer has written the order off. Rio de Janeiro is the clearest operational target — 13.5% late against São Paulo's 5.9%, in the second-largest market.

---

## 9. Known limitations — state these before you're asked

- **The proxy measures cheapness, not markdown.** A product-level markdown definition flags 9.3% of items vs 68.9%, agreeing only 35% of the time.
- **The outcome window is dominated by the first order.** 98.3% of "90-day revenue" *is* the first purchase — and the group is assigned by that same purchase's price, so the headline comparison is substantially mechanical. Isolating **post-first-order** spend removes the circularity: R$3.33 vs R$2.01 per customer, a 1.66x gap (Welch t-test p < 0.0001). Notably the two components move in opposite directions — discount-acquired customers are *more* likely to return (1.88% vs 1.55%, χ² p = 0.0004) but spend far less when they do (~R$107 vs ~R$215 per returner). Discounting buys smaller baskets, not lower loyalty.
- **Observational data.** Associations only.
- **Retention cannot be studied here.** ~97% of customers buy once; cohort curves are uninformative.

---

## 10. Tableau dashboard

Two tabs, [published on Tableau Public](https://public.tableau.com/app/profile/karishma.mehta8733/viz/RetailPromotionEffectivenessOlistAnalysis/Dashboard1).

**Tab 1 — Promotion effectiveness.** Hero comparison ($73 vs $287 by acquisition type), category scorecard with a Reduce / Monitor / Maintain recommendation per category, and 90-day customer revenue against promotional depth.

The recommendation rule is explicit: *Reduce Promo Depth* flags categories in the top quartile of discount rate (>75% of items below their category average price) that also fall below the median 90-day customer revenue of $153 — high promotional cost, low customer return.

**Tab 2 — Delivery performance.** Review score by delivery timing, and a day-level scatter isolating the six-day window where satisfaction actually moves.

**Design intent:** every chart title states a finding rather than describing the chart — "Discount Buyers Generate 74% Less Revenue in 90 Days", "Every Day Late Costs a Third of a Star". A reader who only reads titles still leaves with the argument.

---

## 11. Recommendation

**Restructure promotional spend in electronics and food/food_drink first.** These categories combine the highest discount exposure (63–76% of items below category average) with the lowest 90-day customer revenue (R$74–85 vs R$141 average). Discounting there is buying the least valuable customers at the highest frequency.

**What "restructure" means concretely:** shift from broad price-led promotion toward targeted offers, and run a controlled pricing test in one or two categories before chain-wide change — precisely because this analysis is observational and cannot establish causation on its own.

---

## 12. Interview quick answers

| Question | Answer |
|---|---|
| "Walk me through it" | Business question → SQL pipeline at item grain → promote discount flag to a customer attribute via first order → compare 90-day revenue → regression for confounders → robustness check → category recommendation. |
| "How did you define discount without a discount field?" | Price below category average. It's a proxy; it captures cheapness more than markdown, which is why I tested a stricter definition and a product-level markdown definition. |
| "Is it causal?" | No. Observational, self-selected. Controls rule out named confounders only. A pricing A/B test is the next step. |
| "What would you do differently?" | Measure post-acquisition spend rather than a window dominated by the first order, and use a product-level markdown flag. |
| "What did you get wrong?" | Keyed on `customer_id`, which is per-order in Olist. Re-ran person-level: core finding strengthened, retention claims retracted. |
