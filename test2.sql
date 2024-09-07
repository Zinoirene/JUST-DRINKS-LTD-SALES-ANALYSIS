---To Create an Aggregate Table for Vendor Billings and Purchasing Activity---

CREATE TABLE DataPrep1_AggregatedVendorActivity AS
SELECT 
    VendorNumber,
	VendorName,
    SUM(Dollars) AS TotalBilled,
    SUM(Quantity) AS TotalQuantityPurchased
FROM 
VendorInvoices
Group By 1, 2;
	
Select * From DataPrep1_AggregatedVendorActivity;

---To Create a Table showing Top 10 Vendors by Quantity Purchased---	
CREATE TABLE DataPrep1_Top10VendorsByQuantity AS
SELECT 
    VendorNumber,
    VendorName,
    SUM(Quantity) AS TotalQuantityPurchased
FROM 
    Purchases
GROUP BY 
    1, 2
ORDER BY 
    TotalQuantityPurchased DESC
LIMIT 10;

Select * from DataPrep1_Top10VendorsByQuantity;


---To Create additional Table insight showing Top 10 by billings(money spent)---
CREATE TABLE DataPrep1_TopVendorsByBilling AS
SELECT 
    VendorNumber,
    VendorName,
    SUM(Dollars) AS TotalDollarsBilled
FROM 
    VendorInvoices
GROUP BY 
    VendorNumber, VendorName
ORDER BY 
    TotalDollarsBilled DESC
LIMIT 10;

Select * from DataPrep1_TopVendorsByBilling;

--- To create an additional table insight Inventory Purchase and Trends---
Drop TABLE DataPrep2_InventoryCycleAnalysis;
CREATE TABLE DataPrep2_InventoryCycleAnalysis AS
SELECT
	p.InventoryId,
    p.Description,
	pp.VendorName,
	pp.VendorNumber,
    p.Brand,
	pp.PurchasePrice,
	p.Quantity,
    p.ReceivingDate,
    JULIANDAY(LEAD(p.ReceivingDate) OVER (PARTITION BY p.Description ORDER BY p.ReceivingDate)) - JULIANDAY(p.ReceivingDate) AS DaysUntilNextReceiving
FROM Purchases AS p
JOIN PurchasePrices AS pp
ON p.Description = pp.Description AND p.VendorNumber = pp.VendorNumber
ORDER BY p.Description, p.ReceivingDate;

Select * from DataPrep2_InventoryCycleAnalysis;


Create table DataPrep2_InventoryCycleAnalysis_v2 AS
SELECT
    p.InventoryId,
    p.Store,
	p.Quantity,
	p.PurchasePrice,
	p.dollars,
    p.Brand,
    p.Description,
    p.ReceivingDate AS PurchaseDate,
    fi.endDate AS LastInventoryDate,
    julianday(fi.endDate) - julianday(p.ReceivingDate) AS DaysInInventory
FROM
    Purchases p
LEFT JOIN
    FinalInventory fi ON p.InventoryId = fi.InventoryId AND p.Store = fi.Store
WHERE
    p.ReceivingDate IS NOT NULL AND fi.endDate IS NOT NULL;
	
Select * from DataPrep2_InventoryCycleAnalysis_v2;
--Where DaysInInventory >= 365;

-- To Create Sales TABLE----
create table all_purchases_v2 as
select * from
(select InventoryId, Store, Brand, PurchasePrice, Quantity
from Purchases
union all
select InventoryId, Store, Brand, Price as PurchasePrice, onHand as Quantity
from StartInventory); --This Union was done to merge the Purchases Table and StartInventory table to get the total Quantity of Goods and their prices within the year


create table purchase_evolved_v2_store as
select
a.*,
coalesce(b.onHand, 0) as onHand, -- used to ensure the finalinventory table do not return a Null value
c.Size,
c.Classification,
c.selling_price
from
(
select
Store,
InventoryId,
Brand,
avg(PurchasePrice) PurchasePrice,
sum(Quantity) total_qty
FROM
all_purchases_v2
group by 1, 2,3
) as a
left JOIN
(
select
Store,
InventoryId,
onHand
from 
FinalInventory
) as b on a.InventoryId = b.InventoryId and a.Store = b.Store
left join
(
select
Brand,
Size,
Price as selling_price,
Classification
FROM
PurchasePrices
) as c on a.Brand = c.Brand;


Create Table purchase_evolved_v3_store as
select
*,
(selling_price * sold_qty) as Final_Sales
FROM
(
Select
*,
(total_qty - onHand) as sold_Qty
FROM
purchase_evolved_v2_store
);

---Select 
Classification,
Sum(final_sales) as total_sales
From
purchase_evolved_v3
---Group By 1;---

select * from purchase_evolved_v2_store;

select
Store,
Classification,
avg(selling_price) as Average_Sales_Price
from
purchase_evolved_v2_store
group by 1,2;

Create table purchase_evolved_v5_store as
SELECT
a.*,
b.Volume
from
(
select
*
FROM
purchase_evolved_v3_store
) as a
left JOIN
(
select
Brand,
volume
from PurchasePrices
) as b on a.Brand = b.Brand;

Select * from purchase_evolved_v5_store;

Select Classification,
volume,
Sum(sold_Qty) as Qty_sold,
Sum(final_sales) as Sales_Dollars
from
purchase_evolved_v5_store
Group by 1,2;

Select Classification,
sum(final_sales) AS Total_sales_Dollars
From purchase_evolved_v5
Group by Classification;

Select Sum(final_sales)
From purchase_evolved_v5_store;

Select Store,
Classification,
Avg(final_sales)
from purchase_evolved_v5
Group by Classification, Store;