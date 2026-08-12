"""
OLS of 90-day customer revenue on discount acquisition.

Rebuilds the v2 pipeline from the raw Kaggle CSVs (same logic as
sql/mysql_02_master_table.sql and sql/mysql_03_customer_tables.sql), then
fits the regression and the robustness check.

Why the regression exists: the raw $73 vs $287 gap invites the objection
"discount-acquired customers might simply be buying in cheaper categories."
Controls answer exactly that -- the coefficient is the difference *within*
the same category, month and freight band. It is not a causal estimate;
customers self-selected into discounted purchases.

Run:  python3 v2_mysql_rebuild/regression.py
"""
import pandas as pd
import statsmodels.formula.api as smf

DATA = 'data/'

# ---------- master_orders (mirrors mysql_02) ----------
orders = pd.read_csv(DATA + 'olist_orders_dataset.csv',
                     parse_dates=['order_purchase_timestamp'])
items = pd.read_csv(DATA + 'olist_order_items_dataset.csv')
products = pd.read_csv(DATA + 'olist_products_dataset.csv')[
    ['product_id', 'product_category_name']]
customers = pd.read_csv(DATA + 'olist_customers_dataset.csv')[
    ['customer_id', 'customer_unique_id']]

m = (orders[orders.order_status == 'delivered']
     [['order_id', 'customer_id', 'order_purchase_timestamp']]
     .merge(items[['order_id', 'product_id', 'price', 'freight_value']], on='order_id')
     .merge(products, on='product_id')
     .merge(customers, on='customer_id')
     .rename(columns={'order_purchase_timestamp': 'order_date',
                      'product_category_name': 'category'}))
m = m[m.category.notna()]
assert len(m) == 108660, f"expected 108,660 master rows, got {len(m):,}"

# discount flag: priced below the category average (delivered orders only)
m['discount_flag'] = (m.price < m.groupby('category')['price'].transform('mean')).astype(int)

# ---------- person-level tables (mirrors mysql_03) ----------
first_date = m.groupby('customer_unique_id')['order_date'].transform('min')
first_items = m[m.order_date == first_date]

# acquisition flag: any item in the first order was discounted
cfo = first_items.groupby('customer_unique_id').agg(
    acquired_via_discount=('discount_flag', 'max')).reset_index()
# first-order attributes: take the first item listed
cfo = cfo.merge(
    first_items.sort_values('order_date').groupby('customer_unique_id')
    .agg(first_order_date=('order_date', 'first'),
         category=('category', 'first'),
         freight_value=('freight_value', 'first')).reset_index(),
    on='customer_unique_id')

# 90-day revenue per person
w = m.merge(cfo[['customer_unique_id', 'first_order_date']], on='customer_unique_id')
w = w[w.order_date <= w.first_order_date + pd.Timedelta(days=90)]
ltv = w.groupby('customer_unique_id', as_index=False)['price'].sum() \
       .rename(columns={'price': 'ltv_90d'})

reg = cfo.merge(ltv, on='customer_unique_id')
reg['order_month'] = reg.first_order_date.dt.month
assert len(reg) == 92098, f"expected 92,098 customers, got {len(reg):,}"

# trim the top 1% -- a handful of very large baskets otherwise dominate the fit
cap = reg.ltv_90d.quantile(0.99)
reg = reg[reg.ltv_90d <= cap].dropna()

FORMULA = 'ltv_90d ~ {flag} + freight_value + order_month + C(category)'

print("=" * 62)
print("OLS: 90-day customer revenue ~ discount acquisition + controls")
print("=" * 62)
main = smf.ols(FORMULA.format(flag='acquired_via_discount'), data=reg).fit()
ci = main.conf_int().loc['acquired_via_discount']
print(f"  coefficient : {main.params['acquired_via_discount']:>10.2f} BRL")
print(f"  95% CI      : [{ci[0]:.2f}, {ci[1]:.2f}]")
print(f"  p-value     : {main.pvalues['acquired_via_discount']:.3g}")
print(f"  n           : {int(main.nobs):,}")
print(f"  R-squared   : {main.rsquared:.3f}")

# ---------- robustness: stricter discount definition ----------
p25 = m.groupby('category')['price'].quantile(0.25).rename('p25')
m2 = m.merge(p25, on='category')
m2['strict_flag'] = (m2.price < m2.p25).astype(int)
strict = (m2[m2.order_date == m2.groupby('customer_unique_id')['order_date'].transform('min')]
          .groupby('customer_unique_id', as_index=False)['strict_flag'].max())

reg2 = reg.merge(strict, on='customer_unique_id')
alt = smf.ols(FORMULA.format(flag='strict_flag'), data=reg2).fit()
print("\nRobustness -- strict definition (bottom 25th pct of category price)")
print(f"  coefficient : {alt.params['strict_flag']:>10.2f} BRL")
print(f"  p-value     : {alt.pvalues['strict_flag']:.3g}")
print(f"  n           : {int(alt.nobs):,}")

# ---------- the honest caveat ----------
w2 = w.merge(cfo[['customer_unique_id', 'acquired_via_discount']], on='customer_unique_id')
w2['is_first'] = w2.order_date == w2.first_order_date
share = w2.loc[w2.is_first, 'price'].sum() / w2.price.sum() * 100
print("\nCaveat: %.1f%% of 90-day revenue IS the first order, and the group is" % share)
print("assigned by that same order's price. The comparison is substantially")
print("mechanical; post-acquisition spend is the non-circular outcome.")

after = (w2[~w2.is_first].groupby('acquired_via_discount')['price'].sum()
         / w2.groupby('acquired_via_discount')['customer_unique_id'].nunique())
print(f"  post-first-order spend: full price {after[0]:.2f} vs discounted {after[1]:.2f} BRL")
