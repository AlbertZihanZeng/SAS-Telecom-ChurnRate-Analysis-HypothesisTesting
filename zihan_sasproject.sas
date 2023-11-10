*libname TP "C:\Users\zihan\Documents\Metro College\5. SAS\Project";

/*1.1  Explore and describe the dataset briefly. For example, is the acctno unique? What
is the number of accounts activated and deactivated? When is the earliest and
latest activation/deactivation dates available? And so on¡­.*/

data tc;
	infile "C:\Users\zihan\Documents\Metro College\5. SAS\Project\New_Wireless_Fixed.txt"
		DLM=" " truncover;
	input Acctno$ 1-13
		@15 Actdt mmddyy10.
		@26 Deactdt mmddyy10.
		DeactReason$ 41-44
		@53 GoodCredit
		@62 RatePlan
		DealerType$ 65-66
		Age 74-75
		Province$ 80-81
		_Sales $ 83-92;
	Sales = input(_Sales,dollar32.);
	format Actdt Deactdt mmddyy10. Sales dollar8.2;
	drop _Sales;
run;
proc print data=tc (obs=50);run;

proc means data=tc n nmiss;run;
proc sql;
	select count(*) as accts,count(distinct acctno) as unique_accts
	from tc
;quit;
proc means data=tc n nmiss mean median stddev min max;
var Actdt Deactdt Age Sales;
run;
proc freq data=tc;
table DeactReason GoodCredit RatePlan DealerType Province;
run;

data acctdt;
	min_acctdt = 14264;
	max_acctdt = 14995;
	n_acct = 102255;
	min_deactdt = 14269;
	max_deactdt = 14995;
	n_deact = 19635;
	n_active = n_acct-n_deact;
format min_acctdt max_acctdt min_deactdt max_deactdt mmddyy10.;
proc print;run;


/*1.2  What is the age and province distributions of active and deactivated customers?*/

proc sgplot data=tc;
histogram Age;
run;
proc sgplot data=tc;
vbar Province;
run;

proc sgplot data=tc1;
title 'Account Status by Age Group';
vbar AgeGrp /group=Status;
run;title;
proc freq data=tc1;
table AgeGrp*Status /chisq nopercent;
run;

proc sgplot data=tc1;
title 'Account Status by Province';
vbar Province /group=Status;
run;title;
proc freq data=tc1;
table Province*Status /chisq nopercent;
run;


/*1.3 Segment the customers based on age, province and sales amount:
Sales segment: < $100, $100---500, $500-$800, $800 and above.
Age segments: < 20, 21-40, 41-60, 60 and above.*/

proc format;
value AgeGroup
	low-<20 ='Under 20'
	20 - 40 ='21-40'
	40 - 60 ='41-60'
	61-high ='Above 60'
;
value SalesGroup
	low -<100 ='Below 100'
	100 - 500 ='100-500'
	500 - 800 ='500-800'
	800 -high ='Above 800'
;
run;
data tc1;
	set tc;
	format AgeGrp agegroup. SalesGrp salesgroup.;
	AgeGrp = Age;
	SalesGrp = Sales;
run;
proc print data=tc1 (obs=50);run;


/*1.4.Statistical Analysis:
1) Calculate the tenure in days for each account and give its simple statistics.*/

data tc1;
	set tc1;
	* last actdt = 14995;
	if missing(deactdt) then TenureDays = intck("day",actdt,14995);
	else TenureDays = intck("day",actdt,deactdt);
run;
proc print data=tc1 (obs=50);run;
proc means data=tc1 n mean std min q1 median q3 max qrange maxdec=1;
var TenureDays;
run;
proc sgplot data=tc1;
histogram TenureDays;
title "Histogram for Tenure Days";
run;title;


/*2) Calculate the number of accounts deactivated for each month.*/

proc sql;
	create table tc_periods as
	select a.Year, a.Month, a.Period, a.N_Act, b.N_Deactivates
	from (
		select year(actdt) as Year,
		  month(actdt) as Month,
		  year(actdt)*100 + month(actdt) as Period,
		  count(actdt) as N_Act
		from tc1
		group by Year,Month,Period
	) as a
	left join (
		select year(deactdt) as Year,
		  month(deactdt) as Month,
		  year(deactdt)*100 + month(deactdt) as Period,
		  count(deactdt) as N_Deactivates
		from tc1
		where deactdt is not null
		group by Year,Month,Period
	) b on b.Period = a.Period
	order by a.Period
;quit;
proc print data=tc_periods;run;

proc sgplot data=tc_periods;
title 'Number of Account Deactivation by Period';
vbar period /freq=n_deactivates;
run;title;
proc sgplot data=tc_periods;
title 'Number of Account Activation by Period';
vbar period /freq=n_act;
run;title;


/*3) Segment the account, first by account status ¡°Active¡± and ¡°Deactivated¡±, then by
Tenure: < 30 days, 31---60 days, 61 days--- one year, over one year. Report the
number of accounts of percent of all for each segment.*/

proc format;
value tenuregrp
	low- 30 = '<30 days'
	30 - 60 = '31-60 days'
	60 -365 = '61 days - one year'
	365-high= 'Over one year'
;run;
data tc1;
	set tc1;
	length Status $11;
	format Tenure tenuregrp.;
	if missing(deactdt) then Status = 'Active';
	else Status = 'Deactivated';
	Tenure = TenureDays;
run;
proc print data=tc1 (obs=50);run;

proc freq data=tc1;
table Tenure /nocum;
run;
proc sgplot data=tc1;
histogram TenureDays /group=Tenure scale=count;
title "Histogram for Tenure Days";
run;title;



/*4) Test the general association between the tenure segments and ¡°Good Credit¡±
¡°RatePlan ¡± and ¡°DealerType.¡±*/

proc freq data=tc1;
table Tenure*GoodCredit /chisq nopercent;
run;
proc freq data=tc1;
table Tenure*RatePlan /chisq nopercent;
run;
proc freq data=tc1;
table Tenure*DealerType /chisq nopercent;
run;


/*5) Is there any association between the account status and the tenure segments?
Could you find out a better tenure segmentation strategy that is more associated
with the account status?*/

proc freq data=tc1;
table Status*Tenure Tenure /chisq nopercent;
run;

proc freq data=tc1;
table Status*Tenure /nofreq norow nopercent;
run;
proc freq data=tc1;
table Tenure*Status /chisq nofreq nocol nopercent;
run;
proc sql;
	create table tc_tenure as
	select TenureDays, count(*) as n, count(deactdt) as n_deactive
	from tc1
	group by TenureDays
	order by TenureDays
;quit;
data tc_tenure;
	set tc_tenure;
	retain nsum n_deactsum;
	nsum = sum(nsum,n);
	n_deactsum = sum(n_deactsum,n_deactive);
	cum_deact_rate = n_deactsum / nsum;
	drop nsum n_deactsum;
	daily_deact_rate = n_deactive / n;
run;
proc print data=tc_tenure;run;
proc means data=tc_tenure;var cum_deact_rate;run;
proc univariate data=tc1;
var TenureDays;
class Status;
histogram TenureDays;
run;
proc sgplot data=tc_tenure;
title 'Cumulative Deactivation Rate by Tenure Days';
series x=TenureDays y=cum_deact_rate;
run;title;
proc sgplot data=tc_tenure (obs=70);
title 'Cumulative Deactivation Rate by Tenure Days <70';
series x=TenureDays y=cum_deact_rate;
run;title;
proc sgplot data=tc_tenure (obs=70);
title 'Daily Deactivation Rate by Tenure Days <70';
vbar TenureDays /response=daily_deact_rate;
run;title;
/*
data tc_tenure1;
	set tc_tenure;
	by TenureDays;
	retain tdays trate;
	if first.TenureDays then do;
		diff_days = TenureDays - tdays;
		diff_rate = cum_deact_rate - trate;
		tdays = TenureDays;
		trate = cum_deact_rate;
		end;
	rate_change = diff_rate / diff_days;
	drop diff_rate diff_days tdays trate;
run;
proc print data=tc_tenure1;run;
proc sgplot data=tc_tenure1 (obs=70);
title 'Daily Change in Cumulative Deactivation Rate';
vbar TenureDays /response=rate_change;
run;title;
*/
data tc_tenure1;
	set tc_tenure;
	length Tenure $13;
	if TenureDays < 5 then Tenure = '<5 days';
	else if TenureDays <= 20 then Tenure = '5-20 days';
	else if TenureDays <= 60 then Tenure = '21-60 days';
	else if TenureDays <= 400 then Tenure = '61-400 days';
	else Tenure = 'Over 400 days';
run;
proc print data=tc_tenure1;run;
proc sort data=tc_tenure1 out=tc_tenure1;
by Tenure;
run;
data tc_tenure1;
	set tc_tenure1;
	by Tenure;
	retain nsum n_deactsum;
	if first.Tenure then do;
		nsum = n;
		n_deactsum = n_deactive;
		cum_grp_rate = n_deactsum/nsum;
		end;
	else do;
		nsum = sum(nsum,n);
		n_deactsum = sum(n_deactsum,n_deactive);
		cum_grp_rate = n_deactsum/nsum;
		end;
	drop nsum n_deactsum;
run;
proc sort data=tc_tenure1 out=tc_tenure1;
by TenureDays;
run;
proc print data=tc_tenure1;run;

proc sgplot data=tc_tenure1;
title 'Cumulative Deactivation Rate by Tenure';
series x=TenureDays y=cum_grp_rate /group=Tenure;
run;title;


proc format;
value newtenuregrp
	low-<5 = '<5 days'
	5  - 20 = '5-20 days'
	20 - 60 = '21-60 days'
	60 -400 = '61-400 days'
	400-high= 'Over 400 days'
;run;
data tc2;
	set tc1;
	format Tenure newtenuregrp.;
	Tenure = TenureDays;
run;
proc print data=tc2 (obs=50);run;
proc freq data=tc2;
table Status*Tenure /chisq nofreq norow nopercent;
run;
proc freq data=tc2;
table Tenure*Status /chisq nofreq nocol nopercent;
run;
proc sgplot data=tc2;
vbar Tenure /group=Status;
run;


/*6) Does Sales amount differ among different account status, GoodCredit, and
customer age segments?*/

proc freq data=tc1;
table SalesGrp*Status SalesGrp*GoodCredit SalesGrp*AgeGrp /chisq nocol norow nopercent;
run;

*Check for normality;
proc univariate data=tc1 normal plot;
class Status;
var Sales;
histogram;
run;
proc univariate data=tc1 normal plot;
class GoodCredit;
var Sales;
histogram;
run;
proc univariate data=tc1 normal plot;
class AgeGrp;
var Sales;
histogram;
run;

*Check for outliers;
proc means data=tc1 std min q1 median q3 max qrange maxdec=2;
class Status;
var Sales;run;
proc sql;
	select Status, count(*) as n_outlier
	from tc1
	where (Sales > 191+3*139 and deactdt is null)
		or (Sales > 188+3*135 and deactdt is not null)
	group by Status
;quit;
proc sgplot data=tc1;
vbox Sales /group=Status;
run;

*Log transformation;
data tc_log;
	set tc1;
	SalesLog = log(Sales);
run;
proc print data=tc_log (obs=30);run;

proc means data=tc_log std min q1 median q3 max qrange maxdec=2;
var SalesLog;
run;
proc sgplot data=tc_log;
vbox SalesLog /group=Status;
run;
proc sgplot data=tc_log;
vbox SalesLog /group=GoodCredit;
run;
proc sgplot data=tc_log;
vbox SalesLog /group=AgeGrp;
run;

*Check for equal variances;
proc glm data=tc_log;
class Status;
model SalesLog=Status;
means Status / hovtest=levene(type=abs);
run;
proc glm data=tc_log;
class GoodCredit;
model SalesLog=GoodCredit;
means GoodCredit / hovtest=levene(type=abs);
run;

*T-test;
proc ttest data=tc_log;
class Status;
var SalesLog;
run;
proc ttest data=tc1 dist=lognormal;
class GoodCredit;
var Sales;
run;

*Anova for AgeGrp;
proc glm data=tc_log;
class AgeGrp;
model SalesLog=AgeGrp;
means AgeGrp / hovtest=levene(type=abs) welch;
run;



*non-parametric test;
proc npar1way data=tc1;
class Status;
var Sales;
run;
proc npar1way data=tc1;
class GoodCredit;
var Sales;
run;
proc npar1way data=tc1;
class AgeGrp;
var Sales;
run;


************;

/*Other bivariate analysis;*/

*Status;
proc freq data=tc1;
table Status*GoodCredit Status*RatePlan Status*DealerType /chisq nopercent;
run;

*Tenure;
proc freq data=tc1;
table Tenure*AgeGrp Tenure*SalesGrp /chisq nofreq nopercent;
run;

*AgeGrp;
proc freq data=tc1;
table AgeGrp*GoodCredit AgeGrp*RatePlan AgeGrp*DealerType /chisq nofreq nopercent;
run;

*GoodCredit/RatePlan/DealerType;
proc freq data=tc1;
table GoodCredit*DealerType GoodCredit*RatePlan RatePlan*DealerType /chisq nofreq nopercent;
run;

*SalesGroup;
proc freq data=tc1;
table SalesGrp*Tenure SalesGrp*RatePlan SalesGrp*DealerType /chisq nofreq nopercent;
run;

*DeactReason;
proc freq data=tc1;
table DeactReason*Tenure DeactReason*AgeGrp DeactReason*GoodCredit 
	DeactReason*RatePlan DeactReason*DealerType /chisq nofreq nopercent;
run;
proc npar1way data=tc1;
class DeactReason;
var Sales;
run;

*Sales*TenureDays correlation;
proc corr data=tc1;
var Sales;
with TenureDays;
run;


/*Overall account deactivation rate by tenure*/

proc sql;
create table tc_tenure2 as
select Tenure, count(deactdt)/102255 as Deactivation_rate
from tc1
group by Tenure
order by Tenure
;quit;
proc sgplot data=tc_tenure2;
title 'Overall Deactivation Rate by Tenure';
vbar Tenure /response=Deactivation_rate;
run;title;



