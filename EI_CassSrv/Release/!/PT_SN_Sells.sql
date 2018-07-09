Select CAST('0' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
from "EcrSells" a
left join "Ecrs" c on (c.sernumber=a.sernumber)
left join "Departs" d on (d.id=c.departid)
where
(a.moment >= '%DATE_BEGIN%') and
(a.moment < '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0) and
a.EcrPayID not in (select b.ID from  "EcrPays" b
  where
  (b.moment >= '%DATE_BEGIN%') and
  (b.moment < '%DATE_END%'))
Group by CAST('0' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
union all
Select CAST('0' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
From "EcrSells" a
left join "EcrPays" b on (b.id=a.EcrPayID)
left join "Ecrs" c on (c.sernumber=b.sernumber)
left join "Departs" d on (d.id=c.departid)
Where
(b.oper in (5,10,11)) and (b.chknumber <> a.chknumber) and
(b.moment >= '%DATE_BEGIN%') and
(b.moment < '%DATE_END%') and            
(a.moment >= '%DATE_BEGIN%') and
(a.moment <= '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0)
Group by CAST('0' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
union all
Select CAST('0' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
From "EcrSells" a
left join "EcrPays" b on (b.id=a.EcrPayID)
left join "Ecrs" c on (c.sernumber=b.sernumber)
left join "Departs" d on (d.id=c.departid)
Where
(b.oper in (1,2)) and (b.total = 0) and
(b.moment >= '%DATE_BEGIN%') and
(b.moment < '%DATE_END%') and            
(a.moment >= '%DATE_BEGIN%') and
(a.moment <= '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0)
Group by CAST('0' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
union all
Select CAST('0' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
From "EcrSells" a
left join "EcrPays" b on (b.id=a.EcrPayID)
left join "Ecrs" c on (c.sernumber=b.sernumber)
left join "Departs" d on (d.id=c.departid)
Where
(b.oper in (1,2)) and
(b.moment >= '%DATE_BEGIN%') and
(b.moment < '%DATE_END%') and            
(b.paycash <> 0) and
(a.moment >= '%DATE_BEGIN%') and
(a.moment <= '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0)
Group by CAST('0' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
union all
Select CAST('1' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
From "EcrSells" a
left join "EcrPays" b on (b.id=a.EcrPayID)
left join "Ecrs" c on (c.sernumber=b.sernumber)
left join "Departs" d on (d.id=c.departid)
Where
(b.oper in (1,2)) and
(b.moment >= '%DATE_BEGIN%') and
(b.moment < '%DATE_END%') and            
(b.paycheck <> 0) and
(a.moment >= '%DATE_BEGIN%') and
(a.moment <= '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0)
Group by CAST('1' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
union all
Select CAST('2' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
From "EcrSells" a
left join "EcrPays" b on (b.id=a.EcrPayID)
left join "Ecrs" c on (c.sernumber=b.sernumber)
left join "Departs" d on (d.id=c.departid)
Where
(b.oper in (1,2)) and
(b.moment >= '%DATE_BEGIN%') and
(b.moment < '%DATE_END%') and            
(b.paycredit <> 0) and
(a.moment >= '%DATE_BEGIN%') and
(a.moment <= '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0)
Group by CAST('2' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
union all
Select CAST('3' as integer), d.Number as Depart, a.sernumber, a.EcrCode as Code, a.Price,
sum(a.Quantity) as Quantity, sum(a.Total) as Summa, sum(a.TaxSum) as TaxSum,
sum(a.Addition - a.Discount) as AddDisc
From "EcrSells" a
left join "EcrPays" b on (b.id=a.EcrPayID)
left join "Ecrs" c on (c.sernumber=b.sernumber)
left join "Departs" d on (d.id=c.departid)
Where
(b.oper in (1,2)) and
(b.moment >= '%DATE_BEGIN%') and
(b.moment < '%DATE_END%') and            
(b.paycard <> 0) and
(a.moment >= '%DATE_BEGIN%') and
(a.moment <= '%DATE_END%') and
(d.Number = %DEPART% or %DEPART% = 0)
Group by CAST('3' as integer), d.Number, a.sernumber, a.EcrCode, a.Price, a.TaxNumber, abs(a.Discount)
having sum(a.Quantity) <> 0
Order by 1,2,3,4
